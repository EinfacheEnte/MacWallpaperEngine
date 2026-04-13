import Foundation
import AppKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isRunning: Bool = false

    private let wallpaperController = WallpaperWindowController()
    private let displayManager = DisplayManager()
    private var activityToken: NSObjectProtocol?

    private var screenParamsObserver: Any?
    private var sleepObserver: Any?
    private var wakeObserver: Any?
    private var activeSpaceObserver: Any?
    private var didBecomeActiveObserver: Any?
    private var didResignActiveObserver: Any?

    func start(using settings: SettingsModel) {
        if isRunning {
            apply(using: settings)
            return
        }
        isRunning = true

        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Playing live wallpaper video"
        )

        displayManager.start()
        wallpaperController.apply(settings: settings, displays: displayManager.currentDisplays())

        if screenParamsObserver == nil {
            screenParamsObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    guard self.isRunning else { return }
                    self.wallpaperController.apply(settings: settings, displays: self.displayManager.currentDisplays())
                }
            }
        }

        if sleepObserver == nil {
            sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    guard self.isRunning else { return }
                    self.wallpaperController.pauseAll()
                }
            }
        }

        if wakeObserver == nil {
            wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    guard self.isRunning else { return }
                    self.wallpaperController.resumeAll()
                }
            }
        }

        if activeSpaceObserver == nil {
            activeSpaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    guard self.isRunning else { return }
                    self.wallpaperController.resumeAll()
                }
            }
        }

        if didBecomeActiveObserver == nil {
            didBecomeActiveObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    guard self.isRunning else { return }
                    self.wallpaperController.resumeAll()
                }
            }
        }

        if didResignActiveObserver == nil {
            didResignActiveObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    guard self.isRunning else { return }
                    self.wallpaperController.bringAllToFront()
                }
            }
        }
    }

    func apply(using settings: SettingsModel) {
        guard isRunning else { return }
        wallpaperController.apply(settings: settings, displays: displayManager.currentDisplays())
        wallpaperController.resumeAll()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        wallpaperController.stop()
        displayManager.stop()
        removeObservers()
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }
    }

    private func removeObservers() {
        if let o = screenParamsObserver {
            NotificationCenter.default.removeObserver(o)
            screenParamsObserver = nil
        }
        if let o = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(o)
            sleepObserver = nil
        }
        if let o = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(o)
            wakeObserver = nil
        }
        if let o = activeSpaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(o)
            activeSpaceObserver = nil
        }
        if let o = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(o)
            didBecomeActiveObserver = nil
        }
        if let o = didResignActiveObserver {
            NotificationCenter.default.removeObserver(o)
            didResignActiveObserver = nil
        }
    }
}
