import SwiftUI
import UIKit

/// 버튼·패널 영역만 터치를 받고 나머지는 아래 앱 윈도우로 통과시킨다.
final class PassthroughWindow: UIWindow {
    var interactiveRegions: @MainActor () -> [CGRect] = { [] }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else { return nil }
        if rootViewController?.presentedViewController != nil { return hit }
        return interactiveRegions().contains { $0.contains(point) } ? hit : nil
    }
}

@MainActor
@Observable
final class DebugModel {
    enum Tab: String, CaseIterable { case metrics = "현재 값", log = "변경 로그" }
    enum Anchor { case top, bottom }

    var isOpen = false
    var tab: Tab = .metrics
    var anchor: Anchor = .bottom
    var snapshot = MetricsSnapshot()
    var log: [ChangeLogEntry] = []
    var buttonFrame: CGRect = .zero
    var panelFrame: CGRect = .zero
}

@MainActor
final class DebugOverlayController {
    private static var controllers: [ObjectIdentifier: DebugOverlayController] = [:]

    static func install(in scene: UIWindowScene) {
        let id = ObjectIdentifier(scene)
        guard controllers[id] == nil else { return }
        controllers[id] = DebugOverlayController(scene: scene)
    }

    let model = DebugModel()
    private weak var scene: UIWindowScene?
    private let window: PassthroughWindow
    private var hinge = HingeReading()
    private var keyboardFrame: CGRect?
    private var refreshTask: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []

    private init(scene: UIWindowScene) {
        self.scene = scene
        window = PassthroughWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let host = UIHostingController(rootView: DebugOverlayRoot(model: model, onSave: { [weak self] label in self?.saveSnapshot(label: label) }))
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.interactiveRegions = { [model] in
            [model.buttonFrame] + (model.isOpen ? [model.panelFrame] : [])
        }
        window.isHidden = false

        let interaction = UIHingeInteraction { [weak self] _, update in
            guard let self else { return }
            if let h = update.hinge {
                hinge = HingeReading(isAvailable: true, status: Self.label(h.status), angle: h.angle)
            } else {
                hinge = HingeReading()
            }
            refresh()
        }
        window.addInteraction(interaction)

        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] note in
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            MainActor.assumeIsolated { self?.keyboardFrame = frame }
        })
        observers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.keyboardFrame = nil }
        })
        observers.append(center.addObserver(forName: UIScene.didDisconnectNotification, object: scene, queue: .main) { _ in
            MainActor.assumeIsolated { Self.controllers[ObjectIdentifier(scene)] = nil }
        })

        startRefreshing()
    }

    private func startRefreshing() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                refresh()
                let interval: Duration = model.isOpen ? .milliseconds(250) : .milliseconds(500)
                try? await Task.sleep(for: interval)
            }
        }
    }

    private func refresh() {
        guard let scene else { return }
        let next = LayoutInspector.collect(scene: scene, hinge: hinge, keyboardFrame: keyboardFrame)
        let changes = next.key.changes(from: model.snapshot.key)
        if !changes.isEmpty {
            let isFirst = model.snapshot.sections.isEmpty
            model.log.insert(ChangeLogEntry(date: .now, changes: isFirst ? ["시작: \(next.key.shape) \(next.key.size)"] : changes), at: 0)
            if model.log.count > 100 { model.log.removeLast(model.log.count - 100) }
        }
        if next != model.snapshot { model.snapshot = next }
    }

    private func saveSnapshot(label: String) {
        SnapshotStore.shared.add(label: label, text: model.snapshot.plainText)
        if let scene, let app = LayoutInspector.appWindow(in: scene) { app.makeKey() }
    }

    private static func label(_ status: UIHinge.Status) -> String {
        switch status {
        case .closed: "closed"
        case .partiallyOpen: "partiallyOpen"
        case .fullyOpen: "fullyOpen"
        default: "unknown"
        }
    }
}

// MARK: - 설치

private struct SceneFinder: UIViewRepresentable {
    func makeUIView(context: Context) -> FinderView { FinderView() }
    func updateUIView(_ uiView: FinderView, context: Context) {}

    final class FinderView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let scene = window?.windowScene, !(window is PassthroughWindow) else { return }
            DebugOverlayController.install(in: scene)
        }
    }
}

extension View {
    func installDebugOverlay() -> some View {
        background(SceneFinder().allowsHitTesting(false))
    }
}
