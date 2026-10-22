import SwiftUI

/// 바 데모 공통 — 지금 세로 바가 가능한 상황인지와 쉐이프를 보여준다.
struct BarStatusCard: View {
    @Environment(\.toolbarVerticalEdge) private var edge
    @Environment(\.layoutContext) private var layout

    var body: some View {
        Card(title: "현재 상태") {
            InfoRow("toolbarVerticalEdge", edge.label, highlight: edge != nil)
            InfoRow("shape", layout.shape.rawValue)
            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var hint: String {
        edge == nil
            ? "가로 바 상황입니다. Duo 외부 화면이나 내부 가로에서는 세로 바로 바뀝니다."
            : "항목이 세로 축에 놓일 수 있는 상황입니다. 바는 하드웨어 기준으로 \(edge == .trailing ? "오른쪽" : "왼쪽")에 붙습니다."
    }
}

/// detail 열 안의 바와, 디스플레이 가장자리에 붙은 전체 화면 바를 비교하기 위한 래퍼.
struct BarDemoScaffold<Content: View>: View {
    let intro: String
    let isFullScreen: Bool
    @ViewBuilder var content: Content
    var fullScreen: (() -> AnyView)?

    var body: some View {
        DemoPage(intro: intro) {
            BarStatusCard()
            content
            if !isFullScreen, let fullScreen {
                FullScreenLauncher { fullScreen() }
                Text("스플릿 뷰에서는 detail 열만 세로 바에 참여하고, 컨테이너가 디스플레이 가장자리에 붙어 있을 때만 세로로 이동합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
