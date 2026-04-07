import Foundation
import AppKit
import CoreGraphics

struct DisplayDescriptor: Hashable {
    let id: String
    let name: String
    let frame: CGRect
}

final class DisplayManager {
    func start() {
        // v1: polling via screen-parameter notifications handled by AppModel.
    }

    func stop() { }

    func currentDisplays() -> [DisplayDescriptor] {
        NSScreen.screens.map { screen in
            let did = DisplayManager.displayID(for: screen)
            return DisplayDescriptor(
                id: String(did),
                name: screen.localizedName,
                frame: screen.frame
            )
        }
    }

    static func displayID(for screen: NSScreen) -> CGDirectDisplayID {
        let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        return CGDirectDisplayID(num?.uint32Value ?? 0)
    }

    // Note: `NSScreen.localizedName` is used for user-visible names.
}

