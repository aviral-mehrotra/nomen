import AppKit
import SwiftUI
import os

@MainActor
final class PanelController {
    private let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "Panel")
    private let renamer = FileRenamer()
    private let tagger = FinderTagger()
    private let tagStore = TagStore()
    private var queue: [Screenshot] = []
    private var currentPanel: PromptPanel?
    private var currentViewModel: RenamePromptViewModel?

    func enqueue(_ screenshot: Screenshot) {
        queue.append(screenshot)
        log.notice("Enqueued \(screenshot.originalFilename, privacy: .public); queue depth \(self.queue.count)")
        if currentPanel == nil {
            showNext()
        }
    }

    private func showNext() {
        guard !queue.isEmpty else { return }
        let screenshot = queue.removeFirst()
        present(screenshot)
    }

    private func present(_ screenshot: Screenshot) {
        let viewModel = RenamePromptViewModel(
            screenshot: screenshot,
            renamer: renamer,
            tagger: tagger,
            tagStore: tagStore,
            history: AppServices.shared.history
        ) { [weak self] in
            self?.dismiss()
        }
        currentViewModel = viewModel

        let hostingController = NSHostingController(rootView: RenamePromptView(viewModel: viewModel))
        let fittingSize = hostingController.sizeThatFits(in: NSSize(width: 480, height: 1000))
        let panelSize = NSSize(width: 480, height: fittingSize.height)

        let panel = PromptPanel(contentRect: NSRect(origin: .zero, size: panelSize))
        panel.contentViewController = hostingController
        panel.setContentSize(panelSize)

        positionPanel(panel)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
        }
        currentPanel = panel
        log.notice("Presenting panel for \(screenshot.originalFilename, privacy: .public) size=\(panelSize.width)x\(panelSize.height)")
    }

    private func positionPanel(_ panel: PromptPanel) {
        let mouse = NSEvent.mouseLocation
        let chosen = NSScreen.screens.first { NSPointInRect(mouse, $0.frame) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let screen = chosen else { return }

        let visible = screen.visibleFrame
        let panelFrame = panel.frame
        let x = visible.origin.x + (visible.width - panelFrame.width) / 2.0
        let yCenter = visible.origin.y + (visible.height - panelFrame.height) / 2.0
        let y = yCenter + visible.height * 0.05
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func dismiss() {
        let panelToClose = currentPanel
        currentPanel = nil
        currentViewModel = nil
        log.notice("Panel dismissed")
        if let panelToClose {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.12
                ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panelToClose.animator().alphaValue = 0
            }, completionHandler: {
                panelToClose.close()
            })
        }
        showNext()
    }

    /// Manually summon a panel — used for development verification before FSEvents wiring.
    func summonTestPanel() {
        let fakeURL = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Downloads/Screenshot test.png")
        enqueue(Screenshot(url: fakeURL, createdAt: Date()))
    }
}
