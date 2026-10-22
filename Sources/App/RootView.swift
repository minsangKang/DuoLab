import SwiftUI

struct RootView: View {
    @State private var selection: Demo?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(DemoSection.allCases) { section in
                    Section(section.rawValue) {
                        ForEach(section.demos) { demo in
                            NavigationLink(value: demo) {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(demo.title)
                                        Text(demo.summary)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: demo.systemImage)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("DuoLab")
        } detail: {
            if let selection {
                selection.destination
                    .navigationTitle(selection.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .id(selection)
            } else {
                ContentUnavailableView("데모를 선택하세요", systemImage: "rectangle.split.2x1",
                                       description: Text("오른쪽 아래 플로팅 버튼으로 어디서든 레이아웃 수치를 볼 수 있습니다."))
            }
        }
    }
}

struct SecondaryWindowView: View {
    static let id = "secondary"
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.layoutContext) private var layout

    var body: some View {
        NavigationStack {
            List {
                InfoRow("shape", layout.shape.rawValue)
                InfoRow("size", layout.size.short)
            }
            .navigationTitle("보조 창")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기", systemImage: "xmark") { dismissWindow(id: Self.id) }
                }
            }
        }
    }
}
