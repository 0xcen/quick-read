import SwiftUI
import HotKey

@main
struct QuickReadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var overlayController: OverlayWindowController?
    var hotKey: HotKey?
    var resumeHotKey: HotKey?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupGlobalHotkey()
        
        // Hide dock icon - menu bar only app
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: "QuickRead")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: MenuBarView(
            onStartReading: { [weak self] in self?.startReading() },
            onResumeReading: { [weak self] session in self?.resumeReading(session: session) }
        ))
    }
    
    private func setupGlobalHotkey() {
        // Cmd + Shift + R - Start reading from current browser tab
        hotKey = HotKey(key: .r, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.startReading()
        }
        
        // Cmd + Shift + E - Resume last read
        resumeHotKey = HotKey(key: .e, modifiers: [.command, .shift])
        resumeHotKey?.keyDownHandler = { [weak self] in
            self?.resumeLastRead()
        }
    }
    
    func resumeLastRead() {
        popover?.performClose(nil)
        
        guard let lastSession = HistoryStore.shared.lastSession, !lastSession.isComplete else {
            // No session to resume, show error
            let alert = NSAlert()
            alert.messageText = "Nothing to Resume"
            alert.informativeText = "No unfinished reading session found."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        
        resumeReading(session: lastSession)
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func startReading() {
        popover?.performClose(nil)
        
        Task {
            do {
                // Get URL from frontmost browser
                let url = try await BrowserBridge.getActiveTabURL()
                
                // Check if it's a JS-heavy site that won't parse well
                let jsHeavySites = ["x.com", "twitter.com", "facebook.com", "instagram.com", "threads.net"]
                let isJSHeavy = jsHeavySites.contains(where: { url.host?.contains($0) == true })
                
                if isJSHeavy {
                    // Try clipboard first for JS-heavy sites
                    if let clipboardContent = await MainActor.run(body: { getClipboardText() }),
                       !clipboardContent.isEmpty,
                       clipboardContent.split(separator: " ").count > 5 {
                        let content = ArticleContent(
                            url: url,
                            title: "From \(url.host ?? "clipboard")",
                            text: clipboardContent
                        )
                        await MainActor.run {
                            showOverlay(with: content)
                        }
                        return
                    }
                    
                    // Show helpful message for X/Twitter
                    await MainActor.run {
                        showJSHeavySiteHelp(siteName: url.host ?? "this site")
                    }
                    return
                }
                
                // Fetch and parse content
                let content = try await ReadabilityParser.parse(url: url)
                
                // Show overlay
                await MainActor.run {
                    showOverlay(with: content)
                }
            } catch {
                // If parsing fails, try clipboard as fallback
                if let clipboardContent = await MainActor.run(body: { getClipboardText() }),
                   !clipboardContent.isEmpty,
                   clipboardContent.split(separator: " ").count > 5 {
                    let content = ArticleContent(
                        url: URL(string: "clipboard://")!,
                        title: "From Clipboard",
                        text: clipboardContent
                    )
                    await MainActor.run {
                        showOverlay(with: content)
                    }
                    return
                }
                
                await MainActor.run {
                    showError(error)
                }
            }
        }
    }
    
    private func getClipboardText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
    
    private func showJSHeavySiteHelp(siteName: String) {
        let alert = NSAlert()
        alert.messageText = "Copy Text First"
        alert.informativeText = "\(siteName) loads content dynamically. Please select and copy (⌘C) the text you want to read, then trigger QuickRead again."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func resumeReading(session: ReadingSession) {
        popover?.performClose(nil)
        showOverlay(with: session.content, startingAt: session.wordIndex)
    }
    
    private func showOverlay(with content: ArticleContent, startingAt wordIndex: Int = 0) {
        if overlayController == nil {
            overlayController = OverlayWindowController()
        }
        overlayController?.show(content: content, startingAt: wordIndex)
    }
    
    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "QuickRead Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
