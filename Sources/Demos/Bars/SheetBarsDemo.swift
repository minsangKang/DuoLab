import SwiftUI

struct SheetBarsDemo: View {
    enum SheetKind: String, Identifiable {
        case toolbar, singleClose, singleCloseDisabled
        var id: String { rawValue }
    }

    @State private var sheet: SheetKind?

    var body: some View {
        DemoPage(intro: "외부 화면에서 시트 툴바는 측면으로 갑니다. 내부 화면에서는 시트가 중앙에 뜨고 항목은 가로를 유지합니다. 닫기 하나뿐인 시트는 세로 바를 끄면 공간을 덜 씁니다.") {
            BarStatusCard()
            Card(title: "시트 열기") {
                Button("툴바가 있는 시트") { sheet = .toolbar }
                Button("닫기 하나뿐인 시트 (기본)") { sheet = .singleClose }
                Button("닫기 하나뿐인 시트 (세로 바 끔)") { sheet = .singleCloseDisabled }
            }
        }
        .sheet(item: $sheet) { kind in
            switch kind {
            case .toolbar:
                NavigationStack {
                    SheetBody(title: "툴바 시트")
                        .toolbar {
                            CloseToolbarItem()
                            ToolbarItem(placement: .confirmationAction) {
                                Button("완료", systemImage: "checkmark") { sheet = nil }
                            }
                            ToolbarItemGroup(placement: .bottomBar) {
                                Button("사진", systemImage: "photo") {}
                                Button("카메라", systemImage: "camera") {}
                                Button("파일", systemImage: "doc") {}
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            case .singleClose:
                NavigationStack {
                    SheetBody(title: "닫기만 (기본)").toolbar { CloseToolbarItem() }
                }
            case .singleCloseDisabled:
                NavigationStack {
                    SheetBody(title: "닫기만 (세로 바 끔)").toolbar { CloseToolbarItem() }
                }
                .toolbarVerticalBehavior(.disabled)
            }
        }
    }
}

private struct SheetBody: View {
    let title: String

    var body: some View {
        List {
            BarStatusCard().listRowInsets(EdgeInsets())
            ForEach(0..<12, id: \.self) { Text("행 \($0 + 1)") }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
