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
                    .fill(Color.cobaltBlue)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.cobaltLabel)
                    )

            case .missed:
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.pageGround)
                    .frame(width: 18, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.hairline, lineWidth: 1)
                    )

            case .notScheduled:
                Text("—")
                    .font(.hostGrotesk(.medium, size: 12))
                    .foregroundStyle(Color.mutedText.opacity(0.6))
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
    .background(Color.cardSurface)
}
