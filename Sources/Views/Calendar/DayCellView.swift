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

        Text("\(dayNumber)")
            .font(hostGrotesk(.medium, size: 14))
            .monospacedDigit()
            .foregroundStyle(isCurrentMonth && completionRate >= 1.0 ? Color.cobaltLabel : Color.primaryText)
            .opacity(isCurrentMonth ? 1.0 : 0.3)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(backgroundView)
            .overlay(overlayRings)
            .contentShape(Rectangle())
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        if completionRate > 0 && isCurrentMonth {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.cobaltBlue.opacity(intensityOpacity))
        } else {
            Color.clear
        }
    }

    private var intensityOpacity: Double {
        switch completionRate {
        case 0:
            return 0
        case 0.001...0.50:
            return 0.15
        case 0.501...0.99:
            return 0.35
        default:
            return 1.0
        }
    }

    // MARK: - Overlay Rings

    @ViewBuilder
    private var overlayRings: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.cobaltBlue, lineWidth: 2)
            }

            if isToday && !isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.hairline, lineWidth: 1)
            }
        }
    }
}

#Preview {
    HStack(spacing: 4) {
        DayCellView(
            date: .now,
            completionRate: 0,
            isToday: true,
            isSelected: false,
            isCurrentMonth: true
        )
        DayCellView(
            date: .now,
            completionRate: 0.4,
            isToday: false,
            isSelected: false,
            isCurrentMonth: true
        )
        DayCellView(
            date: .now,
            completionRate: 0.75,
            isToday: false,
            isSelected: true,
            isCurrentMonth: true
        )
        DayCellView(
            date: .now,
            completionRate: 1.0,
            isToday: false,
            isSelected: false,
            isCurrentMonth: true
        )
        DayCellView(
            date: .now,
            completionRate: 0.5,
            isToday: false,
            isSelected: false,
            isCurrentMonth: false
        )
    }
    .padding()
    .background(Color.pageGround)
}
