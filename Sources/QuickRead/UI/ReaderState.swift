import SwiftUI
import Combine

class ReaderState: ObservableObject {
    // Content
    let content: ArticleContent
    
    // RSVP Engine
    @Published var currentWord: String = ""
    @Published var currentIndex: Int = 0
    @Published var orpIndex: Int = 0
    @Published var isPlaying: Bool = false
    
    // UI State
    @Published var countdownValue: Int? = nil
    @Published var showCountdown: Bool = false
    @Published var isReady: Bool = true // Start in ready state (title centered)
    
    // Settings
    @Published var wpm: Int
    
    private var timer: Timer?
    private var countdownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Track if this is a resume (started mid-article)
    let isResume: Bool
    
    init(content: ArticleContent, startingAt index: Int = 0) {
        self.content = content
        self.wpm = AppSettings.shared.wpm
        self.isResume = index > 0
        
        // Apply rewind on resume
        var adjustedIndex = index
        if index > 0 {
            let rewindSentences = AppSettings.shared.resumeRewindSentences
            if rewindSentences > 0 {
                adjustedIndex = Self.rewindBySentences(in: content.words, from: index, sentences: rewindSentences)
            }
        }
        self.currentIndex = adjustedIndex
        
        if adjustedIndex < content.words.count {
            self.currentWord = content.words[adjustedIndex]
            self.orpIndex = calculateORP(for: content.words[adjustedIndex])
        }
        
        // Sync WPM changes to settings
        $wpm
            .dropFirst()
            .sink { AppSettings.shared.wpm = $0 }
            .store(in: &cancellables)
    }
    
    /// Rewind by a number of sentences (looking for sentence-ending punctuation)
    private static func rewindBySentences(in words: [String], from index: Int, sentences: Int) -> Int {
        var sentencesFound = 0
        var currentIndex = index
        
        // Walk backwards looking for sentence endings (.!?)
        while currentIndex > 0 && sentencesFound < sentences {
            currentIndex -= 1
            let word = words[currentIndex]
            if word.hasSuffix(".") || word.hasSuffix("!") || word.hasSuffix("?") {
                sentencesFound += 1
            }
        }
        
        // Move to the word after the sentence ending (start of sentence)
        if sentencesFound > 0 && currentIndex < index - 1 {
            currentIndex += 1
        }
        
        return max(0, currentIndex)
    }
    
    var totalWords: Int { content.words.count }
    
    var progress: Double {
        guard totalWords > 0 else { return 0 }
        return Double(currentIndex) / Double(totalWords)
    }
    
    var timeRemaining: String {
        guard totalWords > 0, wpm > 0 else { return "0:00" }
        let remainingWords = totalWords - currentIndex
        let seconds = (remainingWords * 60) / wpm
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    func beginFromReady() {
        isReady = false
        
        // Determine if we should show countdown
        let shouldShowCountdown: Bool
        if isResume {
            shouldShowCountdown = AppSettings.shared.showCountdown && AppSettings.shared.countdownOnResume
        } else {
            shouldShowCountdown = AppSettings.shared.showCountdown
        }
        
        if shouldShowCountdown {
            startCountdown()
        } else {
            startReading()
        }
    }
    
    func startCountdown() {
        showCountdown = true
        countdownValue = 3
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if let value = self.countdownValue {
                if value > 1 {
                    self.countdownValue = value - 1
                } else {
                    self.countdownValue = 0 // "GO"
                    self.countdownTimer?.invalidate()
                    
                    // Start reading after brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showCountdown = false
                        self.startReading()
                    }
                }
            }
        }
    }
    
    func startReading() {
        guard currentIndex < content.words.count else { return }
        isPlaying = true
        
        let interval = 60.0 / Double(wpm)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.advance()
        }
    }
    
    func pause() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    func toggle() {
        if isPlaying {
            pause()
        } else {
            startReading()
        }
    }
    
    func stop() {
        pause()
        countdownTimer?.invalidate()
    }
    
    func skipForward(_ count: Int = 5) {
        currentIndex = min(currentIndex + count, content.words.count - 1)
        updateCurrentWord()
    }
    
    func skipBackward(_ count: Int = 5) {
        currentIndex = max(currentIndex - count, 0)
        updateCurrentWord()
    }
    
    func increaseWPM() {
        wpm = min(wpm + 50, 800)
        if isPlaying {
            pause()
            startReading()
        }
    }
    
    func decreaseWPM() {
        wpm = max(wpm - 50, 200)
        if isPlaying {
            pause()
            startReading()
        }
    }
    
    func createSession() -> ReadingSession {
        ReadingSession(content: content, wordIndex: currentIndex)
    }
    
    private func advance() {
        guard currentIndex < content.words.count - 1 else {
            pause()
            return
        }
        currentIndex += 1
        updateCurrentWord()
    }
    
    private func updateCurrentWord() {
        guard currentIndex < content.words.count else {
            currentWord = ""
            return
        }
        currentWord = content.words[currentIndex]
        orpIndex = calculateORP(for: currentWord)
    }
    
    private func calculateORP(for word: String) -> Int {
        let length = word.count
        switch length {
        case 1: return 0
        case 2...5: return 1
        case 6...9: return 2
        case 10...13: return 3
        default: return 4
        }
    }
}
