import SwiftUI
import SwiftData

enum TodayFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case build = "Build"
    case quit = "Quit"

    var id: String { rawValue }
}

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SupabaseSyncService.self) private var syncService
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.sortOrder)
    private var habits: [Habit]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @State private var selectedFilter: TodayFilter = .all
    @State private var showAddSheet = false
    @State private var showProfileSheet = false

    private var scheduledHabits: [Habit] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate) - 1 // 0=Sun..6=Sat
        return habits.filter { habit in
            let isScheduledToday = habit.scheduleDays.isEmpty || habit.scheduleDays.contains(weekday)
            guard isScheduledToday else { return false }

            switch selectedFilter {
            case .all:
                return true
            case .build:
                return habit.type == .build
            case .quit:
                return habit.type == .quit
            }
        }
    }

    private var completedCount: Int {
        scheduledHabits.filter { habit in
            logFor(habit: habit)?.isCompleted ?? false
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack(alignment: .center) {
                // Left: Filter Pill
                Menu {
                    ForEach(TodayFilter.allCases) { filter in
                        Button {
                            withAnimation(.snappySpring) {
                                selectedFilter = filter
                            }
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedFilter.rawValue)
                            .font(.hostGrotesk(.medium, size: 13))
                            .foregroundStyle(Color.primaryText)
                            .letterpress(isLight: false)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.mutedText)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(LinearGradient.cardGradient)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(SkeuomorphicButtonStyle())

                Spacer()

                // Center: Today title
                VStack(spacing: 2) {
                    Text("Today")
                        .font(.hostGrotesk(.semibold, size: 22))
                        .foregroundStyle(Color.primaryText)
                        .letterpress(isLight: false)

                    Text("\(completedCount) / \(scheduledHabits.count)")
                        .font(.hostGrotesk(.medium, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.cobaltBlue)
                        .letterpress(isLight: false)
                }

                Spacer()

                // Right: Tactile Add button
                Button {
                    showAddSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.cardGradient)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.cobaltBlue)
                    }
                }
                .buttonStyle(SkeuomorphicButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // 7-day Horizontal Week Strip
            WeekStripView(selectedDate: $selectedDate)

            HairlineDivider()
                .padding(.top, 4)

            // Habit List or Empty State
            if scheduledHabits.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.cobaltBlue.opacity(0.12))
                            .frame(width: 64, height: 64)

                        Image(systemName: "sparkles")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.cobaltBlue)
                    }

                    Text("No habits scheduled")
                        .font(.hostGrotesk(.medium, size: 18))
                        .foregroundStyle(Color.secondaryText)

                    Text("Tap + to add or unfilter your habits")
                        .font(.hostGrotesk(.regular, size: 14))
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.bottom, 80)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(scheduledHabits) { habit in
                            HabitRowView(
                                habit: habit,
                                date: selectedDate,
                                log: logFor(habit: habit),
                                onToggle: {
                                    toggleCompletion(for: habit)
                                },
                                onSlip: habit.type == .quit ? {
                                    markSlip(for: habit)
                                } : nil
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 96) // Breathing room above floating navigation bar
                }
            }
        }
        .paperBackground()
        .task {
            autoSyncDailyStats()
        }
        .sheet(isPresented: $showAddSheet) {
            AddHabitSheet()
        }
    }

    // MARK: - Helpers

    private func logFor(habit: Habit) -> HabitLog? {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        return habit.logs.first {
            Calendar.current.isDate($0.date, inSameDayAs: startOfDay)
        }
    }

    private func toggleCompletion(for habit: Habit) {
        withAnimation(.snappySpring) {
            HabitLog.toggleLog(
                for: habit,
                on: selectedDate,
                context: modelContext
            )
        }
        autoSyncDailyStats()
    }

    private func markSlip(for habit: Habit) {
        withAnimation(.snappySpring) {
            HabitLog.toggleLog(
                for: habit,
                on: selectedDate,
                asSlip: true,
                context: modelContext
            )
        }
        autoSyncDailyStats()
    }

    private func autoSyncDailyStats() {
        guard syncService.isConfigured else { return }
        let scheduled = scheduledHabits.count
        let completed = completedCount
        let rate = scheduled > 0 ? Double(completed) / Double(scheduled) : 0.0
        let streak = habits.map { StreakCalculator.currentStreak(for: $0, asOf: selectedDate, logs: $0.logs) }.max() ?? 0
        Task {
            try? await syncService.syncDailyStats(
                completedCount: completed,
                scheduledCount: scheduled,
                completionRate: rate,
                activeStreak: streak
            )
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
