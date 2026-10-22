import SwiftUI

struct OverflowDemo: View {
    var isFullScreen = false

    @State private var itemCount = 4
    @State private var composeIsHigh = true
    @State private var note = ""

    private let symbols = ["star", "heart", "bookmark", "tag", "paperclip", "link", "pin", "bell", "flag", "trash", "folder", "printer"]

    var body: some View {
        BarDemoScaffold(
            intro: "세로 공간은 좁아서 오버플로가 자주 납니다. 기본은 아래에서 위로 넘치고, visibilityPriority가 높은 항목이 가장 나중에 접힙니다. 줄임표(…)는 오버플로 전용입니다.",
            isFullScreen: isFullScreen
        ) {
            Card(title: "조절") {
                Stepper("하단 항목 \(itemCount)개", value: $itemCount, in: 0...symbols.count)
                Toggle("'작성' visibilityPriority(.high)", isOn: $composeIsHigh)
                TextField("키보드를 올려 세로 공간을 줄여 보세요", text: $note)
                    .textFieldStyle(.roundedBorder)
            }
            Card(title: "항목 순서 (세로 바 위에서부터)") {
                Text("1. 닫기 (cancellationAction)\n2. 완료 (topBarPinnedTrailing)\n3. 시스템 오버플로 메뉴 (Scan · Connect)\n4. 하단 항목들 · 작성")
                    .font(.footnote)
                    .monospaced()
            }
        } fullScreen: {
            AnyView(NavigationStack {
                OverflowDemo(isFullScreen: true)
                    .navigationTitle("오버플로")
                    .toolbar { CloseToolbarItem() }
            })
        }
        .toolbar {
            ToolbarItem(placement: .topBarPinnedTrailing) {
                Button("완료", systemImage: "checkmark") {}
            }
            ToolbarOverflowMenu {
                Button("Scan", systemImage: "qrcode.viewfinder") {}
                Button("Connect", systemImage: "antenna.radiowaves.left.and.right") {}
            }
            ToolbarItemGroup(placement: .bottomBar) {
                ForEach(symbols.prefix(itemCount), id: \.self) { symbol in
                    Button(symbol, systemImage: symbol) {}
                }
            }
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button("작성", systemImage: "square.and.pencil") {}
            }
            .visibilityPriority(composeIsHigh ? .high : .automatic)
        }
    }
}
