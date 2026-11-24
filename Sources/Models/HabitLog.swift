import Foundation
import SwiftData

@Model
final class HabitLog {
    @Attribute(.unique) var id: UUID

    /// Normalized to the start of the calendar day.
    var date: Date

    var isCompleted: Bool

    /// For quit habits — indicates a slip was logged on this day.
    var isSlip: Bool

    var habit: Habit?

    // MARK: Init

    init(
        id: UUID = UUID(),
        date: Date = .now,
        isCompleted: Bool = false,
        isSlip: Bool = false,
        habit: Habit? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
        self.isSlip = isSlip
        self.habit = habit
    }

    // MARK: - Toggle / Slip Convenience

    /// Finds an existing log for the given habit + date or creates one, then
    /// toggles `isCompleted`.
    ///
    /// For **quit** habits, calling this with `asSlip: true` marks the log as a
    /// slip (isSlip = true, isCompleted = false).
    static func toggleLog(
        for habit: Habit,
        on date: Date,
        asSlip: Bool = false,
        context: ModelContext
    ) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let existing = habit.logs.first {
            Calendar.current.isDate($0.date, inSameDayAs: startOfDay)
        }

        if let log = existing {
            if asSlip && habit.type == .quit {
                log.isSlip = true
                log.isCompleted = false
            } else {
                log.isCompleted.toggle()
                if log.isCompleted {
                    log.isSlip = false
                }
            }
        } else {
            let newLog = HabitLog(
                date: startOfDay,
                isCompleted: !asSlip,
                isSlip: asSlip && habit.type == .quit,
                habit: habit
            )
            context.insert(newLog)
        }
    }
}
