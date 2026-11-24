package com.habittracker.app.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface HabitDao {

    @Query("SELECT * FROM habits WHERE isArchived = 0 ORDER BY sortOrder ASC")
    fun getActiveHabits(): Flow<List<Habit>>

    @Query("SELECT * FROM habits ORDER BY sortOrder ASC")
    suspend fun getAllHabits(): List<Habit>

    @Query("SELECT * FROM habit_logs WHERE dateString = :dateString")
    fun getLogsForDate(dateString: String): Flow<List<HabitLog>>

    @Query("SELECT * FROM habit_logs WHERE habitId = :habitId AND dateString = :dateString LIMIT 1")
    suspend fun getLog(habitId: String, dateString: String): HabitLog?

    @Query("SELECT * FROM habit_logs WHERE habitId = :habitId")
    suspend fun getLogsForHabit(habitId: String): List<HabitLog>

    @Query("SELECT * FROM habit_logs WHERE dateString >= :startDate AND dateString <= :endDate")
    suspend fun getLogsInRange(startDate: String, endDate: String): List<HabitLog>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHabit(habit: Habit)

    @Update
    suspend fun updateHabit(habit: Habit)

    @Delete
    suspend fun deleteHabit(habit: Habit)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdateLog(log: HabitLog)

    @Query("DELETE FROM habit_logs")
    suspend fun deleteAllLogs()

    @Query("DELETE FROM habits")
    suspend fun deleteAllHabits()
}
