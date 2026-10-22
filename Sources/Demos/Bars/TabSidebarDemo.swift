import SwiftUI

struct TabSidebarDemo: View {
    var body: some View {
        DemoPage(intro: "내부 화면에서는 탭 바를 사이드바로 올릴 수 있습니다(건강 앱 방식). 외부 화면에서는 탭이 세로로 배열되고, 계층 구조는 두 화면에서 같게 유지됩니다.") {
            BarStatusCard()
            FullScreenLauncher(label: "sidebarAdaptable TabView 열기") {
                SidebarTabs()
            }
        }
    }
}

private struct SidebarTabs: View {
    enum Placement: String, CaseIterable, Identifiable {
        case automatic, sidebar, tabBar
        var id: String { rawValue }
        var value: AdaptableTabBarPlacement {
            switch self {
            case .automatic: .automatic
            case .sidebar: .sidebar
            case .tabBar: .tabBar
            }
        }
    }

    @State private var placement: Placement = .sidebar

    var body: some View {
        TabView {
            Tab("요약", systemImage: "heart.text.square") { page("요약") }
            Tab("공유", systemImage: "person.2") { page("공유") }
            TabSection("카테고리") {
                Tab("활동", systemImage: "flame") { page("활동") }
                Tab("수면", systemImage: "bed.double") { page("수면") }
                Tab("영양", systemImage: "fork.knife") { page("영양") }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .defaultTabBarPlacement(placement.value)
    }

    private func page(_ title: String) -> some View {
        NavigationStack {
            List {
                Picker("defaultTabBarPlacement", selection: $placement) {
                    ForEach(Placement.allCases) { Text($0.rawValue).tag($0) }
                }
                BarStatusCard().listRowInsets(EdgeInsets())
            }
            .navigationTitle(title)
            .toolbar { CloseToolbarItem() }
        }
    }
}
