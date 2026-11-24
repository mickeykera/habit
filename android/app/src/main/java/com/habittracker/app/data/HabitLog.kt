package com.habittracker.app.data

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(
    tableName = "habit_logs",
    foreignKeys = [
        ForeignKey(
            entity = Habit::class,
            parentColumns = ["id"],
            childColumns = ["habitId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["habitId", "dateString"], unique = true)
    ]
)
data class HabitLog(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val habitId: String,
    val dateString: String, // YYYY-MM-DD format normalized
    val isCompleted: Boolean = false,
    val isSlip: Boolean = false
)
