import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    @State private var syncService = SupabaseSyncService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncService)
        }
        .modelContainer(for: Habit.self, HabitLog.self)
    }
}
