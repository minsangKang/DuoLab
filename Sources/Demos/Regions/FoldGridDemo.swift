import SwiftUI

struct FoldGridDemo: View {
    @State private var fold = FoldProbe()
    @State private var hingeGutter: CGFloat = 24

    private let items = Array(0..<36)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("접힐 수 있는 기기면(includeInactive) 열 수를 짝수로 유지하고, 세로 힌지 주변 간격만 넓혀 각 항목이 한 영역 안에 머물게 합니다. 바깥 여백은 그대로입니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Card(title: "상태") {
                    InfoRow("canFold", "\(fold.canFold)")
                    InfoRow("fold 축", fold.verticalFold != nil ? "세로 (좌우 분할)" : (fold.canFold ? "가로 또는 범위 밖" : "-"))
                    InfoRow("열 수", "\(columns(for: fold.width))")
                    Stepper("힌지 간격 \(Int(hingeGutter))pt", value: $hingeGutter, in: 8...64, step: 8)
                }
                grid
            }
            .padding()
        }
    }

    @ViewBuilder
    private var grid: some View {
        let count = columns(for: fold.width)
        Group {
            if let foldFrame = fold.verticalFold, count >= 2 {
                let half = count / 2
                let leftWidth = max(foldFrame.minX - hingeGutter / 2, 0)
                HStack(alignment: .top, spacing: 0) {
                    tileGrid(items.filter { $0 % count < half }, columns: half)
                        .frame(width: leftWidth)
                    Color.red.opacity(0.15)
                        .frame(width: foldFrame.width + hingeGutter)
                        .frame(maxHeight: .infinity)
                    tileGrid(items.filter { $0 % count >= half }, columns: count - half)
                }
            } else {
                tileGrid(items, columns: count)
            }
        }
        .onGeometryChange(for: FoldProbe.self) { proxy in
            let regions = proxy.reservedRegions(kind: .division, options: .includeInactive)
            let vertical = regions.first { $0.frame.height >= $0.frame.width && $0.frame.minX > 0 && $0.frame.maxX < proxy.size.width }
            return FoldProbe(width: proxy.size.width, canFold: !regions.isEmpty, verticalFold: vertical?.frame)
        } action: { fold = $0 }
    }

    private func tileGrid(_ data: [Int], columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: max(columns, 1)), spacing: 8) {
            ForEach(data, id: \.self) { i in
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hue: Double(i % 12) / 12, saturation: 0.45, brightness: 0.92))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(Text("\(i + 1)").font(.headline))
            }
        }
    }

    /// 밀도는 연속적인 폭이 결정하고, 접힐 수 있으면 짝수로 맞춘다.
    private func columns(for width: CGFloat) -> Int {
        let byWidth = max(Int(width / 120), 1)
        guard fold.canFold else { return byWidth }
        return max(byWidth - byWidth % 2, 2)
    }
}

private struct FoldProbe: Equatable {
    var width: CGFloat = 0
    var canFold = false
    var verticalFold: CGRect?
}
