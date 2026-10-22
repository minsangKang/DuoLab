import SwiftUI

struct DemoPage<Content: View>: View {
    let intro: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(intro)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                content
            }
            .padding()
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }
}

struct Card<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title).font(.headline)
            }
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
    }
}

struct InfoRow: View {
    let key: String
    let value: String
    var highlight = false

    init(_ key: String, _ value: String, highlight: Bool = false) {
        self.key = key
        self.value = value
        self.highlight = highlight
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .monospaced()
                .multilineTextAlignment(.trailing)
                .foregroundStyle(highlight ? Color.orange : Color.primary)
        }
        .font(.footnote)
    }
}

/// 바 데모는 NavigationSplitView detail 열 안과, 디스플레이 가장자리에 붙은 전체 화면 스택에서 결과가 다르다.
struct FullScreenLauncher<Content: View>: View {
    var label = "전체 화면 NavigationStack으로 열기"
    @ViewBuilder var content: () -> Content
    @State private var isPresented = false

    var body: some View {
        Button(label, systemImage: "arrow.up.left.and.arrow.down.right") { isPresented = true }
            .buttonStyle(.borderedProminent)
            .fullScreenCover(isPresented: $isPresented, content: content)
    }
}

/// 전체 화면 데모에서 공통으로 쓰는 닫기 버튼 — 세로 바 맨 위(cancellationAction)에 놓인다.
struct CloseToolbarItem: ToolbarContent {
    @Environment(\.dismiss) private var dismiss

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("닫기", systemImage: "xmark") { dismiss() }
        }
    }
}

extension CGFloat {
    var pt: String {
        let rounded = (self * 10).rounded() / 10
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(format: "%.1f", rounded)
    }
}

extension Double {
    var pt: String { CGFloat(self).pt }
}

extension CGSize {
    var short: String { "\(width.pt) × \(height.pt)" }
}

extension CGRect {
    var short: String { "(\(minX.pt), \(minY.pt)) \(width.pt)×\(height.pt)" }
}

extension EdgeInsets {
    var short: String { "T\(top.pt) L\(leading.pt) B\(bottom.pt) R\(trailing.pt)" }
}

extension UIEdgeInsets {
    var short: String { "T\(top.pt) L\(left.pt) B\(bottom.pt) R\(right.pt)" }
}

extension NSDirectionalEdgeInsets {
    var short: String { "T\(top.pt) L\(leading.pt) B\(bottom.pt) R\(trailing.pt)" }
}

extension Optional where Wrapped == HorizontalEdge {
    var label: String {
        switch self {
        case .leading: "leading"
        case .trailing: "trailing"
        case nil: "nil (가로 바)"
        }
    }
}
