import SwiftUI

struct CompressionDemo: View {
    var body: some View {
        DemoPage(intro: "툴바와 탭 바가 하나의 세로 영역을 나눠 씁니다. 넘치면 탐색 중심 화면은 툴바를 먼저 접고(기본), 작업 중심 화면은 탭 바를 먼저 접습니다. 가로 모드 외부 화면에서 가장 잘 드러납니다.") {
            BarStatusCard()
            FullScreenLauncher(label: "TabView로 열기") {
                CompressionTabs()
            }
        }
    }
}

private struct CompressionTabs: View {
    @State private var prefersToolbar = false

    var body: some View {
        TabView {
            ForEach(["Recents", "Shared", "Browse", "Favorites"], id: \.self) { name in
                Tab(name, systemImage: icon(name)) {
                    NavigationStack {
                        List {
                            Section {
                                Toggle(".prefersToolbarItems (탭 바 먼저 접기)", isOn: $prefersToolbar)
                            } footer: {
                                Text(prefersToolbar ? "작업 중심: 툴바 항목을 끝까지 남깁니다." : "탐색 중심(automatic): 툴바가 먼저 접혀 목적지 접근을 유지합니다.")
                            }
                            BarStatusCard()
                                .listRowInsets(EdgeInsets())
                            ForEach(0..<20, id: \.self) { Text("\(name) 항목 \($0 + 1)") }
                        }
                        .navigationTitle(name)
                        .toolbar {
                            CloseToolbarItem()
                            ToolbarItemGroup(placement: .bottomBar) {
                                Button("정렬", systemImage: "arrow.up.arrow.down") {}
                                Button("필터", systemImage: "line.3.horizontal.decrease") {}
                                Button("공유", systemImage: "square.and.arrow.up") {}
                                Button("추가", systemImage: "plus") {}
                            }
                        }
                    }
                    .toolbarVerticalCompressionBehavior(prefersToolbar ? .prefersToolbarItems : .automatic)
                }
            }
        }
    }

    private func icon(_ name: String) -> String {
        switch name {
        case "Recents": "clock"
        case "Shared": "person.2"
        case "Browse": "folder"
        default: "star"
        }
    }
}
