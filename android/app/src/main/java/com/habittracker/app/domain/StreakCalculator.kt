package com.habittracker.app.domain

import com.habittracker.app.data.Habit
import com.habittracker.app.data.HabitLog
import com.habittracker.app.data.HabitType
import java.time.LocalDate

object StreakCalculator {

    fun calculateStreak(
        habit: Habit,
        asOfDate: LocalDate,
        logs: List<HabitLog>
    ): Int {
        val logsByDate = logs.associateBy { it.dateString }
        val today = LocalDate.now()
        val isEvaluatingToday = asOfDate == today
        var allowIncompleteToday = isEvaluatingToday

        var streak = 0
        var currentDate = asOfDate

        for (i in 0 until 1000) {
            val zeroBasedWeekday = currentDate.dayOfWeek.value % 7 // 0=Sun..6=Sat

            if (habit.isScheduledOn(zeroBasedWeekday)) {
                val dateStr = currentDate.toString()
                val log = logsByDate[dateStr]

                when (habit.habitType) {
                    HabitType.BUILD -> {
                        if (log?.isCompleted == true) {
                            streak++
                            allowIncompleteToday = false
                        } else if (allowIncompleteToday) {
                            allowIncompleteToday = false
                        } else {
                            return streak
                        }
                    }
                    HabitType.QUIT -> {
                        if (log?.isSlip == true) {
                            return streak
                        } else {
                            streak++
                        }
                    }
                }
            }

            currentDate = currentDate.minusDays(1)
        }

        return streak
    }
}
