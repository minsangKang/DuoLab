import SwiftUI

struct AdaptivePatternsDemo: View {
    @Environment(\.layoutContext) private var layout
    @State private var width: CGFloat = 0

    var body: some View {
        DemoPage(intro: "분기 코드를 잘 짜는 것보다 분기가 필요 없게 만드는 쪽이 낫습니다. 아래 패턴은 시스템이나 연속적인 폭이 알아서 정합니다.") {
            Card(title: "브레이크포인트 vs 쉐이프") {
                let byWidth = width > 700
                let byShape = !layout.shape.prefersSingleColumn
                InfoRow("이 화면 폭", width.pt)
                InfoRow("width > 700 → 2컬럼", byWidth ? "2컬럼" : "1컬럼")
                InfoRow("shape → 2컬럼", byShape ? "2컬럼" : "1컬럼")
                if byWidth != byShape {
                    Label("두 방식의 결과가 다릅니다. Duo 외부 가로처럼 넓지만 compact인 곳에서 브레이크포인트가 깨집니다.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("지금은 결과가 같습니다. Duo 외부 가로, Plus·Max 가로로 바꿔 보세요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Card(title: "AnyLayout — 상태를 유지한 채 축만 교체") {
                let axisLayout = layout.isWide ? AnyLayout(HStackLayout(spacing: 8)) : AnyLayout(VStackLayout(spacing: 8))
                axisLayout {
                    CounterTile(title: "A")
                    CounterTile(title: "B")
                }
                Text("카운터를 올린 뒤 회전해도 값이 유지됩니다. (기준: isWide = \(layout.isWide ? "Y" : "N"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Card(title: "ViewThatFits — 들어가는 레이아웃을 시스템이 고름") {
                ViewThatFits(in: .horizontal) {
                    HStack { actionButtons }
                    VStack(alignment: .leading) { actionButtons }
                }
            }

            Card(title: "LazyVGrid(.adaptive(minimum: 140)) — 컬럼 수는 폭이 결정") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                    ForEach(0..<12, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hue: Double(i) / 12, saturation: 0.5, brightness: 0.9))
                            .frame(height: 60)
                            .overlay(Text("\(i + 1)").font(.headline))
                    }
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button("새로 만들기", systemImage: "plus") {}
        Button("가져오기", systemImage: "square.and.arrow.down") {}
        Button("공유하기", systemImage: "square.and.arrow.up") {}
        Button("설정", systemImage: "gear") {}
    }
}

private struct CounterTile: View {
    let title: String
    @State private var count = 0

    var body: some View {
        HStack {
            Text("\(title): \(count)").monospacedDigit()
            Spacer()
            Button("+1") { count += 1 }.buttonStyle(.bordered)
        }
        .padding()
        .background(.background, in: .rect(cornerRadius: 12))
    }
}

#Preview("compactShort") { ShapePreview(shape: .compactShort) { AdaptivePatternsDemo() } }
#Preview("regularWide") { ShapePreview(shape: .regularWide) { AdaptivePatternsDemo() } }
