import SwiftUI

@main
struct NomenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Empty scene — the menu bar app owns its own windows. SwiftUI requires at
        // least one Scene; this one is intentionally never rendered.
        Settings { EmptyView() }
    }
}
