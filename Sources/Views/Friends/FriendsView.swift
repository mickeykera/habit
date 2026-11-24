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
                    .letterpress(isLight: false)

                Spacer()

                // Right circular + button
                Button {
                    showAddFriend = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.cardGradient)
                            .frame(width: 36, height: 36)
                            .overlay(Circle().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)

                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.cobaltBlue)
                    }
                }
                .buttonStyle(SkeuomorphicButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            EngravedDivider()

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
        .paperBackground()
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
                    .fill(LinearGradient.wellGradient)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().strokeBorder(LinearGradient.reverseBevel, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.cobaltBlue)
            }
            .padding(.top, 24)

            Text("It's always nice to have someone by your side. Tap + to invite a friend.")
                .font(.hostGrotesk(.medium, size: 15))
                .foregroundStyle(Color.secondaryText)
                .letterpress(isLight: false)
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
                        .font(.hostGrotesk(.semibold, size: 14))
                }
                .foregroundStyle(Color.cobaltLabel)
                .letterpress(isLight: true)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .skeuomorphicCobaltButton(cornerRadius: 10)
            }
            .buttonStyle(SkeuomorphicButtonStyle())
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .skeuomorphicCard(cornerRadius: 16)
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
                    .letterpress(isLight: false)
            }
            Text("Add your Supabase credentials in Settings to enable cloud sync and compete with friends.")
                .font(.hostGrotesk(.regular, size: 13))
                .foregroundStyle(Color.secondaryText)
                .letterpress(isLight: false)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .skeuomorphicCard(cornerRadius: 14)
    }

    // MARK: - User Card
    private var userCard: some View {
        HStack(spacing: 14) {
            // Cobalt enamel avatar medallion
            ZStack {
                Circle()
                    .fill(LinearGradient.cobaltEnamel)
                    .frame(width: 46, height: 46)
                    .overlay(Circle().strokeBorder(LinearGradient(colors: [Color.white.opacity(0.65), Color.black.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
                    .shadow(color: Color.cobaltBlue.opacity(0.35), radius: 3, x: 0, y: 1.5)

                Text(initials(from: syncService.displayName))
                    .font(.hostGrotesk(.bold, size: 16))
                    .foregroundStyle(Color.cobaltLabel)
                    .letterpress(isLight: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(syncService.displayName)
                    .font(.hostGrotesk(.semibold, size: 16))
                    .foregroundStyle(Color.primaryText)
                    .letterpress(isLight: false)

                HStack(spacing: 6) {
                    Text("Code: \(syncService.friendCode)")
                        .font(.hostGrotesk(.regular, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)

                    Button {
                        UIPasteboard.general.string = syncService.friendCode
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.cobaltBlue)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("100%")
                    .font(.hostGrotesk(.bold, size: 20))
                    .foregroundStyle(Color.cobaltBlue)
                    .monospacedDigit()
                    .letterpress(isLight: false)

                HStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.goldGradient)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.8), lineWidth: 0.5))

                        Text("1")
                            .font(.hostGrotesk(.bold, size: 10))
                            .foregroundStyle(Color(red: 0.24, green: 0.17, blue: 0.02))
                    }
                    Text("Rank #1")
                        .font(.hostGrotesk(.semibold, size: 12))
                        .foregroundStyle(Color.secondaryText)
                        .letterpress(isLight: false)
                }
            }
        }
        .padding(14)
        .skeuomorphicCard(cornerRadius: 16)
    }

    // MARK: - Timeframe Picker
    private var timeframePicker: some View {
        HStack(spacing: 4) {
            ForEach(Timeframe.allCases, id: \.self) { tf in
                timeframeButton(for: tf)
            }
        }
        .padding(4)
        .skeuomorphicWell(cornerRadius: 11)
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
                .letterpress(isLight: isSelected)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient.cobaltEnamel)
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(LinearGradient(colors: [Color.white.opacity(0.65), Color.black.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 0.75))
                                .shadow(color: Color.cobaltBlue.opacity(0.3), radius: 2, x: 0, y: 1)
                        } else {
                            Color.clear
                        }
                    }
                )
        }
        .buttonStyle(SkeuomorphicButtonStyle())
    }

    // MARK: - Leaderboard Section
    private var leaderboardSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("LEADERBOARD")
                    .font(.hostGrotesk(.semibold, size: 12))
                    .foregroundStyle(Color.mutedText)
                    .letterpress(isLight: false)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(displayFriends.enumerated()), id: \.element.id) { index, friend in
                    friendRow(rank: index + 1, friend: friend)
                    if index < displayFriends.count - 1 {
                        EngravedDivider().padding(.leading, 50)
                    }
                }
            }
            .skeuomorphicCard(cornerRadius: 16)
        }
    }

    private func friendRow(rank: Int, friend: FriendStats) -> some View {
        HStack(spacing: 12) {
            rankMedallion(rank: rank)

            // Anodized charcoal avatar
            ZStack {
                Circle()
                    .fill(LinearGradient.charcoalGradient)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(LinearGradient(colors: [Color.white.opacity(0.3), Color.black.opacity(0.5)], startPoint: .top, endPoint: .bottom), lineWidth: 0.75))
                    .shadow(color: Color.black.opacity(0.12), radius: 1.5, x: 0, y: 1)

                Text(friend.avatarInitials)
                    .font(.hostGrotesk(.semibold, size: 12))
                    .foregroundStyle(Color.inverseText)
                    .letterpress(isLight: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.hostGrotesk(.medium, size: 15))
                    .foregroundStyle(Color.primaryText)
                    .letterpress(isLight: false)

                HStack(spacing: 6) {
                    Text("\(friend.totalCompletions) done")
                        .font(.hostGrotesk(.regular, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)

                    Text("·")
                        .foregroundStyle(Color.mutedText)

                    Text("\(friend.currentStreak)d streak")
                        .font(.hostGrotesk(.regular, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)
                }

                // Recessed progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(LinearGradient.wellGradient)
                            .overlay(Capsule().strokeBorder(LinearGradient.reverseBevel, lineWidth: 0.5))

                        Capsule()
                            .fill(LinearGradient.cobaltEnamel)
                            .frame(width: max(0, geo.size.width * CGFloat(friend.completionRate)))
                            .shadow(color: Color.cobaltBlue.opacity(0.3), radius: 1, x: 0, y: 0.5)
                    }
                }
                .frame(height: 5)
                .padding(.top, 1)
            }

            Spacer()

            Text("\(Int(friend.completionRate * 100))%")
                .font(.hostGrotesk(.bold, size: 17))
                .foregroundStyle(Color.cobaltBlue)
                .monospacedDigit()
                .letterpress(isLight: false)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func rankMedallion(rank: Int) -> some View {
        let (gradient, textColor, borderColor) = medalColors(for: rank)
        return ZStack {
            Circle()
                .fill(gradient)
                .frame(width: 26, height: 26)
                .overlay(Circle().strokeBorder(borderColor, lineWidth: 0.75))
                .shadow(color: Color.black.opacity(rank <= 3 ? 0.2 : 0.05), radius: 1.5, x: 0, y: 1)

            Text("\(rank)")
                .font(.hostGrotesk(.bold, size: 12))
                .monospacedDigit()
                .foregroundStyle(textColor)
                .letterpress(isLight: rank <= 3)
        }
    }

    private func medalColors(for rank: Int) -> (LinearGradient, Color, LinearGradient) {
        switch rank {
        case 1:
            return (
                LinearGradient.goldGradient,
                Color(red: 0.24, green: 0.17, blue: 0.02),
                LinearGradient(colors: [Color.white.opacity(0.85), Color.black.opacity(0.3)], startPoint: .top, endPoint: .bottom)
            )
        case 2:
            return (
                LinearGradient.silverGradient,
                Color(red: 0.15, green: 0.15, blue: 0.15),
                LinearGradient(colors: [Color.white.opacity(0.9), Color.black.opacity(0.3)], startPoint: .top, endPoint: .bottom)
            )
        case 3:
            return (
                LinearGradient.bronzeGradient,
                Color(red: 0.24, green: 0.12, blue: 0.05),
                LinearGradient(colors: [Color.white.opacity(0.8), Color.black.opacity(0.3)], startPoint: .top, endPoint: .bottom)
            )
        default:
            return (
                LinearGradient.wellGradient,
                Color.secondaryText,
                LinearGradient.reverseBevel
            )
        }
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
                        .letterpress(isLight: false)

                    HStack {
                        Text(syncService.friendCode.isEmpty ? "------" : syncService.friendCode)
                            .font(.hostGrotesk(.bold, size: 26))
                            .foregroundStyle(Color.primaryText)
                            .monospacedDigit()
                            .letterpress(isLight: false)

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
                    .skeuomorphicCard(cornerRadius: 12)
                }

                EngravedDivider()

                // Add by code
                VStack(alignment: .leading, spacing: 8) {
                    Text("ENTER FRIEND'S CODE")
                        .font(.hostGrotesk(.semibold, size: 12))
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)

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
                        .letterpress(isLight: true)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .skeuomorphicCobaltButton(cornerRadius: 8)
                        .disabled(friendCodeInput.trimmingCharacters(in: .whitespaces).count != 6)
                    }
                    .padding(12)
                    .skeuomorphicWell(cornerRadius: 12)
                }

                Spacer()
            }
            .padding(16)
            .paperBackground()
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
