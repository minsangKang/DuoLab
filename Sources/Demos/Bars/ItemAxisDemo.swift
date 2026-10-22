import SwiftUI

struct ItemAxisDemo: View {
    var isFullScreen = false

    @State private var isSelecting = false
    @State private var badgeCount = 7
    @State private var compassAxis: AxisOption = .verticalPreferred

    enum AxisOption: String, CaseIterable, Identifiable {
        case automatic, verticalPreferred, horizontalOnly
        var id: String { rawValue }
        var behavior: ToolbarItemAxisBehavior {
            switch self {
            case .automatic: .automatic
            case .verticalPreferred: .verticalPreferred
            case .horizontalOnly: .horizontalOnly
            }
        }
    }

    var body: some View {
        BarDemoScaffold(
            intro: "아이콘이 있는 항목은 세로로, 텍스트만 있는 항목은 가로에 남습니다. 커스텀 뷰는 기본적으로 가로에 남으니 세로 표현이 가능하면 직접 허용해야 합니다.",
            isFullScreen: isFullScreen
        ) {
            Card(title: "항목 구성") {
                InfoRow("선택/완료 (심볼↔텍스트)", ".horizontalOnly")
                InfoRow("나침반 커스텀 뷰", compassAxis.rawValue, highlight: true)
                InfoRow("받은편지함", ".badge(\(badgeCount))")
                InfoRow("₩12,000 (텍스트만)", "가로 유지")
                Picker("나침반 axisBehavior", selection: $compassAxis) {
                    ForEach(AxisOption.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                Stepper("배지 개수 \(badgeCount)", value: $badgeCount, in: 0...99)
                Text("관련된 항목끼리는 같은 축에 두세요. 텍스트가 독립 정보를 전달하면(금액) 가로에 남기고, 개수는 배지로 바꿉니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } fullScreen: {
            AnyView(NavigationStack {
                ItemAxisDemo(isFullScreen: true)
                    .navigationTitle("항목 축")
                    .toolbar { CloseToolbarItem() }
            })
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SelectOrDoneButton(isSelecting: $isSelecting)
            }
            .axisBehavior(.horizontalOnly)

            ToolbarItem(placement: .topBarTrailing) {
                CompassView()
            }
            .axisBehavior(compassAxis.behavior)

            ToolbarItem(placement: .bottomBar) {
                Button("받은편지함", systemImage: "tray") {}
                    .badge(badgeCount)
            }
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button("₩12,000") {}
            }
        }
    }
}

private struct SelectOrDoneButton: View {
    @Binding var isSelecting: Bool

    var body: some View {
        Button {
            isSelecting.toggle()
        } label: {
            if isSelecting {
                Text("완료")
            } else {
                Label("선택", systemImage: "checkmark.circle")
            }
        }
    }
}

/// 세로 바에 들어가면 고정 너비에 맞게 세로로 쌓는다.
private struct CompassView: View {
    @Environment(\.toolbarVerticalEdge) private var edge

    var body: some View {
        let layout = edge == nil ? AnyLayout(HStackLayout(spacing: 4)) : AnyLayout(VStackLayout(spacing: 0))
        layout {
            Image(systemName: "location.north.line.fill")
            Text("N").font(.caption2.bold())
        }
        .accessibilityLabel("나침반")
    }
}
