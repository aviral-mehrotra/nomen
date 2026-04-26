import ServiceManagement
import os

enum LaunchAtLogin {
    private static let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "LaunchAtLogin")

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            log.error("Toggle launch-at-login failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
