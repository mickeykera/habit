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
            VStack(spacing: 16) {
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
        .paperBackground()
        .sheet(isPresented: $showAddHabitSheet) {
            AddHabitSheet()
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Left: Filter/Sort Circular Button
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
                        .overlay(Circle().stroke(Color.hairline, lineWidth: 1))

                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                }
            }

            Spacer()

            // Center: Overall ⌄ Dropdown
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
                        .font(.hostGrotesk(.medium, size: 15))
                        .foregroundStyle(Color.primaryText)
                        .letterpress(isLight: false)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(LinearGradient.cardGradient)
                )
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(SkeuomorphicButtonStyle())

            Spacer()

            // Right: + Button
            Button {
                showAddHabitSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient.cardGradient)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.cobaltBlue)
                }
            }
            .buttonStyle(SkeuomorphicButtonStyle())
        }
    }

    // MARK: - Habit Filter Strip: Tactile Physical Tokens
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
                            .font(.system(size: 12))
                        Text("All")
                            .font(.hostGrotesk(.medium, size: 13))
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .foregroundStyle(isAllSelected ? Color.cobaltLabel : Color.primaryText)
                    .letterpress(isLight: isAllSelected)
                    .background(
                        Capsule().fill(isAllSelected ? LinearGradient.cobaltEnamel : LinearGradient.cardGradient)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(isAllSelected ? LinearGradient(colors: [Color.white.opacity(0.65), Color.black.opacity(0.25)], startPoint: .top, endPoint: .bottom) : LinearGradient.topLightBevel, lineWidth: 1)
                    )
                    .shadow(color: isAllSelected ? Color.cobaltBlue.opacity(0.35) : Color.black.opacity(0.05), radius: isAllSelected ? 4 : 2, x: 0, y: isAllSelected ? 2 : 1)
                }
                .buttonStyle(SkeuomorphicButtonStyle())

                // Each active habit chip
                ForEach(habits) { habit in
                    let isSelected = selectedHabitId == habit.id
                    Button {
                        withAnimation(.snappySpring) { selectedHabitId = habit.id }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: habit.iconName)
                                .font(.system(size: 12))
                            Text(habit.title)
                                .font(.hostGrotesk(.medium, size: 13))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .foregroundStyle(isSelected ? Color.cobaltLabel : Color.primaryText)
                        .letterpress(isLight: isSelected)
                        .background(
                            Capsule().fill(isSelected ? LinearGradient.cobaltEnamel : LinearGradient.cardGradient)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(isSelected ? LinearGradient(colors: [Color.white.opacity(0.65), Color.black.opacity(0.25)], startPoint: .top, endPoint: .bottom) : LinearGradient.topLightBevel, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? Color.cobaltBlue.opacity(0.35) : Color.black.opacity(0.05), radius: isSelected ? 4 : 2, x: 0, y: isSelected ? 2 : 1)
                    }
                    .buttonStyle(SkeuomorphicButtonStyle())
                }
            }
            .padding(.vertical, 3)
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
                        .background(Circle().fill(LinearGradient.cardGradient))
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(SkeuomorphicButtonStyle())

                Spacer()

                Text(monthHeaderTitle)
                    .font(.hostGrotesk(.medium, size: 16))
                    .foregroundStyle(Color.primaryText)
                    .letterpress(isLight: false)

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(LinearGradient.cardGradient))
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(SkeuomorphicButtonStyle())
            }
            .padding(.horizontal, 4)

            // Weekday Header M T W T F S S
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.hostGrotesk(.medium, size: 12))
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)
                        .frame(maxWidth: .infinity)
                }
            }

            EngravedDivider()

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
        .padding(14)
        .skeuomorphicCard(cornerRadius: 16)
    }

    // MARK: - Stats Summary Card
    private var statsSummaryCard: some View {
        let stats = computeStats()

        return VStack(spacing: 16) {
            // Centered Circular Progress Ring (Physical Analog Gauge)
            VStack(spacing: 10) {
                ZStack {
                    // Recessed circular track groove
                    Circle()
                        .stroke(LinearGradient.wellGradient, lineWidth: 12)
                        .frame(width: 124, height: 124)
                        .overlay(
                            Circle()
                                .strokeBorder(LinearGradient.reverseBevel, lineWidth: 1)
                                .frame(width: 136, height: 136)
                        )

                    // Enamel liquid gauge arc
                    Circle()
                        .trim(from: 0, to: max(0.001, CGFloat(isShowingOverallRate ? stats.overallRate : stats.monthlyRate)))
                        .stroke(
                            LinearGradient.cobaltEnamel,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 124, height: 124)
                        .shadow(color: Color.cobaltBlue.opacity(0.35), radius: 3, x: 0, y: 1)
                        .animation(.snappySpring, value: isShowingOverallRate)

                    // Raised central ceramic face
                    Circle()
                        .fill(LinearGradient.cardGradient)
                        .frame(width: 96, height: 96)
                        .overlay(Circle().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)

                    // Percentage Text on ceramic face
                    VStack(spacing: 2) {
                        Text("\(Int(round((isShowingOverallRate ? stats.overallRate : stats.monthlyRate) * 100)))%")
                            .font(.hostGrotesk(.bold, size: 24))
                            .monospacedDigit()
                            .foregroundStyle(Color.cobaltBlue)
                            .letterpress(isLight: false)

                        Text(isShowingOverallRate ? "Overall Rate" : "Monthly Rate")
                            .font(.hostGrotesk(.medium, size: 10))
                            .foregroundStyle(Color.mutedText)
                            .letterpress(isLight: false)
                    }
                }

                // ⇄ Toggle Button
                Button {
                    withAnimation(.snappySpring) {
                        isShowingOverallRate.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                        Text(isShowingOverallRate ? "Show Monthly" : "Show Overall")
                            .font(.hostGrotesk(.medium, size: 11))
                    }
                    .foregroundStyle(Color.secondaryText)
                    .letterpress(isLight: false)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(LinearGradient.cardGradient))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(LinearGradient.topLightBevel, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(SkeuomorphicButtonStyle())
            }
            .padding(.top, 4)

            EngravedDivider()

            // 2×2 KPI Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                kpiCell(title: "Best Streaks", value: "\(stats.bestStreak) Day", icon: "flame.fill")
                kpiCell(title: "Perfect Days", value: "\(stats.perfectDays) Day", icon: "star.fill")
                kpiCell(title: "Habits Done", value: "\(stats.habitsDone)", icon: "checkmark.circle.fill")
                kpiCell(title: "Daily Average", value: String(format: "%.1f", stats.dailyAverage), icon: "chart.line.uptrend.xyaxis")
            }
        }
        .padding(16)
        .skeuomorphicCard(cornerRadius: 16)
    }

    private func kpiCell(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient.wellGradient)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().strokeBorder(LinearGradient.reverseBevel, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.cobaltBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.hostGrotesk(.regular, size: 11))
                    .foregroundStyle(Color.mutedText)
                    .letterpress(isLight: false)

                Text(value)
                    .font(.hostGrotesk(.semibold, size: 14))
                    .monospacedDigit()
                    .foregroundStyle(Color.primaryText)
                    .letterpress(isLight: false)
            }
            Spacer()
        }
        .padding(10)
        .skeuomorphicCard(cornerRadius: 12)
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
                    .letterpress(isLight: false)

                Spacer()

                Text("\(completedHabitsForSelectedDay.count) completed")
                    .font(.hostGrotesk(.medium, size: 13))
                    .foregroundStyle(Color.mutedText)
                    .letterpress(isLight: false)
            }

            EngravedDivider()

            if completedHabitsForSelectedDay.isEmpty {
                HStack {
                    Spacer()
                    Text("No habits data for this date")
                        .font(.hostGrotesk(.regular, size: 13))
                        .foregroundStyle(Color.mutedText)
                        .letterpress(isLight: false)
                        .padding(.vertical, 8)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(completedHabitsForSelectedDay) { habit in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.wellGradient)
                                    .frame(width: 26, height: 26)
                                    .overlay(Circle().strokeBorder(LinearGradient.reverseBevel, lineWidth: 1))

                                Image(systemName: habit.iconName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.cobaltBlue)
                            }

                            Text(habit.title)
                                .font(.hostGrotesk(.regular, size: 14))
                                .foregroundStyle(Color.primaryText)
                                .letterpress(isLight: false)

                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(LinearGradient.cobaltEnamel)
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().strokeBorder(LinearGradient(colors: [Color.white.opacity(0.6), Color.black.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 0.75))
                                    .shadow(color: Color.cobaltBlue.opacity(0.3), radius: 2, x: 0, y: 1)

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
        .padding(14)
        .skeuomorphicCard(cornerRadius: 14)
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

        // Best streak across filtered habits
        var maxStreak = 0
        for habit in filteredHabits {
            let streak = StreakCalculator.currentStreak(for: habit, asOf: Date.now, logs: habit.logs)
            if streak > maxStreak { maxStreak = streak }
        }

        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        let avg = Double(totalDone) / Double(max(1, daysInMonth))

        // Overall rate across all habit logs
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
