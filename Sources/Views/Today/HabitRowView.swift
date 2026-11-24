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
                // Left: Habit icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCompleted ? Color.cobaltBlue.opacity(0.12) : Color.pageGround)
                        .frame(width: 40, height: 40)

                    Image(systemName: habit.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isCompleted ? Color.cobaltBlue : Color.secondaryText)
                }

                // Center: Title + Compact pill tag
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.hostGrotesk(.medium, size: 16))
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if habit.type == .quit {
                            InverseBadge(text: "QUIT")

                            if isSlip {
                                Text("Slip logged")
                                    .font(.hostGrotesk(.medium, size: 11))
                                    .foregroundStyle(Color.red)
                            } else if isCompleted {
                                Text("Stayed Clean")
                                    .font(.hostGrotesk(.medium, size: 11))
                                    .foregroundStyle(Color.cobaltBlue)
                            }
                        } else {
                            Text(isCompleted ? "1/1" : "0/1")
                                .font(.hostGrotesk(.medium, size: 11))
                                .monospacedDigit()
                                .foregroundStyle(isCompleted ? Color.cobaltBlue : Color.mutedText)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(isCompleted ? Color.cobaltBlue.opacity(0.12) : Color.pageGround)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                // Right: Tabular streak count + Completion button
                VStack(spacing: 3) {
                    if streakCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(isCompleted ? Color.cobaltBlue : Color.mutedText)
                            Text("\(streakCount)d")
                                .font(.hostGrotesk(.semibold, size: 11))
                                .monospacedDigit()
                                .foregroundStyle(isCompleted ? Color.cobaltBlue : Color.mutedText)
                        }
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
            .background(
                isCompleted ? Color.cobaltBlue.opacity(0.08) : Color.cardSurface
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(AppPillButtonStyle())
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
