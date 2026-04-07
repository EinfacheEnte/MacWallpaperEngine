import SwiftUI
import AppKit

@main
struct WallpaperEngineMacApp: App {
    @StateObject private var settings = SettingsModel()
    @StateObject private var appModel = AppModel()
    @State private var settingsWindowController: NSWindowController?

    var body: some Scene {
        WindowGroup("Settings") {
            ContentView()
                .environmentObject(settings)
                .environmentObject(appModel)
                .frame(minWidth: 540, minHeight: 380)
        }
        .defaultSize(width: 640, height: 420)
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

                Button("Choose video (same for all)…") {
                    settings.chooseSameVideo()
                }

                Button("Open settings…") {
                    openSettingsWindow()
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

    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        // SwiftUI WindowGroup will already exist; just bring app forward.
        // If user closed the window, macOS typically recreates it via Window menu or dock icon.
        // Keeping this minimal for v1 menubar mode.
    }
}

