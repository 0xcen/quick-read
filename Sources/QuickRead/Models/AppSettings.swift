import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage("wpm") var wpm: Int = 400
    @AppStorage("showCountdown") var showCountdown: Bool = true
    @AppStorage("countdownOnResume") var countdownOnResume: Bool = false // Only countdown on fresh start, not resume
    @AppStorage("resumeRewindSentences") var resumeRewindSentences: Int = 1 // Jump back X sentences on resume
    @AppStorage("overlayDarkness") var overlayDarkness: Double = 0.5 // 0.3 = mid grey, 0.8 = near black
    @AppStorage("fontSize") var fontSize: FontSize = .large
    @AppStorage("historyDays") var historyDays: Int = 30
    
    enum FontSize: String, CaseIterable, Codable {
        case medium = "Medium"
        case large = "Large"
        case extraLarge = "Extra Large"
        
        var size: CGFloat {
            switch self {
            case .medium: return 48
            case .large: return 64
            case .extraLarge: return 80
            }
        }
    }
    
    var wpmRange: ClosedRange<Int> { 200...800 }
    
    func increaseWPM() {
        wpm = min(wpm + 50, wpmRange.upperBound)
    }
    
    func decreaseWPM() {
        wpm = max(wpm - 50, wpmRange.lowerBound)
    }
}
