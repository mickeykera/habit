import SwiftUI
import SwiftData

// MARK: - Filter Type

enum FilterType: Hashable, Identifiable {
    case all
    case build
    case quit
    case specific(Habit)

    var id: String {
        switch self {
        case .all: "all"
        case .build: "build"
        case .quit: "quit"
        case .specific(let habit): "habit-\(habit.id.uuidString)"
        }
    }

    var label: String {
        switch self {
        case .all: "All"
        case .build: "Build"
        case .quit: "Quit"
        case .specific(let habit): habit.title
        }
    }

    static func == (lhs: FilterType, rhs: FilterType) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Month Data

struct DayData: Identifiable {
    let id: Date
    let date: Date
    let completedCount: Int
    let scheduledCount: Int
    let habits: [(habit: Habit, completed: Bool)]

    var completionRate: Double {
        guard scheduledCount > 0 else { return 0 }
        return Double(completedCount) / Double(scheduledCount)
    }
}

// MARK: - Calendar View

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]

    @State private var selectedMonth: Date = .now
    @State private var selectedDay: Date?
    @State private var filterType: FilterType = .all
    @State private var monthData: [Date: DayData] = [:]

    private let calendar = Calendar.current
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthHeader
                filterRow
                calendarGrid
                if let selectedDay, let dayData = monthData[selectedDay] {
                    dayDetailCard(dayData)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.pageGround)
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { recomputeMonthData() }
        .onChange(of: selectedMonth) { _, _ in recomputeMonthData() }
        .onChange(of: filterType) { _, _ in recomputeMonthData() }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Button { advanceMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                }

                Spacer()

                Text(monthYearString)
                    .font(hostGrotesk(.semibold, size: 20))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Button { advanceMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                }
            }

            Text(monthlySuccessRateString)
                .font(hostGrotesk(.bold, size: 40))
                .monospacedDigit()
                .foregroundStyle(Color.cobaltBlue)

            HStack(spacing: 16) {
                Label("\(totalCompletions) done", systemImage: "checkmark.circle.fill")
                    .font(hostGrotesk(.medium, size: 13))
                    .monospacedDigit()
                    .foregroundStyle(Color.secondaryText)

                Label("\(longestStreak) day streak", systemImage: "flame.fill")
                    .font(hostGrotesk(.medium, size: 13))
                    .monospacedDigit()
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(.all)
                filterPill(.build)
                filterPill(.quit)
            }
        }
    }

    private func filterPill(_ type: FilterType) -> some View {
        let isActive = filterType == type
        return Button {
            withAnimation(.snappySpring) {
                filterType = type
            }
        } label: {
            Text(type.label)
                .font(hostGrotesk(.medium, size: 13))
                .foregroundStyle(isActive ? Color.inverseText : Color.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isActive ? Color.cobaltBlue : Color.cardSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.hairline, lineWidth: isActive ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = generateMonthDays()
        return VStack(spacing: 0) {
            // Weekday header
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .font(hostGrotesk(.medium, size: 13))
                        .foregroundStyle(Color.mutedText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)

            // Day cells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    let isCurrentMonth = calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                    let dayData = monthData[calendar.startOfDay(for: date)]
                    let rate = dayData?.completionRate ?? 0

                    DayCellView(
                        date: date,
                        completionRate: rate,
                        isToday: calendar.isDateInToday(date),
                        isSelected: selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                        isCurrentMonth: isCurrentMonth
                    )
                    .onTapGesture {
                        withAnimation(.snappySpring) {
                            if selectedDay.map({ calendar.isDate($0, inSameDayAs: date) }) == true {
                                selectedDay = nil
                            } else {
                                selectedDay = calendar.startOfDay(for: date)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .insetCard()
    }

    // MARK: - Day Detail Card

    private func dayDetailCard(_ data: DayData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            let pct = Int(data.completionRate * 100)
            Text("\(pct)% — \(data.completedCount) of \(data.scheduledCount) habits")
                .font(hostGrotesk(.semibold, size: 16))
                .monospacedDigit()
                .foregroundStyle(Color.primaryText)

            HairlineDivider()

            ForEach(data.habits, id: \.habit.id) { entry in
                HStack(spacing: 8) {
                    Image(systemName: entry.completed ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(entry.completed ? Color.cobaltBlue : Color.mutedText)
                        .font(.system(size: 16))

                    Text(entry.habit.title)
                        .font(hostGrotesk(.regular, size: 15))
                        .foregroundStyle(Color.primaryText)

                    Spacer()
                }
            }
        }
        .padding(14)
        .insetCard()
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Computation

    private func recomputeMonthData() {
        monthData = computeMonthData()
    }

    private func computeMonthData() -> [Date: DayData] {
        let monthInterval = monthRange
        let start = monthInterval.lowerBound
        let end = monthInterval.upperBound

        // Filter habits based on filterType
        let filteredHabits: [Habit]
        switch filterType {
        case .all:
            filteredHabits = habits
        case .build:
            filteredHabits = habits.filter { $0.type == .build }
        case .quit:
            filteredHabits = habits.filter { $0.type == .quit }
        case .specific(let habit):
            filteredHabits = [habit]
        }

        // Fetch all logs in the month range
        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate<HabitLog> { log in
                log.date >= start && log.date < end
            }
        )
        let allLogs = (try? modelContext.fetch(descriptor)) ?? []

        // Index logs by (habitID, date)
        var logIndex: [String: HabitLog] = [:]
        for log in allLogs {
            if let habitID = log.habit?.id {
                let key = "\(habitID)-\(calendar.startOfDay(for: log.date).timeIntervalSince1970)"
                logIndex[key] = log
            }
        }

        var result: [Date: DayData] = [:]
        var currentDate = start

        while currentDate < end {
            let weekday = calendar.component(.weekday, from: currentDate)
            var completedCount = 0
            var scheduledCount = 0
            var habitEntries: [(habit: Habit, completed: Bool)] = []

            for habit in filteredHabits {
                guard habit.isScheduled(on: weekday) else { continue }
                scheduledCount += 1
                let key = "\(habit.id)-\(currentDate.timeIntervalSince1970)"
                let log = logIndex[key]
                let completed = log?.isCompleted == true
                if completed { completedCount += 1 }
                habitEntries.append((habit: habit, completed: completed))
            }

            result[currentDate] = DayData(
                id: currentDate,
                date: currentDate,
                completedCount: completedCount,
                scheduledCount: scheduledCount,
                habits: habitEntries
            )

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return result
    }

    // MARK: - Calendar Helpers

    private var monthRange: Range<Date> {
        let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
        let start = calendar.date(from: comps)!
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        return start..<end
    }

    private func generateMonthDays() -> [Date] {
        let range = monthRange
        let start = range.lowerBound
        let firstWeekday = calendar.component(.weekday, from: start)

        // Leading days from previous month (Sunday = 1)
        let leadingDays = firstWeekday - calendar.firstWeekday
        let adjustedLeading = (leadingDays + 7) % 7

        var days: [Date] = []

        // Previous month fill
        for i in stride(from: adjustedLeading, through: 1, by: -1) {
            if let date = calendar.date(byAdding: .day, value: -i, to: start) {
                days.append(date)
            }
        }

        // Current month days
        var current = start
        while current < range.upperBound {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        // Trailing days to fill to complete rows of 7
        let remainder = days.count % 7
        if remainder > 0 {
            let trailing = 7 - remainder
            for i in 0..<trailing {
                if let date = calendar.date(byAdding: .day, value: i, to: range.upperBound) {
                    days.append(date)
                }
            }
        }

        return days
    }

    private func advanceMonth(_ value: Int) {
        withAnimation(.snappySpring) {
            selectedMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) ?? selectedMonth
            selectedDay = nil
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var monthlySuccessRateString: String {
        let today = calendar.startOfDay(for: .now)
        let daysUpToToday = monthData.values.filter { $0.date <= today && $0.scheduledCount > 0 }
        let totalScheduled = daysUpToToday.reduce(0) { $0 + $1.scheduledCount }
        let totalCompleted = daysUpToToday.reduce(0) { $0 + $1.completedCount }
        guard totalScheduled > 0 else { return "—" }
        return "\(Int(Double(totalCompleted) / Double(totalScheduled) * 100))%"
    }

    private var totalCompletions: Int {
        monthData.values.reduce(0) { $0 + $1.completedCount }
    }

    private var longestStreak: Int {
        let sortedDays = monthData.values
            .filter { $0.scheduledCount > 0 }
            .sorted { $0.date < $1.date }
        var longest = 0
        var current = 0
        for day in sortedDays {
            if day.completionRate >= 1.0 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
    .modelContainer(for: Habit.self, HabitLog.self, inMemory: true)
}
