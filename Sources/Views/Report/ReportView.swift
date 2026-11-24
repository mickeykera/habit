import SwiftUI
import SwiftData

struct ReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]

    @State private var currentWeekStart: Date = Self.mondayOfCurrentWeek()

    private let calendar = Calendar.current
    private let dayColumnWidth: CGFloat = 38
    private let nameColumnWidth: CGFloat = 100
    private let totalColumnWidth: CGFloat = 50
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                weekSwitcher
                reportTable
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.pageGround)
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Week Switcher

    private var weekSwitcher: some View {
        HStack {
            Button { advanceWeek(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
            }

            Spacer()

            Text(weekRangeString)
                .font(hostGrotesk(.medium, size: 16))
                .foregroundStyle(Color.primaryText)

            Spacer()

            Button { advanceWeek(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Report Table

    private var reportTable: some View {
        VStack(spacing: 0) {
            headerRow
            HairlineDivider()
            habitRows
            HairlineDivider()
            summaryRow
        }
        .padding(12)
        .insetCard()
    }

    // MARK: Header Row

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: nameColumnWidth, alignment: .leading)

            ForEach(0..<7, id: \.self) { index in
                Text(dayLabels[index])
                    .font(hostGrotesk(.medium, size: 13))
                    .foregroundStyle(Color.mutedText)
                    .frame(width: dayColumnWidth)
            }

            Text("Total")
                .font(hostGrotesk(.medium, size: 11))
                .foregroundStyle(Color.mutedText)
                .frame(width: totalColumnWidth)
        }
        .padding(.bottom, 8)
    }

    // MARK: Habit Rows

    private var habitRows: some View {
        let weekDates = generateWeekDates()
        let logIndex = buildLogIndex(for: weekDates)

        return ForEach(habits) { habit in
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(habit.title)
                        .font(hostGrotesk(.regular, size: 14))
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: nameColumnWidth, alignment: .leading)

                    ForEach(weekDates, id: \.self) { date in
                        let weekday = calendar.component(.weekday, from: date)
                        let isScheduled = habit.isScheduled(on: weekday)
                        let key = "\(habit.id)-\(date.timeIntervalSince1970)"
                        let log = logIndex[key]
                        let state: ReportCellView.CellState = {
                            if !isScheduled { return .notScheduled }
                            if log?.isCompleted == true { return .completed }
                            return .missed
                        }()

                        ReportCellView(state: state)
                            .frame(width: dayColumnWidth)
                    }

                    // Per-habit weekly ratio
                    let ratio = habitWeeklyRatio(habit: habit, dates: weekDates, logIndex: logIndex)
                    Text(ratio)
                        .font(hostGrotesk(.medium, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.secondaryText)
                        .frame(width: totalColumnWidth)
                }
                .padding(.vertical, 6)

                HairlineDivider()
            }
        }
    }

    // MARK: Summary Row

    private var summaryRow: some View {
        let weekDates = generateWeekDates()
        let logIndex = buildLogIndex(for: weekDates)

        return HStack(spacing: 0) {
            Text("Daily %")
                .font(hostGrotesk(.medium, size: 12))
                .foregroundStyle(Color.mutedText)
                .frame(width: nameColumnWidth, alignment: .leading)

            ForEach(weekDates, id: \.self) { date in
                let pct = dailyPercentage(date: date, logIndex: logIndex)
                Text(pct)
                    .font(hostGrotesk(.medium, size: 11))
                    .monospacedDigit()
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: dayColumnWidth)
            }

            let overall = overallWeeklyRate(dates: weekDates, logIndex: logIndex)
            Text(overall)
                .font(hostGrotesk(.semibold, size: 12))
                .monospacedDigit()
                .foregroundStyle(Color.cobaltBlue)
                .frame(width: totalColumnWidth)
        }
        .padding(.top, 8)
    }

    // MARK: - Data Helpers

    private func generateWeekDates() -> [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: currentWeekStart)
        }
    }

    private func buildLogIndex(for dates: [Date]) -> [String: HabitLog] {
        guard let first = dates.first, let last = dates.last else { return [:] }
        let end = calendar.date(byAdding: .day, value: 1, to: last)!

        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate<HabitLog> { log in
                log.date >= first && log.date < end
            }
        )
        let logs = (try? modelContext.fetch(descriptor)) ?? []

        var index: [String: HabitLog] = [:]
        for log in logs {
            if let habitID = log.habit?.id {
                let day = calendar.startOfDay(for: log.date)
                let key = "\(habitID)-\(day.timeIntervalSince1970)"
                index[key] = log
            }
        }
        return index
    }

    private func habitWeeklyRatio(habit: Habit, dates: [Date], logIndex: [String: HabitLog]) -> String {
        var scheduled = 0
        var completed = 0
        for date in dates {
            let weekday = calendar.component(.weekday, from: date)
            guard habit.isScheduled(on: weekday) else { continue }
            scheduled += 1
            let key = "\(habit.id)-\(date.timeIntervalSince1970)"
            if logIndex[key]?.isCompleted == true { completed += 1 }
        }
        guard scheduled > 0 else { return "—" }
        return "\(completed)/\(scheduled)"
    }

    private func dailyPercentage(date: Date, logIndex: [String: HabitLog]) -> String {
        let weekday = calendar.component(.weekday, from: date)
        var scheduled = 0
        var completed = 0
        for habit in habits {
            guard habit.isScheduled(on: weekday) else { continue }
            scheduled += 1
            let key = "\(habit.id)-\(date.timeIntervalSince1970)"
            if logIndex[key]?.isCompleted == true { completed += 1 }
        }
        guard scheduled > 0 else { return "—" }
        return "\(Int(Double(completed) / Double(scheduled) * 100))%"
    }

    private func overallWeeklyRate(dates: [Date], logIndex: [String: HabitLog]) -> String {
        var totalScheduled = 0
        var totalCompleted = 0
        for date in dates {
            let weekday = calendar.component(.weekday, from: date)
            for habit in habits {
                guard habit.isScheduled(on: weekday) else { continue }
                totalScheduled += 1
                let key = "\(habit.id)-\(date.timeIntervalSince1970)"
                if logIndex[key]?.isCompleted == true { totalCompleted += 1 }
            }
        }
        guard totalScheduled > 0 else { return "—" }
        return "\(Int(Double(totalCompleted) / Double(totalScheduled) * 100))%"
    }

    // MARK: - Navigation

    private func advanceWeek(_ value: Int) {
        withAnimation(.snappySpring) {
            currentWeekStart = calendar.date(byAdding: .weekOfYear, value: value, to: currentWeekStart) ?? currentWeekStart
        }
    }

    private var weekRangeString: String {
        let end = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: currentWeekStart)) – \(formatter.string(from: end))"
    }

    // MARK: - Monday Calculation

    static func mondayOfCurrentWeek() -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let weekday = cal.component(.weekday, from: today) // 1=Sun
        // Monday = weekday 2. Offset: (weekday - 2 + 7) % 7
        let daysBack = (weekday - 2 + 7) % 7
        return cal.date(byAdding: .day, value: -daysBack, to: today)!
    }
}

#Preview {
    NavigationStack {
        ReportView()
    }
    .modelContainer(for: Habit.self, HabitLog.self, inMemory: true)
}
