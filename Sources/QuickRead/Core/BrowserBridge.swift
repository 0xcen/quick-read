import Foundation
import AppKit

enum BrowserError: LocalizedError {
    case noBrowserFound
    case noURLFound
    case scriptError(String)
    case unsupportedBrowser(String)
    
    var errorDescription: String? {
        switch self {
        case .noBrowserFound:
            return "No supported browser is currently active. Please open Safari, Chrome, Arc, or another supported browser."
        case .noURLFound:
            return "Could not get the URL from the active browser tab."
        case .scriptError(let message):
            return "Browser script error: \(message)"
        case .unsupportedBrowser(let name):
            return "'\(name)' is not supported. Please use Safari, Chrome, Arc, Brave, Edge, Opera, Vivaldi, Atlas, Dia, or Commet."
        }
    }
}

struct BrowserBridge {
    
    private static let browserScripts: [String: String] = [
        "Safari": """
            tell application "Safari"
                if (count of windows) > 0 then
                    return URL of current tab of front window
                end if
            end tell
            return ""
            """,
        "Google Chrome": """
            tell application "Google Chrome"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """,
        "Arc": """
            tell application "Arc"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """,
        "Brave Browser": """
            tell application "Brave Browser"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """,
        "Microsoft Edge": """
            tell application "Microsoft Edge"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """,
        "Opera": """
            tell application "Opera"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """,
        "Vivaldi": """
            tell application "Vivaldi"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """,
        "ChatGPT Atlas": """
            tell application "ChatGPT Atlas"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """,
        "Dia": """
            tell application "Dia"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """,
        "Commet": """
            tell application "Commet"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """
    ]
    
    private static let supportedBrowserBundleIDs: [String: String] = [
        "com.apple.Safari": "Safari",
        "com.google.Chrome": "Google Chrome",
        "company.thebrowser.Browser": "Arc",
        "com.brave.Browser": "Brave Browser",
        "com.microsoft.edgemac": "Microsoft Edge",
        "com.operasoftware.Opera": "Opera",
        "com.vivaldi.Vivaldi": "Vivaldi",
        "com.openai.chat": "ChatGPT Atlas",
        "com.openai.chatgpt-atlas": "ChatGPT Atlas",
        "build.dia": "Dia",
        "com.commet.browser": "Commet"
    ]
    
    static func getActiveTabURL() async throws -> URL {
        // Get frontmost app
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleID = frontApp.bundleIdentifier else {
            throw BrowserError.noBrowserFound
        }
        
        let appName = frontApp.localizedName ?? "Unknown"
        
        // Check if it's a known browser
        if let browserName = supportedBrowserBundleIDs[bundleID],
           let script = browserScripts[browserName] {
            let urlString = try await runAppleScript(script)
            
            guard !urlString.isEmpty, let url = URL(string: urlString) else {
                throw BrowserError.noURLFound
            }
            return url
        }
        
        // Try generic Chromium-based browser script as fallback
        let genericScript = """
            tell application "\(appName)"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """
        
        do {
            let urlString = try await runAppleScript(genericScript)
            guard !urlString.isEmpty, let url = URL(string: urlString) else {
                throw BrowserError.noURLFound
            }
            return url
        } catch {
            // If generic fails, report as unsupported
            throw BrowserError.unsupportedBrowser(appName)
        }
    }
    
    private static func runAppleScript(_ source: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let script = NSAppleScript(source: source)
                let result = script?.executeAndReturnError(&error)
                
                if let error = error {
                    let message = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                    continuation.resume(throwing: BrowserError.scriptError(message))
                    return
                }
                
                let urlString = result?.stringValue ?? ""
                continuation.resume(returning: urlString)
            }
        }
    }
}
