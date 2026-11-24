import SwiftUI

struct CompletionCircle: View {
    let isCompleted: Bool
    var isQuit: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fillColor: Color {
        if isQuit {
            // Green-ish cobalt for quit-clean
            return Color(red: 0x1E / 255.0, green: 0x60 / 255.0, blue: 0x8F / 255.0)
        }
        return .cobaltBlue
    }

    var body: some View {
        ZStack {
            if isCompleted {
                Circle()
                    .fill(fillColor)
                    .frame(width: 24, height: 24)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .strokeBorder(Color.hairline, lineWidth: 1)
                    .frame(width: 24, height: 24)
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

#Preview("Completed Build") {
    CompletionCircle(isCompleted: true)
        .padding()
}

#Preview("Completed Quit") {
    CompletionCircle(isCompleted: true, isQuit: true)
        .padding()
}
