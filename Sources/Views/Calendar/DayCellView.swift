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
                    // Glossy cobalt enamel gem
                    Circle()
                        .fill(isPerfect ? LinearGradient.cobaltEnamel : LinearGradient(colors: [Color.cobaltBlue.opacity(0.6), Color.cobaltDeep.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 30, height: 30)
                        .overlay(
                            // Top specular highlight crescent
                            VStack {
                                LinearGradient(colors: [Color.white.opacity(0.65), Color.clear], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 10)
                                Spacer()
                            }
                            .clipShape(Circle())
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(colors: [Color.white.opacity(0.7), Color.black.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.cobaltBlue.opacity(0.35), radius: 3, x: 0, y: 1.5)

                    Text("\(dayNumber)")
                        .font(.hostGrotesk(.semibold, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.cobaltLabel)
                        .letterpress(isLight: true)
                } else {
                    // Tactile recessed well for uncompleted days
                    Circle()
                        .fill(LinearGradient.wellGradient)
                        .frame(width: 30, height: 30)
                        .overlay(
                            VStack(spacing: 0) {
                                LinearGradient(colors: [Color.black.opacity(0.20), Color.clear], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 2.5)
                                Spacer()
                                Color.white.opacity(0.80)
                                    .frame(height: 1)
                            }
                            .clipShape(Circle())
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(LinearGradient.reverseBevel, lineWidth: 0.8)
                        )

                    Text("\(dayNumber)")
                        .font(.hostGrotesk(.medium, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(Color.primaryText)
                        .letterpress(isLight: false)
                }

                // Selection bezel ring
                if isSelected && isCurrentMonth {
                    Circle()
                        .strokeBorder(
                            LinearGradient(colors: [Color.cobaltBlue, Color.cobaltDeep], startPoint: .top, endPoint: .bottom),
                            lineWidth: 2
                        )
                        .frame(width: 33, height: 33)
                        .shadow(color: Color.cobaltBlue.opacity(0.4), radius: 3, x: 0, y: 1)
                }
            }

            // Glowing cobalt dot under today's date
            if isToday {
                Circle()
                    .fill(Color.cobaltBlue)
                    .frame(width: 3.5, height: 3.5)
                    .shadow(color: Color.cobaltBlue.opacity(0.8), radius: 2.5, x: 0, y: 0)
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
    .background(Color.pageGround)
}
