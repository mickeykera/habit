import Foundation

enum StreakCalculator: Sendable {
    /// Calculate the current streak for a habit as of a given date.
    ///
    /// - **Build** habits: count consecutive scheduled days backward from `date`
    ///   where a completed log exists. If today is scheduled and not yet completed,
    ///   the existing streak from the prior scheduled day is preserved (completing
    ///   today advances the streak). If a prior scheduled day was missed, the streak is 0.
    /// - **Quit** habits: count consecutive scheduled days backward from `date`
    ///   where no slip was logged (a missing log counts as clean/stayed clean).
    ///   A slip immediately resets the streak to 0.
    static func currentStreak(
        for habit: Habit,
        asOf date: Date,
        logs: [HabitLog]
    ) -> Int {
        let calendar = Calendar.current

        // Index logs by start-of-day for O(1) lookups.
        var logsByDate: [Date: HabitLog] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            logsByDate[day] = log
        }

        var streak = 0
        var currentDate = calendar.startOfDay(for: date)
        let isEvaluatingToday = calendar.isDateInToday(currentDate)

        // For build habits, today is in progress: an incomplete status today does not wipe
        // yesterday's established streak yet.
        var allowIncompleteToday = isEvaluatingToday

        for _ in 0..<1000 {
            let weekday = calendar.component(.weekday, from: currentDate)

            if habit.isScheduled(on: weekday) {
                let log = logsByDate[currentDate]

                switch habit.type {
                case .build:
                    if log?.isCompleted == true {
                        streak += 1
                        allowIncompleteToday = false
                    } else if allowIncompleteToday {
                        // Today is still underway; examine prior scheduled days without breaking yet
                        allowIncompleteToday = false
                    } else {
                        // A past scheduled day was missed — streak stops here
                        return streak
                    }

                case .quit:
                    if log?.isSlip == true {
                        // Logged a slip — streak breaks immediately
                        return streak
                    } else {
                        // Stayed clean (or default clean)
                        streak += 1
                    }
                }
            }

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return streak
    }
}
