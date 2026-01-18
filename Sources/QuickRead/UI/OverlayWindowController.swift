import SwiftUI
import AppKit

class OverlayWindowController {
    private var window: NSWindow?
    private var readerState: ReaderState?
    
    func show(content: ArticleContent, startingAt wordIndex: Int = 0) {
        // Create state
        let state = ReaderState(content: content, startingAt: wordIndex)
        self.readerState = state
        
        // Create window if needed
        if window == nil {
            window = createOverlayWindow()
        }
        
        // Set content
        let readerView = ReaderView(state: state) { [weak self] in
            self?.dismiss()
        }
        window?.contentView = NSHostingView(rootView: readerView)
        
        // Show window - starts in ready state, user presses space to begin
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func dismiss() {
        // Save position to history
        if let state = readerState {
            HistoryStore.shared.saveSession(state.createSession())
        }
        
        window?.orderOut(nil)
        readerState?.stop()
        readerState = nil
    }
    
    private func createOverlayWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Cover all screens
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true)
        }
        
        return window
    }
}
