package com.habittracker.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

enum class HabitType(val value: String, val displayName: String) {
    BUILD("build", "Build"),
    QUIT("quit", "Quit");

    companion object {
        fun fromString(value: String): HabitType =
            entries.find { it.value == value } ?: BUILD
    }
}

@Entity(tableName = "habits")
data class Habit(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val type: String = HabitType.BUILD.value,
    val scheduleDays: String = "", // Comma-separated 0..6 (0=Sun..6=Sat), empty=daily
    val reminderHour: Int? = null,
    val reminderMinute: Int? = null,
    val isArchived: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
    val sortOrder: Int = 0
) {
    val habitType: HabitType
        get() = HabitType.fromString(type)

    fun getScheduleDayList(): List<Int> {
        if (scheduleDays.isBlank()) return emptyList()
        return scheduleDays.split(",").mapNotNull { it.trim().toIntOrNull() }
    }

    fun isScheduledOn(zeroBasedWeekday: Int): Boolean {
        val days = getScheduleDayList()
        return days.isEmpty() || days.contains(zeroBasedWeekday)
    }
}
