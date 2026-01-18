import Foundation
import Combine

class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    
    @Published var sessions: [ReadingSession] = []
    
    private let defaults = UserDefaults.standard
    private let storageKey = "readingSessions"
    
    var lastSession: ReadingSession? {
        sessions.first
    }
    
    init() {
        loadSessions()
        cleanOldSessions()
    }
    
    func saveSession(_ session: ReadingSession) {
        // Remove existing session for same URL
        sessions.removeAll { $0.content.url == session.content.url }
        
        // Add new session at the beginning
        sessions.insert(session, at: 0)
        
        // Keep only last 100 sessions
        if sessions.count > 100 {
            sessions = Array(sessions.prefix(100))
        }
        
        persistSessions()
    }
    
    func removeSession(_ session: ReadingSession) {
        sessions.removeAll { $0.id == session.id }
        persistSessions()
    }
    
    func clearAll() {
        sessions.removeAll()
        persistSessions()
    }
    
    private func loadSessions() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ReadingSession].self, from: data) else {
            return
        }
        sessions = decoded
    }
    
    private func persistSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        defaults.set(data, forKey: storageKey)
    }
    
    private func cleanOldSessions() {
        let historyDays = AppSettings.shared.historyDays
        guard historyDays > 0 else { return } // 0 means keep forever
        
        let cutoff = Calendar.current.date(byAdding: .day, value: -historyDays, to: Date()) ?? Date()
        sessions.removeAll { $0.lastReadAt < cutoff }
        persistSessions()
    }
}
