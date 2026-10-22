import Foundation

struct MetricsSnapshot: Equatable {
    struct Row: Equatable, Identifiable {
        let key: String
        let value: String
        var warn = false
        var id: String { key }
    }

    struct Section: Equatable, Identifiable {
        let title: String
        var rows: [Row]
        var id: String { title }
    }

    /// 변경 로그에서 비교하는 핵심 값. 바뀌면 한 줄이 쌓인다.
    struct Key: Equatable {
        var shape = ""
        var sizeClass = ""
        var size = ""
        var safeArea = ""
        var verticalBarEdge = ""
        var fold = ""
        var hinge = ""
        var screen = ""

        func changes(from old: Key) -> [String] {
            let pairs: [(String, String, String)] = [
                ("shape", old.shape, shape),
                ("class", old.sizeClass, sizeClass),
                ("size", old.size, size),
                ("safe", old.safeArea, safeArea),
                ("vbar", old.verticalBarEdge, verticalBarEdge),
                ("fold", old.fold, fold),
                ("hinge", old.hinge, hinge),
                ("screen", old.screen, screen),
            ]
            return pairs.compactMap { name, a, b in a == b ? nil : "\(name): \(a) → \(b)" }
        }
    }

    var sections: [Section] = []
    var key = Key()
    var badge = "–"

    var plainText: String {
        sections.map { section in
            "[\(section.title)]\n" + section.rows.map { "  \($0.key): \($0.value)\($0.warn ? "  ⚠︎" : "")" }.joined(separator: "\n")
        }
        .joined(separator: "\n")
    }
}

struct ChangeLogEntry: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let changes: [String]
}
