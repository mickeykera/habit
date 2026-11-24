import SwiftUI

struct CompletionCircle: View {
    let isCompleted: Bool
    var isQuit: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if isCompleted {
                Circle()
                    .fill(Color.cobaltBlue)
                    .frame(width: 28, height: 28)

                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.cobaltLabel)
            } else {
                Circle()
                    .strokeBorder(Color.hairline, lineWidth: 1.5)
                    .frame(width: 28, height: 28)
            }
        }
        .animation(reduceMotion ? .none : .snappySpring, value: isCompleted)
        .accessibilityLabel(isCompleted ? "Completed" : "Not completed")
    }
}

#Preview("Incomplete") {
    CompletionCircle(isCompleted: false)
        .padding()
}

#Preview("Completed") {
    CompletionCircle(isCompleted: true)
        .padding()
}
