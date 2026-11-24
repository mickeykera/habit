package com.habittracker.app.config

/**
 * Central application configuration for backend services.
 * When configured here, the app connects automatically for all users without manual input.
 */
object AppConfig {
    /**
     * Paste your Supabase Project URL here (e.g. "https://abcdefghijklmnopqrst.supabase.co")
     */
    const val DEFAULT_SUPABASE_URL: String = ""

    /**
     * Paste your Supabase Anon Public Key here
     */
    const val DEFAULT_SUPABASE_ANON_KEY: String = ""

    val isAutoSyncConfigured: Boolean
        get() = DEFAULT_SUPABASE_URL.isNotBlank() && DEFAULT_SUPABASE_ANON_KEY.isNotBlank()
}
