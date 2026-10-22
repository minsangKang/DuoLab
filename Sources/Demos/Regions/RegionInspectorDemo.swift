import SwiftUI

struct RegionInspectorDemo: View {
    var body: some View {
        DemoPage(intro: "division은 힌지가 한 영역을 나누는 것, occlusion은 내부 카메라가 작은 프레임을 가리는 것입니다. 기본 조회는 활성 영역만, includeInactive는 펼쳐진(너비 0) 접힘까지 돌려줍니다.") {
            FullScreenLauncher(label: "전체 화면 인스펙터 열기") {
                RegionCanvas()
                    .overlay(alignment: .bottomTrailing) { CloseOverlayButton() }
            }
            Card(title: "이 detail 열 기준") {
                RegionCanvas(compact: true)
                    .frame(height: 260)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
    }
}

/// proxy 좌표계 기준으로 예약 영역을 그리고 수치를 나열한다.
struct RegionCanvas: View {
    var compact = false

    var body: some View {
        GeometryReader { proxy in
            let divisions = proxy.reservedRegions(kind: .division, options: .includeInactive)
            let occlusions = proxy.reservedRegions(kind: .occlusion, options: .includeInactive)
            ZStack(alignment: .topLeading) {
                Color.secondary.opacity(0.08)
                ForEach(divisions) { region in
                    RegionShape(region: region, color: .red)
                }
                ForEach(occlusions) { region in
                    RegionShape(region: region, color: .blue)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        InfoRow("proxy.size", proxy.size.short)
                        InfoRow("division (includeInactive)", "\(divisions.count)개")
                        InfoRow("division (활성만)", "\(proxy.reservedRegions(kind: .division).count)개",
                                highlight: !proxy.reservedRegions(kind: .division).isEmpty)
                        ForEach(Array(divisions.enumerated()), id: \.element.id) { i, r in
                            regionRows("division[\(i)]", r)
                        }
                        InfoRow("occlusion", "\(occlusions.count)개")
                        ForEach(Array(occlusions.enumerated()), id: \.element.id) { i, r in
                            regionRows("occlusion[\(i)]", r)
                        }
                        if divisions.isEmpty {
                            Text("division이 없습니다. 접히는 기기가 아니거나, 이 뷰가 힌지와 겹치지 않습니다.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(.regularMaterial, in: .rect(cornerRadius: 12))
                    .padding(compact ? 8 : 16)
                }
            }
        }
        .ignoresSafeArea(edges: compact ? [] : .all)
    }

    @ViewBuilder
    private func regionRows(_ name: String, _ r: ReservedRegion) -> some View {
        InfoRow("\(name) isActive", "\(r.isActive)", highlight: r.isActive)
        InfoRow("\(name) frame", r.frame.short)
        InfoRow("\(name) margins", r.margins.short)
    }
}

private struct RegionShape: View {
    let region: ReservedRegion
    let color: Color

    var body: some View {
        let frame = region.frame
        Rectangle()
            .fill(color.opacity(region.isActive ? 0.45 : 0.15))
            .overlay(Rectangle().strokeBorder(color, style: StrokeStyle(lineWidth: 2, dash: region.isActive ? [] : [6, 4])))
            .frame(width: max(frame.width, 2), height: max(frame.height, 2))
            .offset(x: frame.minX - (frame.width < 2 ? 1 : 0), y: frame.minY - (frame.height < 2 ? 1 : 0))
            .allowsHitTesting(false)
    }
}
