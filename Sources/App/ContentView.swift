import SwiftUI

enum AppTab: Int, CaseIterable, Sendable {
    case today = 0
    case calendar = 1
    case friends = 2
    case report = 3
    case settings = 4

    var icon: String {
        switch self {
        case .today: "house.fill"
        case .calendar: "calendar"
        case .friends: "person.2.fill"
        case .report: "list.bullet.clipboard.fill"
        case .settings: "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .today: "Today"
        case .calendar: "Calendar"
        case .friends: "Friends"
        case .report: "Report"
        case .settings: "Settings"
        }
    }
}

struct ContentView: View {
    @Environment(SupabaseSyncService.self) private var syncService
    @State private var selectedTab: AppTab = .today
    @State private var showAddHabitSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                LinearGradient.paperGroundGradient
                    .ignoresSafeArea()
                PaperGrainView()
            }

            ZStack {
                TodayView()
                    .opacity(selectedTab == .today ? 1 : 0)
                    .allowsHitTesting(selectedTab == .today)

                CalendarView()
                    .opacity(selectedTab == .calendar ? 1 : 0)
                    .allowsHitTesting(selectedTab == .calendar)

                FriendsView()
                    .opacity(selectedTab == .friends ? 1 : 0)
                    .allowsHitTesting(selectedTab == .friends)

                ReportView()
                    .opacity(selectedTab == .report ? 1 : 0)
                    .allowsHitTesting(selectedTab == .report)

                SettingsView()
                    .opacity(selectedTab == .settings ? 1 : 0)
                    .allowsHitTesting(selectedTab == .settings)
            }
            .animation(.easeInOut(duration: 0.22), value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Skeuomorphic Floating Dock
            floatingNavigationBar
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .sheet(isPresented: $showAddHabitSheet) {
            AddHabitSheet()
        }
    }

    private var floatingNavigationBar: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab

                if tab == .today && selectedTab == .today {
                    // Smart `+` Shortcut: Convex Cobalt Enamel Push-Button
                    Button {
                        showAddHabitSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.cobaltEnamel)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    // Top specular crescent highlight
                                    VStack {
                                        LinearGradient(colors: [Color.white.opacity(0.65), Color.clear], startPoint: .top, endPoint: .bottom)
                                            .frame(height: 14)
                                        Spacer()
                                    }
                                    .clipShape(Circle())
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.70), Color.black.opacity(0.30)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.25), radius: 2.5, x: 0, y: 1.5)
                                .shadow(color: Color.cobaltBlue.opacity(0.50), radius: 8, x: 0, y: 3)

                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.cobaltLabel)
                                .letterpress(isLight: true)
                        }
                    }
                    .buttonStyle(SkeuomorphicButtonStyle())
                    .frame(maxWidth: .infinity)
                } else {
                    Button {
                        withAnimation(.snappySpring) {
                            selectedTab = tab
                        }
                    } label: {
                        ZStack {
                            if isSelected {
                                // Recessed / debossed well with inner shadow & bottom highlight
                                Capsule()
                                    .fill(LinearGradient.wellGradient)
                                    .frame(height: 40)
                                    .overlay(
                                        VStack(spacing: 0) {
                                            LinearGradient(colors: [Color.black.opacity(0.20), Color.clear], startPoint: .top, endPoint: .bottom)
                                                .frame(height: 3)
                                            Spacer()
                                            Color.white.opacity(0.85)
                                                .frame(height: 1)
                                        }
                                        .clipShape(Capsule())
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(LinearGradient.reverseBevel, lineWidth: 1)
                                    )
                            }

                            VStack(spacing: 2) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(
                                        isSelected ? Color.cobaltBlue : Color.secondaryText
                                    )
                                    .shadow(
                                        color: isSelected ? Color.cobaltBlue.opacity(0.60) : Color.white.opacity(0.8),
                                        radius: isSelected ? 3 : 0.5,
                                        x: 0,
                                        y: isSelected ? 1 : 0.75
                                    )

                                if isSelected {
                                    // Tiny glowing cobalt indicator dot
                                    Circle()
                                        .fill(Color.cobaltBlue)
                                        .frame(width: 3.5, height: 3.5)
                                        .shadow(color: Color.cobaltBlue.opacity(0.9), radius: 3, x: 0, y: 0)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 3.5, height: 3.5)
                                }
                            }
                            .frame(width: 44, height: 40)
                        }
                    }
                    .buttonStyle(SkeuomorphicButtonStyle())
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        // Raised physical dock (matte ceramic/brushed aluminum look)
        .background(
            Capsule()
                .fill(LinearGradient.cardGradient)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(LinearGradient.topLightBevel, lineWidth: 1.5)
        )
        .overlay(
            VStack {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.75), lineWidth: 1)
                    .frame(height: 14)
                    .mask(
                        VStack {
                            Rectangle().frame(height: 2)
                            Spacer()
                        }
                    )
                Spacer()
            }
            .clipShape(Capsule())
            .allowsHitTesting(false)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1.5)
        .shadow(color: Color(red: 0x36 / 255.0, green: 0x30 / 255.0, blue: 0x24 / 255.0).opacity(0.18), radius: 14, x: 0, y: 6)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
        .environment(SupabaseSyncService())
}
