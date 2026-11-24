package com.habittracker.app.service

import android.content.Context
import android.content.SharedPreferences
import com.habittracker.app.config.AppConfig
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
        get() {
            val saved = prefs.getString("supabase_url", "") ?: ""
            return if (saved.isNotBlank()) saved else AppConfig.DEFAULT_SUPABASE_URL
        }
        set(value) = prefs.edit().putString("supabase_url", value).apply()

    var supabaseAnonKey: String
        get() {
            val saved = prefs.getString("supabase_anon_key", "") ?: ""
            return if (saved.isNotBlank()) saved else AppConfig.DEFAULT_SUPABASE_ANON_KEY
        }
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

    var accessToken: String
        get() = prefs.getString("access_token", "") ?: ""
        set(value) = prefs.edit().putString("access_token", value).apply()

    var currentUserEmail: String
        get() = prefs.getString("current_user_email", "") ?: ""
        set(value) = prefs.edit().putString("current_user_email", value).apply()

    var currentUserId: String
        get() = prefs.getString("current_user_id", "") ?: ""
        set(value) = prefs.edit().putString("current_user_id", value).apply()

    var isAuthenticated: Boolean
        get() = prefs.getBoolean("is_authenticated", false) && (accessToken.isNotBlank() || currentUserId.isNotBlank())
        set(value) = prefs.edit().putBoolean("is_authenticated", value).apply()

    val isConfigured: Boolean
        get() = supabaseUrl.isNotBlank() && supabaseAnonKey.isNotBlank()

    suspend fun signUp(email: String, pass: String, name: String): Result<Unit> = withContext(Dispatchers.IO) {
        if (!isConfigured) return@withContext Result.failure(Exception("Supabase not configured. Check Project URL and Anon Key."))
        try {
            val endpoint = "$supabaseUrl/auth/v1/signup"
            val url = URL(endpoint)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("apikey", supabaseAnonKey)
            conn.setRequestProperty("Content-Type", "application/json")
            conn.doOutput = true

            val dataObj = JSONObject().apply { put("display_name", name.trim()) }
            val payload = JSONObject().apply {
                put("email", email.trim())
                put("password", pass)
                put("data", dataObj)
            }

            OutputStreamWriter(conn.outputStream).use { it.write(payload.toString()) }
            val code = conn.responseCode
            val responseText = if (code in 200..299) {
                conn.inputStream.bufferedReader().use { it.readText() }
            } else {
                conn.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
            }

            if (code in 200..299) {
                val json = JSONObject(responseText)
                accessToken = json.optString("access_token", "active_session")
                val user = json.optJSONObject("user")
                currentUserId = user?.optString("id", "") ?: ""
                currentUserEmail = email.trim()
                if (name.isNotBlank()) displayName = name.trim()
                isAuthenticated = true
                Result.success(Unit)
            } else {
                val errJson = try { JSONObject(responseText) } catch (e: Exception) { null }
                val msg = errJson?.optString("msg") ?: errJson?.optString("error_description") ?: "Sign up failed ($code)"
                Result.failure(Exception(msg))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun signIn(email: String, pass: String): Result<Unit> = withContext(Dispatchers.IO) {
        if (!isConfigured) return@withContext Result.failure(Exception("Supabase not configured. Check Project URL and Anon Key."))
        try {
            val endpoint = "$supabaseUrl/auth/v1/token?grant_type=password"
            val url = URL(endpoint)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("apikey", supabaseAnonKey)
            conn.setRequestProperty("Content-Type", "application/json")
            conn.doOutput = true

            val payload = JSONObject().apply {
                put("email", email.trim())
                put("password", pass)
            }

            OutputStreamWriter(conn.outputStream).use { it.write(payload.toString()) }
            val code = conn.responseCode
            val responseText = if (code in 200..299) {
                conn.inputStream.bufferedReader().use { it.readText() }
            } else {
                conn.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
            }

            if (code in 200..299) {
                val json = JSONObject(responseText)
                accessToken = json.optString("access_token", "active_session")
                val user = json.optJSONObject("user")
                currentUserId = user?.optString("id", "") ?: ""
                currentUserEmail = email.trim()
                val meta = user?.optJSONObject("user_metadata")
                val metaName = meta?.optString("display_name", "") ?: ""
                if (metaName.isNotBlank()) displayName = metaName
                isAuthenticated = true
                Result.success(Unit)
            } else {
                val errJson = try { JSONObject(responseText) } catch (e: Exception) { null }
                val msg = errJson?.optString("error_description") ?: errJson?.optString("msg") ?: "Invalid email or password"
                Result.failure(Exception(msg))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun getOAuthUrl(provider: String, redirectUrl: String = "com.habittracker.app://callback"): String {
        return "$supabaseUrl/auth/v1/authorize?provider=$provider&redirect_to=$redirectUrl"
    }

    fun signOut() {
        accessToken = ""
        currentUserId = ""
        currentUserEmail = ""
        isAuthenticated = false
    }

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

    fun getFriends(): List<FriendStats> = emptyList()

    fun getDemoFriends(): List<FriendStats> = emptyList()
}
