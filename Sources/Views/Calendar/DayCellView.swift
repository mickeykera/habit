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
        let isPerfect = completionRate >= 0.999 && isCurrentMonth

        VStack(spacing: 2) {
            ZStack {
                // Circular stepped fill
                Circle()
                    .fill(backgroundFill)
                    .frame(width: 32, height: 32)

                // Selection or border ring
                if isSelected {
                    Circle()
                        .strokeBorder(Color.cobaltBlue, lineWidth: 2)
                        .frame(width: 32, height: 32)
                } else if isToday {
                    Circle()
                        .strokeBorder(Color.cobaltBlue.opacity(0.5), lineWidth: 1)
                        .frame(width: 32, height: 32)
                }

                Text("\(dayNumber)")
                    .font(.hostGrotesk(.medium, size: 13))
                    .monospacedDigit()
                    .foregroundStyle(isPerfect ? Color.cobaltLabel : Color.primaryText)
                    .opacity(isCurrentMonth ? 1.0 : 0.25)
            }

            // Small dot under today's date
            if isToday {
                Circle()
                    .fill(Color.cobaltBlue)
                    .frame(width: 3, height: 3)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 3, height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .contentShape(Rectangle())
    }

    private var backgroundFill: Color {
        guard isCurrentMonth && completionRate > 0 else { return .clear }
        switch completionRate {
        case 0.001..<0.5:
            return Color.cobaltBlue.opacity(0.18)
        case 0.5..<0.999:
            return Color.cobaltBlue.opacity(0.45)
        default:
            return Color.cobaltBlue
        }
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
    .background(Color.pageGround)
}
