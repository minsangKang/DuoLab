import SwiftUI

struct LayoutContext: Equatable {
    // L1 — 분기용
    var shape: LayoutShape = .regularWide
    var size: CGSize = .zero

    // L2 — 보정용
    var safeArea = EdgeInsets()
    var foldFrames: [CGRect] = []
    var canFold = false
    var occlusionFrames: [CGRect] = []

    var isFolded: Bool { !foldFrames.isEmpty }
    var isWide: Bool { size.width > size.height }
    var hasAsymmetricSafeArea: Bool { safeArea.leading != safeArea.trailing }
}

extension EnvironmentValues {
    @Entry var layoutContext = LayoutContext()
}

private struct LayoutContextModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @State private var probe = Probe()

    struct Probe: Equatable {
        var size: CGSize = .zero
        var safeArea = EdgeInsets()
        var foldFrames: [CGRect] = []
        var canFold = false
        var occlusionFrames: [CGRect] = []
    }

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: Probe.self) { proxy in
                Probe(
                    size: proxy.size,
                    safeArea: proxy.safeAreaInsets,
                    foldFrames: proxy.reservedRegions(kind: .division).map(\.frame),
                    canFold: !proxy.reservedRegions(kind: .division, options: .includeInactive).isEmpty,
                    occlusionFrames: proxy.reservedRegions(kind: .occlusion).map(\.frame)
                )
            } action: { probe = $0 }
            .environment(\.layoutContext, context)
    }

    private var context: LayoutContext {
        LayoutContext(
            shape: LayoutShape(h: h, v: v, isWide: probe.size.width > probe.size.height),
            size: probe.size,
            safeArea: probe.safeArea,
            foldFrames: probe.foldFrames,
            canFold: probe.canFold,
            occlusionFrames: probe.occlusionFrames
        )
    }
}

extension View {
    func measureLayoutContext() -> some View {
        modifier(LayoutContextModifier())
    }
}
