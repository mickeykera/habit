import SwiftUI
import SwiftData
import UserNotifications
import UniformTypeIdentifiers

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(SupabaseSyncService.self) private var syncService
    @Environment(\.modelContext) private var modelContext

    @AppStorage("weekStartDay") private var weekStartDay: String = "Monday"
    @AppStorage("defaultHabitType") private var defaultHabitType: String = "build"
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled: Bool = false
    @AppStorage("dailyReminderHour") private var dailyReminderHour: Int = 9
    @AppStorage("dailyReminderMinute") private var dailyReminderMinute: Int = 0

    @State private var supabaseURL: String = ""
    @State private var supabaseAnonKey: String = ""
    @State private var showResetConfirmation = false
    @State private var showImporter = false
    @State private var isSyncing = false
    @State private var syncStatusMessage: String?
    @State private var showSyncStatusAlert = false

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
        ScrollView {
            VStack(spacing: 24) {
                profileSyncSection
                if !syncService.isConfigured {
                    supabaseConfigSection
                }
                preferencesSection
                dataManagementSection
                aboutSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color.pageGround)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Profile & Sync Section

    private var profileSyncSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Profile & Sync")

            VStack(spacing: 0) {
                // Display Name
                settingsRow {
                    HStack {
                        Text("Display Name")
                            .font(hostGrotesk(.regular, size: 16))
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        TextField("Your name", text: Binding(
                            get: { syncService.displayName },
                            set: { newValue in
                                syncService.displayName = newValue
                                UserDefaults.standard.set(newValue, forKey: "displayName")
                            }
                        ))
                        .font(hostGrotesk(.regular, size: 16))
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 160)
                    }
                }

                HairlineDivider().padding(.horizontal, 16)

                // Friend Code
                settingsRow {
                    HStack {
                        Text("Friend Code")
                            .font(hostGrotesk(.regular, size: 16))
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        Text(syncService.friendCode.isEmpty ? "------" : syncService.friendCode)
                            .font(hostGrotesk(.bold, size: 16))
                            .foregroundStyle(Color.cobaltBlue)
                            .monospacedDigit()
                            .tracking(2)
                        Button {
                            UIPasteboard.general.string = syncService.friendCode
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.cobaltBlue)
                        }
                        .padding(.leading, 4)
                    }
                }

                HairlineDivider().padding(.horizontal, 16)

                // Connection Status
                settingsRow {
                    HStack {
                        Text("Status")
                            .font(hostGrotesk(.regular, size: 16))
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        Circle()
                            .fill(syncService.isConfigured ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(syncService.isConfigured ? "Connected" : "Not Configured")
                            .font(hostGrotesk(.medium, size: 14))
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                HairlineDivider().padding(.horizontal, 16)

                // Sync Now Button
                settingsRow {
                    Button {
                        Task {
                            await performSync()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSyncing {
                                ProgressView()
                                    .tint(Color.cobaltBlue)
                                    .padding(.trailing, 6)
                            }
                            Text(isSyncing ? "Syncing…" : "Sync Now")
                                .font(hostGrotesk(.semibold, size: 16))
                                .foregroundStyle(Color.cobaltBlue)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cobaltBlue, lineWidth: 1)
                        )
                    }
                    .disabled(isSyncing || !syncService.isConfigured)
                }

                // Privacy Notice
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.cobaltBlue)
                    Text("Habit titles never leave your device. Only anonymized completion counts are synced.")
                        .font(hostGrotesk(.regular, size: 12))
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .padding(.top, 4)
            }
            .insetCard()
        }
    }

    // MARK: - Supabase Configuration Section

    private var supabaseConfigSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Supabase Configuration")

            VStack(spacing: 0) {
                settingsRow {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Connect to Supabase to enable friend sync.")
                            .font(hostGrotesk(.regular, size: 14))
                            .foregroundStyle(Color.secondaryText)

                        TextField("Supabase URL", text: $supabaseURL)
                            .font(hostGrotesk(.regular, size: 15))
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .padding(10)
                            .background(Color.pageGround)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.hairline, lineWidth: 1)
                            )

                        TextField("Anon Key", text: $supabaseAnonKey)
                            .font(hostGrotesk(.regular, size: 15))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(10)
                            .background(Color.pageGround)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.hairline, lineWidth: 1)
                            )

                        Button {
                            syncService.configure(url: supabaseURL, anonKey: supabaseAnonKey)
                        } label: {
                            Text("Connect")
                                .font(hostGrotesk(.semibold, size: 16))
                                .foregroundStyle(Color.cobaltLabel)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.cobaltBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(supabaseURL.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  supabaseAnonKey.trimmingCharacters(in: .whitespaces).isEmpty)

                        Text("Create a free Supabase project, run schema.sql, then paste your URL and anon key above.")
                            .font(hostGrotesk(.regular, size: 12))
                            .foregroundStyle(Color.mutedText)
                    }
                }
            }
            .insetCard()
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Preferences")

            VStack(spacing: 0) {
                // Week starts on
                settingsRow {
                    HStack {
                        Text("Week starts on")
                            .font(hostGrotesk(.regular, size: 16))
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        Picker("", selection: $weekStartDay) {
                            Text("Monday").tag("Monday")
                            Text("Sunday").tag("Sunday")
                        }
                        .pickerStyle(.menu)
                        .tint(Color.cobaltBlue)
                    }
                }

                HairlineDivider().padding(.horizontal, 16)

                // Default habit type
                settingsRow {
                    HStack {
                        Text("Default habit type")
                            .font(hostGrotesk(.regular, size: 16))
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        Picker("", selection: $defaultHabitType) {
                            Text("Build").tag("build")
                            Text("Quit").tag("quit")
                        }
                        .pickerStyle(.menu)
                        .tint(Color.cobaltBlue)
                    }
                }

                HairlineDivider().padding(.horizontal, 16)

                // Haptics
                settingsRow {
                    Toggle(isOn: $hapticsEnabled) {
                        Text("Haptics")
                            .font(hostGrotesk(.regular, size: 16))
                            .foregroundStyle(Color.primaryText)
                    }
                    .tint(Color.cobaltBlue)
                }

                HairlineDivider().padding(.horizontal, 16)

                // Daily Reminder
                settingsRow {
                    VStack(spacing: 8) {
                        Toggle(isOn: $dailyReminderEnabled) {
                            Text("Daily reminder")
                                .font(hostGrotesk(.regular, size: 16))
                                .foregroundStyle(Color.primaryText)
                        }
                        .tint(Color.cobaltBlue)
                        .onChange(of: dailyReminderEnabled) { _, enabled in
                            if enabled {
                                requestNotificationPermission()
                            } else {
                                cancelDailyReminder()
                            }
                        }

                        if dailyReminderEnabled {
                            DatePicker(
                                "Time",
                                selection: reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .font(hostGrotesk(.regular, size: 16))
                            .tint(Color.cobaltBlue)
                        }
                    }
                }
            }
            .insetCard()
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Data Management")

            VStack(spacing: 0) {
                // Export JSON
                settingsRow {
                    Button {
                        exportJSON()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                            Text("Export as JSON")
                                .font(hostGrotesk(.regular, size: 16))
                            Spacer()
                        }
                        .foregroundStyle(Color.primaryText)
                    }
                }

                HairlineDivider().padding(.horizontal, 16)

                // Export CSV
                settingsRow {
                    Button {
                        exportCSV()
                    } label: {
                        HStack {
                            Image(systemName: "tablecells")
                                .font(.system(size: 14))
                            Text("Export as CSV")
                                .font(hostGrotesk(.regular, size: 16))
                            Spacer()
                        }
                        .foregroundStyle(Color.primaryText)
                    }
                }

                HairlineDivider().padding(.horizontal, 16)

                // Import Backup
                settingsRow {
                    Button {
                        showImporter = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14))
                            Text("Import Backup")
                                .font(hostGrotesk(.regular, size: 16))
                            Spacer()
                        }
                        .foregroundStyle(Color.primaryText)
                    }
                }

                HairlineDivider().padding(.horizontal, 16)

                // Reset All Data
                settingsRow {
                    Button {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                            Text("Reset All Data")
                                .font(hostGrotesk(.regular, size: 16))
                            Spacer()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .insetCard()
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("About")

            VStack(spacing: 0) {
                settingsRow {
                    HStack {
                        Text("Version")
                            .font(hostGrotesk(.regular, size: 16))
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        Text("1.0.0")
                            .font(hostGrotesk(.regular, size: 14))
                            .monospacedDigit()
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                HairlineDivider().padding(.horizontal, 16)

                settingsRow {
                    HStack {
                        Text("Build")
                            .font(hostGrotesk(.regular, size: 16))
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        Text(buildInfo)
                            .font(hostGrotesk(.regular, size: 14))
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                HairlineDivider().padding(.horizontal, 16)

                settingsRow {
                    Text("Made with SwiftUI & SwiftData")
                        .font(hostGrotesk(.regular, size: 14))
                        .foregroundStyle(Color.mutedText)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .insetCard()
        }
    }

    // MARK: - Helpers

    private var buildInfo: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(hostGrotesk(.semibold, size: 13))
            .foregroundStyle(Color.mutedText)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }

    // MARK: - Actions

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

        // Streak from longest current active habit
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

    // MARK: - Notifications

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
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["habittracker.daily"])
    }

    // MARK: - Export / Import

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

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("HabitTracker-Backup.json")
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

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("HabitTracker-Export.csv")
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

        // iPad popover anchor
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
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { $0.id == habitID }
            )
            log.habit = try? modelContext.fetch(descriptor).first
            modelContext.insert(log)
        }

        try? modelContext.save()
    }

    // MARK: - Reset

    private func resetAllData() {
        do {
            try modelContext.delete(model: HabitLog.self)
            try modelContext.delete(model: Habit.self)
            try modelContext.save()
        } catch {
            // Deletion completed or handled
        }
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
