import AVFoundation
import SwiftUI

@MainActor
@Observable
final class TeleprompterModel {
    var isEnabled = true
    var isAvailable = false
    var speed: Double = 30
    var script = """
    안녕하세요. 이 화면은 iPhone Duo의 외부 디스플레이에 표시됩니다.
    촬영하는 사람은 내부 화면에서 카메라를 보고,
    촬영되는 사람은 외부 화면에서 이 대본을 읽습니다.
    씬 액세서리는 앱이 내부 디스플레이에서 전체 화면으로 실행 중이고
    활성 카메라 세션이 있을 때만 사용할 수 있습니다.
    기기를 닫으면 사용 불가로 바뀌니 버튼도 같이 비활성화됩니다.
    """
}

struct SceneAccessoryDemo: View {
    @State private var model = TeleprompterModel()
    @State private var controller = CameraController()
    @State private var hasCamera = true

    var body: some View {
        Group {
            if hasCamera {
                content
            } else {
                NoCameraView()
            }
        }
        .task {
            guard await CameraCatalog.requestAccess(), let device = CameraCatalog.virtualFrontDevices().first ?? CameraCatalog.individualDevices().first else {
                hasCamera = false
                return
            }
            _ = await controller.use(uniqueID: device.uniqueID)
        }
        .onDisappear { Task { await controller.stop() } }
    }

    private var content: some View {
        DemoPage(intro: "CameraCaptureAccessory는 메인 UI는 내부 디스플레이에 두고, 외부 디스플레이에 별도 UI를 띄웁니다. 사용 가능 여부는 시스템이 동적으로 바꾸므로 onAvailabilityChange로 관찰합니다.") {
            CameraPreview(session: controller.session)
                .frame(height: 280)
                .clipShape(.rect(cornerRadius: 16))
                .sceneAccessory {
                    CameraCaptureAccessory(isEnabled: $model.isEnabled) {
                        TeleprompterView(model: model)
                    }
                    .onAvailabilityChange { model.isAvailable = $0 }
                }

            Card(title: "액세서리 상태") {
                InfoRow("isAvailable", "\(model.isAvailable)", highlight: !model.isAvailable)
                Toggle("isEnabled (외부 화면에 텔레프롬프터)", isOn: $model.isEnabled)
                    .disabled(!model.isAvailable)
                Slider(value: $model.speed, in: 10...80) { Text("속도") }
                Text("속도 \(Int(model.speed)) pt/s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Card(title: "대본") {
                TextEditor(text: $model.script)
                    .frame(minHeight: 140)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $model.isEnabled) {
                    Label("텔레프롬프터", systemImage: "text.viewfinder")
                }
                .disabled(!model.isAvailable)
            }
        }
    }
}

/// 외부 디스플레이용 UI. 일정 속도로 대본을 올린다.
private struct TeleprompterView: View {
    let model: TeleprompterModel
    @State private var start = Date.now
    @State private var textHeight: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(start)
                let travel = textHeight + geo.size.height
                let offset = geo.size.height - CGFloat((elapsed * model.speed).truncatingRemainder(dividingBy: Double(travel)))
                Text(model.script)
                    .font(.system(size: 34, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(width: geo.size.width)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { textHeight = max($0, 1) }
                    .offset(y: offset)
            }
        }
        .background(.black)
        .ignoresSafeArea()
    }
}
