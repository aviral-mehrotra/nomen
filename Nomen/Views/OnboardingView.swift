import AppKit
import SwiftUI

struct OnboardingView: View {
    let onFinished: () -> Void

    enum Step: Int, CaseIterable {
        case welcome
        case folder
        case optimize
        case ready
    }

    @State private var step: Step = .welcome
    @State private var folderURL: URL? = AppServices.shared.watchFolderURL
    @State private var showsFloatingThumbnail: Bool = ScreencaptureDefaults.showsFloatingThumbnail

    /// If the user already has the floating-thumbnail toggle off (or it's been
    /// disabled since launch), skip the optimize step entirely.
    private var visibleSteps: [Step] {
        showsFloatingThumbnail
            ? Step.allCases
            : [.welcome, .folder, .ready]
    }

    private var currentIndex: Int {
        visibleSteps.firstIndex(of: step) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                content
                    .padding(.horizontal, 36)
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            footer
        }
        .frame(width: 560, height: 580)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 14) {
            captureMark
                .frame(width: 22, height: 22)
                .foregroundStyle(.primary)

            Text("Set up Nomen")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            ProgressDots(current: currentIndex, total: visibleSteps.count)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var captureMark: some View {
        Canvas { ctx, size in
            let scale = size.width / 24
            let r: CGFloat = 1.2 * scale
            var path = Path()
            // Top-left
            path.move(to: CGPoint(x: 4 * scale, y: 9 * scale))
            path.addArc(tangent1End: CGPoint(x: 4 * scale, y: 4 * scale),
                        tangent2End: CGPoint(x: 9 * scale, y: 4 * scale),
                        radius: r)
            path.addLine(to: CGPoint(x: 9 * scale, y: 4 * scale))
            // Top-right
            path.move(to: CGPoint(x: 15 * scale, y: 4 * scale))
            path.addArc(tangent1End: CGPoint(x: 20 * scale, y: 4 * scale),
                        tangent2End: CGPoint(x: 20 * scale, y: 9 * scale),
                        radius: r)
            path.addLine(to: CGPoint(x: 20 * scale, y: 9 * scale))
            // Bottom-left
            path.move(to: CGPoint(x: 4 * scale, y: 15 * scale))
            path.addArc(tangent1End: CGPoint(x: 4 * scale, y: 20 * scale),
                        tangent2End: CGPoint(x: 9 * scale, y: 20 * scale),
                        radius: r)
            path.addLine(to: CGPoint(x: 9 * scale, y: 20 * scale))
            // Bottom-right
            path.move(to: CGPoint(x: 15 * scale, y: 20 * scale))
            path.addArc(tangent1End: CGPoint(x: 20 * scale, y: 20 * scale),
                        tangent2End: CGPoint(x: 20 * scale, y: 15 * scale),
                        radius: r)
            path.addLine(to: CGPoint(x: 20 * scale, y: 15 * scale))

            ctx.stroke(path, with: .color(.primary), style: .init(lineWidth: 2.0, lineCap: .round, lineJoin: .round))

            // Center dot
            let dotR: CGFloat = 1.7 * scale
            ctx.fill(
                Path(ellipseIn: CGRect(x: 12 * scale - dotR, y: 12 * scale - dotR, width: dotR * 2, height: dotR * 2)),
                with: .color(.primary)
            )
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            welcomeStep
        case .folder:
            folderStep
        case .optimize:
            optimizeStep
        case .ready:
            readyStep
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepEyebrow("Welcome")
            stepTitle("Set up Nomen.")
            stepBody("This will take about a minute. We'll grant Nomen permission to watch your screenshot folder, optionally tune one macOS setting for instant prompts, and get you ready to go.")

            calloutCard(icon: "internaldrive", title: "Is Nomen in your Applications folder?") {
                Text("If you opened the disk image and double-clicked Nomen without dragging it into Applications first, drag it there now from the disk image window. Then click Continue below.")
            }
        }
    }

    private var folderStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepEyebrow("Step 1 of \(visibleSteps.count - 1)")
            stepTitle("Choose your screenshot folder.")
            stepBody("Nomen needs to watch the **same folder where macOS saves your screenshots** — otherwise it won't see them when they land.")

            if let detected = ScreencaptureDefaults.location {
                detailRow(label: "macOS is currently saving to", value: detected.path)
            }

            calloutCard(icon: "exclamationmark.circle", title: "Pick the folder shown above") {
                Text("Your screenshot **save folder** and Nomen's **watch folder** must match. If you pick a different folder in the dialog, Nomen won't see your screenshots and the prompt won't appear.")
            }

            if let granted = folderURL {
                successRow(text: "Granted: \(granted.path)")
            }

            Text("If you change the screenshot save location later, open Nomen Settings and update the watch folder to match.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }

    private var optimizeStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepEyebrow("Step 2 of \(visibleSteps.count - 1) — optional")
            stepTitle("Get instant prompts.")
            stepBody("macOS holds new screenshots in the floating thumbnail (bottom-right of your screen) for ~5 seconds before writing the file to disk. That delay is what makes Nomen's prompt feel slow on first try. To get sub-second prompts, do the following:")

            instructionList([
                "Click the button below to open Screenshot.",
                "In the toolbar near the bottom of your screen, click **Options**.",
                "Uncheck **Show Floating Thumbnail** in the menu that appears."
            ])

            HStack(spacing: 10) {
                Button {
                    let url = URL(fileURLWithPath: "/System/Applications/Utilities/Screenshot.app")
                    NSWorkspace.shared.open(url)
                } label: {
                    Label("Open Screenshot", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Text("Or skip this step — Nomen still works either way.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepEyebrow("All set")
            stepTitle("You're ready.")
            stepBody("Take a screenshot with **⌘ + ⇧ + 4** or **⌘ + ⇧ + 5** and Nomen will pop up to name it. Press **Esc** any time to skip without renaming.")

            calloutCard(icon: "menubar.rectangle", title: "Nomen lives in your menu bar") {
                Text("Click the small Nomen mark up there to see your recent renamed screenshots, change settings, pause detection, or quit.")
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            if currentIndex > 0 {
                Button("Back") {
                    step = visibleSteps[currentIndex - 1]
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: handlePrimary) {
                Text(primaryButtonTitle)
                    .frame(minWidth: 120)
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .disabled(primaryDisabled)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var primaryButtonTitle: String {
        switch step {
        case .welcome:
            return "Continue"
        case .folder:
            return folderURL == nil ? "Choose Folder…" : "Continue"
        case .optimize:
            return "Continue"
        case .ready:
            return "Start using Nomen"
        }
    }

    private var primaryDisabled: Bool { false }

    private func handlePrimary() {
        switch step {
        case .welcome:
            advance()
        case .folder:
            if folderURL == nil {
                if let picked = AppServices.shared.watchFolderAccess.promptForFolder() {
                    AppServices.shared.startWatching(at: picked)
                    folderURL = picked
                }
                // If user cancelled the dialog, stay on this step.
            } else {
                advance()
            }
        case .optimize:
            advance()
        case .ready:
            onFinished()
        }
    }

    private func advance() {
        if currentIndex + 1 < visibleSteps.count {
            step = visibleSteps[currentIndex + 1]
        }
    }

    // MARK: Reusable bits

    private func stepEyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)
            .tracking(1)
    }

    private func stepTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(.primary)
    }

    private func stepBody(_ text: String) -> some View {
        Text(LocalizedStringKey(text))
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.tertiary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func successRow(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }

    private func calloutCard<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                content()
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.tertiary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func instructionList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 18, alignment: .leading)
                    Text(LocalizedStringKey(line))
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
