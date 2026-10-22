import AVFoundation
import AVKit
import SwiftUI
import UIKit

struct CameraDeviceInfo: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let type: String
    let position: String
    var isVirtual = false
}

struct ActiveCameraInfo: Equatable, Sendable {
    var name = "-"
    var type = "-"
    var position = "-"
    var activeConstituent = "-"
    var dynamicAspectRatio = "-"
    var compensationSupported = false
    var compensationEnabled = false
}

enum CameraCatalog {
    static func info(_ device: AVCaptureDevice) -> CameraDeviceInfo {
        CameraDeviceInfo(id: device.uniqueID, name: device.localizedName, type: label(device.deviceType),
                         position: label(device.position), isVirtual: device.isVirtualDevice)
    }

    /// 다른 iPhone과 같은 요청 — Duo에서는 새 가상 전면 카메라가 발견된다.
    static func virtualFrontDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
            mediaType: .video, position: .front
        ).devices
    }

    static let individualTypes: [AVCaptureDevice.DeviceType] = [
        .builtInOuterUltraWideCamera, .builtInInnerUltraWideCamera, .builtInDualWideCamera, .builtInWideAngleCamera,
    ]

    static func individualDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: individualTypes, mediaType: .video, position: .unspecified).devices
    }

    static func label(_ type: AVCaptureDevice.DeviceType) -> String {
        switch type {
        case .builtInOuterUltraWideCamera: "outerUltraWide"
        case .builtInInnerUltraWideCamera: "innerUltraWide"
        case .builtInDualWideCamera: "dualWide"
        case .builtInWideAngleCamera: "wideAngle"
        case .builtInUltraWideCamera: "ultraWide"
        default: type.rawValue.replacingOccurrences(of: "AVCaptureDeviceTypeBuiltIn", with: "")
        }
    }

    static func label(_ position: AVCaptureDevice.Position) -> String {
        switch position {
        case .front: "front"
        case .back: "back"
        default: "unspecified"
        }
    }

    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: true
        case .notDetermined: await AVCaptureDevice.requestAccess(for: .video)
        default: false
        }
    }
}

/// 세션 구성은 메인 밖에서. 코디네이터 handler에서는 Sendable한 uniqueID만 넘긴다.
actor CameraController {
    // 프리뷰 레이어가 메인에서 세션을 참조해야 해서 노출한다. 구성 변경은 이 액터 안에서만 한다.
    nonisolated(unsafe) let session = AVCaptureSession()
    private var input: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()

    func use(uniqueID: String) -> ActiveCameraInfo? {
        guard let device = AVCaptureDevice(uniqueID: uniqueID) else { return nil }
        if input?.device.uniqueID == uniqueID { return info() }

        session.beginConfiguration()
        if let input { session.removeInput(input) }
        if let newInput = try? AVCaptureDeviceInput(device: device), session.canAddInput(newInput) {
            session.addInput(newInput)
            input = newInput
        }
        if !session.outputs.contains(photoOutput), session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
        if !session.isRunning { session.startRunning() }
        return info()
    }

    func setSensorOrientationCompensation(_ enabled: Bool) -> ActiveCameraInfo {
        if photoOutput.isCameraSensorOrientationCompensationSupported {
            photoOutput.isCameraSensorOrientationCompensationEnabled = enabled
        }
        return info()
    }

    func info() -> ActiveCameraInfo {
        guard let device = input?.device else { return ActiveCameraInfo() }
        return ActiveCameraInfo(
            name: device.localizedName,
            type: CameraCatalog.label(device.deviceType),
            position: CameraCatalog.label(device.position),
            activeConstituent: device.activePrimaryConstituent.map { "\($0.localizedName) (\(CameraCatalog.label($0.deviceType)))" } ?? "-",
            dynamicAspectRatio: device.dynamicAspectRatio?.rawValue ?? "nil",
            compensationSupported: photoOutput.isCameraSensorOrientationCompensationSupported,
            compensationEnabled: photoOutput.isCameraSensorOrientationCompensationEnabled
        )
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
    }
}

/// AVCaptureVideoPreviewLayer를 담는 뷰. 필요하면 자기 자신을 기준으로 방향 코디네이터를 만든다.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var mirrored: Bool?
    var rotationDeviceID: String?
    var onDirectionChange: ((AVCaptureDeviceDirectionMap) -> Void)?

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onDirectionChange = onDirectionChange
        return view
    }

    func updateUIView(_ view: PreviewUIView, context: Context) {
        view.onDirectionChange = onDirectionChange
        view.applyMirroring(mirrored)
        view.attachRotation(deviceID: rotationDeviceID)
    }

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        var onDirectionChange: ((AVCaptureDeviceDirectionMap) -> Void)?
        private var directionCoordinator: AVCaptureDeviceDirectionCoordinator?
        private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
        private var rotationObservation: NSKeyValueObservation?
        private var rotationDeviceID: String?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil, onDirectionChange != nil, directionCoordinator == nil else { return }
            // 코디네이터는 뷰에 묶여 있어 main actor 전용. 디스플레이마다 뷰가 다르면 코디네이터도 따로 만든다.
            directionCoordinator = AVCaptureDeviceDirectionCoordinator(
                view: self,
                deviceTypes: CameraCatalog.individualTypes
            ) { [weak self] map in
                MainActor.assumeIsolated { self?.onDirectionChange?(map) }
            }
        }

        func applyMirroring(_ mirrored: Bool?) {
            guard let connection = previewLayer.connection, connection.isVideoMirroringSupported else { return }
            if let mirrored {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = mirrored
            } else {
                connection.automaticallyAdjustsVideoMirroring = true
            }
        }

        func attachRotation(deviceID: String?) {
            guard deviceID != rotationDeviceID else { return }
            rotationDeviceID = deviceID
            rotationObservation = nil
            rotationCoordinator = nil
            guard let deviceID, let device = AVCaptureDevice(uniqueID: deviceID) else { return }
            let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
            rotationCoordinator = coordinator
            previewLayer.connection?.videoRotationAngle = coordinator.videoRotationAngleForHorizonLevelPreview
            rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.new]) { [weak self] coordinator, _ in
                let angle = coordinator.videoRotationAngleForHorizonLevelPreview
                DispatchQueue.main.async { self?.previewLayer.connection?.videoRotationAngle = angle }
            }
        }
    }
}

struct NoCameraView: View {
    var body: some View {
        ContentUnavailableView(
            "카메라 없음",
            systemImage: "camera.badge.ellipsis",
            description: Text("시뮬레이터에는 카메라가 없습니다. iPhone Duo 실기기에서 확인하세요.")
        )
    }
}
