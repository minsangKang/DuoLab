import SwiftUI

struct ConcentricDemo: View {
    var body: some View {
        DemoPage(intro: "ConcentricRectangle은 컨테이너(여기선 기기 화면) 모서리와 동심원을 이루는 곡률을 자동으로 계산합니다. Duo의 내·외부 화면 형태에 맞게 업데이트됐습니다.") {
            Card(title: "카드 안에서") {
                ConcentricRectangle()
                    .fill(Color.green.gradient)
                    .frame(height: 120)
                    .containerShape(.rect(cornerRadius: 24))
            }
            FullScreenLauncher(label: "화면 모서리에 맞춰 보기") {
                ConcentricFullScreen()
            }
        }
    }
}

private struct ConcentricFullScreen: View {
    var body: some View {
        ZStack {
            ConcentricRectangle().fill(Color.green.opacity(0.35)).padding(8)
            ConcentricRectangle().fill(Color.green.opacity(0.5)).padding(24)
            ConcentricRectangle().fill(Color.green.opacity(0.7)).padding(48)
        }
        .ignoresSafeArea()
        .overlay(alignment: .center) {
            Text("세 겹 모두 기기 모서리와 동심원").font(.headline).foregroundStyle(.white)
        }
        .overlay(alignment: .topTrailing) { CloseOverlayButton() }
    }
}
