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
    @State private var selectedTab: AppTab = .today
    @State private var showAddHabitSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.pageGround
                .ignoresSafeArea()

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

            // Floating Pill Navigation Bar
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
                    // Smart `+` shortcut on Tab 1
                    Button {
                        showAddHabitSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.cobaltBlue)
                                .frame(width: 44, height: 44)

                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.cobaltLabel)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                } else {
                    Button {
                        withAnimation(.snappySpring) {
                            selectedTab = tab
                        }
                    } label: {
                        ZStack {
                            if isSelected {
                                Capsule()
                                    .fill(Color.cobaltBlue.opacity(0.12))
                                    .frame(height: 38)
                            }

                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? Color.cobaltBlue : Color.secondaryText)
                                .frame(width: 44, height: 40)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.cardSurface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.hairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
        .environment(SupabaseSyncService())
}
