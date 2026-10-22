import SwiftUI

struct SafeAreaDemo: View {
    var body: some View {
        SafeAreaVisualizer(showsLauncher: true)
    }
}

/// 네 변 인셋을 색 띠로 그린다. 배경은 ignoresSafeArea로 밖까지, 전경은 안쪽에.
struct SafeAreaVisualizer: View {
    var showsLauncher = false

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            ZStack {
                SafeAreaBands(insets: insets, size: proxy.size)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Card(title: "이 뷰의 safeAreaInsets") {
                            InfoRow("top", insets.top.pt)
                            InfoRow("leading", insets.leading.pt, highlight: insets.leading != insets.trailing)
                            InfoRow("trailing", insets.trailing.pt, highlight: insets.leading != insets.trailing)
                            InfoRow("bottom", insets.bottom.pt)
                            InfoRow("안전 영역 크기", proxy.size.short)
                            if insets.leading != insets.trailing {
                                Label("좌우가 비대칭입니다. `width - left * 2` 같은 계산은 여기서 깨집니다.", systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        Card(title: "색 띠 범례") {
                            Legend(color: .red, text: "top")
                            Legend(color: .blue, text: "leading")
                            Legend(color: .green, text: "trailing")
                            Legend(color: .purple, text: "bottom")
                            Text("세로 바가 있는 포즈에선 leading/trailing 띠에 바가 들어갑니다. 전경(이 카드)은 안쪽, 배경 그라디언트는 바 뒤까지 확장됩니다.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if showsLauncher {
                            FullScreenLauncher(label: "내비게이션 바 없이 전체 화면으로") {
                                SafeAreaVisualizer()
                                    .overlay(alignment: .bottomTrailing) { CloseOverlayButton() }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

private struct SafeAreaBands: View {
    let insets: EdgeInsets
    let size: CGSize

    var body: some View {
        let full = CGSize(width: size.width + insets.leading + insets.trailing,
                          height: size.height + insets.top + insets.bottom)
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [.indigo.opacity(0.25), .teal.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
            band(.red, CGRect(x: 0, y: 0, width: full.width, height: insets.top), insets.top)
            band(.purple, CGRect(x: 0, y: full.height - insets.bottom, width: full.width, height: insets.bottom), insets.bottom)
            band(.blue, CGRect(x: 0, y: 0, width: insets.leading, height: full.height), insets.leading)
            band(.green, CGRect(x: full.width - insets.trailing, y: 0, width: insets.trailing, height: full.height), insets.trailing)
        }
        .frame(width: full.width, height: full.height)
    }

    private func band(_ color: Color, _ rect: CGRect, _ value: CGFloat) -> some View {
        color.opacity(0.35)
            .overlay {
                if value >= 14 {
                    Text(value.pt).font(.caption2.bold()).monospaced().foregroundStyle(.white)
                }
            }
            .frame(width: max(rect.width, 0), height: max(rect.height, 0))
            .offset(x: rect.minX, y: rect.minY)
    }
}

private struct Legend: View {
    let color: Color
    let text: String

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.5)).frame(width: 18, height: 12)
            Text(text).font(.caption)
        }
    }
}

struct CloseOverlayButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button("닫기", systemImage: "xmark") { dismiss() }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .padding()
    }
}
