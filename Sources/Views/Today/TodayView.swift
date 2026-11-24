import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.sortOrder)
    private var habits: [Habit]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @State private var showAddSheet = false

    private var scheduledHabits: [Habit] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate) - 1 // 0=Sun..6=Sat
        return habits.filter { habit in
            habit.scheduleDays.isEmpty || habit.scheduleDays.contains(weekday)
        }
    }

    private var completedCount: Int {
        scheduledHabits.filter { habit in
            logFor(habit: habit)?.isCompleted ?? false
        }.count
    }

    private var dateHeaderString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    HStack {
                        Text(dateHeaderString)
                            .font(.hostGrotesk(.medium, size: 32))
                            .foregroundStyle(Color.primaryText)
                            .tracking(-0.5)

                        Spacer()

                        Text("\(completedCount) / \(scheduledHabits.count)")
                            .font(.hostGrotesk(.semibold, size: 20))
                            .monospacedDigit()
                            .foregroundStyle(Color.cobaltBlue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }

                // Week strip
                WeekStripView(selectedDate: $selectedDate)

                HairlineDivider()

                // Habit list or empty state
                if scheduledHabits.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.mutedText)

                        Text("No habits yet")
                            .font(.hostGrotesk(.medium, size: 20))
                            .foregroundStyle(Color.secondaryText)

                        Text("Tap + to add your first habit")
                            .font(.hostGrotesk(.regular, size: 16))
                            .foregroundStyle(Color.mutedText)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(scheduledHabits) { habit in
                                VStack(spacing: 0) {
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

                                    HairlineDivider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 80) // Space for FAB
                    }
                }
            }
            .background(Color.pageGround)

            // Floating add button
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.cobaltBlue))
                    .shadow(color: .cobaltBlue.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showAddSheet) {
            AddHabitSheet()
        }
    }

    // MARK: - Data helpers

    private func logFor(habit: Habit) -> HabitLog? {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        return habit.logs.first { log in
            Calendar.current.isDate(log.date, inSameDayAs: startOfDay)
        }
    }

    private func toggleCompletion(for habit: Habit) {
        HabitLog.toggleLog(for: habit, on: selectedDate, context: modelContext)
    }

    private func markSlip(for habit: Habit) {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        if let existingLog = logFor(habit: habit) {
            existingLog.isSlip = true
            existingLog.isCompleted = false
        } else {
            let log = HabitLog(
                date: startOfDay,
                isCompleted: false,
                isSlip: true
            )
            log.habit = habit
            modelContext.insert(log)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
