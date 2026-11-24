import Foundation
import SwiftData

// MARK: - HabitType

enum HabitType: String, Codable, CaseIterable, Sendable {
    case build
    case quit

    var displayName: String {
        switch self {
        case .build: "Build"
        case .quit: "Quit"
        }
    }
}

// MARK: - Habit

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var title: String

    /// Stored as rawValue string for SwiftData compatibility.
    var typeRawValue: String

    /// Days of the week when this habit is scheduled.
    /// 0 = Sunday … 6 = Saturday. Empty means daily.
    var scheduleDays: [Int]

    var reminderTime: Date?
    var isArchived: Bool
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]

    // MARK: Computed

    var type: HabitType {
        get { HabitType(rawValue: typeRawValue) ?? .build }
        set { typeRawValue = newValue.rawValue }
    }

    /// Whether this habit is scheduled on a given weekday (1=Sunday…7=Saturday
    /// from Calendar, mapped to 0=Sunday…6=Saturday).
    func isScheduled(on weekday: Int) -> Bool {
        guard !scheduleDays.isEmpty else { return true } // empty = daily
        // Calendar.component(.weekday) returns 1-based (1=Sun), convert to 0-based.
        let zeroBased = weekday - 1
        return scheduleDays.contains(zeroBased)
    }

    // MARK: Init

    init(
        id: UUID = UUID(),
        title: String,
        type: HabitType = .build,
        scheduleDays: [Int] = [],
        reminderTime: Date? = nil,
        isArchived: Bool = false,
        createdAt: Date = .now,
        sortOrder: Int = 0,
        logs: [HabitLog] = []
    ) {
        self.id = id
        self.title = title
        self.typeRawValue = type.rawValue
        self.scheduleDays = scheduleDays
        self.reminderTime = reminderTime
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.logs = logs
    }
}
