# iPhone Duo 개발 가이드

2026-09-20 기준 · Apple Tech Talks 6편 정리

iOS 27.1 SDK로 다시 빌드하고 사이즈 클래스·세이프 에어리어·표준 바 컨테이너만 제대로 쓰면 대부분은 자동으로 적응합니다. 나머지는 예약 영역, ArrangementView, 힌지 API로 다듬는 일입니다.

---

## 시작하기

제일 먼저 할 일은 iOS 27.1 SDK로 다시 빌드하는 것입니다. 어떤 SDK로 빌드했는지에 따라 앱이 쓰는 화면 영역이 세 단계로 달라집니다.

| 빌드 SDK | 앱이 보이는 모습 |
| --- | --- |
| iOS 27 이전 | 닫힌 상태에서 상태 표시줄과 카메라 왼쪽 공간만 사용. 펼치면 익숙한 크기와 화면 비율을 그대로 유지 |
| iOS 27 | 내부 디스플레이의 상태 표시줄 영역 왼쪽까지 확장. iPhone 앱 크기 조정 대응 작업이 그대로 효과를 냄 |
| iOS 27.1 | 화면 가장자리까지 확장. 표준 내비게이션·툴바 버튼이 상태 표시줄 아래에 **세로로** 배치됨 |

iOS 27.1 SDK로 빌드하지 않아도 앱은 정상 동작합니다. 다만 세로 바를 비롯한 새 동작은 전혀 켜지지 않습니다.

### 시뮬레이터로 확인하기

1. Xcode 27.1을 설치합니다.
2. Device Hub에서 iPhone Duo 시뮬레이터를 선택해 앱을 실행합니다.
3. 시뮬레이터 화면 하단의 제어 버튼으로 **열기 / 닫기 / 회전 / 접기**를 전환하며 각 포즈를 확인합니다.
4. 내부 디스플레이에서 하단 홈 인디케이터를 잡아 화면 한쪽으로 드래그하면 Split View 멀티태스킹을 테스트할 수 있습니다. 양쪽 모두 테스트해야 합니다 — 세로로 배치된 콘텐츠는 앱의 어느 쪽에나 나타날 수 있습니다.

### App Resizability 기능 써보기

WWDC26 "Modernize Your UIKit App"에서 소개된 앱 현대화 기능이 Xcode 27.1에서 **App Resizability**로 이름이 바뀌었고, 이제 SwiftUI와 iPhone Duo를 지원합니다. 적응형 레이아웃 모범 사례를 한 번에 점검하는 가장 빠른 방법입니다.

### 알아둘 예외

- `UIRequiresFullScreen` 키는 계속 준수됩니다. 하지만 사용자가 기기를 열거나 닫으면 앱 크기는 어차피 조정됩니다.
- 지원 화면 방향도 준수됩니다. 하지만 내부 디스플레이에서는 Split View 멀티태스킹을 포함해 앱 크기가 조정됩니다.
- 즉 "크기 조정을 막았으니 괜찮다"는 성립하지 않습니다. 유연한 레이아웃은 선택이 아닙니다.

> 출처: [Prepare your app for iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111461/)

---

## 레이아웃 기본기

iPhone Duo의 레이아웃 판단 기준은 **사이즈 클래스** 하나뿐입니다. 고정 너비, 브레이크포인트, 특정 화면에 묶인 치수는 전부 제거하세요.

### 상황 1 — 레이아웃을 분기해야 할 때

사이즈 클래스로만 분기합니다. iPhone Duo의 조합은 세 가지입니다.

| 화면 | 방향 | horizontal | vertical |
| --- | --- | --- | --- |
| 외부 | 세로 | compact | regular |
| 외부 | 가로 | compact | compact |
| 내부 | 세로·가로 | regular | regular |

```swift
// SwiftUI
@Environment(\.horizontalSizeClass)
private var horizontalSizeClass

@Environment(\.verticalSizeClass)
private var verticalSizeClass

// UIKit
traitCollection.horizontalSizeClass
traitCollection.verticalSizeClass
```

디자인 관점에서는 더 단순합니다. 외부 디스플레이는 compact width, 내부 디스플레이는 regular width — 이 두 가지만 대상으로 다루면 됩니다. 포즈별로 맞춤 레이아웃을 따로 그릴 필요는 없습니다.

### 상황 2 — 화면 방향을 보고 있다면

내부 디스플레이는 **앱이 지원하는 인터페이스 방향을 따르지 않습니다.** idiom과 마찬가지로 방향을 레이아웃 판단에 쓰지 마세요.

외부 디스플레이의 방향은 다른 iPhone과 동일하게 동작합니다. 사용자가 기기를 텐트처럼 세워두고 쓸 수 있으니, 아직 가로 모드를 지원하지 않는다면 지금이 추가할 타이밍입니다.

### 상황 3 — 화면 크기나 스케일이 필요할 때

디스플레이가 둘인 기기에서 `UIScreen.main`은 모호하고, 향후 릴리스에서 지원 중단됩니다. 가능하면 화면 참조 자체를 없애고 environment, trait collection, 씬의 bounds 같은 국소적인 개념을 쓰세요.

```swift
// 화면이 꼭 필요하면 윈도우 씬에서 동적으로 가져옴
let screen = window?.windowScene?.screen

// 스케일은 trait으로
func updateThumbnail(from image: UIImage) {
    // Before
    let screenScale = UIScreen.main.scale

    // After
    let screenScale = traitCollection.displayScale
    // ...
}
```

### 상황 4 — UI를 화면 모서리에 맞추고 싶을 때

iOS 26에서 도입된 Concentricity API가 iPhone Duo의 화면 형태에 맞게 업데이트됐습니다.

```swift
// SwiftUI
ConcentricRectangle()
    .fill(Color.green)
    .padding(8.0)
    .ignoresSafeArea()

// UIKit
// UICornerConfiguration
```

### 상황 5 — 세이프 에어리어 처리

내비게이션 바, 툴바, 탭 바는 세이프 에어리어 **밖에** 놓이며, 상태 표시줄 같은 시스템 UI와 카메라 같은 하드웨어를 자동으로 피합니다. 가로 바는 상·하 여백을, 세로 바는 선행·후행 여백을 줍니다.

- **전경 요소**(상호작용 컨트롤, 읽혀야 하는 텍스트)는 세이프 에어리어 안에 둔다.
- **배경 요소**(전체 화면 아트워크)는 바·사이드바 뒤로 확장하게 둔다.

```swift
// 전경은 안으로
foreground.frame = view.bounds.inset(by: view.safeAreaInsets)

// 배경은 밖으로
// SwiftUI
.ignoresSafeArea()
// UIKit
backgroundView.frame = view.bounds
```

SwiftUI는 기본적으로 세이프 에어리어 안에 배치됩니다. UIKit에서 수동 레이아웃을 한다면 safe area layout guide나 layout margins에 맞추세요.

### 상황 6 — 양쪽 여백이 같다고 가정하는 코드

iPhone Duo에서 세이프 에어리어와 레이아웃 여백은 **비대칭이 기본**입니다. 가로 모드와 Split View에서는 세로 바가 왼쪽에 나타날 수도 있습니다.

```swift
// 피해야 할 패턴: 반대쪽 여백이 같다고 가정
let width = view.bounds.width - view.safeAreaInsets.left * 2

// 각 변을 독립적으로 처리
let width = view.bounds.inset(by: view.safeAreaInsets).width
```

### 상황 7 — 표준 컨테이너를 쓰고 있는지 점검

표준 탐색 패턴은 모든 포즈에 자동으로 적응합니다.

- `NavigationSplitView` / `UISplitViewController` — 닫히면 열이 접혀 단일 스택으로, 열리면 타일·오버레이로 표시
- `TabView` / `UITabBarController` — 탭이 상황에 따라 세로로 배열됨
- 시트, 팝오버, 컨텍스트 메뉴, 알림도 각 화면에 맞게 조정됨

내부 디스플레이에서는 탭 바를 사이드바로 올릴 수 있습니다. 정보 밀도가 높은 앱에 잘 맞습니다.

```swift
// SwiftUI
TabView { … }
    .defaultTabBarPlacement(.sidebar)

// UIKit
tabBarController.sidebar.preferredPlacement = .sidebar
```

> 출처: [Prepare your app for iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111461/) · 두 사이즈 클래스에만 집중하라는 지침은 [Design for iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111466/)

---

## 세로 바 — 바가 옆으로 간다

iPhone Duo는 화면이 더 넓고 낮습니다. 그래서 상·하단에 있던 컨트롤이 화면 옆으로 이동해 콘텐츠의 세로 공간을 비우고, 엄지에도 더 가까워집니다. 새 컴포넌트가 아니라 **같은 컴포넌트가 다른 축으로 배치되는 것**입니다.

### 어느 포즈에서 세로가 되나

| 포즈 | 바 방향 |
| --- | --- |
| 외부 디스플레이 (세로·가로) | 세로 |
| 내부 디스플레이 가로 | 세로 |
| 내부 디스플레이 세로 | 가로 (익숙한 iPhone 레이아웃으로 복귀) |

### 상황 1 — 재빌드했는데도 바가 가로로 남아 있다

내비게이션 컨테이너가 제공하는 바를 쓰고 있는지 확인하세요. 직접 만든 `UIToolbar`, `UINavigationBar`, `UITabBar`의 콘텐츠는 **고려되지 않습니다.**

```swift
// SwiftUI — toolbar 수정자를 내비게이션 컨테이너와 함께
var body: some View {
    NavigationStack {
        ContentView()
            .toolbar {
                ToolbarItem(placement: .bottomBar) { … }
            }
    }
}
```

```swift
// UIKit — 이러면 안 됩니다
let toolbar = UIToolbar()
toolbar.items = [...]

// 대신 뷰 컨트롤러에 toolbarItems를 설정하고
// UINavigationController / UITabBarController에 올린다
```

### 상황 2 — 여러 종류의 바가 같이 있다

iPhone Duo는 내비게이션·툴바·탭 바 컨트롤이 **하나의 공유 영역**에 공존합니다. 기존 바를 90도 돌려 세로 스택으로 쌓는다고 상상하면 됩니다. 레이아웃에 따라 툴바만, 탭 바만, 또는 둘 다 포함됩니다.

복잡한 레이아웃에서는 규칙이 좀 더 좁습니다.

- 툴바 항목은 컨테이너가 **디스플레이 가장자리에 붙어 있을 때만** 세로로 이동합니다.
- 스플릿 뷰에서는 detail 열만 참여합니다. 다른 열의 항목은 가로로 유지됩니다.
- detail 열에 이미 세로 바가 있으므로, 인스펙터를 펼쳐도 별도의 세로 바는 생기지 않습니다.

시트는 따로 알아두세요.

- 외부 디스플레이: 시트에 툴바가 있으면 세로로 표시됩니다.
- 내부 디스플레이: 기본적으로 중앙 정렬되고 항목은 가로로 유지됩니다.
- `preferredPlacement`로 위치를 바꾸면, 왼쪽 시트는 세로 바가 없고 오른쪽 시트는 세로 바가 생깁니다.

바는 하드웨어에 정렬되므로 RTL 언어 환경에서도 기기의 같은 쪽에 위치합니다. 바는 고정되고 콘텐츠가 바를 기준으로 조정됩니다.

### 상황 3 — 항목 순서 정리

세로로 표시되어도 상하 계층은 그대로입니다. 위쪽부터 순서를 맞추세요.

1. 주요 탐색 컨트롤 — 뒤로, 닫기
2. 눈에 띄는 동작 — 완료 등
3. 나머지 항목 — 원래 그룹 구조는 세로 스페이서로 구분된 채 유지됩니다

```swift
// 뒤로 / 닫기 버튼
// SwiftUI
.toolbar {
    ToolbarItem(placement: .cancellationAction) { … }
}

// UIKit — 내비게이션 컨트롤러를 쓰면 뒤로 버튼은 자동 추가됩니다
navigationItem.leftItemsSupplementBackButton = false
navigationItem.leadingItemGroups = [UIBarButtonItemGroup(...)]
```

```swift
// 눈에 띄는 주요 동작
// SwiftUI
.toolbar {
    ToolbarItem(placement: .topBarPinnedTrailing) { … }
}

// UIKit
navigationItem.pinnedTrailingGroup = UIBarButtonItemGroup(...)
```

모든 포즈에서 바가 세로가 되는 것은 아닙니다. 사용자가 기기를 열고 닫을 때마다 버튼 위치를 다시 익힐 필요가 없도록 컨트롤 배치를 일관되게 유지하세요.

> 출처: [Raise the bar with iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111462/) · 컨트롤이 측면으로 가는 이유는 [Design for iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111466/)

---

## 툴바 항목과 오버플로 관리

가로 바는 항목의 높이가 고정이고 너비가 유연합니다. 세로 바는 반대로 너비가 고정이고 높이가 유연합니다. 그래서 **아이콘 전용 항목**에 훨씬 유리합니다.

### 시스템이 표현을 고르는 기준

앱은 보통 항목에 아이콘과 제목 두 가지를 지정하고, 시스템이 상황에 맞는 표현을 고릅니다.

| 상황 | 표시 |
| --- | --- |
| 상·하단 바 | 아이콘 우선, 아이콘이 없으면 텍스트 |
| 오버플로 메뉴 | 제목 + 아이콘 둘 다 |
| 세로 바 | 아이콘이 있는 항목은 세로로, 텍스트만 있는 항목은 가로 유지 |

그러니 **항목에 제목과 이미지를 항상 둘 다 주세요.** 콘텐츠가 이미지여도 제목이 필요합니다 — 오버플로로 가거나 확장될 때 그 제목을 씁니다.

### 상황 1 — 기본 추론을 바꿔야 할 때: AxisBehavior

**심볼과 텍스트를 오가는 커스텀 항목**은 세로 바에 들어가면 안 됩니다. 시스템 Edit 버튼은 자동으로 가로에 남지만, 직접 만들었다면 명시해야 합니다.

```swift
// SwiftUI — 가로 바에 고정
.toolbar {
    ToolbarItem { SelectOrDoneButton() }
        .axisBehavior(.horizontalOnly)
}

// UIKit
item.axisBehavior = .horizontalOnly
```

반대로 UIKit 커스텀 뷰나 복잡한 뷰는 시스템이 기본적으로 가로로 유지합니다. 그 뷰가 세로 표현을 지원한다면 직접 허용해야 합니다.

```swift
// SwiftUI — 세로 바에 들어갈 수 있게
.toolbar {
    ToolbarItem { CompassView() }
        .axisBehavior(.verticalPreferred)
}

// UIKit
let item = UIBarButtonItem(customView: CompassView())
item.axisBehavior = .verticalPreferred
```

관련된 항목끼리는 반드시 같은 축에 두세요.

### 상황 2 — 항목에 텍스트가 붙어 있다

텍스트가 있으면 세로 바로 갈 수 없습니다. 이 질문으로 판단하세요. **"이 텍스트가 심볼을 보강하기만 하는가, 독립적인 정보를 전달하는가?"**

- 보강에 그친다 → 심볼만으로 바꿔 세로 바에 넣습니다.
- 의미 있는 정보다 (예: 장바구니 버튼의 금액) → 가로 바에 남깁니다.

개수 표시는 인라인 텍스트 대신 iOS 26에 추가된 배지 API를 쓰면 심볼 전용 항목이 됩니다.

```swift
// SwiftUI
.toolbar {
    ToolbarItem(...) {
        InboxButton().badge(7)
    }
}

// UIKit
let item = UIBarButtonItem(...)
item.badge = .count(7)
```

액세서리 바는 세로 축으로 옮기지 말고 키보드에 계속 붙여두세요.

### 상황 3 — 커스텀 뷰를 세로로 보낼 때

바의 고정 너비에 들어가거나, 세로용 레이아웃을 따로 갖춰야 합니다. `toolbarVerticalEdge`로 시점을 감지해 메트릭을 조정하세요. 이 값은 항목이 세로 축에 배치될 수 있을 때 설정되고, 그렇지 않으면 nil입니다.

```swift
// SwiftUI — 콘텐츠 뷰 안에서도, 항목의 커스텀 뷰 안에서도 읽을 수 있습니다
struct ContentView: View {
    @Environment(\.toolbarVerticalEdge) var edge

    var body: some View {
        switch edge { … }
    }
}

// UIKit
switch traitCollection.verticalBarEdge { … }
```

두 가지를 더 주의하세요.

- 세로 바도 기본적으로 스크롤 가장자리 효과가 없습니다. 단, '투명도 감소' 설정이 켜지면 배경이 생깁니다. 어느 쪽이든 커스텀 뷰의 가독성을 확보하세요.
- 유연한 스페이서는 세로 축에서 크기가 0입니다. 고정 스페이서는 최소 크기를 유지합니다. 앱에서 간격을 임의로 만들지 마세요.

### 상황 4 — 항목이 넘칠 때 무엇을 먼저 접을까

세로 공간은 좁습니다. 특히 가로 모드 외부 디스플레이, 키보드가 뜨거나 세로 모드에서 PiP를 쓸 때 오버플로가 자주 일어납니다.

- **탐색 중심 화면** → 툴바가 먼저 접혀 목적지 접근을 유지합니다. 기본값입니다.
- **작업 중심 화면** → 탭 바를 먼저 접어 자주 쓰는 동작을 남깁니다.

```swift
// SwiftUI
TabView {
    Tab("Recents", systemImage: "clock") {
        ContentView()
            .toolbarVerticalCompressionBehavior(.prefersToolbarItems)
    }
}

// UIKit
navigationItem.verticalBarCompressionBehavior = .prefersBarItems
```

### 상황 5 — 자체 오버플로 메뉴가 이미 있다

시스템이 관리하는 단일 메뉴로 합치세요.

```swift
// SwiftUI
.toolbar {
    ToolbarOverflowMenu {
        Button("Scan") { … }
        Button("Connect") { … }
    }
}

// UIKit
navigationItem.additionalOverflowItems = UIDeferredMenuElement({ provider in
    provider(self.persistentOverflowItems())
})
```

기존 메뉴를 전부 오버플로로 바꿀 필요는 없습니다. 줄임표(…)는 iPhone에서 오버플로 전용 기호입니다. 다른 메뉴에는 고유한 심볼을 주세요.

### 상황 6 — 무엇을 끝까지 보이게 할까

기본은 아래에서 위로 넘칩니다. 그룹 단위로 먼저 우선순위를 주고, 필요하면 그룹 안 항목에 주세요.

```swift
// SwiftUI
.toolbar {
    ToolbarItem { Button(...) { … } }
        .visibilityPriority(.high)
}

// UIKit
let item = UIBarButtonItem(...)
item.visibilityPriority = .high
```

메일의 '작성', 메모의 '새 메모'처럼 자주 쓰는 동작은 가장 나중에 접히게 하세요. 배지처럼 상태를 전달하는 컨트롤도 오래 남겨두어야 합니다.

### 상황 7 — 세로 바를 꺼야 하는 경우

대부분의 앱은 세로 바가 잘 맞습니다. 두 경우만 예외입니다.

- 계산기처럼 하단이 무거운 단일 페이지 앱 — 콘텐츠가 가로로 꽉 차게
- 닫기 버튼 하나뿐인 시트 — 공간을 줄이지 않게

```swift
// SwiftUI
NavigationStack {
    ContentView()
        .toolbarVerticalBehavior(.disabled)
}

// UIKit
class MyViewController: UIViewController {
    override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
        .disabled
    }
}
```

> 출처: [Raise the bar with iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111462/)

---

## 예약 영역 (Reserved Regions)

힌지와 두 대의 카메라가 사용 가능한 공간을 바꿉니다. 이걸 **예약 영역**이라고 부르며, iPadOS의 창 제어 요소처럼 레이아웃이 이미 적응하고 있는 다른 영역과 똑같이 다루면 됩니다.

| 종류 | 정체 | 동작 | 활성 조건 |
| --- | --- | --- | --- |
| `.division` | 힌지(접힘) | 한 영역을 여러 영역으로 **나눈다** | 사용자가 기기를 접었을 때만 |
| `.occlusion` | FaceTime 카메라 | 영역을 **가린다** (뷰 내부의 작은 프레임) | 카메라가 활성일 때 |

외부 디스플레이의 카메라는 항상 표시되며, 시스템 툴바와 탭 바는 이를 반영한 새 안전 영역 안에 세로로 배치됩니다. 표준 컨테이너만 써도 여기까지는 자동입니다.

### 상황 1 — 커스텀 레이아웃이 접힘을 가로질러 있다

힌지 영역을 직접 조회해 내 레이아웃에 반영합니다.

```swift
// SwiftUI — GeometryReader 또는 onGeometryChange
GeometryReader { proxy in
    let regions = proxy.reservedRegions(kind: .division)
    let frames = regions.map(\.frame)
    // ...
}
```

```swift
// UIKit
let regions = view.reservedRegions(kind: .division)

// frame을 조회해 자체 레이아웃에 반영
let frames = regions.map(\.frame)
```

### 상황 2 — 기기가 펼쳐져 있을 때도 구조를 맞춰두고 싶다

기본적으로는 **활성 영역만** 돌아옵니다. 펼쳐진 상태의 fold는 비활성이며 너비가 0입니다. `includeInactive`로 비활성 영역까지 조회하면 고수준 결정에 쓸 수 있습니다. 예를 들어 그리드 레이아웃에서 division 영역이 존재하기만 하면 열 수를 짝수로 유지하는 식입니다.

```swift
GeometryReader { proxy in
    let regions = proxy.reservedRegions(
        kind: .division, options: .includeInactive)

    let frames = regions.map(\.frame)
    // ...
}
```

### 상황 3 — 내부 카메라가 콘텐츠를 가린다

```swift
GeometryReader { proxy in
    let regions = proxy.reservedRegions(kind: .occlusion)

    let frames = regions.map(\.frame)
    // ...
}
```

뷰파인더가 경험의 핵심이라면, 중요한 콘텐츠와 컨트롤을 이 영역에서 멀리 배치하세요.

### 상황 4 — 안전 영역 밖까지 UI를 채우고 싶다

iOS 27.1에서 예약 영역은 반대 방향으로도 쓰입니다. 시스템 UI와 충돌하지 않으면서도 안전 영역 밖에 UI를 안전하게 놓아 가용 공간을 극대화할 수 있습니다. SwiftUI는 `ReservedRegion`, UIKit은 `UIViewReservedRegion`입니다. 커스텀 바를 만들거나 화면 가장자리까지 채우는 UI에 유용합니다.

수동으로 배치한 컨트롤 중 우선순위가 높은 것부터 찾아, 필요한 경우에만 예약 영역으로 자체 오프셋을 구현하세요. 표준 컨테이너로 해결되는 것을 굳이 직접 계산할 필요는 없습니다.

> 출처: [Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111463/) · 상황 4(안전 영역 밖 배치)는 [Prepare your app for iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111461/)

---

## ArrangementView — 두 뷰를 배열하는 새 컨테이너

iOS 27.1의 새 레이아웃 컨테이너입니다. 탐색 컨테이너(`NavigationStack`, `TabView`)와 콘텐츠 컨테이너(`List`, `ScrollView`) 사이에 위치하며, **주 뷰와 보조 뷰를 규칙에 따라 배치**합니다. 그 규칙을 배열(arrangement)이라고 부릅니다.

배열은 여러 입력을 보고 출력을 결정합니다. 입력은 가로·세로 사이즈 클래스, 너비와 높이의 종횡비, 활성 division 영역의 유무입니다. 출력은 각 뷰를 표시할지와 프레임 크기입니다.

### 기본 구성

```swift
// SwiftUI
var body: some View {
    NavigationStack {
        ArrangementView {
            PlayerView()
        } secondary: {
            UpNextView()
        }
    }
}
```

```swift
// UIKit
let arrangementVC = UIArrangementViewController()
let navController = UINavigationController(rootViewController: arrangementVC)

let playerVC = PlayerViewController()
arrangementVC.setViewController(playerVC, for: .primary)

let upNextVC = UpNextViewController()
arrangementVC.setViewController(upNextVC, for: .secondary)
```

### split — 나란히 놓기 (기본값)

주어진 경계를 주 뷰와 보조 뷰 사이에 나눕니다. 기본으로 너비 > 높이면 수평 분할, 회전해서 높이 > 너비가 되면 수직 분할합니다.

```swift
// SwiftUI
ArrangementView {
    PlayerView()
} secondary: {
    UpNextView()
}
.arrangementViewStyle(.split)
```

항상 수평으로만 나누고 싶다면 축을 제한합니다.

```swift
// SwiftUI
.arrangementViewStyle(.split.axes(.horizontal))

// UIKit
arrangementVC.updateArrangement(.split.axes(.horizontal))
```

분할할 수 없는 축이 주 축이면 배열 뷰는 **단일 뷰만** 표시합니다. 높이가 너비보다 큰 상황에서 수평만 허용했다면 `PlayerView`만 남는 식입니다.

### overlay — 위아래로 겹치기

```swift
// SwiftUI — 주/보조를 바꿔 건네도 됩니다
ArrangementView {
    UpNextView()
} secondary: {
    PlayerView()
}
.arrangementViewStyle(.overlay)
```

기기를 접으면 overlay 배열은 두 뷰를 나란히 놓으려 합니다. 이때 여유가 생기므로 뷰의 접힘/펼침 상태를 전환하면 좋습니다. Z 인덱스로 감지합니다.

```swift
// SwiftUI
enum UpNextMinimization { case collapsed; case expanded }

struct UpNextView: View {
    @Environment(\.overlayArrangementZIndex)
    private var zIndex: Int

    var body: some View {
        UpNextList(minimization: minimization)
    }

    var minimization: UpNextMinimization {
        zIndex > 0 ? .collapsed : .expanded
    }
}
```

```swift
// UIKit
let primaryState = arrangementVC.state(for: .primary)
myModel.minimization = (primaryState?.zIndex ?? 0) > 0
    ? .collapsed : .expanded
```

### 어느 쪽을 고를까

순서대로 판단하세요.

1. **기존 앱의 패턴을 따릅니다.** 이미 `HStack`/`VStack`으로 분할형 레이아웃을 만들고 있다면 split, `ZStack`으로 겹치고 있다면 overlay입니다. 이 컴포넌트들은 각 배열로 자연스럽게 전환됩니다.
2. **명확한 전경/배경 관계** → overlay. 예: 접근성 리더 — 컨트롤이 전경, 읽는 콘텐츠가 배경. 읽는 콘텐츠는 스크롤로 해결되므로 가끔 가려도 괜찮습니다.
3. **주 콘텐츠–세부 정보 관계** → split. 예: 팟캐스트의 '재생 중'과 대본 — 둘 중 어느 쪽도 가려지면 안 됩니다.

### 쓰지 말아야 할 곳

- `ArrangementView`는 탐색 인프라를 제공하지 **않습니다.** `NavigationSplitView` 같은 탐색 컨테이너를 `ArrangementView` 안에 넣지 마세요.
- `List`나 `ScrollView` 같은 스크롤 컨테이너 안에 `ArrangementView`를 넣지 마세요.

> 출처: [Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111463/)

---

## 힌지, 멀티태스킹, 씬 액세서리

### 힌지에 반응하는 인터랙션

배경화면이 힌지 각도에 따라 줌되는 것처럼, 앱도 힌지에 반응할 수 있습니다. SwiftUI는 `onHingeChange` 수정자, UIKit은 `UIHingeInteraction`을 제공합니다. 둘 다 고수준 상태(닫힘·부분적으로 열림·완전히 열림)와 연속적인 각도 업데이트를 줍니다.

힌지 데이터는 실시간입니다. **인터랙션과 효과용이며, 레이아웃 구성에는 쓰지 마세요.** 레이아웃은 arrangement와 reserved region API의 일입니다.

```swift
struct InstrumentView: View {
    /// Normalized bend, 0 is no bend, 1 is deepest bend
    @State private var pitchBend: Double = 0

    var body: some View {
        GuitarView(pitchBend: pitchBend)
            .onHingeChange { _, context in
                // context.hinge가 nil이면 힌지가 없는 기기입니다
                if let hinge = context.hinge, hinge.status == .partiallyOpen {
                    pitchBend = calculatePitchBend(angle: hinge.angle)
                }
                else {
                    pitchBend = 0
                }
            }
    }

    private func calculatePitchBend(angle: Angle) -> Double { ... }
}
```

클로저는 이전 컨텍스트와 현재 컨텍스트를 받습니다. 힌지를 읽지 않는 상태로 넘어갈 때 값을 되돌리는 else 처리를 빼먹지 마세요.

### 스플릿 뷰 멀티태스킹

모든 앱이 iPhone Duo의 멀티태스킹에 참여합니다. 두 가지 레이아웃이 있지만 앱 입장에서는 둘 다 동일하게 처리합니다.

- 두 앱을 50/50으로 나란히 배치
- 동영상 PiP를 화면 상단에 고정하고 앱이 남은 공간에 맞춤 — 기기를 접으면 동영상이 절반을 채우도록 확장되므로, 앱은 다양한 높이에 실시간으로 적응해야 합니다

iPad 크기 조정이나 iPhone 미러링을 이미 지원한다면 사실상 준비가 된 상태입니다.

### 여러 씬 — 외부 디스플레이에서는 새 창을 못 만듭니다

iPhone Duo는 앱 UI의 여러 인스턴스를 지원하는 최초의 iPhone입니다. iPad에서 지원하면 여기서도 동작합니다. 다만 **새 창 생성은 내부 디스플레이에서만 가능**하고, 외부 디스플레이에서는 불가능합니다. iPad와 다른 점입니다.

새 씬을 요청할 때 오류가 나지 않도록 처리하세요. 사용할 수 없을 때 자동으로 숨겨지는 `UIWindowSceneActivationAction`을 쓰면 가장 간단합니다.

### 씬 액세서리 — 두 디스플레이에 동시에 표시하기

씬 액세서리는 앱의 메인 UI에 추가 콘텐츠를 연동해 다른 디스플레이에 보여줍니다. iPhone Duo에서는 `CameraCaptureAccessory`가 새로 추가됐습니다. 메인 UI는 내부 디스플레이에 두고, 외부 디스플레이에 별도 UI를 띄우는 식입니다. 촬영 중인 상대방에게 화면을 보여주는 용도입니다.

사용 조건은 앱이 **내부 디스플레이에서 전체 화면으로 실행 중**이고 **활성 카메라 세션이 있을 때**입니다. 카메라 UI와 동일한 뷰에 등록하세요.

```swift
struct CameraRootView: View {
    @State private var model = TeleprompterModel()

    var body: some View {
        CameraView(model: model)
            .sceneAccessory {
                CameraCaptureAccessory(isEnabled: $model.isEnabled) {
                    TeleprompterView(model: model)
                }
                .onAvailabilityChange { newValue in
                    model.isAvailable = newValue
                }
            }
            .toolbar {
                TeleprompterToggle(isEnabled: $model.isEnabled)
                    .disabled(!model.isAvailable)
            }
    }
}
```

사용 가능 여부는 시스템이 동적으로 제어합니다. 기본은 활성이지만 언제든 꺼질 수 있으므로(예: 기기를 닫았을 때), `onAvailabilityChange`로 관찰해 관련 컨트롤을 비활성화하세요. 앱이 직접 켜고 끌 때는 `isEnabled`를 씁니다.

> 출처: [Leverage multiple displays and scenes on iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111464/)

---

## 카메라

iPhone Duo는 전면 카메라가 둘인 최초의 iPhone입니다. 둘 다 초광각 정사각형 센서이고, 내부 카메라는 iPhone 최초의 디스플레이 내 카메라입니다.

| 카메라 | 디바이스 타입 | 능력 |
| --- | --- | --- |
| 외부 전면 | `.builtInOuterUltraWideCamera` | 최대 4K, 120fps |
| 내부 전면 | `.builtInInnerUltraWideCamera` | 1080p, 최대 60fps |
| 가상 전면 | discovery session으로 발견 | 두 카메라의 공통 기능만 — 최대 1080p, 60fps |

깊이(depth) 기능은 **개별 카메라에 접근할 때만** 지원됩니다.

### 상황 1 — 그냥 셀카가 동작하면 된다

가상 전면 카메라를 쓰세요. 다른 iPhone과 똑같이 `AVCaptureDeviceDiscoverySession`으로 `position: .front` + Wide/Ultra Wide 타입을 요청하면 새 가상 전면 카메라가 발견됩니다. 펼치면 내부 카메라, 접으면 외부 카메라로 **자동 전환**됩니다. 추가 작업이 없습니다.

### 상황 2 — 4K나 깊이가 필요해 개별 카메라를 쓴다

이제 열고 닫을 때의 카메라 전환을 앱이 직접 처리해야 합니다. `AVCaptureDeviceDirectionCoordinator`(AVKit)를 쓰세요.

문제의 본질은 `AVCaptureDevice.position`이 **고정 속성**이라는 점입니다. 내·외부 전면 카메라 모두 `.front`이지만, 두 디스플레이가 서로 반대를 볼 수 있어서 "front가 항상 사용자를 향하지는 않습니다". 내부 디스플레이를 보면서 외부 전면 카메라로 스트리밍하면 그 카메라는 사용자를 등지고 있고, 펼친 채 기기를 뒤집으면 **후면 카메라로 셀카를 찍게** 됩니다.

코디네이터는 "지금 어떤 카메라가 사용자 쪽인지"를 뷰 기준으로 알려주고, 바뀔 때마다 갱신합니다.

```swift
directionCoordinator = AVCaptureDeviceDirectionCoordinator(
    view: view,
    deviceTypes: [
        .builtInOuterUltraWideCamera,
        .builtInInnerUltraWideCamera,
        .builtInDualWideCamera,
    ],
    changeHandler: { [weak self] map in
        self?.updateCameraSession(map)
    }
)
```

changeHandler에서 할 일은 세 가지입니다.

1. 전면으로 바뀐 카메라로 계속 스트리밍되도록 `AVCaptureSession`을 재구성합니다.
2. 미러링을 다시 판단합니다. 후면 카메라가 사용자를 향할 때는 미러링해야 자연스러운 셀카가 됩니다.
3. UI를 갱신합니다.

주의할 점이 있습니다. 코디네이터는 뷰에 묶여 있어 **main actor 전용**이므로, changeHandler 안에서 AVFoundation API를 직접 호출하면 안 됩니다. 코디네이터는 `AVCaptureDevice` 대신 Sendable한 `AVCaptureDeviceDescriptor`를 줍니다. 이걸 카메라 액터로 안전하게 넘긴 뒤에 AVFoundation을 쓰세요.

### 상황 3 — 두 디스플레이를 동시에 쓴다

아이 사진을 찍으면서 외부 화면으로 재미있는 걸 보여주는 식입니다. 디스플레이당 UIView가 따로 생기므로 **각 뷰마다 별도의 코디네이터를 만드세요.** 각 코디네이터는 자기 뷰를 기준으로 위치를 보고합니다 — 같은 후면 카메라를 외부 코디네이터는 전면으로, 내부 코디네이터는 후면으로 보고합니다. 화면 분배는 씬 액세서리로 합니다.

### 상황 4 — 내부 디스플레이에서 미리보기 주변에 여백이 생긴다

후면 카메라 전체 시야각을 쓰면 남는 공간이 생깁니다. 미리보기를 한쪽으로 오프셋하고 남은 공간에 컨트롤을 모으거나, 미리보기를 화면 전체로 채우거나 — 앱에 맞는 쪽을 고르면 됩니다.

```swift
// 레이어 경계 안에서 미리보기가 놓이는 방식
previewLayer.videoGravity = .resizeAspectFill

// 내부 디스플레이용 가로 화면비 선택
let ratio = device.dynamicAspectRatio
```

### 상황 5 — 회전과 성능

회전 코디네이터를 도입하세요. 앱이 디스플레이를 전환할 때 코디네이터가 갱신되어 미리보기와 사진이 항상 올바른 방향으로 유지됩니다. 도입한 뒤에는 센서 방향 보정을 꺼 성능을 개선하세요. 이 보정은 iPhone Duo의 모든 전면 카메라에서 기본 활성화되어 있습니다.

```swift
// 회전 코디네이터를 쓰고 있다면 끌 수 있습니다
photoOutput.isCameraSensorOrientationCompensationEnabled = false
```

> 출처: [Build a great camera experience for iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111465/)

---

## 디자인 원칙 — 어디에 무엇을 둘까

사용자는 iPhone Duo를 여러 자세로 씁니다. 책처럼 부분적으로 접기도 하고, 노트북처럼 테이블에 올려두기도 하고, 가장자리로 세우기도 합니다. 그런데 **자세별로 맞춤 레이아웃을 그릴 필요는 없습니다.** 크기 조절이 자유로운 디자인이면 잘 동작합니다.

### 측면 공간에 들어가는 것

탭 바, 앱 툴바, 뒤로 가기 같은 탐색 컨트롤, 재설계된 상태 표시줄, 그리고 실시간 현황이 오면 세로로 확장되는 Dynamic Island가 이 공간을 나눠 씁니다. 공간이 부족하면 앱 컨트롤은 자동으로 오버플로 메뉴로 접힙니다.

매핑은 단순합니다. 상단 툴바 버튼은 세로 공간의 위로, 하단 툴바 버튼은 아래로, 탭 바는 하단 정렬을 유지합니다. 단 **텍스트 버튼이나 세그먼트 컨트롤처럼 너무 넓은 항목은 내비게이션 바에 그대로 남습니다.**

### 외부 디스플레이 — 중앙 정렬을 다시 생각하기

대부분의 콘텐츠는 컨트롤에 가려지지 않도록 오프셋이 필요합니다. 가로 세이프 영역 여백에 맞춰 정렬되어 있다면 자동으로 적용됩니다. 세 가지 접근이 있습니다.

| 접근 | 언제 |
| --- | --- |
| 세이프 영역에 맞춰 오프셋 | 대부분의 콘텐츠 |
| 전체 화면 중앙 정렬 유지 | 스크롤 없는 몰입형·시각적 인터페이스. 단 상호작용 요소가 오른쪽 컨트롤에 가리지 않을 때만 |
| 혼합 | 전체 너비 배경·헤더 + 인셋된 스크롤 전경. 상호작용 요소는 전부 스크롤 영역 안에 |

### 내부 디스플레이 — 늘어난 iPhone 앱이 되지 않기

- **스플릿 뷰**로 앱 계층의 여러 수준을 동시에 보여줍니다.
- **두 열 레이아웃**으로 재구성합니다. 세로로 쌓던 것을 가로 공간이 넓어지면 두 열로 (음악 앱 방식).
- **탭 바를 사이드바로** 올립니다. 정보 밀도가 높은 앱에 맞습니다 (건강 앱 방식).

지켜야 할 선이 하나 있습니다. **내부와 외부의 계층 구조가 달라지면 안 됩니다.** 사용자는 앱을 쓰는 동안 기기를 수시로 열고 닫으므로, 기능을 특정 화면 모드에 묶지 마세요.

### 접힘 회피 (fold avoidance)

버튼이 접힌 부분에 정확히 놓이면 탭하기 어렵습니다. 그래서 기기가 부분적으로 접히면 시스템이 상호작용 요소를 옆으로 밀어냅니다. 시트, 알림, 메뉴, 툴바 버튼에 내장되어 있으니 **같은 동작을 원하면 시스템 컴포넌트를 쓰세요.** 스크롤 가능한 콘텐츠는 이 영역을 피할 필요가 없습니다.

### 변위(displacement) 패턴 — 무엇을 어디로 옮길까

요소를 접힘에 맞춰 옮길 때의 규칙입니다.

- **범위**: 독립적으로 적응 가능하면 그 요소만, 서로 연동되면 함께 옮깁니다. 예를 들어 사진과 컨텍스트 메뉴는 함께 움직여 접힘선 기준으로 정렬합니다.
- **과하게 옮기지 않기**: 원래 위치에서 멀어질수록 시각적 관계가 약해집니다.
- **옮기지 않는 것**: 기사, 피드, 문서, 목록처럼 연속 스크롤되는 콘텐츠. 이미 스크롤로 적응하므로 영역 간 이동은 연속성을 깹니다.

어디로 옮길지는 **목적**으로 정하고, 목적은 기기 사용 방식에 따라 달라집니다.

| 자세 | 배치 |
| --- | --- |
| 책처럼 부분 접힘 | 알림 같은 요소는 뒤쪽 영역으로 — 기기를 닫으면 외부 디스플레이에서 이어지므로 |
| 테이블에 세워둠 | 상단은 멀리서도 보이는 콘텐츠(알림), 하단은 탭 가능한 컨트롤(미디어 컨트롤) |
| 여러 영역이 다 적합 | 맥락에 맞는 배치 우선 — 검색은 키보드 위에 |

시스템이 알아서 하는 것도 많습니다. 액션 시트·알림·메뉴·팝오버는 완전히 보이도록 자동 재배치되고, 분할 화면 앱은 두 열 너비를 50/50으로 맞춥니다. 그리드라면 힌지 주변 간격을 넓히면서 바깥 여백은 유지해 각 항목을 한 영역 안에 두세요.

### 시트 동작

| 상황 | 동작 |
| --- | --- |
| 외부 디스플레이 | 시트 컨트롤도 측면으로 이동 |
| 외부 + 세로 막대 비활성화 | 컨트롤이 그대로. 시트가 전면 카메라 바로 앞까지 올라오고 상태 표시줄 위치가 조정됨. 툴바 버튼이 하나뿐인 시트에 효과적 |
| 내부 디스플레이 | 가로·세로 모두 표준 가로 막대 |
| 부분 접힘 | 접힌 부분에 닿지 않도록 옆으로 밀림 |

### 핸즈프리 자세용 선택 레이아웃

테이블에 세워두고 쓰는 상황을 위해 상단에 미디어, 하단 안정적인 면에 탭 가능한 컨트롤을 두는 레이아웃은 고려해볼 만합니다. 단 다른 자세와 **동일한 컨트롤과 계층 구조**를 갖게 하세요. 기능을 특정 자세에 묶으면 안 됩니다.

> 출처: [Design for iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111466/) · 변위 패턴과 예약 영역 대응은 [Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111463/)

---

## 적용 체크리스트

위에서부터 순서대로 내려가면 됩니다. 앞의 네 개만 해도 앱은 iPhone Duo에서 제대로 동작합니다.

- [ ] iOS 27.1 SDK(Xcode 27.1)로 재빌드한다
- [ ] Device Hub의 iPhone Duo 시뮬레이터에서 열기·닫기·회전·접기 모두 확인한다
- [ ] Split View 멀티태스킹을 **양쪽** 모두 테스트한다
- [ ] Xcode의 App Resizability 기능을 돌려 적응형 레이아웃 문제를 점검한다
- [ ] 고정 너비·브레이크포인트를 사이즈 클래스로 바꾼다
- [ ] 인터페이스 방향·idiom으로 레이아웃을 분기하는 코드를 제거한다
- [ ] `UIScreen.main` 참조를 없애거나 `windowScene.screen` / `traitCollection.displayScale`로 바꾼다
- [ ] 양쪽 세이프 에어리어 인셋이 같다고 가정한 계산을 각 변 독립 처리로 고친다
- [ ] 커스텀 `UIToolbar`/`UITabBar`/`UINavigationBar` 대신 내비게이션 컨테이너가 관리하는 바를 쓴다
- [ ] 모든 툴바 항목에 제목과 이미지를 둘 다 지정한다
- [ ] 심볼↔텍스트를 오가는 커스텀 항목에 `.horizontalOnly`를 준다
- [ ] 세로 표현이 가능한 커스텀 뷰에 `.verticalPreferred`를 준다
- [ ] 인라인 개수 텍스트를 배지 API로 바꾼다
- [ ] 화면별로 압축 동작(툴바 먼저 vs 탭 바 먼저)을 지정한다
- [ ] 자체 오버플로 메뉴를 시스템 메뉴로 합치고, 줄임표를 오버플로 전용으로 단일화한다
- [ ] 항목별 `visibilityPriority`를 지정한다
- [ ] 중앙 정렬 레이아웃을 점검해 2열로 바꿀지, 변위를 적용할지 정한다
- [ ] 수동 배치한 고우선순위 컨트롤에 ReservedRegions로 자체 오프셋을 넣는다
- [ ] 커스텀 가로 분할·오버레이 레이아웃을 `ArrangementView`로 옮긴다
- [ ] 새 씬 요청이 외부 디스플레이에서 실패해도 오류가 안 나도록 처리한다
- [ ] (카메라 앱) 가상 전면 카메라로 충분한지, 방향 코디네이터까지 필요한지 정한다
- [ ] (선택) 힌지 API로 앱만의 인터랙션을 더한다

> 출처: 아래 여섯 편 전체

---

## 참고 영상

Apple Tech Talks 전문과 샘플 코드를 근거로 정리했습니다.

| 영상 | 다룬 내용 |
| --- | --- |
| [Prepare your app for iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111461/) | SDK 단계별 동작, 사이즈 클래스, 세이프 에어리어, 표준 컨테이너 |
| [Design for iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111466/) | 디자인 원칙, 컨트롤 배치, 내·외부 디스플레이, 시트, 접힘 회피 |
| [Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111463/) | 예약 영역, 변위 패턴, ArrangementView |
| [Leverage multiple displays and scenes on iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111464/) | 힌지 API, 멀티태스킹, 여러 씬, 씬 액세서리 |
| [Raise the bar with iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111462/) | 세로 바, 툴바 항목 축, 오버플로 우선순위 |
| [Build a great camera experience for iPhone Duo](https://developer.apple.com/kr/videos/play/tech-talks/111465/) | 전면 카메라 둘, 방향 코디네이터, 미리보기 |

함께 언급된 자료

- WWDC26 — Modernize Your UIKit App (유연한 레이아웃 원칙, App Resizability의 전신)
- WWDC26 — What's new in SwiftUI (`visibilityPriority`)
- WWDC25 — 바 디자인 업데이트와 항목 그룹화
- WWDC26 — iOS 앱에서 Center Stage 전면 카메라 지원하기 (정사각 센서)
- Apple Developer 문서 — "카메라가 향하는 방향에 따라 카메라 선택하기", "카메라 앱에서 기기 회전 지원"
