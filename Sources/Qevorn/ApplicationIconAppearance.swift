import AppKit
import SwiftUI

/// Keeps the Dock icon legible by following the app's current macOS appearance.
struct ApplicationIconAppearance: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear(perform: updateApplicationIcon)
            .onChange(of: colorScheme) { _, _ in
                updateApplicationIcon()
            }
    }

    private func updateApplicationIcon() {
        let variant = colorScheme == .dark ? "dark" : "light"
        guard
            let iconURL = Bundle.main.url(
                forResource: "qevorn-\(variant)",
                withExtension: "png",
                subdirectory: "Branding"
            ),
            let icon = NSImage(contentsOf: iconURL)
        else {
            return
        }

        NSApplication.shared.applicationIconImage = icon
    }
}
