import SwiftUI

enum LayoutShape: String, CaseIterable, Equatable, Sendable {
    case compactTall    // C x R — 아이폰 세로, Duo 외부 세로, 슬라이드 오버
    case compactShort   // C x C — 아이폰 가로(일반), Duo 외부 가로
    case regularShort   // R x C — 아이폰 Plus/Max 가로, 낮고 넓은 창
    case regularTall    // R x R, 세로가 김 — 아이패드 세로, Duo 내부 세로
    case regularWide    // R x R, 가로가 김 — 아이패드 가로, Duo 내부 가로, 맥

    init(h: UserInterfaceSizeClass?, v: UserInterfaceSizeClass?, isWide: Bool) {
        let hCompact = h == .compact
        let vCompact = v == .compact
        switch (hCompact, vCompact) {
        case (true, false): self = .compactTall
        case (true, true): self = .compactShort
        case (false, true): self = .regularShort
        case (false, false): self = isWide ? .regularWide : .regularTall
        }
    }

    var prefersSingleColumn: Bool {
        self == .compactTall || self == .compactShort
    }

    enum Presentation: String, Sendable { case stack, split, expanded }

    var presentation: Presentation {
        switch self {
        case .compactTall, .compactShort: .stack
        case .regularShort, .regularTall: .split
        case .regularWide: .expanded
        }
    }

    var sizeClassLabel: String {
        switch self {
        case .compactTall: "C × R"
        case .compactShort: "C × C"
        case .regularShort: "R × C"
        case .regularTall: "R × R · 세로"
        case .regularWide: "R × R · 가로"
        }
    }

    var examples: String {
        switch self {
        case .compactTall: "아이폰 세로 · Duo 외부 세로 · 슬라이드 오버 · Duo 스플릿뷰"
        case .compactShort: "아이폰 가로(일반) · Duo 외부 가로"
        case .regularShort: "아이폰 Plus·Max 가로 · 낮고 넓은 창"
        case .regularTall: "아이패드 세로 · Duo 내부 세로"
        case .regularWide: "아이패드 가로 · Duo 내부 가로 · 맥 창"
        }
    }
}

extension UserInterfaceSizeClass? {
    var shortLabel: String {
        switch self {
        case .compact: "C"
        case .regular: "R"
        default: "?"
        }
    }
}
