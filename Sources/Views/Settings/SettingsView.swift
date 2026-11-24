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
            // Clean Top Bar Header
            HStack {
                Spacer()
                Text("Settings")
                    .font(.hostGrotesk(.medium, size: 22))
                    .foregroundStyle(Color.primaryText)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 20) {
                    // Header Profile Card (Clean #FFFFFF / #F7F6F6 with circular avatar, display name, pill button to copy friend code)
                    if syncService.isAuthenticated {
                        authenticatedHeaderCard
                    } else {
                        unauthenticatedHeaderCard
                    }

                    // Grouped Flat #F7F6F6 Cards for Habit Manager, Preferences, Friends Sync, Data & Backup
                    groupedSettingsCard

                    // About Card
                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 96) // Floating nav bar padding
            }
        }
        .background(Color.pageGround.ignoresSafeArea())
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

    // MARK: - Header Profile Card (Authenticated)
    private var authenticatedHeaderCard: some View {
        HStack(spacing: 14) {
            // Circular Initials Avatar
            ZStack {
                Circle()
                    .fill(Color.cobaltBlue)
                    .frame(width: 50, height: 50)

                Text(initials(from: syncService.displayName))
                    .font(.hostGrotesk(.bold, size: 18))
                    .foregroundStyle(Color.cobaltLabel)
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
                }

                Text("Friend Code: \(syncService.friendCode)")
                    .font(.hostGrotesk(.regular, size: 12))
                    .monospacedDigit()
                    .foregroundStyle(Color.mutedText)
            }

            Spacer()

            // Pill button to copy 6-char Friend Code
            Button {
                UIPasteboard.general.string = syncService.friendCode
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                    Text("Copy")
                }
                .font(.hostGrotesk(.medium, size: 12))
                .foregroundStyle(Color.cobaltBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.cardSurface)
                .clipShape(Capsule())
            }
            .buttonStyle(AppPillButtonStyle())
        }
        .padding(14)
        .background(Color.pageGround)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.hairline, lineWidth: 1))
    }

    // MARK: - Header Profile Card (Unauthenticated)
    private var unauthenticatedHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.cardSurface)
                    .frame(width: 50, height: 50)

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.cobaltBlue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Account / Sign Up")
                    .font(.hostGrotesk(.semibold, size: 16))
                    .foregroundStyle(Color.primaryText)

                Text("Save data permanently in the cloud.")
                    .font(.hostGrotesk(.regular, size: 12))
                    .foregroundStyle(Color.mutedText)
            }

            Spacer()

            Button {
                showAuthSheet = true
            } label: {
                Text("Sign Up")
                    .font(.hostGrotesk(.semibold, size: 13))
                    .foregroundStyle(Color.cobaltLabel)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.cobaltBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(AppPillButtonStyle())
        }
        .padding(14)
        .background(Color.pageGround)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.hairline, lineWidth: 1))
    }

    // MARK: - Grouped Settings Card (Flat #F7F6F6, 8pt radius, clean row spacing)
    private var groupedSettingsCard: some View {
        VStack(spacing: 12) {
            settingRow(title: "Habit Manager", subtitle: "\(habits.count) habits", icon: "slider.horizontal.3") {
                showHabitManager = true
            }

            settingRow(title: "Preferences", subtitle: "\(weekStartDay) start", icon: "gearshape") {
                showPreferencesSheet = true
            }

            settingRow(title: "Friends Sync (Supabase)", subtitle: syncService.isConfigured ? "Connected" : "Offline", icon: "arrow.triangle.2.circlepath") {
                showSupabaseSheet = true
            }

            settingRow(title: "Data & Backup", subtitle: "JSON / CSV / Reset", icon: "externaldrive") {
                showDataBackupSheet = true
            }

            if syncService.isAuthenticated {
                settingRow(title: "Sign Out", subtitle: syncService.currentUserEmail ?? "Account", icon: "rectangle.portrait.and.arrow.right") {
                    Task {
                        await syncService.signOut()
                    }
                }
            }
        }
        .padding(12)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func settingRow(title: String, subtitle: String? = nil, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.pageGround)
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.cobaltBlue)
                }

                Text(title)
                    .font(.hostGrotesk(.medium, size: 15))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                if let subtitle {
                    Text(subtitle)
                        .font(.hostGrotesk(.regular, size: 13))
                        .foregroundStyle(Color.mutedText)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mutedText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .buttonStyle(AppPillButtonStyle())
    }

    // MARK: - About Card
    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("About HabitTracker")
                    .font(.hostGrotesk(.semibold, size: 14))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
                    .font(.hostGrotesk(.medium, size: 12))
                    .monospacedDigit()
                    .foregroundStyle(Color.secondaryText)
            }

            Text("100% On-Device & Private. Built with SwiftUI, SwiftData, and zero-cost cloud sync. Habit names, notes, and personal metadata never leave your local device.")
                .font(.hostGrotesk(.regular, size: 12))
                .foregroundStyle(Color.mutedText)
                .lineSpacing(2)
        }
        .padding(14)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

    // MARK: - Helpers & Actions
    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return name.prefix(2).uppercased()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                scheduleDailyReminder()
            } else {
                DispatchQueue.main.async {
                    dailyReminderEnabled = false
                }
            }
        }
    }

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])

        var components = DateComponents()
        components.hour = dailyReminderHour
        components.minute = dailyReminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "HabitTracker"
        content.body = "Don't forget to check your habits today!"
        content.sound = .default

        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }

    private func resetAllData() {
        for log in habitLogs {
            modelContext.delete(log)
        }
        for habit in habits {
            modelContext.delete(habit)
        }
    }

    private func exportJSON() {
        let exportData = habits.map { habit in
            [
                "id": habit.id.uuidString,
                "title": habit.title,
                "type": habit.type.rawValue,
                "scheduleDays": habit.scheduleDays,
                "logs": habit.logs.map { [
                    "date": ISO8601DateFormatter().string(from: $0.date),
                    "isCompleted": $0.isCompleted,
                    "isSlip": $0.isSlip
                ] }
            ] as [String: Any]
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        shareText(jsonString, filename: "HabitTracker_Export.json")
    }

    private func exportCSV() {
        var csv = "Habit,Date,Completed,Slip\n"
        for habit in habits {
            for log in habit.logs {
                let dateStr = ISO8601DateFormatter().string(from: log.date)
                csv += "\"\(habit.title)\",\(dateStr),\(log.isCompleted),\(log.isSlip)\n"
            }
        }
        shareText(csv, filename: "HabitTracker_Logs.csv")
    }

    private func shareText(_ text: String, filename: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? text.write(to: tempURL, atomically: true, encoding: .utf8)

        let av = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }

        for item in json {
            guard let title = item["title"] as? String,
                  let typeStr = item["type"] as? String,
                  let type = HabitType(rawValue: typeStr) else { continue }

            let scheduleDays = item["scheduleDays"] as? [Int] ?? []
            let habit = Habit(title: title, type: type, scheduleDays: scheduleDays)
            modelContext.insert(habit)

            if let logsData = item["logs"] as? [[String: Any]] {
                for logDict in logsData {
                    guard let dateStr = logDict["date"] as? String,
                          let date = ISO8601DateFormatter().date(from: dateStr) else { continue }
                    let isCompleted = logDict["isCompleted"] as? Bool ?? false
                    let isSlip = logDict["isSlip"] as? Bool ?? false

                    let log = HabitLog(date: date, isCompleted: isCompleted, isSlip: isSlip, habit: habit)
                    modelContext.insert(log)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
        .environment(SupabaseSyncService())
}
