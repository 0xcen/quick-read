import Foundation

struct ReadingSession: Codable, Identifiable {
    let id: UUID
    let content: ArticleContent
    var wordIndex: Int
    var lastReadAt: Date
    
    init(content: ArticleContent, wordIndex: Int = 0) {
        self.id = UUID()
        self.content = content
        self.wordIndex = wordIndex
        self.lastReadAt = Date()
    }
    
    var progress: Double {
        guard content.wordCount > 0 else { return 0 }
        return Double(wordIndex) / Double(content.wordCount)
    }
    
    var isComplete: Bool {
        wordIndex >= content.wordCount
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    mutating func updatePosition(_ index: Int) {
        wordIndex = min(max(0, index), content.wordCount)
        lastReadAt = Date()
    }
}
