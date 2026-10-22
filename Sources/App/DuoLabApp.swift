import SwiftUI

@main
struct DuoLabApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .measureLayoutContext()
                .installDebugOverlay()
        }

        WindowGroup("보조 창", id: SecondaryWindowView.id) {
            SecondaryWindowView()
                .measureLayoutContext()
                .installDebugOverlay()
        }
        .handlesExternalEvents(matching: [SecondaryWindowView.id])
    }
}
