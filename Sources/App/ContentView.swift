import SwiftUI

struct ContentView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0xFB / 255.0, green: 0xFA / 255.0, blue: 0xF4 / 255.0, alpha: 1)
        appearance.shadowColor = UIColor(red: 0xDC / 255.0, green: 0xDB / 255.0, blue: 0xD5 / 255.0, alpha: 1)

        let inactiveColor = UIColor(red: 0x59 / 255.0, green: 0x58 / 255.0, blue: 0x58 / 255.0, alpha: 1)
        let activeColor = UIColor(red: 0x1E / 255.0, green: 0x40 / 255.0, blue: 0xAF / 255.0, alpha: 1)

        appearance.stackedLayoutAppearance.normal.iconColor = inactiveColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: inactiveColor]
        appearance.stackedLayoutAppearance.selected.iconColor = activeColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: activeColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }

            ReportView()
                .tabItem {
                    Label("Report", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Color.cobaltBlue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, HabitLog.self, inMemory: true)
        .environment(SupabaseSyncService())
}
