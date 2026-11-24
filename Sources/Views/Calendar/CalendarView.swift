import SwiftUI
import SwiftData

enum CalendarFilterScope: String, CaseIterable, Identifiable {
    case overall = "Overall"
    case build = "Build Only"
    case quit = "Quit Only"

    var id: String { rawValue }
}

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.sortOrder)
    private var habits: [Habit]

    @State private var selectedMonth: Date = .now
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: .now)
    @State private var scopeFilter: CalendarFilterScope = .overall
    @State private var selectedHabitId: UUID? = nil // nil = "All"
    @State private var isShowingOverallRate: Bool = false
    @State private var showAddHabitSheet: Bool = false

    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday start (M T W T F S S)
        return cal
    }()

    private let weekdaySymbols = ["M", "T", "W", "T", "F", "S", "S"]

    // MARK: - Filtered Habits
    private var filteredHabits: [Habit] {
        if let habitId = selectedHabitId {
            return habits.filter { $0.id == habitId }
        }
        switch scopeFilter {
        case .overall:
            return habits
        case .build:
            return habits.filter { $0.type == .build }
        case .quit:
            return habits.filter { $0.type == .quit }
        }
    }

    // MARK: - Month Dates
    private var daysInSelectedMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))
        else { return [] }

        // Start grid from the Monday of the first week
        let weekdayOfFirst = (calendar.component(.weekday, from: firstDay) + 5) % 7 // 0=Mon..6=Sun
        guard let startDate = calendar.date(byAdding: .day, value: -weekdayOfFirst, to: firstDay) else {
            return []
        }

        let totalDays = 42 // 6 rows of 7
        return (0..<totalDays).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startDate)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                topBar
                habitFilterStrip
                monthlyCalendarCard
                statsSummaryCard
                doneTodayCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 96) // Safe area above floating pill bar
        }
        .background(Color.pageGround.ignoresSafeArea())
        .sheet(isPresented: $showAddHabitSheet) {
            AddHabitSheet()
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Left: Filter Icon
            Menu {
                ForEach(CalendarFilterScope.allCases) { scope in
                    Button {
                        withAnimation(.snappySpring) {
                            scopeFilter = scope
                            selectedHabitId = nil
                        }
                    } label: {
                        HStack {
                            Text(scope.rawValue)
                            if scopeFilter == scope && selectedHabitId == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.cardSurface)
                        .frame(width: 36, height: 36)

                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                }
            }

            Spacer()

            // Center: Overall ⌄ Pill Selector
            Menu {
                ForEach(CalendarFilterScope.allCases) { scope in
                    Button {
                        withAnimation(.snappySpring) {
                            scopeFilter = scope
                            selectedHabitId = nil
                        }
                    } label: {
                        HStack {
                            Text(scope.rawValue)
                            if scopeFilter == scope && selectedHabitId == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedHabitId != nil ? (habits.first(where: { $0.id == selectedHabitId })?.title ?? "Habit") : scopeFilter.rawValue)
                        .font(.hostGrotesk(.medium, size: 14))
                        .foregroundStyle(Color.primaryText)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.cardSurface)
                .clipShape(Capsule())
            }
            .buttonStyle(AppPillButtonStyle())

            Spacer()

            // Right: + Pill Button
            Button {
                showAddHabitSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.cardSurface)
                        .frame(width: 36, height: 36)

                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.cobaltBlue)
                }
            }
            .buttonStyle(AppPillButtonStyle())
        }
    }

    // MARK: - Habit Filter Strip (Pill Chips)
    private var habitFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                let isAllSelected = selectedHabitId == nil
                Button {
                    withAnimation(.snappySpring) { selectedHabitId = nil }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 11))
                        Text("All")
                            .font(.hostGrotesk(.medium, size: 13))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .foregroundStyle(isAllSelected ? Color.cobaltLabel : Color.primaryText)
                    .background(isAllSelected ? Color.cobaltBlue : Color.cardSurface)
                    .clipShape(Capsule())
                }
                .buttonStyle(AppPillButtonStyle())

                // Each active habit chip
                ForEach(habits) { habit in
                    let isSelected = selectedHabitId == habit.id
                    Button {
                        withAnimation(.snappySpring) { selectedHabitId = habit.id }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: habit.iconName)
                                .font(.system(size: 11))
                            Text(habit.title)
                                .font(.hostGrotesk(.medium, size: 13))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .foregroundStyle(isSelected ? Color.cobaltLabel : Color.primaryText)
                        .background(isSelected ? Color.cobaltBlue : Color.cardSurface)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(AppPillButtonStyle())
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Monthly Calendar Card
    private var monthlyCalendarCard: some View {
        VStack(spacing: 12) {
            // Header: < 11/2026 >
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.pageGround))
                }
                .buttonStyle(AppPillButtonStyle())

                Spacer()

                Text(monthHeaderTitle)
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
                        .background(Circle().fill(Color.pageGround))
                }
                .buttonStyle(AppPillButtonStyle())
            }
            .padding(.horizontal, 4)

            // Weekday Header M T W T F S S
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.hostGrotesk(.medium, size: 12))
                        .foregroundStyle(Color.mutedText)
                        .frame(maxWidth: .infinity)
                }
            }

            // 7-column Calendar Grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(daysInSelectedMonth, id: \.self) { date in
                    let isCurrentMonth = calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                    let isToday = calendar.isDateInToday(date)
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDay)
                    let rate = completionRate(for: date)

                    DayCellView(
                        date: date,
                        completionRate: rate,
                        isToday: isToday,
                        isSelected: isSelected,
                        isCurrentMonth: isCurrentMonth
                    )
                    .onTapGesture {
                        withAnimation(.snappySpring) {
                            selectedDay = calendar.startOfDay(for: date)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Stats Summary Card
    private var statsSummaryCard: some View {
        let stats = computeStats()

        return VStack(spacing: 16) {
            // Flat Circular Progress Ring
            VStack(spacing: 10) {
                ZStack {
                    // Track circle
                    Circle()
                        .stroke(Color.hairline, lineWidth: 10)
                        .frame(width: 120, height: 120)

                    // Arc
                    Circle()
                        .trim(from: 0, to: max(0.001, CGFloat(isShowingOverallRate ? stats.overallRate : stats.monthlyRate)))
                        .stroke(
                            Color.cobaltBlue,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                        .animation(.snappySpring, value: isShowingOverallRate)

                    // Percentage Text
                    VStack(spacing: 2) {
                        Text("\(Int(round((isShowingOverallRate ? stats.overallRate : stats.monthlyRate) * 100)))%")
                            .font(.hostGrotesk(.bold, size: 24))
                            .monospacedDigit()
                            .foregroundStyle(Color.cobaltBlue)

                        Text(isShowingOverallRate ? "Overall Rate" : "Monthly Rate")
                            .font(.hostGrotesk(.medium, size: 10))
                            .foregroundStyle(Color.mutedText)
                    }
                }

                // Toggle Pill
                Button {
                    withAnimation(.snappySpring) {
                        isShowingOverallRate.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                        Text(isShowingOverallRate ? "Monthly" : "Overall")
                            .font(.hostGrotesk(.medium, size: 11))
                    }
                    .foregroundStyle(Color.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.pageGround)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.hairline, lineWidth: 1))
                }
                .buttonStyle(AppPillButtonStyle())
            }
            .padding(.top, 4)

            // 2×2 KPI Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                kpiCell(title: "Best Streaks", value: "\(stats.bestStreak) Day", icon: "flame.fill")
                kpiCell(title: "Perfect Days", value: "\(stats.perfectDays) Day", icon: "star.fill")
                kpiCell(title: "Habits Done", value: "\(stats.habitsDone)", icon: "checkmark.circle.fill")
                kpiCell(title: "Daily Average", value: String(format: "%.1f", stats.dailyAverage), icon: "chart.line.uptrend.xyaxis")
            }
        }
        .padding(16)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func kpiCell(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.pageGround)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.cobaltBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.hostGrotesk(.regular, size: 11))
                    .foregroundStyle(Color.mutedText)

                Text(value)
                    .font(.hostGrotesk(.semibold, size: 14))
                    .monospacedDigit()
                    .foregroundStyle(Color.primaryText)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.pageGround)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Done Today Card
    private var doneTodayCard: some View {
        let completedHabitsForSelectedDay = filteredHabits.filter { habit in
            let start = calendar.startOfDay(for: selectedDay)
            return habit.logs.contains {
                calendar.isDate($0.date, inSameDayAs: start) && $0.isCompleted
            }
        }

        return VStack(spacing: 12) {
            HStack {
                Text("Done Today")
                    .font(.hostGrotesk(.medium, size: 16))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Text("\(completedHabitsForSelectedDay.count) completed")
                    .font(.hostGrotesk(.medium, size: 13))
                    .foregroundStyle(Color.mutedText)
            }

            if completedHabitsForSelectedDay.isEmpty {
                HStack {
                    Spacer()
                    Text("No habits data for this date")
                        .font(.hostGrotesk(.regular, size: 13))
                        .foregroundStyle(Color.mutedText)
                        .padding(.vertical, 8)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(completedHabitsForSelectedDay) { habit in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.pageGround)
                                    .frame(width: 26, height: 26)

                                Image(systemName: habit.iconName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.cobaltBlue)
                            }

                            Text(habit.title)
                                .font(.hostGrotesk(.regular, size: 14))
                                .foregroundStyle(Color.primaryText)

                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(Color.cobaltBlue)
                                    .frame(width: 20, height: 20)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.cobaltLabel)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private var monthHeaderTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yyyy"
        return formatter.string(from: selectedMonth)
    }

    private func changeMonth(by amount: Int) {
        if let newDate = calendar.date(byAdding: .month, value: amount, to: selectedMonth) {
            withAnimation(.snappySpring) {
                selectedMonth = newDate
            }
        }
    }

    private func completionRate(for date: Date) -> Double {
        let weekday = calendar.component(.weekday, from: date) - 1 // 0=Sun..6=Sat
        let scheduled = filteredHabits.filter { $0.scheduleDays.isEmpty || $0.scheduleDays.contains(weekday) }
        guard !scheduled.isEmpty else { return 0 }

        let start = calendar.startOfDay(for: date)
        let done = scheduled.filter { habit in
            habit.logs.contains { calendar.isDate($0.date, inSameDayAs: start) && $0.isCompleted }
        }.count

        return Double(done) / Double(scheduled.count)
    }

    private struct CalendarComputedStats {
        let monthlyRate: Double
        let overallRate: Double
        let bestStreak: Int
        let perfectDays: Int
        let habitsDone: Int
        let dailyAverage: Double
    }

    private func computeStats() -> CalendarComputedStats {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else {
            return CalendarComputedStats(monthlyRate: 0, overallRate: 0, bestStreak: 0, perfectDays: 0, habitsDone: 0, dailyAverage: 0)
        }

        var totalScheduled = 0
        var totalDone = 0
        var perfectDaysCount = 0

        var date = monthInterval.start
        while date < monthInterval.end {
            let weekday = calendar.component(.weekday, from: date) - 1
            let scheduled = filteredHabits.filter { $0.scheduleDays.isEmpty || $0.scheduleDays.contains(weekday) }

            if !scheduled.isEmpty {
                totalScheduled += scheduled.count
                let start = calendar.startOfDay(for: date)
                let completedOnDay = scheduled.filter { habit in
                    habit.logs.contains { calendar.isDate($0.date, inSameDayAs: start) && $0.isCompleted }
                }.count

                totalDone += completedOnDay
                if completedOnDay == scheduled.count {
                    perfectDaysCount += 1
                }
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? monthInterval.end
        }

        let mRate = totalScheduled > 0 ? Double(totalDone) / Double(totalScheduled) : 0

        var maxStreak = 0
        for habit in filteredHabits {
            let streak = StreakCalculator.currentStreak(for: habit, asOf: Date.now, logs: habit.logs)
            if streak > maxStreak { maxStreak = streak }
        }

        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        let avg = Double(totalDone) / Double(max(1, daysInMonth))

        let allLogs = filteredHabits.flatMap { $0.logs }
        let overallDone = allLogs.filter { $0.isCompleted }.count
        let oRate = allLogs.isEmpty ? mRate : Double(overallDone) / Double(max(1, allLogs.count))

        return CalendarComputedStats(
            monthlyRate: mRate,
            overallRate: oRate,
            bestStreak: maxStreak,
            perfectDays: perfectDaysCount,
            habitsDone: totalDone,
            dailyAverage: avg
        )
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
