import Foundation

struct ArticleContent: Codable, Identifiable {
    let id: UUID
    let url: URL
    let title: String
    let text: String
    let words: [String]
    let estimatedReadTime: Int // in seconds at 300 WPM
    let fetchedAt: Date
    
    init(url: URL, title: String, text: String) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.text = text
        self.words = Self.tokenize(text)
        self.estimatedReadTime = (self.words.count * 60) / 300
        self.fetchedAt = Date()
    }
    
    private static func tokenize(_ text: String) -> [String] {
        // Split by whitespace and filter empty strings
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }
    
    var wordCount: Int { words.count }
}
