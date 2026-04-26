import AppKit
import os

@MainActor
final class MenuBarController {
    private let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "MenuBar")
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var pauseItem: NSMenuItem?
    private var recentItem: NSMenuItem?
    private var paused = false

    var onSummonTestPanel: (() -> Void)?
    var onTogglePause: ((Bool) -> Void)?
    var onOpenWatchFolder: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureStatusItem()
        buildMenu()
        statusItem.menu = menu
        log.notice("Menu bar item attached")
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NomenIcon.menuBarIcon()
        button.toolTip = "Nomen"
    }

    private func buildMenu() {
        menu.removeAllItems()

        let pauseItem = NSMenuItem(title: pauseTitle(), action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)
        self.pauseItem = pauseItem

        menu.addItem(.separator())

        let recentItem = NSMenuItem(title: "Recent", action: nil, keyEquivalent: "")
        recentItem.submenu = makeEmptyRecentSubmenu()
        menu.addItem(recentItem)
        self.recentItem = recentItem

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let openFolderItem = NSMenuItem(
            title: "Open Watch Folder",
            action: #selector(openWatchFolder),
            keyEquivalent: ""
        )
        openFolderItem.target = self
        menu.addItem(openFolderItem)

        menu.addItem(.separator())

        #if DEBUG
        let summonItem = NSMenuItem(
            title: "Summon Test Panel",
            action: #selector(summonTestPanel),
            keyEquivalent: ""
        )
        summonItem.target = self
        menu.addItem(summonItem)
        menu.addItem(.separator())
        #endif

        let quitItem = NSMenuItem(
            title: "Quit Nomen",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func pauseTitle() -> String {
        paused ? "Resume" : "Pause"
    }

    @objc private func togglePause() {
        paused.toggle()
        pauseItem?.title = pauseTitle()
        onTogglePause?(paused)
    }

    @objc private func summonTestPanel() {
        onSummonTestPanel?()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func openWatchFolder() {
        onOpenWatchFolder?()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func revealInFinder(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    private func makeEmptyRecentSubmenu() -> NSMenu {
        let submenu = NSMenu()
        let item = NSMenuItem(
            title: "No recent screenshots — take one with ⌘⇧4",
            action: nil,
            keyEquivalent: ""
        )
        item.isEnabled = false
        submenu.addItem(item)
        return submenu
    }

    func updateRecent(entries: [HistoryEntry]) {
        guard let recentItem else { return }
        let toShow = Array(entries.prefix(10))
        if toShow.isEmpty {
            recentItem.submenu = makeEmptyRecentSubmenu()
            return
        }
        let submenu = NSMenu()
        for entry in toShow {
            let item = NSMenuItem(title: entry.newName, action: #selector(revealInFinder(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = entry.path
            item.toolTip = entry.tags.isEmpty ? nil : "Tags: \(entry.tags.joined(separator: ", "))"
            submenu.addItem(item)
        }
        recentItem.submenu = submenu
    }
}
