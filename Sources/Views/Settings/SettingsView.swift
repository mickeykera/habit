import SwiftUI
import SwiftData
import UserNotifications
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(SupabaseSyncService.self) private var syncService
    @Environment(\.modelContext) private var modelContext

    @AppStorage("weekStartDay") private var weekStartDay: String = "Monday"
    @AppStorage("defaultHabitType") private var defaultHabitType: String = "build"
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled: Bool = false
    @AppStorage("dailyReminderHour") private var dailyReminderHour: Int = 9
    @AppStorage("dailyReminderMinute") private var dailyReminderMinute: Int = 0
    @AppStorage("dailyMoodsJson") private var dailyMoodsJson: String = "{}"

    @State private var displayName: String = ""
    @State private var isEditingName: Bool = false
    @State private var supabaseURL: String = ""
    @State private var supabaseAnonKey: String = ""
    @State private var showResetConfirmation = false
    @State private var showImporter = false
    @State private var isSyncing = false
    @State private var syncStatusMessage: String?
    @State private var showSyncStatusAlert = false

    // Sheets
    @State private var showHabitManager = false
    @State private var showPreferencesSheet = false
    @State private var showSupabaseSheet = false
    @State private var showDataBackupSheet = false
    @State private var showAuthSheet = false

    @Query private var habits: [Habit]
    @Query private var habitLogs: [HabitLog]

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = dailyReminderHour
                components.minute = dailyReminderMinute
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                dailyReminderHour = components.hour ?? 9
                dailyReminderMinute = components.minute ?? 0
                if dailyReminderEnabled {
                    scheduleDailyReminder()
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Spacer()
                Text("Settings")
                    .font(.hostGrotesk(.medium, size: 22))
                    .foregroundStyle(Color.primaryText)
                    .letterpress(isLight: false)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            EngravedDivider()

            ScrollView {
                VStack(spacing: 16) {
                    // Account (if signed in) or Sign Up (if not signed in) above all settings
                    if syncService.isAuthenticated {
                        accountCard
                    } else {
                        signUpCard
                    }

                    // Daily Mood Strip Card
                    dailyMoodStripCard

                    // Settings Grouped Inset Card
                    settingsCard

                    // About Card
                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 96) // Floating nav bar padding
            }
        }
        .paperBackground()
        .onAppear {
            displayName = syncService.displayName
            supabaseURL = syncService.supabaseURL
            supabaseAnonKey = syncService.supabaseAnonKey
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthView()
        }
        .sheet(isPresented: $showHabitManager) {
            habitManagerSheet
        }
        .sheet(isPresented: $showPreferencesSheet) {
            preferencesSheet
        }
        .sheet(isPresented: $showSupabaseSheet) {
            supabaseSheet
        }
        .sheet(isPresented: $showDataBackupSheet) {
            dataBackupSheet
        }
        .alert("Reset All Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all habits and logs. This action cannot be undone.")
        }
        .alert("Sync Status", isPresented: $showSyncStatusAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(syncStatusMessage ?? "")
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    // MARK: - 1. Account Card (When Signed In)
    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Account")
                    .font(.hostGrotesk(.bold, size: 14))
                    .foregroundStyle(Color.cobaltBlue)
                    .letterpress(isLight: false)

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: "10B981"))
                        .frame(width: 7, height: 7)
                    Text("Synced")
                        .font(.hostGrotesk(.medium, size: 11))
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)
                }
            }

            HStack(spacing: 14) {
                // Circular Avatar Initials with Specular Metallic Bezel
                ZStack {
                    Circle()
                        .fill(LinearGradient.cobaltEnamel)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.8), Color.black.opacity(0.35)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.cobaltBlue.opacity(0.35), radius: 3, x: 0, y: 1.5)

                    Text(initials(from: syncService.displayName))
                        .font(.hostGrotesk(.bold, size: 18))
                        .foregroundStyle(Color.cobaltLabel)
                        .letterpress(isLight: true)
                }

                VStack(alignment: .leading, spacing: 3) {
                    if isEditingName {
                        HStack {
                            TextField("Display Name", text: $displayName)
                                .font(.hostGrotesk(.semibold, size: 16))
                                .textFieldStyle(.plain)

                            Button("Done") {
                                syncService.displayName = displayName
                                isEditingName = false
                            }
                            .font(.hostGrotesk(.medium, size: 13))
                            .foregroundStyle(Color.cobaltBlue)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Text(syncService.displayName)
                                .font(.hostGrotesk(.semibold, size: 16))
                                .foregroundStyle(Color.primaryText)
                                .letterpress(isLight: false)

                            Button {
                                isEditingName = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.mutedText)
                            }
                        }
                    }

                    if let email = syncService.currentUserEmail, !email.isEmpty {
                        Text(email)
                            .font(.hostGrotesk(.regular, size: 12))
                            .foregroundStyle(Color.mutedText)
                            .letterpress(isLight: false)
                    }

                    Text("Friend Code: \(syncService.friendCode)")
                        .font(.hostGrotesk(.regular, size: 11))
                        .monospacedDigit()
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)
                }

                Spacer()

                // Copy Friend Code Button
                Button {
                    UIPasteboard.general.string = syncService.friendCode
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.hostGrotesk(.medium, size: 12))
                    .foregroundStyle(Color.cobaltBlue)
                    .letterpress(isLight: false)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LinearGradient.cardGradient))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(SkeuomorphicButtonStyle())
            }
        }
        .padding(14)
        .skeuomorphicCard(cornerRadius: 16)
    }

    // MARK: - 1b. Sign Up Card (When Not Signed In)
    private var signUpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sign Up")
                    .font(.hostGrotesk(.bold, size: 14))
                    .foregroundStyle(Color.cobaltBlue)
                    .letterpress(isLight: false)

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.mutedText.opacity(0.5))
                        .frame(width: 7, height: 7)
                    Text("Local Only")
                        .font(.hostGrotesk(.medium, size: 11))
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)
                }
            }

            HStack(spacing: 14) {
                // Circular Medallion with Recessed Well
                ZStack {
                    Circle()
                        .fill(LinearGradient.wellGradient)
                        .frame(width: 50, height: 50)
                        .overlay(Circle().strokeBorder(LinearGradient.reverseBevel, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1)

                    Image(systemName: "icloud.and.arrow.up.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.cobaltBlue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Save Habits Permanently")
                        .font(.hostGrotesk(.semibold, size: 15))
                        .foregroundStyle(Color.primaryText)
                        .letterpress(isLight: false)

                    Text("Store habits permanently in the cloud and sync across all your devices.")
                        .font(.hostGrotesk(.regular, size: 12))
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Tactile Cobalt Enamel Button
            Button {
                showAuthSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Sign Up / Sign In")
                        .font(.hostGrotesk(.semibold, size: 14))
                        .letterpress(isLight: true)
                }
                .foregroundStyle(Color.cobaltLabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .skeuomorphicCobaltButton(cornerRadius: 12)
            }
            .buttonStyle(SkeuomorphicButtonStyle())
        }
        .padding(14)
        .skeuomorphicCard(cornerRadius: 16)
    }

    // MARK: - 2. Daily Mood Strip Card
    private var dailyMoodStripCard: some View {
        let weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        let moodMap = loadMoods()

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily Moods")
                    .font(.hostGrotesk(.semibold, size: 14))
                    .foregroundStyle(Color.primaryText)
                    .letterpress(isLight: false)

                Spacer()

                Text("Tap day to log")
                    .font(.hostGrotesk(.regular, size: 11))
                    .foregroundStyle(Color.mutedText)
                    .letterpress(isLight: false)
            }

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    let key = weekdayDateKey(for: index)
                    let currentMood = moodMap[key]

                    Button {
                        cycleMood(for: key)
                    } label: {
                        VStack(spacing: 4) {
                            Text(weekdays[index])
                                .font(.hostGrotesk(.medium, size: 11))
                                .foregroundStyle(Color.mutedText)
                                .letterpress(isLight: false)

                            ZStack {
                                if let mood = currentMood {
                                    Circle()
                                        .fill(LinearGradient.cardGradient)
                                        .frame(width: 36, height: 36)
                                        .overlay(Circle().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1))
                                        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)

                                    Text(mood)
                                        .font(.system(size: 17))
                                } else {
                                    Circle()
                                        .fill(LinearGradient.wellGradient)
                                        .frame(width: 36, height: 36)
                                        .overlay(Circle().strokeBorder(LinearGradient.reverseBevel, lineWidth: 1))
                                        .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1)

                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Color.mutedText.opacity(0.7))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SkeuomorphicButtonStyle())
                }
            }
        }
        .padding(14)
        .skeuomorphicCard(cornerRadius: 16)
    }

    // MARK: - 3. Settings Card
    private var settingsCard: some View {
        VStack(spacing: 0) {
            chevronRow(title: "Habit Manager", subtitle: "\(habits.count) habits", icon: "slider.horizontal.3") {
                showHabitManager = true
            }

            EngravedDivider().padding(.horizontal, 14)

            chevronRow(title: "Preferences", subtitle: "\(weekStartDay) start", icon: "gearshape") {
                showPreferencesSheet = true
            }

            EngravedDivider().padding(.horizontal, 14)

            chevronRow(title: "Friends Sync (Supabase)", subtitle: syncService.isConfigured ? "Connected" : "Offline", icon: "arrow.triangle.2.circlepath") {
                showSupabaseSheet = true
            }

            EngravedDivider().padding(.horizontal, 14)

            chevronRow(title: "Data & Backup", subtitle: "JSON / CSV / Reset", icon: "externaldrive") {
                showDataBackupSheet = true
            }

            if syncService.isAuthenticated {
                EngravedDivider().padding(.horizontal, 14)

                chevronRow(title: "Sign Out", subtitle: syncService.currentUserEmail ?? "Account", icon: "rectangle.portrait.and.arrow.right") {
                    Task {
                        await syncService.signOut()
                    }
                }
            }
        }
        .skeuomorphicCard(cornerRadius: 16)
    }

    private func chevronRow(title: String, subtitle: String? = nil, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.wellGradient)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().strokeBorder(LinearGradient.reverseBevel, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1)

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.cobaltBlue)
                }

                Text(title)
                    .font(.hostGrotesk(.medium, size: 15))
                    .foregroundStyle(Color.primaryText)
                    .letterpress(isLight: false)

                Spacer()

                if let subtitle {
                    Text(subtitle)
                        .font(.hostGrotesk(.regular, size: 13))
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mutedText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
        .buttonStyle(SkeuomorphicButtonStyle())
    }

    // MARK: - 4. About Card
    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("About HabitTracker")
                    .font(.hostGrotesk(.semibold, size: 14))
                    .foregroundStyle(Color.primaryText)
                    .letterpress(isLight: false)

                Spacer()

                Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
                    .font(.hostGrotesk(.medium, size: 12))
                    .monospacedDigit()
                    .foregroundStyle(Color.secondaryText)
                    .letterpress(isLight: false)
            }

            EngravedDivider()

            Text("100% On-Device & Private. Built with SwiftUI, SwiftData, and zero-cost cloud sync. Habit names, notes, and personal metadata never leave your local device.")
                .font(.hostGrotesk(.regular, size: 12))
                .foregroundStyle(Color.mutedText)
                .letterpress(isLight: false)
                .lineSpacing(3)
        }
        .padding(14)
        .skeuomorphicCard(cornerRadius: 16)
    }

    // MARK: ==========================================
    // MARK: SUB-SHEETS
    // MARK: ==========================================

    // MARK: Habit Manager Sheet
    private var habitManagerSheet: some View {
        NavigationStack {
            List {
                Section("Active Habits") {
                    ForEach(habits.filter { !$0.isArchived }) { habit in
                        HStack(spacing: 10) {
                            Image(systemName: habit.iconName)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.cobaltBlue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.title)
                                    .font(.hostGrotesk(.medium, size: 15))
                                Text(habit.type == .quit ? "Quit Habit" : "Build Habit")
                                    .font(.hostGrotesk(.regular, size: 11))
                                    .foregroundStyle(Color.mutedText)
                            }

                            Spacer()

                            Button {
                                withAnimation { habit.isArchived = true }
                            } label: {
                                Image(systemName: "archivebox")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.mutedText)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete { indexSet in
                        let active = habits.filter { !$0.isArchived }
                        for index in indexSet {
                            modelContext.delete(active[index])
                        }
                    }
                }

                let archived = habits.filter { $0.isArchived }
                if !archived.isEmpty {
                    Section("Archived Habits") {
                        ForEach(archived) { habit in
                            HStack {
                                Text(habit.title)
                                    .font(.hostGrotesk(.regular, size: 14))
                                    .foregroundStyle(Color.mutedText)

                                Spacer()

                                Button("Unarchive") {
                                    withAnimation { habit.isArchived = false }
                                }
                                .font(.hostGrotesk(.medium, size: 12))
                                .foregroundStyle(Color.cobaltBlue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Habit Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showHabitManager = false }
                        .foregroundStyle(Color.cobaltBlue)
                }
            }
        }
    }

    // MARK: Preferences Sheet
    private var preferencesSheet: some View {
        NavigationStack {
            Form {
                Section("Calendar") {
                    Picker("Week starts on", selection: $weekStartDay) {
                        Text("Monday").tag("Monday")
                        Text("Sunday").tag("Sunday")
                    }
                }

                Section("Habit Defaults") {
                    Picker("Default habit type", selection: $defaultHabitType) {
                        Text("Build").tag("build")
                        Text("Quit").tag("quit")
                    }
                }

                Section("Interaction") {
                    Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                }

                Section("Daily Reminder") {
                    Toggle("Daily Reminder", isOn: $dailyReminderEnabled)
                        .onChange(of: dailyReminderEnabled) { _, enabled in
                            if enabled { requestNotificationPermission() } else { cancelDailyReminder() }
                        }

                    if dailyReminderEnabled {
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showPreferencesSheet = false }
                        .foregroundStyle(Color.cobaltBlue)
                }
            }
        }
    }

    // MARK: Supabase Sheet
    private var supabaseSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cloud Database (Supabase)"), footer: Text("When configured, your habit changes and daily completion stats save automatically to your Supabase cloud database.")) {
                    HStack {
                        Image(systemName: syncService.isConfigured ? "checkmark.circle.fill" : "icloud.slash")
                            .foregroundStyle(syncService.isConfigured ? Color.cobaltBlue : Color.mutedText)
                        Text(syncService.isConfigured ? "Automatic Cloud Sync Active" : "Cloud Not Configured")
                            .font(.hostGrotesk(.medium, size: 14))
                            .foregroundStyle(Color.primaryText)
                    }

                    TextField("Supabase URL", text: $supabaseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    TextField("Anon Key", text: $supabaseAnonKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Save Configuration") {
                        syncService.configure(url: supabaseURL, anonKey: supabaseAnonKey)
                        showSupabaseSheet = false
                    }
                    .disabled(supabaseURL.isEmpty || supabaseAnonKey.isEmpty)
                }
            }
            .navigationTitle("Cloud Database")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSupabaseSheet = false }
                        .foregroundStyle(Color.cobaltBlue)
                }
            }
        }
    }

    // MARK: Data & Backup Sheet
    private var dataBackupSheet: some View {
        NavigationStack {
            List {
                Section("Export") {
                    Button {
                        exportJSON()
                    } label: {
                        Label("Export Data as JSON", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        exportCSV()
                    } label: {
                        Label("Export Logs as CSV", systemImage: "tablecells")
                    }
                }

                Section("Import") {
                    Button {
                        showImporter = true
                    } label: {
                        Label("Import JSON Backup", systemImage: "square.and.arrow.down")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Data & Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showDataBackupSheet = false }
                        .foregroundStyle(Color.cobaltBlue)
                }
            }
        }
    }

    // MARK: - Mood Helpers
    private func loadMoods() -> [String: String] {
        guard let data = dailyMoodsJson.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dict
    }

    private func saveMoods(_ dict: [String: String]) {
        guard let data = try? JSONEncoder().encode(dict),
              let json = String(data: data, encoding: .utf8)
        else { return }
        dailyMoodsJson = json
    }

    private func weekdayDateKey(for index: Int) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date.now)
        let weekday = cal.component(.weekday, from: today)
        let offset = (weekday + 5) % 7 // Monday = 0
        let mon = cal.date(byAdding: .day, value: -offset, to: today) ?? today
        let target = cal.date(byAdding: .day, value: index, to: mon) ?? mon
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: target)
    }

    private func cycleMood(for key: String) {
        let moods = ["😊", "🙂", "😐", "😔", "😴"]
        var current = loadMoods()
        if let existing = current[key], let idx = moods.firstIndex(of: existing) {
            if idx + 1 < moods.count {
                current[key] = moods[idx + 1]
            } else {
                current.removeValue(forKey: key)
            }
        } else {
            current[key] = moods[0]
        }
        saveMoods(current)
    }

    // MARK: - Helpers & Actions
    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return name.prefix(2).uppercased()
    }

    @MainActor
    private func performSync() async {
        isSyncing = true
        defer { isSyncing = false }

        let today = Calendar.current.startOfDay(for: .now)
        let weekday = Calendar.current.component(.weekday, from: today)
        let activeHabits = habits.filter { !$0.isArchived }
        let scheduledToday = activeHabits.filter { $0.isScheduled(on: weekday) }

        var completedCount = 0
        for habit in scheduledToday {
            if habit.logs.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: today) && $0.isCompleted }) {
                completedCount += 1
            }
        }

        let scheduledCount = scheduledToday.count
        let rate = scheduledCount > 0 ? Double(completedCount) / Double(scheduledCount) : 0.0

        let maxStreak = activeHabits.map {
            StreakCalculator.currentStreak(for: $0, asOf: today, logs: $0.logs)
        }.max() ?? 0

        do {
            try await syncService.syncDailyStats(
                completedCount: completedCount,
                scheduledCount: scheduledCount,
                completionRate: rate,
                activeStreak: maxStreak
            )
            syncStatusMessage = "Sync completed successfully!"
            showSyncStatusAlert = true
        } catch {
            syncStatusMessage = "Sync failed: \(error.localizedDescription)"
            showSyncStatusAlert = true
        }
    }

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    scheduleDailyReminder()
                } else {
                    dailyReminderEnabled = false
                }
            }
        }
    }

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["habittracker.daily"])

        let content = UNMutableNotificationContent()
        content.title = "HabitTracker"
        content.body = "Time to check in on your habits!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = dailyReminderHour
        dateComponents.minute = dailyReminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "habittracker.daily", content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["habittracker.daily"])
    }

    @MainActor
    private func exportJSON() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let exportData = ExportPayload(
            habits: habits.map { ExportHabit(from: $0) },
            logs: habitLogs.map { ExportLog(from: $0) }
        )

        guard let data = try? encoder.encode(exportData) else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("HabitTracker-Backup.json")
        try? data.write(to: tempURL)
        presentShareSheet(for: tempURL)
    }

    @MainActor
    private func exportCSV() {
        var csv = "habit_id,habit_title,habit_type,date,is_completed,is_slip\n"
        for log in habitLogs {
            let habitID = log.habit?.id.uuidString ?? ""
            let title = log.habit?.title ?? ""
            let type = log.habit?.type.rawValue ?? ""
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            let date = dateFormatter.string(from: log.date)
            csv += "\(habitID),\"\(title)\",\(type),\(date),\(log.isCompleted),\(log.isSlip)\n"
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("HabitTracker-Export.csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        presentShareSheet(for: tempURL)
    }

    @MainActor
    private func presentShareSheet(for url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene,
        let rootVC = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        rootVC.present(activityVC, animated: true)
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result,
              let url = urls.first,
              url.startAccessingSecurityScopedResource() else { return }

        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(ExportPayload.self, from: data) else { return }

        for exportHabit in payload.habits {
            let habit = Habit(
                id: exportHabit.id,
                title: exportHabit.title,
                type: HabitType(rawValue: exportHabit.type) ?? .build,
                scheduleDays: exportHabit.scheduleDays,
                isArchived: exportHabit.isArchived,
                createdAt: exportHabit.createdAt,
                sortOrder: exportHabit.sortOrder
            )
            modelContext.insert(habit)
        }

        for exportLog in payload.logs {
            let log = HabitLog(
                id: exportLog.id,
                date: exportLog.date,
                isCompleted: exportLog.isCompleted,
                isSlip: exportLog.isSlip
            )
            let habitID = exportLog.habitID
            let descriptor = FetchDescriptor<Habit>(predicate: #Predicate<Habit> { $0.id == habitID })
            log.habit = try? modelContext.fetch(descriptor).first
            modelContext.insert(log)
        }

        try? modelContext.save()
    }

    private func resetAllData() {
        do {
            try modelContext.delete(model: HabitLog.self)
            try modelContext.delete(model: Habit.self)
            try modelContext.save()
        } catch { }
    }
}

// MARK: - Export Data Models
private struct ExportPayload: Codable {
    let habits: [ExportHabit]
    let logs: [ExportLog]
}

private struct ExportHabit: Codable {
    let id: UUID
    let title: String
    let type: String
    let scheduleDays: [Int]
    let isArchived: Bool
    let createdAt: Date
    let sortOrder: Int

    init(from habit: Habit) {
        self.id = habit.id
        self.title = habit.title
        self.type = habit.type.rawValue
        self.scheduleDays = habit.scheduleDays
        self.isArchived = habit.isArchived
        self.createdAt = habit.createdAt
        self.sortOrder = habit.sortOrder
    }
}

private struct ExportLog: Codable {
    let id: UUID
    let habitID: UUID
    let date: Date
    let isCompleted: Bool
    let isSlip: Bool

    init(from log: HabitLog) {
        self.id = log.id
        self.habitID = log.habit?.id ?? UUID()
        self.date = log.date
        self.isCompleted = log.isCompleted
        self.isSlip = log.isSlip
    }
}
