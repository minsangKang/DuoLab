import AVFoundation
import SwiftUI

struct VirtualFrontCameraDemo: View {
    @State private var controller = CameraController()
    @State private var devices: [CameraDeviceInfo] = []
    @State private var active = ActiveCameraInfo()
    @State private var authorized = true
    @State private var loaded = false

    var body: some View {
        Group {
            if !loaded {
                ProgressView()
            } else if !authorized {
                ContentUnavailableView("카메라 권한 없음", systemImage: "lock", description: Text("설정에서 카메라 접근을 허용하세요."))
            } else if devices.isEmpty {
                NoCameraView()
            } else {
                content
            }
        }
        .task { await start() }
        .onDisappear { Task { await controller.stop() } }
    }

    private var content: some View {
        DemoPage(intro: "position: .front + Wide/UltraWide로 요청하면 Duo의 가상 전면 카메라가 발견됩니다. 펼치면 내부, 접으면 외부 카메라로 자동 전환되니 앱은 추가 작업이 없습니다. 공통 기능(최대 1080p·60fps)만 제공합니다.") {
            CameraPreview(session: controller.session, rotationDeviceID: devices.first?.id)
                .frame(height: 300)
                .clipShape(.rect(cornerRadius: 16))
            Card(title: "사용 중") {
                InfoRow("device", active.name)
                InfoRow("type", active.type)
                InfoRow("activePrimaryConstituent", active.activeConstituent, highlight: true)
                InfoRow("dynamicAspectRatio", active.dynamicAspectRatio)
                Text("기기를 열고 닫으며 activePrimaryConstituent가 내부↔외부로 바뀌는지 확인하세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Card(title: "발견된 전면 카메라") {
                ForEach(devices) { d in
                    InfoRow(d.name, "\(d.type)\(d.isVirtual ? " · virtual" : "")")
                }
            }
        }
        .task {
            while !Task.isCancelled {
                active = await controller.info()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func start() async {
        authorized = await CameraCatalog.requestAccess()
        let found = CameraCatalog.virtualFrontDevices()
        devices = found.map(CameraCatalog.info)
        loaded = true
        guard authorized, let first = devices.first else { return }
        active = await controller.use(uniqueID: first.id) ?? ActiveCameraInfo()
    }
}
