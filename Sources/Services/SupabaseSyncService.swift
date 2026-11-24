import Foundation
import Observation
import Supabase

// MARK: - Timeframe

enum Timeframe: String, Codable, CaseIterable, Sendable {
    case today
    case thisWeek
    case thisMonth

    var displayName: String {
        switch self {
        case .today: "Today"
        case .thisWeek: "This Week"
        case .thisMonth: "This Month"
        }
    }
}

// MARK: - FriendStats

struct FriendStats: Codable, Identifiable, Sendable {
    let id: UUID
    let displayName: String
    let avatarInitials: String
    let completionRate: Double
    let totalCompletions: Int
    let currentStreak: Int

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarInitials = "avatar_initials"
        case completionRate = "completion_rate"
        case totalCompletions = "total_completions"
        case currentStreak = "current_streak"
    }
}

// MARK: - Supabase Data Payloads (Strictly Anonymized — Never Contains Habit Names)

private struct ProfileRowPayload: Encodable, Sendable {
    let id: String
    let display_name: String
    let friend_code: String
}

private struct DailyStatsRowPayload: Encodable, Sendable {
    let user_id: String
    let date: String
    let completed_count: Int
    let scheduled_count: Int
    let completion_rate: Double
    let active_streak: Int
    let updated_at: String
}

private struct FriendConnectionRowPayload: Encodable, Sendable {
    let user_id_a: String
    let user_id_b: String
}

// MARK: - SupabaseSyncService

@Observable
final class SupabaseSyncService: @unchecked Sendable {

    // MARK: Published State

    var isConfigured: Bool = false
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var displayName: String = "Habit Tracker"
    var friendCode: String = ""
    var friends: [FriendStats] = []

    // MARK: Private

    private var client: SupabaseClient?

    // MARK: Init

    init() {
        let url = UserDefaults.standard.string(forKey: "supabase_url")
        let key = UserDefaults.standard.string(forKey: "supabase_anon_key")
        let savedName = UserDefaults.standard.string(forKey: "displayName")
        let savedCode = UserDefaults.standard.string(forKey: "friendCode")

        if let savedName, !savedName.isEmpty {
            self.displayName = savedName
        }
        if let savedCode, !savedCode.isEmpty {
            self.friendCode = savedCode
        }

        if let url, let key, let supabaseURL = URL(string: url), !url.isEmpty, !key.isEmpty {
            self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
            self.isConfigured = true
        }
    }

    // MARK: - Configuration

    func configure(url: String, anonKey: String) {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)

        UserDefaults.standard.set(trimmedURL, forKey: "supabase_url")
        UserDefaults.standard.set(trimmedKey, forKey: "supabase_anon_key")

        guard let supabaseURL = URL(string: trimmedURL), !trimmedURL.isEmpty, !trimmedKey.isEmpty else { return }
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: trimmedKey)
        self.isConfigured = true
    }

    // MARK: - Friend Code Generation

    func generateFriendCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    // MARK: - Auth

    /// Sign in anonymously using Supabase Auth.
    func signInAnonymously() async throws {
        guard let client else { return }
        try await client.auth.signInAnonymously()
    }

    /// Retrieve the current authenticated user's ID.
    private func currentUserID() async throws -> UUID? {
        guard let client else { return nil }

        // Attempt to fetch active session
        var session = try? await client.auth.session
        if session == nil {
            try await signInAnonymously()
            session = try? await client.auth.session
        }

        return session?.user.id
    }

    /// Ensure the current user has a session, a friend code, and a profile row.
    func ensureUser() async throws {
        guard let client else { return }
        guard let userID = try await currentUserID() else { return }

        // Generate and persist a friend code if we don't have one yet.
        if friendCode.isEmpty {
            friendCode = generateFriendCode()
            UserDefaults.standard.set(friendCode, forKey: "friendCode")
        }

        // Upsert the profile row.
        let payload = ProfileRowPayload(
            id: userID.uuidString,
            display_name: displayName,
            friend_code: friendCode
        )

        try await client.from("profiles")
            .upsert(payload, onConflict: "id")
            .execute()
    }

    // MARK: - Sync Daily Stats

    /// Upsert today's aggregate stats. NEVER sends habit names — only anonymized counts.
    func syncDailyStats(
        completedCount: Int = 0,
        scheduledCount: Int = 0,
        completionRate: Double = 0.0,
        activeStreak: Int = 0
    ) async throws {
        guard let client else { return }
        try await ensureUser()

        guard let userID = try await currentUserID() else { return }

        isSyncing = true
        defer { isSyncing = false }

        let today = Self.iso8601DateString(for: .now)

        let payload = DailyStatsRowPayload(
            user_id: userID.uuidString,
            date: today,
            completed_count: completedCount,
            scheduled_count: scheduledCount,
            completion_rate: completionRate,
            active_streak: activeStreak,
            updated_at: Self.iso8601TimestampString(for: .now)
        )

        try await client.from("daily_stats")
            .upsert(payload, onConflict: "user_id,date")
            .execute()

        lastSyncDate = .now
    }

    // MARK: - Fetch Friends

    /// Fetch aggregated friend stats for the given timeframe.
    func fetchFriends(timeframe: Timeframe) async throws -> [FriendStats] {
        guard let client else { return [] }
        try await ensureUser()

        guard let userID = try await currentUserID() else { return [] }

        isSyncing = true
        defer { isSyncing = false }

        let (startDate, endDate) = Self.dateRange(for: timeframe)
        let uid = userID.uuidString

        // Find connected friend IDs via friend_connections.
        struct ConnectionRow: Decodable, Sendable {
            let user_id_a: UUID
            let user_id_b: UUID
        }

        let connectionsA: [ConnectionRow] = try await client.from("friend_connections")
            .select("user_id_a, user_id_b")
            .eq("user_id_a", value: uid)
            .execute()
            .value

        let connectionsB: [ConnectionRow] = try await client.from("friend_connections")
            .select("user_id_a, user_id_b")
            .eq("user_id_b", value: uid)
            .execute()
            .value

        var friendIDs: [UUID] = []
        for c in connectionsA { friendIDs.append(c.user_id_b) }
        for c in connectionsB { friendIDs.append(c.user_id_a) }

        guard !friendIDs.isEmpty else {
            friends = []
            return []
        }

        let friendIDStrings = friendIDs.map(\.uuidString)

        // Fetch daily_stats for friends in the date range.
        struct StatsRow: Decodable, Sendable {
            let user_id: UUID
            let completed_count: Int
            let scheduled_count: Int
            let completion_rate: Double
            let active_streak: Int
        }

        let stats: [StatsRow] = try await client.from("daily_stats")
            .select("user_id, completed_count, scheduled_count, completion_rate, active_streak")
            .in("user_id", values: friendIDStrings)
            .gte("date", value: startDate)
            .lte("date", value: endDate)
            .execute()
            .value

        // Fetch profiles for friends.
        struct ProfileRow: Decodable, Sendable {
            let id: UUID
            let display_name: String
        }

        let profiles: [ProfileRow] = try await client.from("profiles")
            .select("id, display_name")
            .in("id", values: friendIDStrings)
            .execute()
            .value

        let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0.display_name) })

        // Aggregate stats per friend.
        var aggregated: [UUID: (totalCompleted: Int, totalScheduled: Int, maxStreak: Int)] = [:]
        for s in stats {
            var agg = aggregated[s.user_id] ?? (0, 0, 0)
            agg.totalCompleted += s.completed_count
            agg.totalScheduled += s.scheduled_count
            agg.maxStreak = max(agg.maxStreak, s.active_streak)
            aggregated[s.user_id] = agg
        }

        let result: [FriendStats] = friendIDs.compactMap { fid in
            let name = profileMap[fid] ?? "Friend"
            let agg = aggregated[fid] ?? (0, 0, 0)
            let rate = agg.totalScheduled > 0
                ? Double(agg.totalCompleted) / Double(agg.totalScheduled)
                : 0.0
            return FriendStats(
                id: fid,
                displayName: name,
                avatarInitials: Self.initials(from: name),
                completionRate: rate,
                totalCompletions: agg.totalCompleted,
                currentStreak: agg.maxStreak
            )
        }.sorted { $0.completionRate > $1.completionRate }

        friends = result
        return result
    }

    // MARK: - Add Friend

    /// Add a friend connection by their 6-character friend code.
    func addFriend(code: String) async throws {
        guard let client else { return }
        try await ensureUser()

        guard let userID = try await currentUserID() else { return }

        // Look up the friend's profile by code.
        struct ProfileLookup: Decodable, Sendable {
            let id: UUID
        }

        let profiles: [ProfileLookup] = try await client.from("profiles")
            .select("id")
            .eq("friend_code", value: code.uppercased().trimmingCharacters(in: .whitespaces))
            .limit(1)
            .execute()
            .value

        guard let friendProfile = profiles.first else {
            throw SyncError.friendNotFound
        }

        let friendID = friendProfile.id
        guard friendID != userID else {
            throw SyncError.cannotAddSelf
        }

        // Canonical ordering: smaller UUID string first.
        let (a, b) = userID.uuidString < friendID.uuidString ? (userID, friendID) : (friendID, userID)

        let payload = FriendConnectionRowPayload(
            user_id_a: a.uuidString,
            user_id_b: b.uuidString
        )

        try await client.from("friend_connections")
            .upsert(payload, onConflict: "user_id_a,user_id_b")
            .execute()
    }

    // MARK: - Errors

    enum SyncError: LocalizedError, Sendable {
        case friendNotFound
        case cannotAddSelf

        var errorDescription: String? {
            switch self {
            case .friendNotFound: "No user found with that friend code."
            case .cannotAddSelf: "You can't add yourself as a friend."
            }
        }
    }

    // MARK: - Demo Data

    static let demoFriends: [FriendStats] = [
        FriendStats(id: UUID(), displayName: "Sarah K", avatarInitials: "SK",
                    completionRate: 0.92, totalCompletions: 47, currentStreak: 14),
        FriendStats(id: UUID(), displayName: "Marcus J", avatarInitials: "MJ",
                    completionRate: 0.85, totalCompletions: 38, currentStreak: 7),
        FriendStats(id: UUID(), displayName: "Aisha P", avatarInitials: "AP",
                    completionRate: 0.78, totalCompletions: 31, currentStreak: 5),
        FriendStats(id: UUID(), displayName: "David L", avatarInitials: "DL",
                    completionRate: 0.65, totalCompletions: 22, currentStreak: 3),
    ]

    // MARK: - Helpers

    private static func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private static func iso8601DateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    private static func iso8601TimestampString(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private static func dateRange(for timeframe: Timeframe) -> (String, String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current

        let end = formatter.string(from: today)

        switch timeframe {
        case .today:
            return (end, end)
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
            return (formatter.string(from: startOfWeek), end)
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
            return (formatter.string(from: startOfMonth), end)
        }
    }
}
