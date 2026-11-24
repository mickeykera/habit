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
                RoundedRectangle(cornerRadius: 3.5)
                    .fill(Color.cobaltBlue)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.cobaltLabel)
                    )

            case .missed:
                RoundedRectangle(cornerRadius: 3.5)
                    .stroke(Color.hairline, lineWidth: 1.5)
                    .background(Color.cardSurface)
                    .frame(width: 16, height: 16)

            case .notScheduled:
                Text("—")
                    .font(.hostGrotesk(.medium, size: 12))
                    .foregroundStyle(Color.mutedText)
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
