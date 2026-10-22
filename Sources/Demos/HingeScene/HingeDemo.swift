import SwiftUI

struct HingeDemo: View {
    @State private var isEnabled = true
    @State private var hasHinge = false
    @State private var status = "-"
    @State private var angle: Angle = .zero
    @State private var updates = 0
    @State private var transitions: [String] = []
    /// 0 = 굽힘 없음, 1 = 가장 깊이 굽힘 (가이드의 pitchBend 예시)
    @State private var bend: Double = 0

    var body: some View {
        DemoPage(intro: "힌지 데이터는 실시간이며 인터랙션·효과용입니다. 레이아웃 구성에는 arrangement와 reserved region API를 쓰세요. hinge가 nil이면 힌지가 없는 기기이니 값을 되돌려야 합니다.") {
            Card(title: "onHingeChange") {
                Toggle("isEnabled", isOn: $isEnabled)
                InfoRow("context.hinge", hasHinge ? "있음" : "nil (힌지 없음)", highlight: !hasHinge)
                InfoRow("status", status)
                InfoRow("angle", "\(Int(angle.degrees))°")
                InfoRow("업데이트 횟수", "\(updates)")
            }

            Card(title: "각도 시각화") {
                HingeDiagram(angle: angle, active: hasHinge)
                    .frame(height: 140)
            }

            Card(title: "효과 — partiallyOpen일 때만 반응") {
                Image(systemName: "guitars.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange.gradient)
                    .scaleEffect(1 + bend * 0.6)
                    .rotationEffect(.degrees(bend * -20))
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .animation(.interactiveSpring, value: bend)
                InfoRow("pitchBend", String(format: "%.2f", bend))
            }

            Card(title: "상태 전환 기록") {
                if transitions.isEmpty {
                    Text("시뮬레이터 하단 컨트롤로 열기·닫기·접기를 바꿔 보세요.").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(Array(transitions.enumerated()), id: \.offset) { _, line in
                    Text(line).font(.caption).monospaced()
                }
            }
        }
        .onHingeChange(isEnabled: isEnabled) { old, new in
            updates += 1
            guard let hinge = new.hinge else {
                hasHinge = false
                status = "-"
                angle = .zero
                bend = 0
                return
            }
            hasHinge = true
            angle = hinge.angle
            status = label(hinge.status)
            if old.hinge?.status != hinge.status {
                transitions.insert("\(Date.now.formatted(date: .omitted, time: .standard))  \(old.hinge.map { label($0.status) } ?? "nil") → \(status)", at: 0)
                if transitions.count > 20 { transitions.removeLast() }
            }
            bend = hinge.status == .partiallyOpen ? max(0, min(1, 1 - hinge.angle.degrees / 180)) : 0
        }
    }

    private func label(_ status: DeviceHinge.Status) -> String {
        switch status {
        case .closed: "closed"
        case .partiallyOpen: "partiallyOpen"
        case .fullyOpen: "fullyOpen"
        default: "unknown"
        }
    }
}

/// 왼쪽 판은 고정, 오른쪽 판이 힌지 각도만큼 펼쳐진다.
private struct HingeDiagram: View {
    let angle: Angle
    let active: Bool

    var body: some View {
        Canvas { context, size in
            let pivot = CGPoint(x: size.width / 2, y: size.height - 16)
            let length = min(size.width / 2 - 16, size.height - 32)
            var left = Path()
            left.move(to: pivot)
            left.addLine(to: CGPoint(x: pivot.x - length, y: pivot.y))
            context.stroke(left, with: .color(.secondary), style: StrokeStyle(lineWidth: 6, lineCap: .round))

            // 0°면 왼쪽 판 위로 겹치고, 180°면 일직선으로 펼쳐진다.
            let theta = angle.radians
            var right = Path()
            right.move(to: pivot)
            right.addLine(to: CGPoint(x: pivot.x - cos(theta) * length, y: pivot.y - sin(theta) * length))
            context.stroke(right, with: .color(active ? .orange : .gray), style: StrokeStyle(lineWidth: 6, lineCap: .round))

            context.fill(Path(ellipseIn: CGRect(x: pivot.x - 6, y: pivot.y - 6, width: 12, height: 12)), with: .color(.primary))
        }
    }
}
