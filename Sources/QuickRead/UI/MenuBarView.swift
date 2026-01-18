import SwiftUI

struct MenuBarView: View {
    let onStartReading: () -> Void
    let onResumeReading: (ReadingSession) -> Void
    
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var historyStore = HistoryStore.shared
    
    @State private var isHoveringStart = false
    @State private var hoveredSessionId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with WPM
            headerSection
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Current/Resume section
            if let lastSession = historyStore.lastSession, !lastSession.isComplete {
                resumeSection(lastSession)
                
                Divider()
                    .background(Color.white.opacity(0.1))
            }
            
            // History section
            if !historyStore.sessions.isEmpty {
                historySection
                
                Divider()
                    .background(Color.white.opacity(0.1))
            }
            
            // Actions
            actionsSection
        }
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            Text("QuickRead")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            
            Spacer()
            
            // WPM Picker
            Menu {
                ForEach([200, 250, 300, 350, 400, 450, 500, 600, 700, 800], id: \.self) { wpm in
                    Button {
                        settings.wpm = wpm
                    } label: {
                        HStack {
                            Text("\(wpm) WPM")
                            if settings.wpm == wpm {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(settings.wpm)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.05))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Resume Section
    
    private func resumeSection(_ session: ReadingSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.blue)
                Text("Continue Reading")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Button {
                onResumeReading(session)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.content.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            ProgressView(value: session.progress)
                                .progressViewStyle(.linear)
                                .frame(width: 60)
                                .tint(.blue)
                            
                            Text("\(session.progressPercentage)%")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(isHoveringStart ? 0.15 : 0.08))
                )
            }
            .buttonStyle(.plain)
            .onHover { isHoveringStart = $0 }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text("History")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    historyStore.clearAll()
                } label: {
                    Text("Clear")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(0.7)
            }
            
            VStack(spacing: 2) {
                ForEach(historyStore.sessions.prefix(5)) { session in
                    historyRow(session)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func historyRow(_ session: ReadingSession) -> some View {
        Button {
            onResumeReading(session)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.content.title)
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(session.isComplete ? "Completed" : "\(session.progressPercentage)% complete")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if session.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.green.opacity(0.7))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hoveredSessionId == session.id ? Color.primary.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hoveredSessionId = $0 ? session.id : nil }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 2) {
            // Start Reading button
            Button {
                onStartReading()
            } label: {
                HStack {
                    Text("⌘⇧R")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.08))
                        )
                    
                    Text("Start Reading")
                        .font(.system(size: 13))
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(MenuRowButtonStyle())
            
            // Resume Last Read button
            if let lastSession = historyStore.lastSession, !lastSession.isComplete {
                Button {
                    onResumeReading(lastSession)
                } label: {
                    HStack {
                        Text("⌘⇧E")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.08))
                            )
                        
                        Text("Resume Last")
                            .font(.system(size: 13))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuRowButtonStyle())
            }
            
            // Settings
            SettingsLink {
                HStack {
                    Image(systemName: "gear")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Settings...")
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(MenuRowButtonStyle())
            
            // Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Quit QuickRead")
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(MenuRowButtonStyle())
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }
}

// MARK: - Button Style

struct MenuRowButtonStyle: ButtonStyle {
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.primary.opacity(0.08) : Color.clear)
            )
            .onHover { isHovering = $0 }
    }
}
