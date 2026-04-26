import AppKit
import SwiftUI

struct OnboardingView: View {
    let onFinished: () -> Void

    @State private var grantedURL: URL? = AppServices.shared.watchFolderURL
    @State private var detectedFolder: URL? = ScreencaptureDefaults.location
    @State private var showsFloatingThumbnail: Bool = ScreencaptureDefaults.showsFloatingThumbnail

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tint)

            Text("Welcome to Nomen")
                .font(.title)

            Text("Nomen prompts you to name every screenshot the moment it lands in your screenshot folder, so you can find it later.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 420)

            if grantedURL == nil {
                if let detectedFolder {
                    Label("macOS is currently saving to: \(detectedFolder.path)", systemImage: "folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }

                if showsFloatingThumbnail {
                    floatingThumbnailTip
                }

                Button(action: chooseFolder) {
                    Text("Choose Screenshot Folder")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            } else {
                readyPanel
                Button(action: onFinished) {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 480)
    }

    @ViewBuilder
    private var floatingThumbnailTip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("For instant prompts", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("macOS holds your screenshot in a floating thumbnail (bottom-right corner) until it times out — the file isn't written to disk until then, which delays Nomen's prompt by ~5 seconds. To get sub-second prompts, turn this off. Optional — Nomen still works either way.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Click the button below, then in the Screenshot toolbar select **Options** and uncheck **Show Floating Thumbnail**.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: openScreenshotApp) {
                Label("Open Screenshot to change this", systemImage: "arrow.up.forward.app")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.tertiary, in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var readyPanel: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("You're all set!")
                .font(.title3.weight(.semibold))
            if let path = grantedURL?.path {
                Text("Watching \(path)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.center)
            }
            Text("Take a screenshot with ⌘⇧4 and Nomen will prompt you to name it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func chooseFolder() {
        if let picked = AppServices.shared.watchFolderAccess.promptForFolder() {
            AppServices.shared.startWatching(at: picked)
            grantedURL = picked
        }
    }

    private func openScreenshotApp() {
        // Screenshot.app is the host for the ⌘⇧5 capture HUD where the Show
        // Floating Thumbnail toggle lives, under its Options menu.
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Screenshot.app")
        NSWorkspace.shared.open(url)
    }
}
