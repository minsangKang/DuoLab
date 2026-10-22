import SwiftUI

struct SplitArrangementDemo: View {
    enum Style: String, CaseIterable, Identifiable {
        case automatic, split
        case horizontalOnly = "split.axes(.horizontal)"
        case verticalOnly = "split.axes(.vertical)"
        var id: String { rawValue }
    }

    @State private var style: Style = .split
    @State private var secondaryVisible = false

    var body: some View {
        styled(
            ArrangementView {
                PlayerPane(title: "주 뷰 · Player", color: .indigo, note: secondaryVisible ? "보조 뷰도 표시 중" : "보조 뷰 숨김 — 단일 뷰")
            } secondary: {
                UpNextPane()
                    .onAppear { secondaryVisible = true }
                    .onDisappear { secondaryVisible = false }
            }
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("스타일", selection: $style) {
                        ForEach(Style.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Label("배열 스타일", systemImage: "rectangle.split.2x1")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text("스타일: \(style.rawValue) · 기본은 너비 > 높이면 수평, 반대면 수직 분할. 분할할 수 없는 축만 허용하면 주 뷰만 남습니다.")
                .font(.caption)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
    }

    @ViewBuilder
    private func styled(_ view: some View) -> some View {
        switch style {
        case .automatic: view.arrangementViewStyle(.automatic)
        case .split: view.arrangementViewStyle(.split)
        case .horizontalOnly: view.arrangementViewStyle(.split.axes(.horizontal))
        case .verticalOnly: view.arrangementViewStyle(.split.axes(.vertical))
        }
    }
}

struct PlayerPane: View {
    let title: String
    let color: Color
    var note: String?
    @State private var size: CGSize = .zero

    var body: some View {
        ZStack {
            color.opacity(0.25)
            VStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill").font(.system(size: 44))
                Text(title).font(.headline)
                Text(size.short).font(.caption).monospaced()
                if let note { Text(note).font(.caption).foregroundStyle(.secondary) }
            }
            .padding()
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
    }
}

struct UpNextPane: View {
    @State private var size: CGSize = .zero

    var body: some View {
        List {
            Section("보조 뷰 · Up Next (\(size.short))") {
                ForEach(1...15, id: \.self) { Text("다음 곡 \($0)") }
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
    }
}
