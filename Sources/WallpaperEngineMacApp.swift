import SwiftUI
import AppKit

@main
struct WallpaperEngineMacApp: App {
    @StateObject private var settings = SettingsModel()
    @StateObject private var appModel = AppModel()
    @StateObject private var library = VideoLibrary()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window("Settings", id: "settings") {
            ContentView()
                .environmentObject(settings)
                .environmentObject(appModel)
                .environmentObject(library)
                .frame(minWidth: 540, minHeight: 480)
        }
        .defaultSize(width: 640, height: 520)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        MenuBarExtra("MacWallpaperEngine", systemImage: "sparkles") {
            VStack(alignment: .leading, spacing: 8) {
                Button(appModel.isRunning ? "Stop wallpaper" : "Start wallpaper") {
                    if appModel.isRunning {
                        appModel.stop()
                    } else {
                        appModel.start(using: settings)
                    }
                }

                Button("Apply settings") {
                    appModel.apply(using: settings)
                }
                .disabled(!appModel.isRunning)

                Divider()

                Button("Open settings…") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                }

                Divider()

                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { newValue in
                        LoginItemManager.setEnabled(newValue)
                    }

                Divider()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
