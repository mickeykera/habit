import SwiftUI
import SwiftData

enum ReportTimeScope: String, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }
}

struct ReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.sortOrder)
    private var habits: [Habit]

    @State private var selectedScope: ReportTimeScope = .weekly
    @State private var selectedWeekStart: Date = Self.mondayOfCurrentWeek()
    @State private var selectedMonth: Date = .now
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)

    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday start
        return cal
    }()

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 0) {
            // Top Pill Segmented Switcher
            topSegmentedSwitcher
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 20) {
                    switch selectedScope {
                    case .weekly:
                        weeklyReportSection
                    case .monthly:
                        monthlyReportSection
                    case .yearly:
                        yearlyReportSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 96) // Floating nav bar padding
            }
        }
        .background(Color.pageGround.ignoresSafeArea())
    }

    // MARK: - Top Pill Segmented Switcher
    private var topSegmentedSwitcher: some View {
        HStack(spacing: 6) {
            ForEach(ReportTimeScope.allCases) { scope in
                let isSelected = selectedScope == scope
                Button {
                    withAnimation(.snappySpring) {
                        selectedScope = scope
                    }
                } label: {
                    Text(scope.rawValue)
                        .font(.hostGrotesk(isSelected ? .semibold : .medium, size: 14))
                        .foregroundStyle(isSelected ? Color.cobaltLabel : Color.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            isSelected ? Color.cobaltBlue : Color.cardSurface
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(AppPillButtonStyle())
            }
        }
    }

    // MARK: ==========================================
    // MARK: 1. WEEKLY REPORT
    // MARK: ==========================================

    private var weeklyReportSection: some View {
        VStack(spacing: 16) {
            // Centered Date Range Selector < 23/11 ~ 29/11 >
            HStack {
                Button {
                    changeWeek(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.cardSurface))
                }
                .buttonStyle(AppPillButtonStyle())

                Spacer()

                Text(weekRangeString)
                    .font(.hostGrotesk(.medium, size: 15))
                    .monospacedDigit()
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Button {
                    changeWeek(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.cardSurface))
                }
                .buttonStyle(AppPillButtonStyle())
            }

            if habits.isEmpty {
                emptyHabitsCard
            } else {
                // Flat Matrix Card
                weeklyMatrixCard

                // 4-column KPI Footer
                weeklyKpiFooter
            }
        }
    }

    private var weeklyMatrixCard: some View {
        let weekDates = generateWeekDates()

        return VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 0) {
                Text("Habit")
                    .font(.hostGrotesk(.medium, size: 12))
                    .foregroundStyle(Color.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(0..<7, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.hostGrotesk(.medium, size: 12))
                        .foregroundStyle(Color.mutedText)
                        .frame(width: 28)
                }

                Text("Total")
                    .font(.hostGrotesk(.medium, size: 11))
                    .foregroundStyle(Color.mutedText)
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.bottom, 12)

            // Habit Rows
            ForEach(habits) { habit in
                let completionData = habitWeekCompletions(for: habit, weekDates: weekDates)

                HStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: habit.iconName)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.cobaltBlue)

                        Text(habit.title)
                            .font(.hostGrotesk(.regular, size: 13))
                            .foregroundStyle(Color.primaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(0..<7, id: \.self) { dayIndex in
                        ReportCellView(state: completionData.states[dayIndex])
                    }

                    // Total %
                    HStack(spacing: 2) {
                        if completionData.rate >= 0.999 {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.cobaltBlue)
                        }
                        Text("\(Int(round(completionData.rate * 100)))%")
                            .font(.hostGrotesk(.semibold, size: 11))
                            .monospacedDigit()
                            .foregroundStyle(completionData.rate >= 0.999 ? Color.cobaltBlue : Color.secondaryText)
                    }
                    .frame(width: 44, alignment: .trailing)
                }
                .padding(.vertical, 8)
            }

            // Best Day Highlight Row
            let bestDay = computeBestDay(weekDates: weekDates)
            HStack {
                Text("Best Day: \(bestDay.name)")
                    .font(.hostGrotesk(.medium, size: 13))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Text("\(Int(round(bestDay.rate * 100)))% completed")
                    .font(.hostGrotesk(.semibold, size: 12))
                    .monospacedDigit()
                    .foregroundStyle(Color.cobaltBlue)
            }
            .padding(10)
            .background(Color.pageGround)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.top, 12)
        }
        .padding(16)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var weeklyKpiFooter: some View {
        let weekDates = generateWeekDates()
        let stats = computeWeeklyStats(weekDates: weekDates)

        return HStack(spacing: 8) {
            kpiFooterCell(title: "Met %", value: "\(stats.metPercent)%")
            kpiFooterCell(title: "Best Day", value: stats.bestDayLabel)
            kpiFooterCell(title: "Total Done", value: "\(stats.totalDone)")
            kpiFooterCell(title: "Best Streak", value: "\(stats.bestStreak)d")
        }
    }

    private func kpiFooterCell(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.hostGrotesk(.bold, size: 18))
                .monospacedDigit()
                .foregroundStyle(Color.cobaltBlue)

            Text(title)
                .font(.hostGrotesk(.regular, size: 11))
                .foregroundStyle(Color.mutedText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: ==========================================
    // MARK: 2. MONTHLY REPORT
    // MARK: ==========================================

    private var monthlyReportSection: some View {
        VStack(spacing: 16) {
            // Centered Month Selector < 2026 Nov >
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.cardSurface))
                }
                .buttonStyle(AppPillButtonStyle())

                Spacer()

                Text(monthYearHeaderString)
                    .font(.hostGrotesk(.medium, size: 16))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.cardSurface))
                }
                .buttonStyle(AppPillButtonStyle())
            }

            if habits.isEmpty {
                emptyHabitsCard
            } else {
                // 2-column Grid of Flat Mini Monthly Calendar Cards
                let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(habits) { habit in
                        miniMonthlyCard(for: habit)
                    }
                }
            }
        }
    }

    private func miniMonthlyCard(for habit: Habit) -> some View {
        guard let _ = calendar.dateInterval(of: .month, for: selectedMonth) else {
            return AnyView(EmptyView())
        }

        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        var completedCount = 0
        var scheduledCount = 0

        var daysData: [(day: Int, isDone: Bool, isSched: Bool)] = []
        for d in 1...daysInMonth {
            var comps = calendar.dateComponents([.year, .month], from: selectedMonth)
            comps.day = d
            if let date = calendar.date(from: comps) {
                let weekday = calendar.component(.weekday, from: date) - 1
                let isSched = habit.scheduleDays.isEmpty || habit.scheduleDays.contains(weekday)
                let start = calendar.startOfDay(for: date)
                let isDone = habit.logs.contains { calendar.isDate($0.date, inSameDayAs: start) && $0.isCompleted }

                if isSched {
                    scheduledCount += 1
                    if isDone { completedCount += 1 }
                }
                daysData.append((day: d, isDone: isDone, isSched: isSched))
            }
        }

        let rate = scheduledCount > 0 ? Double(completedCount) / Double(scheduledCount) : 0
        let isPerfect = rate >= 0.999 && scheduledCount > 0

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                // Card Header: Icon + Title
                HStack(spacing: 6) {
                    Image(systemName: habit.iconName)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.cobaltBlue)

                    Text(habit.title)
                        .font(.hostGrotesk(.semibold, size: 13))
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)

                    Spacer()

                    if isPerfect {
                        Text("PERFECT")
                            .font(.hostGrotesk(.bold, size: 9))
                            .foregroundStyle(Color.cobaltLabel)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cobaltBlue)
                            .clipShape(Capsule())
                    }
                }

                // Compact 7-column Numbered Day Grid
                let gridCols = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
                LazyVGrid(columns: gridCols, spacing: 3) {
                    ForEach(daysData, id: \.day) { item in
                        ZStack {
                            if item.isDone {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.cobaltBlue)
                                    .frame(height: 15)
                            } else if item.isSched {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.pageGround)
                                    .frame(height: 15)
                            } else {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.clear)
                                    .frame(height: 15)
                            }

                            Text("\(item.day)")
                                .font(.system(size: 8, weight: .medium))
                                .monospacedDigit()
                                .foregroundStyle(item.isDone ? Color.cobaltLabel : Color.mutedText)
                        }
                    }
                }

                // Bottom Footer: Rate % + Done Count
                HStack {
                    Text("\(Int(round(rate * 100)))%")
                        .font(.hostGrotesk(.bold, size: 14))
                        .monospacedDigit()
                        .foregroundStyle(Color.cobaltBlue)

                    Spacer()

                    Text("\(completedCount)d done")
                        .font(.hostGrotesk(.medium, size: 11))
                        .monospacedDigit()
                        .foregroundStyle(Color.secondaryText)
                }
            }
            .padding(12)
            .background(Color.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        )
    }

    // MARK: ==========================================
    // MARK: 3. YEARLY REPORT
    // MARK: ==========================================

    private var yearlyReportSection: some View {
        VStack(spacing: 16) {
            // Centered Year Selector < 2026 >
            HStack {
                Button {
                    selectedYear -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.cardSurface))
                }
                .buttonStyle(AppPillButtonStyle())

                Spacer()

                Text("\(selectedYear)")
                    .font(.hostGrotesk(.bold, size: 18))
                    .monospacedDigit()
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Button {
                    selectedYear += 1
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.cardSurface))
                }
                .buttonStyle(AppPillButtonStyle())
            }

            if habits.isEmpty {
                emptyHabitsCard
            } else {
                // Stacked List of Flat Habit Heatmap Cards
                VStack(spacing: 14) {
                    ForEach(habits) { habit in
                        yearlyHabitCard(for: habit)
                    }
                }
            }
        }
    }

    private func yearlyHabitCard(for habit: Habit) -> some View {
        let stats = computeYearlyStats(for: habit, year: selectedYear)

        return VStack(alignment: .leading, spacing: 12) {
            // Header Row: Habit Icon + Name (Left), Rate + Days (Right)
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: habit.iconName)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.cobaltBlue)

                    Text(habit.title)
                        .font(.hostGrotesk(.semibold, size: 15))
                        .foregroundStyle(Color.primaryText)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("\(String(format: "%.1f", stats.rate * 100))%")
                        .font(.hostGrotesk(.bold, size: 15))
                        .monospacedDigit()
                        .foregroundStyle(Color.cobaltBlue)

                    Text("·")
                        .foregroundStyle(Color.mutedText)

                    Text("\(stats.totalDone)D")
                        .font(.hostGrotesk(.semibold, size: 13))
                        .monospacedDigit()
                        .foregroundStyle(Color.secondaryText)
                }
            }

            // 52-week contribution heatmap grid with stepped royal blue opacity
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(0..<52, id: \.self) { weekIndex in
                        VStack(spacing: 3) {
                            ForEach(0..<7, id: \.self) { dayOfWeek in
                                let cellState = stats.grid[weekIndex * 7 + dayOfWeek]
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(cellState == 1 ? Color.cobaltBlue : Color.pageGround)
                                    .frame(width: 9, height: 9)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(14)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers & Data Computation

    private var emptyHabitsCard: some View {
        VStack(spacing: 8) {
            Text("No active habits")
                .font(.hostGrotesk(.medium, size: 16))
                .foregroundStyle(Color.secondaryText)
            Text("Create habits in the Today tab to view reports.")
                .font(.hostGrotesk(.regular, size: 13))
                .foregroundStyle(Color.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private static func mondayOfCurrentWeek() -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: Date.now)
        let weekday = cal.component(.weekday, from: today) // 2=Mon
        let offset = (weekday + 5) % 7 // Mon = 0
        return cal.date(byAdding: .day, value: -offset, to: today) ?? today
    }

    private var weekRangeString: String {
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: selectedWeekStart) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return "< \(formatter.string(from: selectedWeekStart)) ~ \(formatter.string(from: weekEnd)) >"
    }

    private var monthYearHeaderString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM"
        return "< \(formatter.string(from: selectedMonth)) >"
    }

    private func changeWeek(by amount: Int) {
        if let newDate = calendar.date(byAdding: .day, value: amount * 7, to: selectedWeekStart) {
            withAnimation(.snappySpring) { selectedWeekStart = newDate }
        }
    }

    private func changeMonth(by amount: Int) {
        if let newDate = calendar.date(byAdding: .month, value: amount, to: selectedMonth) {
            withAnimation(.snappySpring) { selectedMonth = newDate }
        }
    }

    private func generateWeekDates() -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: selectedWeekStart) }
    }

    private struct HabitWeekData {
        let states: [ReportCellView.CellState]
        let rate: Double
    }

    private func habitWeekCompletions(for habit: Habit, weekDates: [Date]) -> HabitWeekData {
        var states: [ReportCellView.CellState] = []
        var scheduled = 0
        var completed = 0

        for date in weekDates {
            let weekday = calendar.component(.weekday, from: date) - 1
            let isSched = habit.scheduleDays.isEmpty || habit.scheduleDays.contains(weekday)

            if !isSched {
                states.append(.notScheduled)
            } else {
                scheduled += 1
                let start = calendar.startOfDay(for: date)
                let isDone = habit.logs.contains { calendar.isDate($0.date, inSameDayAs: start) && $0.isCompleted }
                if isDone {
                    completed += 1
                    states.append(.completed)
                } else {
                    states.append(.missed)
                }
            }
        }

        let rate = scheduled > 0 ? Double(completed) / Double(scheduled) : 0
        return HabitWeekData(states: states, rate: rate)
    }

    private struct BestDayInfo {
        let name: String
        let rate: Double
    }

    private func computeBestDay(weekDates: [Date]) -> BestDayInfo {
        var bestName = "Monday"
        var maxRate: Double = -1

        let dayFullNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        for (i, date) in weekDates.enumerated() {
            let weekday = calendar.component(.weekday, from: date) - 1
            let sched = habits.filter { $0.scheduleDays.isEmpty || $0.scheduleDays.contains(weekday) }
            guard !sched.isEmpty else { continue }

            let start = calendar.startOfDay(for: date)
            let done = sched.filter { habit in
                habit.logs.contains { calendar.isDate($0.date, inSameDayAs: start) && $0.isCompleted }
            }.count

            let rate = Double(done) / Double(sched.count)
            if rate > maxRate {
                maxRate = rate
                bestName = dayFullNames[i]
            }
        }

        return BestDayInfo(name: bestName, rate: max(0, maxRate))
    }

    private struct WeeklyKpis {
        let metPercent: Int
        let bestDayLabel: String
        let totalDone: Int
        let bestStreak: Int
    }

    private func computeWeeklyStats(weekDates: [Date]) -> WeeklyKpis {
        var totalScheduled = 0
        var totalCompleted = 0

        for date in weekDates {
            let weekday = calendar.component(.weekday, from: date) - 1
            let sched = habits.filter { $0.scheduleDays.isEmpty || $0.scheduleDays.contains(weekday) }
            totalScheduled += sched.count

            let start = calendar.startOfDay(for: date)
            totalCompleted += sched.filter { habit in
                habit.logs.contains { calendar.isDate($0.date, inSameDayAs: start) && $0.isCompleted }
            }.count
        }

        let met = totalScheduled > 0 ? Int(round((Double(totalCompleted) / Double(totalScheduled)) * 100)) : 0
        let bestDay = computeBestDay(weekDates: weekDates)

        var maxStreak = 0
        for habit in habits {
            let streak = StreakCalculator.currentStreak(for: habit, asOf: weekDates.last ?? Date.now, logs: habit.logs)
            if streak > maxStreak { maxStreak = streak }
        }

        return WeeklyKpis(
            metPercent: met,
            bestDayLabel: String(bestDay.name.prefix(2)),
            totalDone: totalCompleted,
            bestStreak: maxStreak
        )
    }

    private struct YearlyStats {
        let rate: Double
        let totalDone: Int
        let grid: [Int] // 52 * 7 = 364 cells
    }

    private func computeYearlyStats(for habit: Habit, year: Int) -> YearlyStats {
        var comps = DateComponents()
        comps.year = year
        comps.month = 1
        comps.day = 1
        guard let yearStart = calendar.date(from: comps) else {
            return YearlyStats(rate: 0, totalDone: 0, grid: Array(repeating: 0, count: 364))
        }

        let weekday = calendar.component(.weekday, from: yearStart)
        let offset = (weekday + 5) % 7
        let gridStart = calendar.date(byAdding: .day, value: -offset, to: yearStart) ?? yearStart

        var grid: [Int] = []
        var totalDone = 0
        var totalSched = 0

        for dayOffset in 0..<364 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: gridStart) {
                let wk = calendar.component(.weekday, from: date) - 1
                let isSched = habit.scheduleDays.isEmpty || habit.scheduleDays.contains(wk)
                let start = calendar.startOfDay(for: date)
                let isDone = habit.logs.contains { calendar.isDate($0.date, inSameDayAs: start) && $0.isCompleted }

                if isSched {
                    totalSched += 1
                    if isDone {
                        totalDone += 1
                        grid.append(1)
                    } else {
                        grid.append(0)
                    }
                } else {
                    grid.append(0)
                }
            } else {
                grid.append(0)
            }
        }

        let rate = totalSched > 0 ? Double(totalDone) / Double(totalSched) : 0
        return YearlyStats(rate: rate, totalDone: totalDone, grid: grid)
    }
}

#Preview {
    ReportView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
