import SwiftUI

struct DayCellView: View {
    let date: Date
    let completionRate: Double
    let isToday: Bool
    let isSelected: Bool
    let isCurrentMonth: Bool

    private let calendar = Calendar.current

    var body: some View {
        let dayNumber = calendar.component(.day, from: date)
        let isDone = completionRate >= 0.001 && isCurrentMonth
        let isPerfect = completionRate >= 0.999 && isCurrentMonth

        VStack(spacing: 2) {
            ZStack {
                if !isCurrentMonth {
                    Text("\(dayNumber)")
                        .font(.hostGrotesk(.medium, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.mutedText.opacity(0.35))
                } else if isDone {
                    // Stepped royal blue completion fill
                    Circle()
                        .fill(isPerfect ? Color.cobaltBlue : Color.cobaltBlue.opacity(0.20 + completionRate * 0.6))
                        .frame(width: 30, height: 30)

                    Text("\(dayNumber)")
                        .font(.hostGrotesk(.semibold, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(isPerfect || completionRate >= 0.6 ? Color.cobaltLabel : Color.cobaltBlue)
                } else {
                    Circle()
                        .fill(Color.pageGround)
                        .frame(width: 30, height: 30)

                    Text("\(dayNumber)")
                        .font(.hostGrotesk(.medium, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.primaryText)
                }

                // Selection ring
                if isSelected && isCurrentMonth {
                    Circle()
                        .strokeBorder(Color.cobaltBlue, lineWidth: 2)
                        .frame(width: 33, height: 33)
                }
            }

            // Cobalt dot under today's date
            if isToday {
                Circle()
                    .fill(Color.cobaltBlue)
                    .frame(width: 3.5, height: 3.5)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 3.5, height: 3.5)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .contentShape(Rectangle())
    }
}

#Preview {
    HStack(spacing: 6) {
        DayCellView(date: .now, completionRate: 0, isToday: false, isSelected: false, isCurrentMonth: true)
        DayCellView(date: .now, completionRate: 0.3, isToday: false, isSelected: false, isCurrentMonth: true)
        DayCellView(date: .now, completionRate: 0.7, isToday: false, isSelected: false, isCurrentMonth: true)
        DayCellView(date: .now, completionRate: 1.0, isToday: true, isSelected: true, isCurrentMonth: true)
    }
    .padding()
    .background(Color.cardSurface)
}
