import SwiftUI
import SwiftData

// MARK: - FriendsView

struct FriendsView: View {
    @Environment(SupabaseSyncService.self) private var syncService
    @Environment(\.modelContext) private var modelContext
    @State private var timeframe: Timeframe = .thisWeek
    @State private var friendCodeInput = ""
    @State private var showAddFriend = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var displayFriends: [FriendStats] {
        syncService.isConfigured ? syncService.friends : SupabaseSyncService.demoFriends
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if !syncService.isConfigured {
                        unconfiguredBanner
                    }

                    userCard
                    HairlineDivider().padding(.vertical, 12)
                    timeframePicker
                    HairlineDivider().padding(.vertical, 12)
                    leaderboard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color.pageGround)
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Color.cobaltBlue)
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                addFriendSheet
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Something went wrong.")
            }
            .task {
                await refreshFriends()
            }
        }
    }

    // MARK: - Unconfigured Banner

    private var unconfiguredBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.cobaltBlue)
                Text("Friends sync not configured")
                    .font(hostGrotesk(.semibold, size: 14))
                    .foregroundStyle(Color.primaryText)
            }
            Text("Add your Supabase credentials in Settings to enable cloud sync and compete with friends.")
                .font(hostGrotesk(.regular, size: 13))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetCard()
        .padding(.bottom, 12)
    }

    // MARK: - User Card

    private var userCard: some View {
        HStack(spacing: 14) {
            // Avatar
            Circle()
                .fill(Color.cobaltBlue)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(initials(from: syncService.displayName))
                        .font(hostGrotesk(.semibold, size: 16))
                        .foregroundStyle(Color.cobaltLabel)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(syncService.displayName)
                    .font(hostGrotesk(.semibold, size: 16))
                    .foregroundStyle(Color.primaryText)
                Text("You")
                    .font(hostGrotesk(.regular, size: 13))
                    .foregroundStyle(Color.mutedText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(userCompletionRate)
                    .font(hostGrotesk(.bold, size: 24))
                    .foregroundStyle(Color.cobaltBlue)
                    .monospacedDigit()
                HStack(spacing: 8) {
                    statLabel(value: "\(userTotalCompletions)", label: "done")
                    statLabel(value: "\(userStreak)d", label: "streak")
                }
            }
        }
        .padding(14)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cobaltBlue.opacity(0.3), lineWidth: 1.5)
        )
    }

    // MARK: - Timeframe Picker

    private var timeframePicker: some View {
        HStack(spacing: 0) {
            ForEach(Timeframe.allCases, id: \.self) { tf in
                Button {
                    timeframe = tf
                    Task { await refreshFriends() }
                } label: {
                    Text(tf.displayName)
                        .font(hostGrotesk(.medium, size: 13))
                        .foregroundStyle(timeframe == tf ? Color.cobaltLabel : Color.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(timeframe == tf ? Color.cobaltBlue : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(3)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.hairline, lineWidth: 1)
        )
    }

    // MARK: - Leaderboard

    private var leaderboard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LEADERBOARD")
                    .font(hostGrotesk(.semibold, size: 13))
                    .foregroundStyle(Color.mutedText)
                Spacer()
            }
            .padding(.bottom, 10)

            if displayFriends.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.mutedText)
                    Text("No friends yet")
                        .font(hostGrotesk(.medium, size: 16))
                        .foregroundStyle(Color.secondaryText)
                    Text("Tap + to add friends by their code")
                        .font(hostGrotesk(.regular, size: 13))
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(displayFriends.enumerated()), id: \.element.id) { index, friend in
                        friendRow(rank: index + 1, friend: friend)
                        if index < displayFriends.count - 1 {
                            HairlineDivider().padding(.leading, 52)
                        }
                    }
                }
                .padding(.vertical, 4)
                .insetCard()
            }
        }
    }

    private func friendRow(rank: Int, friend: FriendStats) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(hostGrotesk(.semibold, size: 14))
                .foregroundStyle(Color.mutedText)
                .monospacedDigit()
                .frame(width: 20)

            Circle()
                .fill(Color.inverseSurface)
                .frame(width: 34, height: 34)
                .overlay(
                    Text(friend.avatarInitials)
                        .font(hostGrotesk(.medium, size: 13))
                        .foregroundStyle(Color.inverseText)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(friend.displayName)
                    .font(hostGrotesk(.medium, size: 15))
                    .foregroundStyle(Color.primaryText)
                HStack(spacing: 6) {
                    statLabel(value: "\(friend.totalCompletions)", label: "done")
                    statLabel(value: "\(friend.currentStreak)d", label: "streak")
                }
            }

            Spacer()

            Text("\(Int(friend.completionRate * 100))%")
                .font(hostGrotesk(.bold, size: 20))
                .foregroundStyle(Color.cobaltBlue)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Add Friend Sheet

    private var addFriendSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Your code
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR FRIEND CODE")
                        .font(hostGrotesk(.semibold, size: 13))
                        .foregroundStyle(Color.mutedText)

                    HStack {
                        Text(syncService.friendCode.isEmpty ? "------" : syncService.friendCode)
                            .font(hostGrotesk(.bold, size: 28))
                            .foregroundStyle(Color.primaryText)
                            .monospacedDigit()
                            .tracking(4)

                        Spacer()

                        Button {
                            UIPasteboard.general.string = syncService.friendCode
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.cobaltBlue)
                        }
                    }
                    .padding(16)
                    .insetCard()

                    Text("Share this code with friends so they can add you.")
                        .font(hostGrotesk(.regular, size: 13))
                        .foregroundStyle(Color.mutedText)
                }

                HairlineDivider()

                // Add friend
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADD A FRIEND")
                        .font(hostGrotesk(.semibold, size: 13))
                        .foregroundStyle(Color.mutedText)

                    HStack(spacing: 10) {
                        TextField("Friend code", text: $friendCodeInput)
                            .font(hostGrotesk(.medium, size: 16))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(Color.cardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.hairline, lineWidth: 1)
                            )

                        Button {
                            Task { await addFriend() }
                        } label: {
                            Text("Add")
                                .font(hostGrotesk(.semibold, size: 15))
                                .foregroundStyle(Color.cobaltLabel)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.cobaltBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(friendCodeInput.count != 6)
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(Color.pageGround)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showAddFriend = false }
                        .font(hostGrotesk(.medium, size: 16))
                        .foregroundStyle(Color.cobaltBlue)
                }
            }
        }
    }

    // MARK: - Helpers

    private func statLabel(value: String, label: String) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .font(hostGrotesk(.semibold, size: 12))
                .foregroundStyle(Color.secondaryText)
                .monospacedDigit()
            Text(label)
                .font(hostGrotesk(.regular, size: 11))
                .foregroundStyle(Color.mutedText)
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var userCompletionRate: String {
        let habits = fetchActiveHabits()
        let date = Calendar.current.startOfDay(for: .now)
        let weekday = Calendar.current.component(.weekday, from: date)
        let scheduled = habits.filter { $0.isScheduled(on: weekday) }
        guard !scheduled.isEmpty else { return "—" }
        let completed = scheduled.filter { habit in
            habit.logs.contains { log in
                Calendar.current.isDate(log.date, inSameDayAs: date) && log.isCompleted
            }
        }
        return "\(Int(Double(completed.count) / Double(scheduled.count) * 100))%"
    }

    private var userTotalCompletions: Int {
        let habits = fetchActiveHabits()
        return habits.reduce(0) { total, habit in
            total + habit.logs.filter(\.isCompleted).count
        }
    }

    private var userStreak: Int {
        let habits = fetchActiveHabits()
        guard let first = habits.first else { return 0 }
        return StreakCalculator.currentStreak(for: first, asOf: .now, logs: first.logs)
    }

    private func fetchActiveHabits() -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func refreshFriends() async {
        guard syncService.isConfigured else { return }
        do {
            _ = try await syncService.fetchFriends(timeframe: timeframe)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func addFriend() async {
        guard syncService.isConfigured else {
            errorMessage = "Configure Supabase in Settings first."
            showError = true
            return
        }
        do {
            try await syncService.addFriend(code: friendCodeInput)
            friendCodeInput = ""
            showAddFriend = false
            await refreshFriends()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
