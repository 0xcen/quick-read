import Foundation
import JavaScriptCore

enum ParserError: LocalizedError {
    case fetchFailed(String)
    case parseFailed(String)
    case noContent
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to fetch page: \(message)"
        case .parseFailed(let message):
            return "Failed to parse content: \(message)"
        case .noContent:
            return "No readable content found on this page."
        case .invalidURL:
            return "Invalid URL provided."
        }
    }
}

struct ReadabilityParser {
    
    static func parse(url: URL) async throws -> ArticleContent {
        // Fetch HTML
        let html = try await fetchHTML(from: url)
        
        // Parse with Readability
        let (title, text) = try parseWithReadability(html: html, url: url)
        
        guard !text.isEmpty else {
            throw ParserError.noContent
        }
        
        return ArticleContent(url: url, title: title, text: text)
    }
    
    private static func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ParserError.fetchFailed("Server returned an error")
            }
            
            // Try to detect encoding from response
            let encoding: String.Encoding
            if let encodingName = httpResponse.textEncodingName {
                encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
                    CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
                ))
            } else {
                encoding = .utf8
            }
            
            guard let html = String(data: data, encoding: encoding) ?? String(data: data, encoding: .utf8) else {
                throw ParserError.fetchFailed("Could not decode page content")
            }
            
            return html
        } catch let error as ParserError {
            throw error
        } catch {
            throw ParserError.fetchFailed(error.localizedDescription)
        }
    }
    
    private static func parseWithReadability(html: String, url: URL) throws -> (title: String, text: String) {
        // Use a simplified extraction approach
        // In production, you'd bundle Readability.js and run it via JSContext
        
        let title = extractTitle(from: html) ?? url.host ?? "Untitled"
        let text = extractMainContent(from: html)
        
        return (title, text)
    }
    
    private static func extractTitle(from html: String) -> String? {
        // Try og:title first
        if let ogTitle = extractMetaContent(from: html, property: "og:title") {
            return ogTitle
        }
        
        // Fall back to <title> tag
        let titlePattern = "<title[^>]*>([^<]+)</title>"
        if let regex = try? NSRegularExpression(pattern: titlePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    private static func extractMetaContent(from html: String, property: String) -> String? {
        let pattern = "<meta[^>]+(?:property|name)=[\"']\(property)[\"'][^>]+content=[\"']([^\"']+)[\"']"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        
        // Try reversed attribute order
        let pattern2 = "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+(?:property|name)=[\"']\(property)[\"']"
        if let regex = try? NSRegularExpression(pattern: pattern2, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        
        return nil
    }
    
    private static func extractMainContent(from html: String) -> String {
        var text = html
        
        // Remove scripts, styles, and other non-content elements
        let removePatterns = [
            "<script[^>]*>[\\s\\S]*?</script>",
            "<style[^>]*>[\\s\\S]*?</style>",
            "<noscript[^>]*>[\\s\\S]*?</noscript>",
            "<header[^>]*>[\\s\\S]*?</header>",
            "<footer[^>]*>[\\s\\S]*?</footer>",
            "<nav[^>]*>[\\s\\S]*?</nav>",
            "<aside[^>]*>[\\s\\S]*?</aside>",
            "<!--[\\s\\S]*?-->",
            "<iframe[^>]*>[\\s\\S]*?</iframe>"
        ]
        
        for pattern in removePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " ")
            }
        }
        
        // Try to find article or main content
        let contentSelectors = [
            "<article[^>]*>([\\s\\S]*?)</article>",
            "<main[^>]*>([\\s\\S]*?)</main>",
            "<div[^>]*class=[\"'][^\"']*(?:content|article|post|entry)[^\"']*[\"'][^>]*>([\\s\\S]*?)</div>"
        ]
        
        for pattern in contentSelectors {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                text = String(text[range])
                break
            }
        }
        
        // Remove remaining HTML tags
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " ")
        }
        
        // Decode HTML entities
        text = decodeHTMLEntities(text)
        
        // Clean up whitespace
        text = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        return text
    }
    
    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [String: String] = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&#39;": "'",
            "&mdash;": "\u{2014}",
            "&ndash;": "\u{2013}",
            "&hellip;": "\u{2026}",
            "&ldquo;": "\u{201C}",
            "&rdquo;": "\u{201D}",
            "&lsquo;": "\u{2018}",
            "&rsquo;": "\u{2019}"
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Handle numeric entities
        if let regex = try? NSRegularExpression(pattern: "&#(\\d+);", options: []) {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for match in matches.reversed() {
                if let range = Range(match.range, in: result),
                   let numRange = Range(match.range(at: 1), in: result),
                   let code = Int(result[numRange]),
                   let scalar = Unicode.Scalar(code) {
                    result.replaceSubrange(range, with: String(Character(scalar)))
                }
            }
        }
        
        return result
    }
}
