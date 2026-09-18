import SwiftUI

@main
struct QevornApp: App {
    var body: some Scene {
        WindowGroup("qevorn") {
            StudioView()
                .background {
                    ApplicationIconAppearance()
                }
        }
        .defaultSize(width: 1440, height: 920)
        .windowResizability(.contentMinSize)
    }
}
