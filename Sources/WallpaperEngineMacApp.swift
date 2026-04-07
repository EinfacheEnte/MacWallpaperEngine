import SwiftUI

@main
struct WallpaperEngineMacApp: App {
    @StateObject private var settings = SettingsModel()
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(appModel)
                .frame(minWidth: 540, minHeight: 380)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

