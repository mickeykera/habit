import SwiftUI

struct WeekStripView: View {
    @Binding var selectedDate: Date

    @State private var weekOffset: Int = 0

    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday start (Mo..Su)
        return cal
    }()

    private let dayLabels = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    private var currentWeekDates: [Date] {
        let today = calendar.startOfDay(for: Date.now)
        guard let baseWeekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return []
        }
        guard let shiftedWeekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: baseWeekInterval.start) else {
            return []
        }
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: shiftedWeekStart)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(currentWeekDates, id: \.self) { date in
                let weekdayIndex = (calendar.component(.weekday, from: date) + 5) % 7 // Monday = 0 .. Sunday = 6
                let dayNumber = calendar.component(.day, from: date)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)

                Button {
                    withAnimation(.snappySpring) {
                        selectedDate = calendar.startOfDay(for: date)
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(dayLabels[weekdayIndex])
                            .font(.hostGrotesk(isSelected ? .semibold : .medium, size: 12))
                            .foregroundStyle(isSelected ? Color.cobaltBlue : Color.mutedText)

                        ZStack {
                            if isSelected {
                                Circle()
                                    .strokeBorder(Color.cobaltBlue, lineWidth: 2)
                                    .background(Circle().fill(Color.cobaltBlue.opacity(0.12)))
                                    .frame(width: 32, height: 32)

                                Text("\(dayNumber)")
                                    .font(.hostGrotesk(.semibold, size: 13))
                                    .monospacedDigit()
                                    .foregroundStyle(Color.cobaltBlue)
                            } else {
                                Circle()
                                    .fill(isToday ? Color.cardSurface : Color.clear)
                                    .frame(width: 32, height: 32)

                                Text("\(dayNumber)")
                                    .font(.hostGrotesk(.medium, size: 13))
                                    .monospacedDigit()
                                    .foregroundStyle(isToday ? Color.cobaltBlue : Color.primaryText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                    .background(
                        isSelected ? Color.cardSurface : Color.clear
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(AppPillButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.pageGround)
        .gesture(
            DragGesture(minimumDistance: 40, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width < -40 {
                        withAnimation(.snappySpring) {
                            weekOffset += 1
                            if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                                selectedDate = calendar.startOfDay(for: newDate)
                            }
                        }
                    } else if value.translation.width > 40 {
                        withAnimation(.snappySpring) {
                            weekOffset -= 1
                            if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                                selectedDate = calendar.startOfDay(for: newDate)
                            }
                        }
                    }
                }
        )
        .onChange(of: selectedDate) { _, newValue in
            let today = calendar.startOfDay(for: Date.now)
            let weekDiff = calendar.dateComponents([.weekOfYear], from: today, to: newValue).weekOfYear ?? 0
            if weekDiff != weekOffset {
                weekOffset = weekDiff
            }
        }
    }
}

#Preview {
    @Previewable @State var date = Date.now
    WeekStripView(selectedDate: $date)
        .background(Color.pageGround)
}
