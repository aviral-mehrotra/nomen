import SwiftUI

struct SettingsView: View {
    @State private var watchFolderPath: String = AppServices.shared.watchFolderURL?.path ?? "Not set"
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @AppStorage("defaultTagsInput") private var defaultTagsInput: String = ""
    @AppStorage("autoDismissSeconds") private var autoDismissSeconds: Int = 120

    var body: some View {
        Form {
            Section("Watch Folder") {
                HStack(alignment: .firstTextBaseline) {
                    Text(watchFolderPath)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Change…") {
                        changeWatchFolder()
                    }
                }
                Text("Nomen prompts you to name new screenshots saved to this folder.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Behavior") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLogin.setEnabled(newValue)
                    }

                HStack {
                    Text("Auto-dismiss after")
                    Spacer()
                    Stepper(value: $autoDismissSeconds, in: 30...600, step: 30) {
                        Text("\(autoDismissSeconds)s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Default Tags") {
                TextField("e.g. screenshot, work", text: $defaultTagsInput)
                Text("Applied automatically to every named screenshot. Comma-separated.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 380)
    }

    private func changeWatchFolder() {
        if let url = AppServices.shared.watchFolderAccess.promptForFolder() {
            watchFolderPath = url.path
            AppServices.shared.startWatching(at: url)
        }
    }
}
