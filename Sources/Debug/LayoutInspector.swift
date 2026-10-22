import SwiftUI
import UIKit

struct HingeReading: Equatable {
    var isAvailable = false
    var status = "알 수 없음"
    var angle: CGFloat = 0
}

/// 디버그 오버레이 윈도우가 아니라, 같은 씬의 앱 윈도우를 UIKit으로 읽는다.
@MainActor
enum LayoutInspector {
    typealias Row = MetricsSnapshot.Row

    static func appWindow(in scene: UIWindowScene) -> UIWindow? {
        let candidates = scene.windows.filter { !($0 is PassthroughWindow) && !$0.isHidden }
        return candidates.first(where: \.isKeyWindow) ?? candidates.first(where: { $0.windowLevel == .normal }) ?? candidates.first
    }

    static func collect(scene: UIWindowScene, hinge: HingeReading, keyboardFrame: CGRect?) -> MetricsSnapshot {
        guard let window = appWindow(in: scene) else {
            return MetricsSnapshot(sections: [.init(title: "오류", rows: [Row(key: "window", value: "앱 윈도우를 찾지 못함", warn: true)])])
        }
        let traits = window.traitCollection
        let h = UserInterfaceSizeClass(traits.horizontalSizeClass)
        let v = UserInterfaceSizeClass(traits.verticalSizeClass)
        let bounds = window.bounds
        let isWide = bounds.width > bounds.height
        let shape = LayoutShape(h: h, v: v, isWide: isWide)
        let topVC = topViewController(from: window.rootViewController)
        let topTraits = topVC?.traitCollection

        let screen = scene.screen
        let screenID = String(UInt(bitPattern: ObjectIdentifier(screen).hashValue) & 0xFFFF, radix: 16)

        let safe = window.safeAreaInsets
        let vcSafe = topVC?.view.safeAreaInsets ?? .zero

        let divisionsAll = window.reservedRegions(kind: .division, options: .includeInactive)
        let divisionsActive = divisionsAll.filter(\.isActive)
        let occlusions = window.reservedRegions(kind: .occlusion, options: .includeInactive)
        let foldLabel = divisionsAll.isEmpty ? "-" : (divisionsActive.isEmpty ? "capable" : "folded")

        let vbar = label(traits.verticalBarEdge)

        var sections: [MetricsSnapshot.Section] = []

        sections.append(.init(title: "요약", rows: [
            Row(key: "shape", value: shape.rawValue),
            Row(key: "presentation", value: shape.presentation.rawValue),
            Row(key: "sizeClass (window)", value: "H \(h.shortLabel) · V \(v.shortLabel)"),
            Row(key: "sizeClass (top VC)", value: "H \(UserInterfaceSizeClass(topTraits?.horizontalSizeClass ?? .unspecified).shortLabel) · V \(UserInterfaceSizeClass(topTraits?.verticalSizeClass ?? .unspecified).shortLabel)"),
            Row(key: "방향 (W > H)", value: isWide ? "가로 (horizontal)" : "세로 (vertical)"),
            Row(key: "top VC", value: topVC.map(typeName) ?? "-"),
        ]))

        sections.append(.init(title: "화면", rows: [
            Row(key: "window bounds", value: bounds.size.short),
            Row(key: "scene coordinateSpace", value: scene.effectiveGeometry.coordinateSpace.bounds.size.short),
            Row(key: "screen bounds", value: screen.bounds.size.short),
            Row(key: "screen nativeBounds", value: screen.nativeBounds.size.short),
            Row(key: "screen id", value: "0x\(screenID)"),
            Row(key: "displayScale", value: traits.displayScale.pt),
            Row(key: "interfaceOrientation", value: label(scene.effectiveGeometry.interfaceOrientation) + " (레이아웃 분기 금지)"),
            Row(key: "idiom", value: label(traits.userInterfaceIdiom)),
            Row(key: "connected scenes", value: "\(UIApplication.shared.connectedScenes.count)"),
            Row(key: "supportsMultipleScenes", value: "\(UIApplication.shared.supportsMultipleScenes)"),
        ]))

        var safeRows = [
            Row(key: "window safeArea", value: safe.short),
            Row(key: "top VC safeArea", value: vcSafe.short),
            Row(key: "좌우 비대칭", value: safe.left != safe.right ? "예 (L\(safe.left.pt) ≠ R\(safe.right.pt))" : "아니오", warn: safe.left != safe.right),
            Row(key: "safe 영역 rect", value: bounds.inset(by: safe).short),
        ]
        if let topVC {
            safeRows += [
                Row(key: "additionalSafeArea", value: topVC.additionalSafeAreaInsets.short),
                Row(key: "layoutMargins", value: topVC.view.directionalLayoutMargins.short),
                Row(key: "systemMinimumMargins", value: topVC.systemMinimumLayoutMargins.short),
                Row(key: "readableContent 폭", value: topVC.view.readableContentGuide.layoutFrame.width.pt),
            ]
        }
        sections.append(.init(title: "세이프 에어리어", rows: safeRows))

        var barRows: [Row] = []
        if let status = scene.statusBarManager {
            barRows.append(Row(key: "status bar", value: status.isStatusBarHidden ? "숨김" : status.statusBarFrame.short))
        }
        barRows.append(Row(key: "verticalBarEdge", value: vbar))
        for bar in visibleBars(in: window) {
            barRows.append(Row(key: bar.name, value: bar.detail))
        }
        if let keyboardFrame, !keyboardFrame.isEmpty {
            barRows.append(Row(key: "keyboard", value: window.convert(keyboardFrame, from: screen.coordinateSpace).short))
        } else {
            barRows.append(Row(key: "keyboard", value: "없음"))
        }
        sections.append(.init(title: "시스템 바", rows: barRows))

        var regionRows: [Row] = [Row(key: "fold", value: foldLabel)]
        for (i, r) in divisionsAll.enumerated() {
            regionRows.append(Row(key: "division[\(i)] \(r.isActive ? "활성" : "비활성")", value: "\(r.frame.short) m:\(r.margins.short)"))
        }
        if occlusions.isEmpty {
            regionRows.append(Row(key: "occlusion", value: "없음"))
        }
        for (i, r) in occlusions.enumerated() {
            regionRows.append(Row(key: "occlusion[\(i)] \(r.isActive ? "활성" : "비활성")", value: "\(r.frame.short) m:\(r.margins.short)"))
        }
        sections.append(.init(title: "예약 영역", rows: regionRows))

        sections.append(.init(title: "힌지", rows: hinge.isAvailable ? [
            Row(key: "status", value: hinge.status),
            Row(key: "angle", value: "\(Int(hinge.angle.radiansToDegrees))°"),
        ] : [Row(key: "hinge", value: "nil (힌지 없는 기기)")]))

        sections.append(.init(title: "접근성", rows: [
            Row(key: "Dynamic Type", value: traits.preferredContentSizeCategory.rawValue.replacingOccurrences(of: "UICTContentSizeCategory", with: "")),
            Row(key: "투명도 감소", value: "\(UIAccessibility.isReduceTransparencyEnabled)"),
            Row(key: "굵은 텍스트", value: "\(UIAccessibility.isBoldTextEnabled)"),
            Row(key: "layoutDirection", value: traits.layoutDirection == .rightToLeft ? "RTL" : "LTR"),
        ]))

        let key = MetricsSnapshot.Key(
            shape: shape.rawValue,
            sizeClass: "\(h.shortLabel)/\(v.shortLabel)",
            size: bounds.size.short,
            safeArea: safe.short,
            verticalBarEdge: vbar,
            fold: foldLabel,
            hinge: hinge.isAvailable ? hinge.status : "nil",
            screen: screenID
        )
        let badge = "\(h.shortLabel)/\(v.shortLabel)" + (divisionsActive.isEmpty ? "" : " ⌇")
        return MetricsSnapshot(sections: sections, key: key, badge: badge)
    }

    // MARK: - 뷰 컨트롤러 / 바 탐색

    static func topViewController(from root: UIViewController?) -> UIViewController? {
        guard var vc = root else { return nil }
        while let presented = vc.presentedViewController, !presented.isBeingDismissed {
            vc = presented
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(from: visible) ?? visible
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        if let split = vc as? UISplitViewController, let last = split.viewControllers.last {
            return topViewController(from: last)
        }
        return vc
    }

    private struct BarInfo {
        let name: String
        let detail: String
    }

    private static func visibleBars(in window: UIWindow) -> [BarInfo] {
        var result: [BarInfo] = []
        var counts: [String: Int] = [:]
        func visit(_ view: UIView) {
            guard !view.isHidden, view.alpha > 0.01 else { return }
            let name: String? = switch view {
            case is UINavigationBar: "navigationBar"
            case is UIToolbar: "toolbar"
            case is UITabBar: "tabBar"
            default: nil
            }
            if let name, view.bounds.width > 0, view.bounds.height > 0 {
                let index = counts[name, default: 0]
                counts[name] = index + 1
                let frame = view.convert(view.bounds, to: window)
                var detail = "\(frame.short)"
                if let nav = view as? UINavigationBar {
                    detail += " · h \(frame.height.pt)"
                    if let title = nav.topItem?.title, !title.isEmpty { detail += " · \"\(title)\"" }
                    if nav.prefersLargeTitles { detail += " · large" }
                }
                result.append(BarInfo(name: "\(name)[\(index)]", detail: detail))
            }
            view.subviews.forEach(visit)
        }
        visit(window)
        if result.isEmpty {
            result.append(BarInfo(name: "UIKit 바", detail: "보이는 navigation/tool/tab bar 없음"))
        }
        return result
    }

    private static func typeName(_ vc: UIViewController) -> String {
        let full = String(describing: type(of: vc))
        return full.split(separator: "<").first.map(String.init) ?? full
    }

    // MARK: - 라벨

    static func label(_ edge: UIVerticalBarEdge) -> String {
        switch edge {
        case .leading: "leading"
        case .trailing: "trailing"
        default: "unspecified"
        }
    }

    private static func label(_ orientation: UIInterfaceOrientation) -> String {
        switch orientation {
        case .portrait: "portrait"
        case .portraitUpsideDown: "portraitUpsideDown"
        case .landscapeLeft: "landscapeLeft"
        case .landscapeRight: "landscapeRight"
        default: "unknown"
        }
    }

    private static func label(_ idiom: UIUserInterfaceIdiom) -> String {
        switch idiom {
        case .phone: "phone"
        case .pad: "pad"
        case .mac: "mac"
        case .vision: "vision"
        case .tv: "tv"
        case .carPlay: "carPlay"
        default: "unspecified"
        }
    }
}

extension CGFloat {
    var radiansToDegrees: CGFloat { self * 180 / .pi }
}
