import Foundation
import Observation
import SwiftData

@Observable
final class HabitStore {
    // MARK: - Properties

    var selectedDate: Date
    var modelContext: ModelContext

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.selectedDate = Calendar.current.startOfDay(for: .now)
    }

    // MARK: - Computed

    /// All non-archived habits sorted by `sortOrder`.
    var habits: [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { !$0.isArchived },
            sortBy: [SortDescriptor(\Habit.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Habits scheduled for `selectedDate`'s weekday.
    var todayHabits: [Habit] {
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        return habits.filter { $0.isScheduled(on: weekday) }
    }

    // MARK: - Log Queries

    /// Fetch the log entry for a habit on a specific date.
    func log(for habit: Habit, on date: Date) -> HabitLog? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return habit.logs.first { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }
    }

    // MARK: - Mutations

    /// Toggle a habit's completion for a given date.
    func toggleCompletion(habit: Habit, date: Date) {
        HabitLog.toggleLog(for: habit, on: date, context: modelContext)
    }

    /// Mark a slip for a quit habit.
    func markSlip(habit: Habit, date: Date) {
        guard habit.type == .quit else { return }
        HabitLog.toggleLog(for: habit, on: date, asSlip: true, context: modelContext)
    }

    // MARK: - Aggregate Queries

    /// Number of completed habits on a given date.
    func completedCount(on date: Date) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate<HabitLog> { $0.date == startOfDay && $0.isCompleted == true }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Number of habits scheduled on a given date.
    func scheduledCount(on date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        return habits.filter { $0.isScheduled(on: weekday) }.count
    }

    /// Completion rate for a given date (0.0 … 1.0).
    func completionRate(on date: Date) -> Double {
        let scheduled = scheduledCount(on: date)
        guard scheduled > 0 else { return 0 }
        return Double(completedCount(on: date)) / Double(scheduled)
    }

    // MARK: - CRUD

    func addHabit(
        title: String,
        type: HabitType,
        scheduleDays: [Int] = [],
        reminderTime: Date? = nil
    ) {
        let maxOrder = (habits.map(\.sortOrder).max() ?? -1) + 1
        let habit = Habit(
            title: title,
            type: type,
            scheduleDays: scheduleDays,
            reminderTime: reminderTime,
            sortOrder: maxOrder
        )
        modelContext.insert(habit)
    }

    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
    }

    func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
    }
}
