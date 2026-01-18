import Foundation
import Combine

class RSVPEngine: ObservableObject {
    @Published var currentWord: String = ""
    @Published var currentIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var orpIndex: Int = 0 // Optimal Recognition Point
    
    private var words: [String] = []
    private var timer: Timer?
    private var wpm: Int = 400
    
    var totalWords: Int { words.count }
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
    
    func load(words: [String], startingAt index: Int = 0) {
        self.words = words
        self.currentIndex = min(max(0, index), words.count)
        updateCurrentWord()
    }
    
    func setWPM(_ newWPM: Int) {
        self.wpm = newWPM
        if isPlaying {
            stop()
            play()
        }
    }
    
    func play() {
        guard !words.isEmpty, currentIndex < words.count else { return }
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
            play()
        }
    }
    
    func stop() {
        pause()
    }
    
    func skipForward(_ count: Int = 5) {
        currentIndex = min(currentIndex + count, words.count - 1)
        updateCurrentWord()
    }
    
    func skipBackward(_ count: Int = 5) {
        currentIndex = max(currentIndex - count, 0)
        updateCurrentWord()
    }
    
    func seekTo(_ index: Int) {
        currentIndex = min(max(0, index), words.count - 1)
        updateCurrentWord()
    }
    
    private func advance() {
        guard currentIndex < words.count - 1 else {
            pause()
            return
        }
        currentIndex += 1
        updateCurrentWord()
    }
    
    private func updateCurrentWord() {
        guard currentIndex < words.count else {
            currentWord = ""
            return
        }
        currentWord = words[currentIndex]
        orpIndex = calculateORP(for: currentWord)
    }
    
    /// Calculate Optimal Recognition Point (ORP)
    /// The ORP is typically around 1/3 into the word, slightly left of center
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
