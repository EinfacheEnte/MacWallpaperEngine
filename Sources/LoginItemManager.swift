import Foundation
import ServiceManagement

enum LoginItemManager {
    static func setEnabled(_ enabled: Bool) {
        if enabled {
            do {
                try SMAppService.mainApp.register()
            } catch {
                NSLog("Failed to enable launch at login: %@", String(describing: error))
            }
        } else {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                NSLog("Failed to disable launch at login: %@", String(describing: error))
            }
        }
    }
}

