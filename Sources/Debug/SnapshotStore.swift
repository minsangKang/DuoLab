import SwiftUI

struct SavedSnapshot: Codable, Identifiable, Hashable {
    var id = UUID()
    var label: String
    var date: Date
    var text: String
}

@MainActor
@Observable
final class SnapshotStore {
    static let shared = SnapshotStore()
    private static let defaultsKey = "debug.snapshots"

    private(set) var items: [SavedSnapshot]

    private init() {
        let data = UserDefaults.standard.data(forKey: Self.defaultsKey)
        items = data.flatMap { try? JSONDecoder().decode([SavedSnapshot].self, from: $0) } ?? []
    }

    func add(label: String, text: String) {
        let name = label.trimmingCharacters(in: .whitespaces)
        items.insert(SavedSnapshot(label: name.isEmpty ? "이름 없음" : name, date: .now, text: text), at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    func removeAll() {
        items.removeAll()
        persist()
    }

    var exportText: String {
        items.map { "## \($0.label) — \($0.date.formatted(date: .abbreviated, time: .standard))\n\($0.text)" }
            .joined(separator: "\n\n")
    }

    private func persist() {
        UserDefaults.standard.set(try? JSONEncoder().encode(items), forKey: Self.defaultsKey)
    }
}

struct SnapshotListView: View {
    @State private var store = SnapshotStore.shared

    var body: some View {
        List {
            Section {
                Text("플로팅 버튼 패널의 저장 버튼으로 현재 값을 남깁니다. 적응형 가이드의 '돌려볼 구성'을 하나씩 돌면서 기록하면 `?` 칸을 채울 수 있습니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if store.items.isEmpty {
                ContentUnavailableView("저장된 스냅샷 없음", systemImage: "tray")
            }
            ForEach(store.items) { item in
                NavigationLink {
                    ScrollView {
                        Text(item.text)
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .navigationTitle(item.label)
                    .toolbar {
                        ToolbarItem {
                            ShareLink(item: item.text) { Label("공유", systemImage: "square.and.arrow.up") }
                        }
                    }
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.label)
                        Text(item.date, format: .dateTime).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { store.delete(at: $0) }
        }
        .toolbar {
            ToolbarItem {
                ShareLink(item: store.exportText) { Label("전체 내보내기", systemImage: "square.and.arrow.up") }
                    .disabled(store.items.isEmpty)
            }
            ToolbarItem {
                Button("모두 삭제", systemImage: "trash", role: .destructive) { store.removeAll() }
                    .disabled(store.items.isEmpty)
            }
        }
    }
}
