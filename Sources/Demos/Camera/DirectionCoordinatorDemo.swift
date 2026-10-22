import AVFoundation
import AVKit
import SwiftUI

struct DirectionCoordinatorDemo: View {
    enum Facing: String, CaseIterable, Identifiable {
        case towardUser = "사용자 쪽 (forward)"
        case awayFromUser = "바깥쪽 (backward)"
        var id: String { rawValue }
    }

    @State private var controller = CameraController()
    @State private var facing: Facing = .towardUser
    @State private var forward: [CameraDeviceInfo] = []
    @State private var backward: [CameraDeviceInfo] = []
    @State private var currentID: String?
    @State private var active = ActiveCameraInfo()
    @State private var compensation = true
    @State private var mapUpdates = 0
    @State private var authorized = true
    @State private var hasCameras = true

    var body: some View {
        Group {
            if !authorized {
                ContentUnavailableView("카메라 권한 없음", systemImage: "lock")
            } else if !hasCameras {
                NoCameraView()
            } else {
                content
            }
        }
        .task {
            authorized = await CameraCatalog.requestAccess()
            hasCameras = !CameraCatalog.individualDevices().isEmpty
        }
        .onDisappear { Task { await controller.stop() } }
    }

    private var content: some View {
        DemoPage(intro: "AVCaptureDevice.position은 고정 속성이라 front가 항상 사용자를 향하지 않습니다. 코디네이터는 이 뷰 기준으로 어떤 카메라가 사용자 쪽인지 알려주고 바뀔 때마다 갱신합니다. 4K·깊이가 필요할 때 씁니다.") {
            CameraPreview(
                session: controller.session,
                mirrored: facing == .towardUser,
                rotationDeviceID: currentID,
                onDirectionChange: handle
            )
            .frame(height: 300)
            .clipShape(.rect(cornerRadius: 16))

            Card(title: "스트리밍할 방향") {
                Picker("방향", selection: $facing) {
                    ForEach(Facing.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                InfoRow("미러링", facing == .towardUser ? "켬 (사용자 쪽이면 후면 카메라도 미러링)" : "끔")
            }

            Card(title: "사용 중") {
                InfoRow("device", active.name, highlight: true)
                InfoRow("type · position", "\(active.type) · \(active.position)")
                InfoRow("dynamicAspectRatio", active.dynamicAspectRatio)
                Toggle("센서 방향 보정 (isCameraSensorOrientationCompensationEnabled)", isOn: $compensation)
                    .font(.footnote)
                    .disabled(!active.compensationSupported)
                Text("회전 코디네이터를 쓰고 있으니 보정을 꺼서 성능을 개선할 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Card(title: "방향 맵 (업데이트 \(mapUpdates)회)") {
                Text("forward — 디스플레이 앞(사용자)을 찍는 카메라").font(.caption.bold())
                ForEach(forward) { InfoRow($0.name, "\($0.type) · \($0.position)") }
                if forward.isEmpty { Text("없음").font(.caption) }
                Text("backward — 디스플레이 뒤를 찍는 카메라").font(.caption.bold())
                ForEach(backward) { InfoRow($0.name, "\($0.type) · \($0.position)") }
                if backward.isEmpty { Text("없음").font(.caption) }
            }
        }
        .onChange(of: facing) { selectCamera() }
        .onChange(of: compensation) { _, on in
            Task { active = await controller.setSensorOrientationCompensation(on) }
        }
    }

    /// main queue에서 호출된다. AVFoundation은 직접 만지지 않고 descriptor 정보만 옮긴다.
    private func handle(_ map: AVCaptureDeviceDirectionMap) {
        mapUpdates += 1
        forward = map.forwardFacingDeviceDescriptors.map(info)
        backward = map.backwardFacingDeviceDescriptors.map(info)
        selectCamera()
    }

    private func selectCamera() {
        let candidates = facing == .towardUser ? forward : backward
        guard let target = candidates.first?.id, target != currentID else { return }
        currentID = target
        Task {
            active = await controller.use(uniqueID: target) ?? ActiveCameraInfo()
            active = await controller.setSensorOrientationCompensation(compensation)
        }
    }

    private func info(_ d: AVCaptureDeviceDescriptor) -> CameraDeviceInfo {
        CameraDeviceInfo(id: d.uniqueID, name: d.localizedName, type: CameraCatalog.label(d.deviceType), position: CameraCatalog.label(d.position))
    }
}
