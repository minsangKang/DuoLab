import SwiftUI

struct ShapeMatrixDemo: View {
    @Environment(\.layoutContext) private var root
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @State private var localSize: CGSize = .zero

    private var localShape: LayoutShape {
        LayoutShape(h: h, v: v, isWide: localSize.width > localSize.height)
    }

    var body: some View {
        DemoPage(intro: "쉐이프는 (가로 사이즈 클래스, 세로 사이즈 클래스, 가로가 더 긴가) 세 값으로만 정합니다. 구조는 쉐이프가, 밀도는 연속적인 폭이 결정합니다.") {
            Card(title: "씬 전체 (루트에서 측정)") {
                InfoRow("shape", root.shape.rawValue, highlight: true)
                InfoRow("presentation", root.shape.presentation.rawValue)
                InfoRow("size", root.size.short)
                InfoRow("isWide", root.isWide ? "Y" : "N")
                InfoRow("prefersSingleColumn", root.shape.prefersSingleColumn ? "Y" : "N")
            }

            Card(title: "이 화면 (detail 열 자신)") {
                InfoRow("sizeClass", "H \(h.shortLabel) · V \(v.shortLabel)")
                InfoRow("shape", localShape.rawValue, highlight: localShape != root.shape)
                InfoRow("size", localSize.short)
                if localShape != root.shape {
                    Text("루트 컨텍스트와 다릅니다. 컬럼 안 재사용 컴포넌트는 자기 사이즈 클래스를 써야 하는 이유입니다.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Card(title: "5개 쉐이프") {
                ForEach(LayoutShape.allCases, id: \.self) { shape in
                    ShapeRow(shape: shape, isCurrent: shape == root.shape)
                }
            }

            Card(title: "3개 모드 (설계용)") {
                HStack(spacing: 8) {
                    ForEach([LayoutShape.Presentation.stack, .split, .expanded], id: \.self) { mode in
                        PresentationGlyph(mode: mode, isCurrent: mode == root.shape.presentation)
                    }
                }
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { localSize = $0 }
    }
}

private struct ShapeRow: View {
    let shape: LayoutShape
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCurrent ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(isCurrent ? Color.accentColor : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(shape.rawValue).font(.subheadline.weight(.semibold)).monospaced()
                    Text(shape.sizeClassLabel).font(.caption).foregroundStyle(.secondary)
                }
                Text(shape.examples).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCurrent ? Color.accentColor.opacity(0.12) : .clear, in: .rect(cornerRadius: 10))
    }
}

private struct PresentationGlyph: View {
    let mode: LayoutShape.Presentation
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 3) {
                switch mode {
                case .stack:
                    RoundedRectangle(cornerRadius: 3).fill(.tint)
                case .split:
                    RoundedRectangle(cornerRadius: 3).fill(.tint.opacity(0.5)).frame(maxWidth: 24)
                    RoundedRectangle(cornerRadius: 3).fill(.tint)
                case .expanded:
                    RoundedRectangle(cornerRadius: 3).fill(.tint.opacity(0.3)).frame(maxWidth: 14)
                    RoundedRectangle(cornerRadius: 3).fill(.tint.opacity(0.5)).frame(maxWidth: 24)
                    RoundedRectangle(cornerRadius: 3).fill(.tint)
                }
            }
            .frame(height: 44)
            Text(mode.rawValue).font(.caption.weight(isCurrent ? .bold : .regular))
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(isCurrent ? Color.accentColor.opacity(0.12) : .clear, in: .rect(cornerRadius: 10))
        .opacity(isCurrent ? 1 : 0.5)
    }
}

#Preview("compactTall") { ShapePreview(shape: .compactTall) { ShapeMatrixDemo() } }
#Preview("regularWide") { ShapePreview(shape: .regularWide) { ShapeMatrixDemo() } }
