import SwiftUI

/// 가이드의 "프리뷰 세트" — environment만 바꾸면 컨테이너 크기는 그대로라 frame도 같이 준다.
struct ShapePreview<Content: View>: View {
    let shape: LayoutShape
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack { content }
            .measureLayoutContext()
            .environment(\.horizontalSizeClass, shape.prefersSingleColumn ? .compact : .regular)
            .environment(\.verticalSizeClass, shape == .compactShort || shape == .regularShort ? .compact : .regular)
            .frame(width: size.width, height: size.height)
    }

    private var size: CGSize {
        switch shape {
        case .compactTall: CGSize(width: 390, height: 844)
        case .compactShort: CGSize(width: 844, height: 390)
        case .regularShort: CGSize(width: 932, height: 430)
        case .regularTall: CGSize(width: 820, height: 1180)
        case .regularWide: CGSize(width: 1180, height: 820)
        }
    }
}
