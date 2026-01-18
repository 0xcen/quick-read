import SwiftUI

struct ReaderView: View {
    @ObservedObject var state: ReaderState
    let onDismiss: () -> Void
    
    @State private var showControls: Bool = true
    @State private var controlsTimer: Timer?
    @State private var eventMonitor: Any?
    @State private var mouseMonitor: Any?
    @State private var cursorHidden: Bool = false
    
    var body: some View {
        ZStack {
            // Frosted glass background
            VisualEffectBlur(material: .fullScreenUI, blendingMode: .behindWindow)
            
            // Dark tint overlay - controlled by settings
            Color.black.opacity(AppSettings.shared.overlayDarkness)
            
            // Content
            VStack(spacing: 0) {
                if state.isReady {
                    readyView
                } else if state.showCountdown {
                    countdownView
                } else {
                    readerContent
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startControlsTimer()
            setupKeyboardHandling()
            setupMouseHandling()
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
            if let monitor = mouseMonitor {
                NSEvent.removeMonitor(monitor)
                mouseMonitor = nil
            }
            showCursor()
        }
    }
    
    // MARK: - Ready View (Title centered, waiting to start)
    
    private var readyView: some View {
        VStack(spacing: 0) {
            // Title at top
            Text(state.content.title)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 40)
                .padding(.top, 60)
            
            Spacer()
            
            // Center: Press Space to start
            VStack(spacing: 16) {
                Text("Press Space to start")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                
                // Word count and time estimate
                Text("\(state.totalWords) words \u{2022} \(state.timeRemaining)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Spacer()
            
            // WPM selector at bottom
            VStack(spacing: 12) {
                Text("Reading Speed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                
                HStack(spacing: 12) {
                    ForEach([300, 400, 500, 600, 700], id: \.self) { wpm in
                        Button {
                            state.wpm = wpm
                        } label: {
                            Text("\(wpm)")
                                .font(.system(size: 13, weight: state.wpm == wpm ? .bold : .medium, design: .monospaced))
                                .foregroundStyle(state.wpm == wpm ? .white : .white.opacity(0.5))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(state.wpm == wpm ? .white.opacity(0.2) : .white.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Countdown View
    
    private var countdownView: some View {
        VStack {
            // Title at top during countdown
            Text(state.content.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
                .padding(.top, 60)
            
            Spacer()
            
            Text(countdownText)
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: state.countdownValue)
            
            Spacer()
        }
    }
    
    private var countdownText: String {
        guard let value = state.countdownValue else { return "" }
        return value == 0 ? "GO" : "\(value)"
    }
    
    // MARK: - Reader Content
    
    private var readerContent: some View {
        VStack(spacing: 0) {
            // Title
            titleBar
                .padding(.top, 60)
            
            Spacer()
            
            // Word display
            wordDisplay
            
            Spacer()
            
            // Progress and controls
            bottomBar
                .padding(.bottom, 60)
        }
        .padding(.horizontal, 80)
    }
    
    private var titleBar: some View {
        Text(state.content.title)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
            .lineLimit(1)
            .opacity(showControls ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: showControls)
    }
    
    private var wordDisplay: some View {
        // ORP word display
        ORPWordView(word: state.currentWord, orpIndex: state.orpIndex)
            .overlay(alignment: .bottom) {
                // Pause indicator - positioned below word without affecting layout
                if !state.isPlaying && !state.showCountdown {
                    Text("PAUSED")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.1))
                        )
                        .offset(y: 60)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: state.isPlaying)
    }
    
    private var bottomBar: some View {
        VStack(spacing: 20) {
            // Progress bar
            progressBar
            
            // Stats
            HStack(spacing: 32) {
                Text("\(state.wpm) WPM")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                
                Text(state.timeRemaining)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                
                Text("\(Int(state.progress * 100))%")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(.white.opacity(0.5))
            
            // Keyboard hints - fade only, no movement
            keyboardHints
                .opacity(showControls ? 1 : 0)
        }
        .opacity(showControls ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: showControls)
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(.white.opacity(0.15))
                
                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geometry.size.width * state.progress))
            }
        }
        .frame(height: 4)
        .frame(maxWidth: 500)
    }
    
    private var keyboardHints: some View {
        HStack(spacing: 24) {
            keyHint("Space", "play/pause")
            keyHint("←→", "skip")
            keyHint("↑↓", "speed")
            keyHint("Esc", "exit")
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.white.opacity(0.3))
    }
    
    private func keyHint(_ key: String, _ action: String) -> some View {
        HStack(spacing: 6) {
            Text(key)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.1))
                )
            Text(action)
        }
    }
    
    // MARK: - Helpers
    
    private func startControlsTimer() {
        controlsTimer?.invalidate()
        showControls = true
        showCursor()
        
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            if state.isPlaying {
                showControls = false
                hideCursor()
            }
        }
    }
    
    private func hideCursor() {
        if !cursorHidden {
            NSCursor.hide()
            cursorHidden = true
        }
    }
    
    private func showCursor() {
        if cursorHidden {
            NSCursor.unhide()
            cursorHidden = false
        }
    }
    
    private func setupMouseHandling() {
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [self] event in
            startControlsTimer()
            return event
        }
    }
    
    private func setupKeyboardHandling() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            handleKeyEvent(event)
            return nil // Consume the event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        startControlsTimer()
        
        switch event.keyCode {
        case 49: // Space
            if state.isReady {
                state.beginFromReady()
            } else if !state.showCountdown {
                state.toggle()
            }
        case 53: // Escape
            onDismiss()
        case 123: // Left arrow
            if !state.isReady && !state.showCountdown {
                state.skipBackward()
            }
        case 124: // Right arrow
            if !state.isReady && !state.showCountdown {
                state.skipForward()
            }
        case 125: // Down arrow
            state.decreaseWPM()
        case 126: // Up arrow
            state.increaseWPM()
        default:
            break
        }
    }
}

// MARK: - ORP Word View

struct ORPWordView: View {
    let word: String
    let orpIndex: Int
    
    var body: some View {
        Canvas { context, size in
            let fontSize = AppSettings.shared.fontSize.size
            let font = CTFontCreateWithName("SF Mono" as CFString, fontSize, nil)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            // Measure character width using the ORP char
            let orpCharStr = orpChar
            let charWidth = measureCharWidth(orpCharStr, font: font)
            
            // Draw each character
            var chars = Array(word)
            for (i, char) in chars.enumerated() {
                let isORP = i == orpIndex
                let color: NSColor = isORP ? .systemRed : .white.withAlphaComponent(0.6)
                
                // Position: ORP char at center, others relative to it
                let offsetFromORP = CGFloat(i - orpIndex)
                let x = centerX + (offsetFromORP * charWidth) - charWidth / 2
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium),
                    .foregroundColor: color
                ]
                let attrString = NSAttributedString(string: String(char), attributes: attributes)
                
                context.draw(Text(AttributedString(attrString)), at: CGPoint(x: x + charWidth / 2, y: centerY))
            }
        }
        .frame(height: AppSettings.shared.fontSize.size * 1.5)
    }
    
    private func measureCharWidth(_ char: String, font: CTFont) -> CGFloat {
        // For monospace, all chars are same width - use fontSize * 0.6 as approximation
        return AppSettings.shared.fontSize.size * 0.6
    }
    
    private var orpChar: String {
        guard orpIndex < word.count else { return "" }
        let index = word.index(word.startIndex, offsetBy: orpIndex)
        return String(word[index])
    }
}

// MARK: - Visual Effect Blur

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
