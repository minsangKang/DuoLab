# DuoLab

iPhone Duo(iOS 27.1)의 적응형 레이아웃 기능을 화면별로 직접 확인해 보는 SwiftUI 샘플앱입니다.

## 기반 문서

아래 두 가이드를 토대로 만들었습니다. 각 데모 화면은 가이드의 한 섹션에 대응합니다.

- [iPhone Duo 개발 가이드](docs/iphone-duo-guide.md) — Apple Tech Talks 6편을 정리한 Duo API와 동작
- [적응형 레이아웃 설계 가이드](docs/adaptive-layout-guide.md) — 사이즈 클래스·종횡비로 나눈 5개 쉐이프와 신호 3계층

## 실행

- Xcode 27.1, iOS 27.1 SDK, [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- 시뮬레이터: iPhone Duo (Device Hub 하단 컨트롤로 열기·닫기·회전·접기 전환)

```bash
make run                              # 프로젝트 생성 → 빌드 → iPhone Duo 시뮬레이터 실행
make build                            # 빌드만
```

## 확인할 수 있는 기능

메인 화면은 `NavigationSplitView` 리스트입니다. 외부 화면에서는 스택으로, 내부 화면에서는 리스트 + 상세로 표시돼 그 자체로 표준 컨테이너 적응 데모가 됩니다.

**레이아웃 기본**
- 사이즈 클래스 & 쉐이프 — 현재 5개 쉐이프 중 어디인지, 루트와 detail 열의 사이즈 클래스 차이
- 세이프 에어리어 — 네 변 인셋 시각화, 좌우 비대칭 경고
- 적응형 패턴 — `AnyLayout`, `ViewThatFits`, adaptive 그리드, 폭 브레이크포인트 vs 쉐이프 비교
- Concentric 모서리 — `ConcentricRectangle`

**바**
- 세로 바 기본, 항목 축(`axisBehavior`, 배지), 오버플로 & `visibilityPriority`
- 압축 동작(`toolbarVerticalCompressionBehavior`), 세로 바 끄기(`toolbarVerticalBehavior`)
- 시트의 바, 탭 바 → 사이드바(`defaultTabBarPlacement`)

**예약 영역**
- 영역 인스펙터 — division·occlusion 프레임과 margins
- 접힘 인지 그리드 — `includeInactive`로 짝수 열 유지, 힌지 주변 간격
- 변위 패턴 — 접힘 방향에 따라 연동 요소를 한 영역으로 이동

**ArrangementView**
- Split — 스타일과 `axes` 제한에 따른 배치
- Overlay — `overlayArrangementZIndex`로 미니 플레이어 접기·펼치기

**힌지 & 씬**
- 힌지 — `onHingeChange` 상태·각도, 각도 연동 효과
- 멀티 씬 — `openWindow`, `UIWindowScene.ActivationAction`

**카메라 (실기기 전용)**
- 가상 전면 카메라 — 열고 닫을 때 자동 전환
- 방향 코디네이터 — `AVCaptureDeviceDirectionCoordinator`로 사용자 쪽 카메라 추적, 미러링
- 씬 액세서리 — `CameraCaptureAccessory`로 외부 화면 텔레프롬프터

## 레이아웃 디버그 패널

모든 화면 위에 드래그 가능한 플로팅 버튼이 떠 있습니다. 누르면 현재 값이 섹션별로 쌓인 패널이 열립니다.

- 요약: 쉐이프, 사이즈 클래스(H/V), 가로·세로 방향
- 화면: 윈도우·스크린 크기, displayScale, idiom
- 세이프 에어리어: 네 변 수치, 비대칭 여부, layoutMargins
- 시스템 바: 상태 표시줄, navigationBar·toolbar·tabBar 프레임과 높이, `verticalBarEdge`, 키보드
- 예약 영역, 힌지, 접근성 설정
- 변경 로그: 포즈를 바꿀 때마다 달라진 값을 시간순으로 기록
- 텍스트 복사, 스냅샷 저장 → '실측 기록' 화면에서 내보내기

적응형 가이드의 '돌려볼 구성'을 하나씩 돌며 스냅샷을 남기면 매트릭스의 `?` 칸을 채울 수 있습니다.

## 참고

- API는 로컬 Xcode 27.1 Beta SDK 기준으로 작성했습니다. 릴리즈 SDK에서는 이름이 다를 수 있습니다.
- 베타 iOS 27.1 런타임은 iPhone Duo 시뮬레이터만 지원해, 다른 기기에서는 아직 확인하지 않았습니다.
