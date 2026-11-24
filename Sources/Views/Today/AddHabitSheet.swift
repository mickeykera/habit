import SwiftUI
import SwiftData
import UserNotifications

struct AddHabitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingHabit: Habit?

    @State private var title: String = ""
    @State private var habitType: HabitType = .build
    @State private var isDaily: Bool = true
    @State private var selectedDays: Set<Int> = [] // 0=Sun..6=Sat
    @State private var hasReminder: Bool = false
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }()
    @State private var showDeleteConfirmation: Bool = false

    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var isEditing: Bool { existingHabit != nil }

    init(habit: Habit? = nil) {
        self.existingHabit = habit
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Habit Name")
                            .font(.hostGrotesk(.medium, size: 13))
                            .foregroundStyle(.mutedText)

                        TextField("e.g., Read 20 minutes", text: $title)
                            .font(.hostGrotesk(.regular, size: 16))
                            .padding(12)
                            .insetCard()
                    }

                    HairlineDivider()

                    // Type picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.hostGrotesk(.medium, size: 13))
                            .foregroundStyle(.mutedText)

                        Picker("Type", selection: $habitType) {
                            Text("Build").tag(HabitType.build)
                            Text("Quit").tag(HabitType.quit)
                        }
                        .pickerStyle(.segmented)
                    }

                    HairlineDivider()

                    // Schedule
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schedule")
                            .font(.hostGrotesk(.medium, size: 13))
                            .foregroundStyle(.mutedText)

                        Toggle("Every day", isOn: $isDaily)
                            .font(.hostGrotesk(.regular, size: 16))
                            .tint(.cobaltBlue)

                        if !isDaily {
                            HStack(spacing: 8) {
                                ForEach(0..<7, id: \.self) { day in
                                    let isSelected = selectedDays.contains(day)
                                    Button {
                                        if isSelected {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    } label: {
                                        Text(weekdayLabels[day])
                                            .font(.hostGrotesk(.medium, size: 13))
                                            .frame(width: 36, height: 36)
                                            .foregroundStyle(isSelected ? .white : .primaryText)
                                            .background(
                                                Circle()
                                                    .fill(isSelected ? Color.cobaltBlue : Color.clear)
                                            )
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(
                                                        isSelected ? Color.clear : Color.hairline,
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    HairlineDivider()

                    // Reminder
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Reminder", isOn: $hasReminder)
                            .font(.hostGrotesk(.regular, size: 16))
                            .tint(.cobaltBlue)

                        if hasReminder {
                            DatePicker(
                                "Time",
                                selection: $reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .font(.hostGrotesk(.regular, size: 16))
                        }
                    }

                    HairlineDivider()

                    // Save button
                    Button {
                        save()
                    } label: {
                        Text(isEditing ? "Update Habit" : "Add Habit")
                            .font(.hostGrotesk(.semibold, size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(title.trimmingCharacters(in: .whitespaces).isEmpty
                                          ? Color.cobaltBlue.opacity(0.4)
                                          : Color.cobaltBlue)
                            )
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)

                    // Edit-mode actions
                    if isEditing {
                        VStack(spacing: 12) {
                            Button {
                                archiveHabit()
                            } label: {
                                Text("Archive Habit")
                                    .font(.hostGrotesk(.medium, size: 16))
                                    .foregroundStyle(.secondaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .insetCard()
                            }

                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Text("Delete Habit")
                                    .font(.hostGrotesk(.medium, size: 16))
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .insetCard()
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(16)
            }
            .background(Color.pageGround)
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.cobaltBlue)
                }
            }
            .alert("Delete Habit", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteHabit()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete this habit and all its history. This cannot be undone.")
            }
            .onAppear {
                if let habit = existingHabit {
                    title = habit.title
                    habitType = habit.type
                    isDaily = habit.scheduleDays.isEmpty
                    selectedDays = Set(habit.scheduleDays)
                    hasReminder = habit.reminderTime != nil
                    if let time = habit.reminderTime {
                        reminderTime = time
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        let scheduleDays = isDaily ? [Int]() : Array(selectedDays).sorted()
        let reminder: Date? = hasReminder ? reminderTime : nil

        if let habit = existingHabit {
            habit.title = trimmedTitle
            habit.type = habitType
            habit.scheduleDays = scheduleDays
            habit.reminderTime = reminder
        } else {
            let habit = Habit(
                title: trimmedTitle,
                type: habitType,
                scheduleDays: scheduleDays,
                reminderTime: reminder
            )
            modelContext.insert(habit)
        }

        if hasReminder {
            scheduleNotification(
                title: trimmedTitle,
                scheduleDays: scheduleDays,
                time: reminderTime
            )
        } else if let habit = existingHabit {
            removeNotifications(for: habit.id)
        }

        dismiss()
    }

    private func archiveHabit() {
        guard let habit = existingHabit else { return }
        habit.isArchived = true
        removeNotifications(for: habit.id)
        dismiss()
    }

    private func deleteHabit() {
        guard let habit = existingHabit else { return }
        removeNotifications(for: habit.id)
        modelContext.delete(habit)
        dismiss()
    }

    // MARK: - Notifications

    private func scheduleNotification(title: String, scheduleDays: [Int], time: Date) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: time)
            let minute = calendar.component(.minute, from: time)

            // Remove old notifications for this habit
            let habitId = existingHabit?.id.uuidString ?? UUID().uuidString
            center.removePendingNotificationRequests(withIdentifiers:
                (0..<7).map { "\(habitId)-\($0)" }
            )

            let daysToSchedule = scheduleDays.isEmpty ? Array(0..<7) : scheduleDays

            for day in daysToSchedule {
                var dateComponents = DateComponents()
                // Convert 0=Sun..6=Sat to Calendar weekday 1=Sun..7=Sat
                dateComponents.weekday = day + 1
                dateComponents.hour = hour
                dateComponents.minute = minute

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: true
                )

                let content = UNMutableNotificationContent()
                content.title = "HabitTracker"
                content.body = "Time for: \(title)"
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: "\(habitId)-\(day)",
                    content: content,
                    trigger: trigger
                )

                center.add(request)
            }
        }
    }

    private func removeNotifications(for id: UUID) {
        let center = UNUserNotificationCenter.current()
        let ids = (0..<7).map { "\(id.uuidString)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

#Preview {
    AddHabitSheet()
}
