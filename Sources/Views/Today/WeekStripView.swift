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
                    VStack(spacing: 5) {
                        Text(dayLabels[weekdayIndex])
                            .font(.hostGrotesk(isSelected ? .semibold : .medium, size: 12))
                            .foregroundStyle(isSelected ? Color.cobaltBlue : Color.mutedText)
                            .letterpress(isLight: false)

                        ZStack {
                            if isSelected {
                                // Raised convex cobalt enamel button
                                Circle()
                                    .fill(LinearGradient.cobaltEnamel)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        VStack {
                                            LinearGradient(colors: [Color.white.opacity(0.60), Color.clear], startPoint: .top, endPoint: .bottom)
                                                .frame(height: 10)
                                            Spacer()
                                        }
                                        .clipShape(Circle())
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                LinearGradient(colors: [Color.white.opacity(0.70), Color.black.opacity(0.30)], startPoint: .top, endPoint: .bottom),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(color: Color.cobaltBlue.opacity(0.40), radius: 4, x: 0, y: 2)

                                Text("\(dayNumber)")
                                    .font(.hostGrotesk(.semibold, size: 13))
                                    .monospacedDigit()
                                    .foregroundStyle(Color.cobaltLabel)
                                    .letterpress(isLight: true)
                            } else {
                                // Tactile circular recessed dimple
                                Circle()
                                    .fill(LinearGradient.wellGradient)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        VStack(spacing: 0) {
                                            LinearGradient(colors: [Color.black.opacity(0.20), Color.clear], startPoint: .top, endPoint: .bottom)
                                                .frame(height: 3)
                                            Spacer()
                                            Color.white.opacity(0.80)
                                                .frame(height: 1)
                                        }
                                        .clipShape(Circle())
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                isToday
                                                    ? LinearGradient(colors: [Color.cobaltBlue.opacity(0.6), Color.cobaltBlue.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                                                    : LinearGradient.reverseBevel,
                                                lineWidth: 1
                                            )
                                    )

                                Text("\(dayNumber)")
                                    .font(.hostGrotesk(.medium, size: 13))
                                    .monospacedDigit()
                                    .foregroundStyle(isToday ? Color.cobaltBlue : Color.primaryText)
                                    .letterpress(isLight: false)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(
                        Group {
                            if isSelected {
                                // Raised beveled vertical pill tab
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(LinearGradient.cardGradient)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .strokeBorder(LinearGradient.topLightBevel, lineWidth: 1.2)
                                    )
                                    .overlay(
                                        VStack {
                                            RoundedRectangle(cornerRadius: 20)
                                                .strokeBorder(Color.white.opacity(0.70), lineWidth: 1)
                                                .frame(height: 12)
                                                .mask(VStack { Rectangle().frame(height: 2); Spacer() })
                                            Spacer()
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                    )
                                    .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1.5)
                                    .shadow(color: Color(red: 0x36 / 255.0, green: 0x30 / 255.0, blue: 0x24 / 255.0).opacity(0.12), radius: 7, x: 0, y: 3.5)
                            }
                        }
                    )
                }
                .buttonStyle(SkeuomorphicButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
