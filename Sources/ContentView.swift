import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsModel
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var library: VideoLibrary

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

            GroupBox("Library") {
                LibraryView()
            }

            GroupBox("Wallpaper selection") {
                VStack(alignment: .leading, spacing: 10) {
                    if settings.mode == .sameForAll {
                        SameForAllPicker()
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

// MARK: - Library View

private struct LibraryView: View {
    @EnvironmentObject private var library: VideoLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if library.videos.isEmpty {
                Text("No videos in library. Add some below.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(library.videos) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.name)
                                        .lineLimit(1)
                                    Text(entry.filename)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    library.remove(id: entry.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 2)
                            .padding(.trailing, 14)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 120)
            }

            Button("Add video…") {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = false
                panel.canChooseFiles = true
                panel.allowsMultipleSelection = true
                panel.allowedContentTypes = [.movie]
                guard panel.runModal() == .OK else { return }
                library.importVideos(from: panel.urls)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Same-for-all picker

private struct SameForAllPicker: View {
    @EnvironmentObject private var settings: SettingsModel
    @EnvironmentObject private var library: VideoLibrary

    var body: some View {
        if library.videos.isEmpty {
            Text("Add videos to your library first.")
                .foregroundStyle(.secondary)
        } else {
            Picker("Video", selection: $settings.sameVideoPath) {
                Text("None").tag("")
                ForEach(library.videos) { entry in
                    Text(entry.name).tag(library.path(for: entry))
                }
            }
        }
    }
}

// MARK: - Per-display picker

private struct DisplayPickerView: View {
    @EnvironmentObject private var settings: SettingsModel
    @EnvironmentObject private var library: VideoLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(settings.knownDisplays, id: \.id) { display in
                DisplayRow(display: display)
            }

            if settings.knownDisplays.isEmpty {
                Text("No displays detected yet.")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { settings.refreshDisplays() }
    }
}

private struct DisplayRow: View {
    let display: SettingsModel.DisplayInfo
    @EnvironmentObject private var settings: SettingsModel
    @EnvironmentObject private var library: VideoLibrary

    private var binding: Binding<String> {
        Binding(
            get: { settings.perDisplayVideoPath[display.id] ?? "" },
            set: { settings.perDisplayVideoPath[display.id] = $0 }
        )
    }

    var body: some View {
        HStack {
            Text(display.name)
            Spacer()
            Picker("", selection: binding) {
                Text("None").tag("")
                ForEach(library.videos) { entry in
                    Text(entry.name).tag(library.path(for: entry))
                }
            }
            .frame(maxWidth: 200)
        }
    }
}
