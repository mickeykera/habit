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
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.cobaltBlue)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.cobaltLabel)
                    )

            case .missed:
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.hairline, lineWidth: 1.5)
                    .frame(width: 14, height: 14)

            case .notScheduled:
                Text("—")
                    .font(hostGrotesk(.medium, size: 12))
                    .foregroundStyle(Color.mutedText)
            }
        }
        .frame(height: 24)
        .contentShape(Rectangle())
    }
}

#Preview {
    HStack(spacing: 12) {
        ReportCellView(state: .completed)
        ReportCellView(state: .missed)
        ReportCellView(state: .notScheduled)
    }
    .padding()
    .background(Color.pageGround)
}
