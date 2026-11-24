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
                // Completion circle
                CompletionCircle(
                    isCompleted: isCompleted,
                    isQuit: habit.type == .quit
                )

                // Title and badge
                HStack(spacing: 6) {
                    Text(habit.title)
                        .font(.hostGrotesk(.regular, size: 16))
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)

                    if habit.type == .quit {
                        InverseBadge(text: "QUIT")
                    }
                }

                Spacer()

                // Streak
                if streakCount > 0 {
                    Text("\(streakCount)d")
                        .font(.hostGrotesk(.medium, size: 14))
                        .monospacedDigit()
                        .foregroundStyle(Color.mutedText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact, trigger: isCompleted)
        .insetCard()
        .background(Color.pageGround)
        .swipeActions(edge: .leading) {
            Button {
                onToggle()
            } label: {
                Image(systemName: isCompleted ? "xmark" : "checkmark")
            }
            .tint(.cobaltBlue)
        }
        .swipeActions(edge: .trailing) {
            if habit.type == .quit, isCompleted || !(log?.isSlip ?? false) {
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
