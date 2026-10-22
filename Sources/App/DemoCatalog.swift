import SwiftUI

enum DemoSection: String, CaseIterable, Identifiable {
    case basics = "레이아웃 기본"
    case bars = "바"
    case regions = "예약 영역"
    case arrangement = "ArrangementView"
    case hingeScene = "힌지 & 씬"
    case camera = "카메라 (실기기)"
    case debug = "디버그"

    var id: String { rawValue }
    var demos: [Demo] { Demo.allCases.filter { $0.section == self } }
}

enum Demo: String, CaseIterable, Identifiable, Hashable {
    case shapeMatrix, safeArea, adaptivePatterns, concentric
    case verticalBar, itemAxis, overflow, compression, verticalDisabled, sheetBars, tabSidebar
    case regionInspector, foldGrid, displacement
    case splitArrangement, overlayArrangement
    case hinge, multiScene
    case virtualFrontCamera, directionCoordinator, sceneAccessory
    case snapshots

    var id: String { rawValue }

    var section: DemoSection {
        switch self {
        case .shapeMatrix, .safeArea, .adaptivePatterns, .concentric: .basics
        case .verticalBar, .itemAxis, .overflow, .compression, .verticalDisabled, .sheetBars, .tabSidebar: .bars
        case .regionInspector, .foldGrid, .displacement: .regions
        case .splitArrangement, .overlayArrangement: .arrangement
        case .hinge, .multiScene: .hingeScene
        case .virtualFrontCamera, .directionCoordinator, .sceneAccessory: .camera
        case .snapshots: .debug
        }
    }

    var title: String {
        switch self {
        case .shapeMatrix: "사이즈 클래스 & 쉐이프"
        case .safeArea: "세이프 에어리어"
        case .adaptivePatterns: "적응형 패턴"
        case .concentric: "Concentric 모서리"
        case .verticalBar: "세로 바 기본"
        case .itemAxis: "항목 축 (AxisBehavior)"
        case .overflow: "오버플로 & 우선순위"
        case .compression: "압축 동작"
        case .verticalDisabled: "세로 바 끄기"
        case .sheetBars: "시트의 바"
        case .tabSidebar: "탭 바 → 사이드바"
        case .regionInspector: "영역 인스펙터"
        case .foldGrid: "접힘 인지 그리드"
        case .displacement: "변위 패턴"
        case .splitArrangement: "Split 배열"
        case .overlayArrangement: "Overlay 배열"
        case .hinge: "힌지"
        case .multiScene: "멀티 씬"
        case .virtualFrontCamera: "가상 전면 카메라"
        case .directionCoordinator: "방향 코디네이터"
        case .sceneAccessory: "씬 액세서리"
        case .snapshots: "실측 기록"
        }
    }

    var systemImage: String {
        switch self {
        case .shapeMatrix: "square.grid.3x2"
        case .safeArea: "rectangle.inset.filled"
        case .adaptivePatterns: "rectangle.split.2x1"
        case .concentric: "app.dashed"
        case .verticalBar: "sidebar.right"
        case .itemAxis: "arrow.up.and.down.and.arrow.left.and.right"
        case .overflow: "ellipsis.circle"
        case .compression: "arrow.down.right.and.arrow.up.left"
        case .verticalDisabled: "rectangle.slash"
        case .sheetBars: "rectangle.bottomhalf.inset.filled"
        case .tabSidebar: "sidebar.left"
        case .regionInspector: "viewfinder"
        case .foldGrid: "square.grid.4x3.fill"
        case .displacement: "arrow.left.and.right.square"
        case .splitArrangement: "rectangle.split.2x1.fill"
        case .overlayArrangement: "rectangle.stack"
        case .hinge: "book"
        case .multiScene: "macwindow.on.rectangle"
        case .virtualFrontCamera: "camera"
        case .directionCoordinator: "camera.rotate"
        case .sceneAccessory: "text.viewfinder"
        case .snapshots: "list.clipboard"
        }
    }

    var summary: String {
        switch self {
        case .shapeMatrix: "H/V 사이즈 클래스와 종횡비로 5개 쉐이프 중 어디인지"
        case .safeArea: "네 변 인셋 시각화, 비대칭 확인"
        case .adaptivePatterns: "AnyLayout · ViewThatFits · adaptive 그리드 · 브레이크포인트 비교"
        case .concentric: "기기 모서리에 맞춘 ConcentricRectangle"
        case .verticalBar: "상·하단 툴바 항목이 세로로 이동하는지"
        case .itemAxis: "horizontalOnly · verticalPreferred · 배지"
        case .overflow: "ToolbarOverflowMenu · visibilityPriority"
        case .compression: "툴바 먼저 vs 탭 바 먼저 접기"
        case .verticalDisabled: "toolbarVerticalBehavior(.disabled)"
        case .sheetBars: "외부·내부 디스플레이에서 시트 툴바"
        case .tabSidebar: "defaultTabBarPlacement(.sidebar)"
        case .regionInspector: "division · occlusion 프레임과 margins"
        case .foldGrid: "includeInactive로 짝수 열 유지"
        case .displacement: "접히면 연동 요소를 한 영역으로"
        case .splitArrangement: "split 스타일과 axes 제한"
        case .overlayArrangement: "overlayArrangementZIndex로 접힘 전환"
        case .hinge: "onHingeChange 상태·각도"
        case .multiScene: "새 창 생성 가능 여부"
        case .virtualFrontCamera: "열고 닫을 때 자동 전환"
        case .directionCoordinator: "사용자 쪽 카메라 추적 + 미러링"
        case .sceneAccessory: "CameraCaptureAccessory 텔레프롬프터"
        case .snapshots: "디버그 패널에서 저장한 스냅샷"
        }
    }

    @MainActor @ViewBuilder
    var destination: some View {
        switch self {
        case .shapeMatrix: ShapeMatrixDemo()
        case .safeArea: SafeAreaDemo()
        case .adaptivePatterns: AdaptivePatternsDemo()
        case .concentric: ConcentricDemo()
        case .verticalBar: VerticalBarDemo()
        case .itemAxis: ItemAxisDemo()
        case .overflow: OverflowDemo()
        case .compression: CompressionDemo()
        case .verticalDisabled: VerticalDisabledDemo()
        case .sheetBars: SheetBarsDemo()
        case .tabSidebar: TabSidebarDemo()
        case .regionInspector: RegionInspectorDemo()
        case .foldGrid: FoldGridDemo()
        case .displacement: DisplacementDemo()
        case .splitArrangement: SplitArrangementDemo()
        case .overlayArrangement: OverlayArrangementDemo()
        case .hinge: HingeDemo()
        case .multiScene: MultiSceneDemo()
        case .virtualFrontCamera: VirtualFrontCameraDemo()
        case .directionCoordinator: DirectionCoordinatorDemo()
        case .sceneAccessory: SceneAccessoryDemo()
        case .snapshots: SnapshotListView()
        }
    }
}
