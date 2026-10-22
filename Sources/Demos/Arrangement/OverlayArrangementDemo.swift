import SwiftUI

struct OverlayArrangementDemo: View {
    enum Axes: String, CaseIterable, Identifiable {
        case all = "overlay"
        case horizontal = "overlay.axes(.horizontal)"
        case vertical = "overlay.axes(.vertical)"
        var id: String { rawValue }
    }

    @State private var axes: Axes = .all

    var body: some View {
        styled(
            ArrangementView {
                ReadingContent()
            } secondary: {
                MiniPlayer()
            }
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("축", selection: $axes) {
                        ForEach(Axes.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Label("overlay 축", systemImage: "rectangle.stack")
                }
            }
        }
    }

    @ViewBuilder
    private func styled(_ view: some View) -> some View {
        switch axes {
        case .all: view.arrangementViewStyle(.overlay)
        case .horizontal: view.arrangementViewStyle(.overlay.axes(.horizontal))
        case .vertical: view.arrangementViewStyle(.overlay.axes(.vertical))
        }
    }
}

/// 배경(읽는 콘텐츠). 가끔 가려져도 스크롤로 해결된다.
private struct ReadingContent: View {
    @Environment(\.overlayArrangementZIndex) private var zIndex

    var body: some View {
        List {
            Section {
                InfoRow("이 뷰의 overlayArrangementZIndex", "\(zIndex)")
                Text("기기를 접으면 overlay 배열은 두 뷰를 나란히 놓으려 합니다. 그때 미니 플레이어가 펼쳐집니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(1...40, id: \.self) { i in
                Text("본문 \(i) — 접근성 리더처럼 컨트롤이 전경, 읽는 콘텐츠가 배경인 관계는 overlay가 맞습니다.")
                    .font(.footnote)
            }
        }
    }
}

/// zIndex > 0 이면 위에 겹쳐 있다는 뜻이라 접고, 나란히(0)면 펼친다.
private struct MiniPlayer: View {
    @Environment(\.overlayArrangementZIndex) private var zIndex

    private var isCollapsed: Bool { zIndex > 0 }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.pink.gradient)
                    .frame(width: isCollapsed ? 44 : 120, height: isCollapsed ? 44 : 120)
                VStack(alignment: .leading) {
                    Text("재생 중인 곡").font(.headline)
                    Text("zIndex \(zIndex) · \(isCollapsed ? "collapsed" : "expanded")")
                        .font(.caption)
                        .monospaced()
                }
                Spacer()
                Image(systemName: "play.fill").font(.title2)
            }
            if !isCollapsed {
                ProgressView(value: 0.4)
                HStack(spacing: 32) {
                    Image(systemName: "backward.fill")
                    Image(systemName: "pause.fill").font(.title)
                    Image(systemName: "forward.fill")
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: isCollapsed ? 20 : 0))
        .padding(isCollapsed ? 12 : 0)
        .animation(.snappy, value: isCollapsed)
    }
}
