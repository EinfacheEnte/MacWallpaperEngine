import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsModel
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Live Video Wallpaper")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: settings.launchAtLogin) { newValue in
                        LoginItemManager.setEnabled(newValue)
                    }
            }

            Picker("Mode", selection: $settings.mode) {
                Text("Same video on all displays").tag(SettingsModel.Mode.sameForAll)
                Text("Different video per display").tag(SettingsModel.Mode.perDisplay)
            }
            .pickerStyle(.segmented)

            Picker("Scale", selection: $settings.scaleMode) {
                Text("Fill").tag(SettingsModel.ScaleMode.fill)
                Text("Fit").tag(SettingsModel.ScaleMode.fit)
            }
            .pickerStyle(.segmented)

            GroupBox("Video selection") {
                VStack(alignment: .leading, spacing: 10) {
                    if settings.mode == .sameForAll {
                        HStack {
                            Text(settings.sameVideoPath.isEmpty ? "No video selected" : settings.sameVideoPath)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(settings.sameVideoPath.isEmpty ? .secondary : .primary)
                            Spacer()
                            Button("Choose…") { settings.chooseSameVideo() }
                        }
                    } else {
                        DisplayPickerView()
                    }
                }
                .padding(.vertical, 4)
            }

            HStack {
                Button(appModel.isRunning ? "Stop" : "Start") {
                    if appModel.isRunning {
                        appModel.stop()
                    } else {
                        appModel.start(using: settings)
                    }
                }
                .keyboardShortcut(.defaultAction)

                Button("Apply") {
                    appModel.apply(using: settings)
                }
                .disabled(!appModel.isRunning)

                Spacer()

                Text(appModel.isRunning ? "Running" : "Stopped")
                    .foregroundStyle(appModel.isRunning ? .green : .secondary)
            }
        }
        .padding(18)
    }
}

private struct DisplayPickerView: View {
    @EnvironmentObject private var settings: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(settings.knownDisplays, id: \.id) { display in
                HStack {
                    Text(display.name)
                    Spacer()
                    Text(settings.videoPath(forDisplayID: display.id).isEmpty ? "No video" : "Selected")
                        .foregroundStyle(.secondary)
                    Button("Choose…") { settings.chooseVideo(forDisplayID: display.id) }
                }
            }

            if settings.knownDisplays.isEmpty {
                Text("No displays detected yet.")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { settings.refreshDisplays() }
    }
}

