import SwiftUI

struct WeekStripView: View {
    @Binding var selectedDate: Date

    @State private var weekOffset: Int = 0

    private let calendar = Calendar.current
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var currentWeekDates: [Date] {
        let today = calendar.startOfDay(for: Date.now)
        guard let baseWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        guard let shiftedWeekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: baseWeekStart) else {
            return []
        }
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: shiftedWeekStart)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(currentWeekDates, id: \.self) { date in
                let weekday = calendar.component(.weekday, from: date) - 1 // 0-based
                let dayNumber = calendar.component(.day, from: date)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)

                Button {
                    selectedDate = calendar.startOfDay(for: date)
                } label: {
                    VStack(spacing: 4) {
                        Text(dayLabels[weekday])
                            .font(.hostGrotesk(.medium, size: 13))
                            .foregroundStyle(isSelected ? .white : .mutedText)

                        Text("\(dayNumber)")
                            .font(.hostGrotesk(.medium, size: 13))
                            .monospacedDigit()
                            .foregroundStyle(isSelected ? .white : .primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if isSelected {
                            Circle()
                                .fill(Color.cobaltBlue)
                                .frame(width: 44, height: 44)
                        } else if isToday {
                            Circle()
                                .strokeBorder(Color.cobaltBlue.opacity(0.3), lineWidth: 1)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width < -50 {
                        withAnimation(.snappySpring) {
                            weekOffset += 1
                            // Select the same weekday in the new week
                            if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                                selectedDate = calendar.startOfDay(for: newDate)
                            }
                        }
                    } else if value.translation.width > 50 {
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
            // Keep weekOffset in sync when selectedDate changes externally
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
