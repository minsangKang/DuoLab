import SwiftUI
import UIKit

struct MultiSceneDemo: View {
    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @Environment(\.openWindow) private var openWindow
    @State private var sceneCount = 0

    var body: some View {
        DemoPage(intro: "Duo는 여러 씬을 지원하는 첫 iPhone이지만 새 창은 내부 디스플레이에서만 만들 수 있습니다. 기기를 묻지 말고 능력을 묻고, 불가할 때는 컨트롤이 사라지게 하세요.") {
            Card(title: "능력") {
                InfoRow("supportsMultipleWindows (SwiftUI)", "\(supportsMultipleWindows)", highlight: !supportsMultipleWindows)
                InfoRow("supportsMultipleScenes (UIKit)", "\(UIApplication.shared.supportsMultipleScenes)")
                InfoRow("연결된 씬", "\(sceneCount)")
            }

            Card(title: "SwiftUI openWindow") {
                Button("보조 창 열기", systemImage: "macwindow.badge.plus") {
                    openWindow(id: SecondaryWindowView.id)
                }
                .disabled(!supportsMultipleWindows)
                Text("외부 디스플레이에서는 supportsMultipleWindows가 false가 되는지 확인하세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Card(title: "UIWindowSceneActivationAction") {
                SceneActivationButton()
                    .frame(height: 44)
                Text("새 창을 만들 수 없는 상황이면 시스템이 이 버튼을 자동으로 숨깁니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            while !Task.isCancelled {
                sceneCount = UIApplication.shared.connectedScenes.count
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

private struct SceneActivationButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIButton {
        let action = UIWindowScene.ActivationAction(
            title: "새 창에서 열기 (UIKit)",
            image: UIImage(systemName: "rectangle.badge.plus"),
            alternate: nil
        ) { _ in
            let activity = NSUserActivity(activityType: "com.klab.DuoLab.secondary")
            activity.targetContentIdentifier = SecondaryWindowView.id
            return UIWindowScene.ActivationConfiguration(userActivity: activity)
        }
        var config = UIButton.Configuration.bordered()
        config.imagePadding = 6
        return UIButton(configuration: config, primaryAction: action)
    }

    func updateUIView(_ uiView: UIButton, context: Context) {}
}
