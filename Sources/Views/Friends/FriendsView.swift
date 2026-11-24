import SwiftUI
import SwiftData

struct FriendsView: View {
    @Environment(SupabaseSyncService.self) private var syncService
    @Environment(\.modelContext) private var modelContext
    @State private var timeframe: Timeframe = .thisWeek
    @State private var friendCodeInput = ""
    @State private var showAddFriend = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var displayFriends: [FriendStats] {
        syncService.friends
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                // Balance spacing
                Circle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)

                Spacer()

                Text("Friends")
                    .font(.hostGrotesk(.medium, size: 22))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                // Right circular + button
                Button {
                    showAddFriend = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.cardSurface)
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(Color.hairline, lineWidth: 1))

                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.cobaltBlue)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            HairlineDivider()

            ScrollView {
                VStack(spacing: 16) {
                    if !syncService.isConfigured {
                        unconfiguredBanner
                    }

                    // User Card
                    userCard

                    // Timeframe Picker
                    timeframePicker

                    // Leaderboard or Empty State
                    if displayFriends.isEmpty {
                        emptyStateView
                    } else {
                        leaderboardSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 96) // Floating bar padding
            }
        }
        .background(Color.pageGround)
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

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.cobaltBlue.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.cobaltBlue)
            }
            .padding(.top, 30)

            Text("It's always nice to have someone by your side. Tap + to invite a friend.")
                .font(.hostGrotesk(.medium, size: 15))
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)

            Button {
                showAddFriend = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add Friend")
                        .font(.hostGrotesk(.medium, size: 14))
                }
                .foregroundStyle(Color.cobaltLabel)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.cobaltBlue)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.hairline, lineWidth: 1))
    }

    // MARK: - Unconfigured Banner
    private var unconfiguredBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.cobaltBlue)
                Text("Friends sync not configured")
                    .font(.hostGrotesk(.semibold, size: 14))
                    .foregroundStyle(Color.primaryText)
            }
            Text("Add your Supabase credentials in Settings to enable cloud sync and compete with friends.")
                .font(.hostGrotesk(.regular, size: 13))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.hairline, lineWidth: 1))
    }

    // MARK: - User Card
    private var userCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.cobaltBlue)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(initials(from: syncService.displayName))
                        .font(.hostGrotesk(.semibold, size: 16))
                        .foregroundStyle(Color.cobaltLabel)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(syncService.displayName)
                    .font(.hostGrotesk(.semibold, size: 16))
                    .foregroundStyle(Color.primaryText)

                HStack(spacing: 4) {
                    Text("Code: \(syncService.friendCode)")
                        .font(.hostGrotesk(.regular, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.mutedText)

                    Button {
                        UIPasteboard.general.string = syncService.friendCode
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.cobaltBlue)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("100%")
                    .font(.hostGrotesk(.bold, size: 20))
                    .foregroundStyle(Color.cobaltBlue)
                    .monospacedDigit()

                Text("Rank #1")
                    .font(.hostGrotesk(.medium, size: 12))
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(14)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.cobaltBlue.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Timeframe Picker
    private var timeframePicker: some View {
        HStack(spacing: 0) {
            ForEach(Timeframe.allCases, id: \.self) { tf in
                timeframeButton(for: tf)
            }
        }
        .padding(3)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color.hairline, lineWidth: 1)
        )
    }

    private func timeframeButton(for tf: Timeframe) -> some View {
        let isSelected = timeframe == tf
        return Button {
            withAnimation(.snappySpring) {
                timeframe = tf
            }
        } label: {
            Text(tf.displayName)
                .font(.hostGrotesk(.medium, size: 13))
                .foregroundStyle(isSelected ? Color.cobaltLabel : Color.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.cobaltBlue : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Leaderboard Section
    private var leaderboardSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("LEADERBOARD")
                    .font(.hostGrotesk(.semibold, size: 12))
                    .foregroundStyle(Color.mutedText)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(displayFriends.enumerated()), id: \.element.id) { index, friend in
                    friendRow(rank: index + 1, friend: friend)
                    if index < displayFriends.count - 1 {
                        HairlineDivider().padding(.leading, 50)
                    }
                }
            }
            .background(Color.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.hairline, lineWidth: 1)
            )
        }
    }

    private func friendRow(rank: Int, friend: FriendStats) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.hostGrotesk(.semibold, size: 13))
                .foregroundStyle(Color.mutedText)
                .monospacedDigit()
                .frame(width: 18)

            Circle()
                .fill(Color.inverseSurface)
                .frame(width: 34, height: 34)
                .overlay(
                    Text(friend.avatarInitials)
                        .font(.hostGrotesk(.medium, size: 13))
                        .foregroundStyle(Color.inverseText)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.hostGrotesk(.medium, size: 15))
                    .foregroundStyle(Color.primaryText)

                HStack(spacing: 6) {
                    Text("\(friend.totalCompletions) done")
                        .font(.hostGrotesk(.regular, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.mutedText)

                    Text("·")
                        .foregroundStyle(Color.mutedText)

                    Text("\(friend.currentStreak)d streak")
                        .font(.hostGrotesk(.regular, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.mutedText)
                }
            }

            Spacer()

            Text("\(Int(friend.completionRate * 100))%")
                .font(.hostGrotesk(.bold, size: 18))
                .foregroundStyle(Color.cobaltBlue)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Add Friend Sheet
    private var addFriendSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Your code
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR FRIEND CODE")
                        .font(.hostGrotesk(.semibold, size: 12))
                        .foregroundStyle(Color.mutedText)

                    HStack {
                        Text(syncService.friendCode.isEmpty ? "------" : syncService.friendCode)
                            .font(.hostGrotesk(.bold, size: 26))
                            .foregroundStyle(Color.primaryText)
                            .monospacedDigit()

                        Spacer()

                        Button {
                            UIPasteboard.general.string = syncService.friendCode
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .font(.hostGrotesk(.medium, size: 13))
                            .foregroundStyle(Color.cobaltBlue)
                        }
                    }
                    .padding(14)
                    .background(Color.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.hairline, lineWidth: 1))
                }

                HairlineDivider()

                // Add by code
                VStack(alignment: .leading, spacing: 8) {
                    Text("ENTER FRIEND'S CODE")
                        .font(.hostGrotesk(.semibold, size: 12))
                        .foregroundStyle(Color.mutedText)

                    HStack {
                        TextField("6-character code", text: $friendCodeInput)
                            .font(.hostGrotesk(.regular, size: 16))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()

                        Button("Add") {
                            addFriend()
                        }
                        .font(.hostGrotesk(.semibold, size: 14))
                        .foregroundStyle(Color.cobaltLabel)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.cobaltBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .disabled(friendCodeInput.trimmingCharacters(in: .whitespaces).count != 6)
                    }
                    .padding(12)
                    .background(Color.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.hairline, lineWidth: 1))
                }

                Spacer()
            }
            .padding(16)
            .background(Color.pageGround)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { showAddFriend = false }
                        .foregroundStyle(Color.cobaltBlue)
                }
            }
        }
    }

    private func addFriend() {
        let code = friendCodeInput.trimmingCharacters(in: .whitespaces).uppercased()
        guard code.count == 6 else { return }

        Task {
            do {
                try await syncService.addFriend(code: code)
                friendCodeInput = ""
                showAddFriend = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
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

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return name.prefix(2).uppercased()
    }
}

#Preview {
    FriendsView()
        .environment(SupabaseSyncService())
}
