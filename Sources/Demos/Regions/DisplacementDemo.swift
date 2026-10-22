import SwiftUI

struct DisplacementDemo: View {
    @State private var simulateFold = false

    var body: some View {
        GeometryReader { proxy in
            let fold = activeFold(in: proxy)
            ZStack(alignment: .topLeading) {
                if let fold {
                    Rectangle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: max(fold.width, 4), height: max(fold.height, 4))
                        .offset(x: fold.minX, y: fold.minY)
                }
                content(fold: fold, size: proxy.size)
            }
            .animation(.snappy, value: fold)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $simulateFold) {
                    Label("접힘 시뮬레이션", systemImage: "book")
                }
            }
        }
    }

    @ViewBuilder
    private func content(fold: CGRect?, size: CGSize) -> some View {
        let status = fold == nil ? "접힘 없음 — 중앙 배치" : (isVertical(fold!) ? "세로 접힘(책) — 뒤쪽 영역으로" : "가로 접힘(테이블) — 위: 미디어 / 아래: 컨트롤")
        VStack(spacing: 0) {
            Text(status)
                .font(.caption.weight(.semibold))
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)

            if let fold, !isVertical(fold) {
                // 테이블에 세운 자세: 위는 멀리서 보는 콘텐츠, 아래는 탭할 컨트롤
                PhotoCard()
                    .frame(maxWidth: .infinity, maxHeight: max(fold.minY - 40, 80))
                    .padding()
                Spacer().frame(height: fold.height + 16)
                MediaControls().padding()
                Spacer()
            } else if let fold {
                // 책 자세: 사진과 메뉴는 연동되어 있으니 함께 뒤쪽(trailing) 영역으로, 접힘선에 붙여 정렬
                HStack(alignment: .top, spacing: 0) {
                    FeedList()
                        .frame(width: fold.minX)
                    Spacer().frame(width: fold.width + 16)
                    VStack(alignment: .leading, spacing: 12) {
                        PhotoCard().frame(height: 220)
                        ContextActions()
                        MediaControls()
                    }
                    .padding(.trailing)
                    .padding(.top)
                }
            } else {
                VStack(spacing: 12) {
                    PhotoCard().frame(maxWidth: 420).frame(height: 220)
                    ContextActions()
                    MediaControls()
                }
                .padding()
                .frame(maxWidth: .infinity)
                FeedList()
            }
        }
    }

    private func activeFold(in proxy: GeometryProxy) -> CGRect? {
        if let real = proxy.reservedRegions(kind: .division).first?.frame { return real }
        guard simulateFold else { return nil }
        let s = proxy.size
        return s.width > s.height
            ? CGRect(x: s.width / 2 - 10, y: 0, width: 20, height: s.height)
            : CGRect(x: 0, y: s.height / 2 - 10, width: s.width, height: 20)
    }

    private func isVertical(_ rect: CGRect) -> Bool { rect.height >= rect.width }
}

private struct PhotoCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.white))
    }
}

private struct ContextActions: View {
    var body: some View {
        HStack {
            Button("좋아요", systemImage: "heart") {}
            Button("공유", systemImage: "square.and.arrow.up") {}
            Button("저장", systemImage: "bookmark") {}
        }
        .buttonStyle(.bordered)
    }
}

private struct MediaControls: View {
    var body: some View {
        HStack(spacing: 28) {
            Image(systemName: "backward.fill")
            Image(systemName: "play.fill").font(.title)
            Image(systemName: "forward.fill")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.fill.tertiary, in: .capsule)
    }
}

/// 연속 스크롤 콘텐츠는 옮기지 않는다 — 이미 스크롤로 적응한다.
private struct FeedList: View {
    var body: some View {
        List(0..<30, id: \.self) { i in
            Text("피드 항목 \(i + 1) · 스크롤 콘텐츠는 접힘선을 피하지 않습니다")
                .font(.footnote)
        }
        .listStyle(.plain)
    }
}
