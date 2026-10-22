import SwiftUI

struct VerticalBarDemo: View {
    var isFullScreen = false

    var body: some View {
        BarDemoScaffold(
            intro: "같은 컴포넌트가 다른 축으로 배치됩니다. 상단 항목은 세로 공간의 위로, 하단 항목은 아래로 갑니다. 직접 만든 UIToolbar는 참여하지 않습니다.",
            isFullScreen: isFullScreen
        ) {
            Card(title: "배치된 항목") {
                Text("상단: 검색 · 공유 (topBarTrailing)\n하단: 보관 · 플래그 · 이동 · 작성 (bottomBar)")
                    .font(.footnote)
                    .monospaced()
            }
        } fullScreen: {
            AnyView(NavigationStack {
                VerticalBarDemo(isFullScreen: true)
                    .navigationTitle("세로 바 기본")
                    .toolbar { CloseToolbarItem() }
            })
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("검색", systemImage: "magnifyingglass") {}
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("공유", systemImage: "square.and.arrow.up") {}
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button("보관", systemImage: "archivebox") {}
                Button("플래그", systemImage: "flag") {}
                Button("이동", systemImage: "folder") {}
            }
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button("작성", systemImage: "square.and.pencil") {}
            }
        }
    }
}
