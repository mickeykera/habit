import Foundation

/// Central application configuration for backend services.
/// When configured here, the app connects automatically for all users without manual input.
public enum AppConfig {
    /// Paste your Supabase Project URL here (e.g. "https://abcdefghijklmnopqrst.supabase.co")
    public static let defaultSupabaseURL: String = ""

    /// Paste your Supabase Anon Public Key here
    public static let defaultSupabaseAnonKey: String = ""

    /// Whether automatic cloud sync is active
    public static var isAutoSyncConfigured: Bool {
        !defaultSupabaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !defaultSupabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
