import SwiftUI

struct ReportCellView: View {
    enum CellState: Sendable {
        case completed
        case missed
        case notScheduled
    }

    let state: CellState

    var body: some View {
        ZStack {
            switch state {
            case .completed:
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient.cobaltEnamel)
                    .frame(width: 18, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.65), Color.black.opacity(0.25)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.75
                            )
                    )
                    .shadow(color: Color.cobaltBlue.opacity(0.35), radius: 2, x: 0, y: 1)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.cobaltLabel)
                    )

            case .missed:
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient.wellGradient)
                    .frame(width: 18, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(LinearGradient.reverseBevel, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1)

            case .notScheduled:
                Text("—")
                    .font(.hostGrotesk(.medium, size: 12))
                    .foregroundStyle(Color.mutedText.opacity(0.6))
                    .letterpress(isLight: false)
            }
        }
        .frame(width: 28, height: 26)
        .contentShape(Rectangle())
    }
}

#Preview {
    HStack(spacing: 8) {
        ReportCellView(state: .completed)
        ReportCellView(state: .missed)
        ReportCellView(state: .notScheduled)
    }
    .padding()
    .background(Color.pageGround)
}
