import SwiftUI

struct VerticalDisabledDemo: View {
    var body: some View {
        DemoPage(intro: "계산기처럼 하단이 무거운 단일 페이지 앱은 세로 바를 꺼서 콘텐츠를 가로로 꽉 채울 수 있습니다. 대부분의 앱은 켜 두는 편이 맞습니다.") {
            BarStatusCard()
            FullScreenLauncher(label: "계산기 화면 열기") {
                CalculatorScreen()
            }
        }
    }
}

private struct CalculatorScreen: View {
    @State private var disabled = true
    @State private var display = "0"

    private let keys: [[String]] = [["C", "±", "%", "÷"], ["7", "8", "9", "×"], ["4", "5", "6", "−"], ["1", "2", "3", "+"], ["0", ".", "⌫", "="]]

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Toggle("toolbarVerticalBehavior(.disabled)", isOn: $disabled)
                    .font(.footnote)
                BarStatusCard()
                Spacer(minLength: 0)
                Text(display)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(keys, id: \.self) { row in
                        GridRow {
                            ForEach(row, id: \.self) { key in
                                Button(key) { tap(key) }
                                    .font(.title2)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(.fill.tertiary, in: .capsule)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("계산기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                CloseToolbarItem()
                ToolbarItem(placement: .topBarTrailing) {
                    Button("기록", systemImage: "clock") {}
                }
            }
        }
        .toolbarVerticalBehavior(disabled ? .disabled : .automatic)
    }

    private func tap(_ key: String) {
        switch key {
        case "C": display = "0"
        case "⌫": display = display.count > 1 ? String(display.dropLast()) : "0"
        case "0"..."9", ".": display = display == "0" ? key : display + key
        default: break
        }
    }
}
