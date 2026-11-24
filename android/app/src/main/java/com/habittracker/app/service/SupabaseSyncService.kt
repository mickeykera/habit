package com.habittracker.app.service

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.time.LocalDate
import java.util.UUID

data class FriendStats(
    val id: String,
    val displayName: String,
    val avatarInitials: String,
    val completionRate: Double,
    val totalCompletions: Int,
    val currentStreak: Int
)

class SupabaseSyncService(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("habit_tracker_prefs", Context.MODE_PRIVATE)

    var supabaseUrl: String
        get() = prefs.getString("supabase_url", "") ?: ""
        set(value) = prefs.edit().putString("supabase_url", value).apply()

    var supabaseAnonKey: String
        get() = prefs.getString("supabase_anon_key", "") ?: ""
        set(value) = prefs.edit().putString("supabase_anon_key", value).apply()

    var displayName: String
        get() = prefs.getString("display_name", "Habit Tracker") ?: "Habit Tracker"
        set(value) = prefs.edit().putString("display_name", value).apply()

    var friendCode: String
        get() {
            var code = prefs.getString("friend_code", "") ?: ""
            if (code.isBlank()) {
                code = generateFriendCode()
                prefs.edit().putString("friend_code", code).apply()
            }
            return code
        }
        set(value) = prefs.edit().putString("friend_code", value).apply()

    val isConfigured: Boolean
        get() = supabaseUrl.isNotBlank() && supabaseAnonKey.isNotBlank()

    fun generateFriendCode(): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return (1..6).map { chars.random() }.joinToString("")
    }

    suspend fun syncDailyStats(
        completedCount: Int,
        scheduledCount: Int,
        completionRate: Double,
        activeStreak: Int
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (!isConfigured) return@withContext Result.failure(Exception("Supabase not configured"))

        try {
            val endpoint = "$supabaseUrl/rest/v1/daily_stats"
            val url = URL(endpoint)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("apikey", supabaseAnonKey)
            conn.setRequestProperty("Authorization", "Bearer $supabaseAnonKey")
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Prefer", "resolution=merge-duplicates")
            conn.doOutput = true

            val payload = JSONObject().apply {
                put("user_id", friendCode) // Anonymous ID mapped to friend code
                put("date", LocalDate.now().toString())
                put("completed_count", completedCount)
                put("scheduled_count", scheduledCount)
                put("completion_rate", completionRate)
                put("active_streak", activeStreak)
            }

            OutputStreamWriter(conn.outputStream).use { it.write(payload.toString()) }
            val code = conn.responseCode
            if (code in 200..299) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Sync failed with status code: $code"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun getDemoFriends(): List<FriendStats> = listOf(
        FriendStats(UUID.randomUUID().toString(), "Sarah K", "SK", 0.92, 47, 14),
        FriendStats(UUID.randomUUID().toString(), "Marcus J", "MJ", 0.85, 38, 7),
        FriendStats(UUID.randomUUID().toString(), "Aisha P", "AP", 0.78, 31, 5),
        FriendStats(UUID.randomUUID().toString(), "David L", "DL", 0.65, 22, 3)
    )
}
