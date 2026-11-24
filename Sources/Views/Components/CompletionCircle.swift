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
                // Convex Glossy Cobalt Enamel Push-Button
                Circle()
                    .fill(LinearGradient.cobaltEnamel)
                    .frame(width: 28, height: 28)
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
                                LinearGradient(
                                    colors: [Color.white.opacity(0.70), Color.black.opacity(0.30)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1.2)
                    .shadow(color: Color.cobaltBlue.opacity(0.45), radius: 6, x: 0, y: 2)

                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.cobaltLabel)
                    .letterpress(isLight: true)
            } else {
                // Deeply Recessed Concave Dimple / Well
                Circle()
                    .fill(LinearGradient.wellGradient)
                    .frame(width: 28, height: 28)
                    .overlay(
                        // Top dark inner shadow + bottom white highlight lip
                        VStack(spacing: 0) {
                            LinearGradient(colors: [Color.black.opacity(0.25), Color.clear], startPoint: .top, endPoint: .bottom)
                                .frame(height: 3)
                            Spacer()
                            Color.white.opacity(0.85)
                                .frame(height: 1)
                        }
                        .clipShape(Circle())
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(LinearGradient.reverseBevel, lineWidth: 1)
                    )
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
