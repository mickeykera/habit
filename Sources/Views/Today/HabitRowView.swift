import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let date: Date
    let log: HabitLog?
    let onToggle: () -> Void
    var onSlip: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCompleted: Bool {
        log?.isCompleted ?? false
    }

    private var isSlip: Bool {
        log?.isSlip ?? false
    }

    private var streakCount: Int {
        StreakCalculator.currentStreak(
            for: habit,
            asOf: date,
            logs: habit.logs
        )
    }

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: 12) {
                // Left: Tactile habit icon medallion
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isCompleted ? LinearGradient(colors: [Color.cobaltBlue.opacity(0.18), Color.cobaltBlue.opacity(0.08)], startPoint: .top, endPoint: .bottom) : LinearGradient.wellGradient)
                        .frame(width: 42, height: 42)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(isCompleted ? LinearGradient(colors: [Color.cobaltBlue.opacity(0.5), Color.cobaltBlue.opacity(0.2)], startPoint: .top, endPoint: .bottom) : LinearGradient.reverseBevel, lineWidth: 1)
                        )
                        .overlay(
                            // Top dark lip for recessed feel
                            VStack {
                                Color.black.opacity(isCompleted ? 0.05 : 0.14).frame(height: 2)
                                Spacer()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        )

                    Image(systemName: habit.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isCompleted ? Color.cobaltBlue : Color.secondaryText)
                        .shadow(color: isCompleted ? Color.cobaltBlue.opacity(0.4) : Color.white.opacity(0.8), radius: isCompleted ? 3 : 0.5, x: 0, y: isCompleted ? 1 : 0.75)
                }

                // Center: Title + Progress/Target pill
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.hostGrotesk(.medium, size: 16))
                        .foregroundStyle(Color.primaryText)
                        .letterpress(isLight: false)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if habit.type == .quit {
                            InverseBadge(text: "QUIT")

                            if isSlip {
                                Text("Slip logged")
                                    .font(.hostGrotesk(.medium, size: 11))
                                    .foregroundStyle(Color.red)
                                    .letterpress(isLight: false)
                            } else if isCompleted {
                                Text("Stayed Clean")
                                    .font(.hostGrotesk(.medium, size: 11))
                                    .foregroundStyle(Color.cobaltBlue)
                                    .letterpress(isLight: false)
                            }
                        } else {
                            // Tactile Recessed Progress Pill
                            HStack(spacing: 3) {
                                Text(isCompleted ? "1/1" : "0/1")
                                    .font(.hostGrotesk(.medium, size: 11))
                                    .monospacedDigit()
                                    .foregroundStyle(isCompleted ? Color.cobaltBlue : Color.mutedText)
                                    .letterpress(isLight: false)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(
                                Capsule()
                                    .fill(isCompleted ? LinearGradient(colors: [Color.cobaltBlue.opacity(0.14), Color.cobaltBlue.opacity(0.06)], startPoint: .top, endPoint: .bottom) : LinearGradient.wellGradient)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(isCompleted ? LinearGradient(colors: [Color.cobaltBlue.opacity(0.4), Color.cobaltBlue.opacity(0.2)], startPoint: .top, endPoint: .bottom) : LinearGradient.reverseBevel, lineWidth: 1)
                            )
                        }
                    }
                }

                Spacer()

                // Right: Streak label above physical push-button
                VStack(spacing: 3) {
                    if streakCount > 0 {
                        // Tactile streak counter badge
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(isCompleted ? Color.cobaltBlue : Color.mutedText)
                            Text("\(streakCount)d")
                                .font(.hostGrotesk(.semibold, size: 11))
                                .monospacedDigit()
                                .foregroundStyle(isCompleted ? Color.cobaltBlue : Color.mutedText)
                                .letterpress(isLight: false)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .fill(isCompleted ? Color.cobaltBlue.opacity(0.10) : Color.black.opacity(0.04))
                        )
                        .clipShape(Capsule())
                    } else {
                        Text(" ")
                            .font(.hostGrotesk(.semibold, size: 11))
                    }

                    CompletionCircle(
                        isCompleted: isCompleted,
                        isQuit: habit.type == .quit
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            // Raised physical card tile
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isCompleted
                            ? LinearGradient(colors: [Color.cardTop, Color.cobaltBlue.opacity(0.06)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient.cardGradient
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isCompleted
                            ? LinearGradient(colors: [Color.white.opacity(0.7), Color.cobaltBlue.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient.topLightBevel,
                        lineWidth: 1
                    )
            )
            .overlay(
                // Crisp top specular highlight rim
                VStack {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.65), lineWidth: 1)
                        .frame(height: 14)
                        .mask(VStack { Rectangle().frame(height: 2); Spacer() })
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .allowsHitTesting(false)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            .shadow(color: Color(red: 0x36 / 255.0, green: 0x30 / 255.0, blue: 0x24 / 255.0).opacity(0.08), radius: 6, x: 0, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(SkeuomorphicButtonStyle())
        .sensoryFeedback(.impact, trigger: isCompleted)
        .swipeActions(edge: .leading) {
            Button {
                onToggle()
            } label: {
                Image(systemName: isCompleted ? "xmark" : "checkmark")
            }
            .tint(Color.cobaltBlue)
        }
        .swipeActions(edge: .trailing) {
            if habit.type == .quit, isCompleted || !isSlip {
                if let onSlip {
                    Button {
                        onSlip()
                    } label: {
                        Text("Slip")
                    }
                    .tint(.red)
                }
            }
        }
        .animation(reduceMotion ? .none : .snappySpring, value: isCompleted)
    }
}
