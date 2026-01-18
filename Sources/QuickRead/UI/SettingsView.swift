import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var historyStore = HistoryStore.shared
    
    private var darknessLabel: String {
        if settings.overlayDarkness < 0.4 {
            return "Light"
        } else if settings.overlayDarkness < 0.6 {
            return "Medium"
        } else if settings.overlayDarkness < 0.75 {
            return "Dark"
        } else {
            return "Black"
        }
    }
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            historyTab
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
    
    // MARK: - General Tab
    
    private var generalTab: some View {
        Form {
            Section {
                HStack {
                    Text("Default WPM")
                    Spacer()
                    Picker("", selection: $settings.wpm) {
                        ForEach([200, 250, 300, 350, 400, 450, 500, 600, 700, 800], id: \.self) { wpm in
                            Text("\(wpm)").tag(wpm)
                        }
                    }
                    .frame(width: 100)
                }
                
                Toggle("Show countdown before reading", isOn: $settings.showCountdown)
                
                if settings.showCountdown {
                    Toggle("Also countdown on resume", isOn: $settings.countdownOnResume)
                        .padding(.leading, 20)
                }
                
                HStack {
                    Text("Rewind on resume")
                    Spacer()
                    Picker("", selection: $settings.resumeRewindSentences) {
                        Text("None").tag(0)
                        Text("1 sentence").tag(1)
                        Text("2 sentences").tag(2)
                        Text("3 sentences").tag(3)
                        Text("5 sentences").tag(5)
                    }
                    .frame(width: 130)
                }
            } header: {
                Text("Reading")
            }
            
            Section {
                HStack {
                    Text("Start Reading")
                    Spacer()
                    Text("⌘ ⇧ R")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primary.opacity(0.08))
                        )
                }
                
                HStack {
                    Text("Resume Last")
                    Spacer()
                    Text("⌘ ⇧ E")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primary.opacity(0.08))
                        )
                }
            } header: {
                Text("Hotkeys")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Appearance Tab
    
    private var appearanceTab: some View {
        Form {
            Section {
                HStack {
                    Text("Background Darkness")
                    Spacer()
                    Slider(value: $settings.overlayDarkness, in: 0.3...0.8, step: 0.05)
                        .frame(width: 150)
                    Text(darknessLabel)
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 60)
                }
                
                HStack {
                    Text("Font Size")
                    Spacer()
                    Picker("", selection: $settings.fontSize) {
                        ForEach(AppSettings.FontSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .frame(width: 120)
                }
            } header: {
                Text("Display")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - History Tab
    
    private var historyTab: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    HStack {
                        Text("Keep history for")
                        Spacer()
                        Picker("", selection: $settings.historyDays) {
                            Text("7 days").tag(7)
                            Text("14 days").tag(14)
                            Text("30 days").tag(30)
                            Text("90 days").tag(90)
                            Text("Forever").tag(0)
                        }
                        .frame(width: 120)
                    }
                    
                    HStack {
                        Text("Stored articles")
                        Spacer()
                        Text("\(historyStore.sessions.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Clear All History") {
                        historyStore.clearAll()
                    }
                    .foregroundStyle(.red)
                } header: {
                    Text("Settings")
                }
            }
            .formStyle(.grouped)
            .frame(height: 160)
            
            // History list
            if !historyStore.sessions.isEmpty {
                List {
                    ForEach(historyStore.sessions) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.content.title)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                Text(session.isComplete ? "Completed" : "\(session.progressPercentage)% • \(session.content.wordCount) words")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                historyStore.removeSession(session)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - About Tab
    
    private var aboutTab: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("QuickRead")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Version 1.0.0")
                .foregroundStyle(.secondary)
            
            Text("Speed read any webpage with RSVP technique")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Link("View on GitHub", destination: URL(string: "https://github.com")!)
                .font(.callout)
        }
        .padding(40)
    }
}
