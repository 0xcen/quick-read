## QuickRead - Native macOS Speed Reader App

A Swift/SwiftUI app that extracts content from any browser, displays it in a full-screen dimmed overlay using RSVP speed reading, and tracks reading history.

---

### Installation & Setup (One-Click Experience)

**First Launch Flow:**
1. User opens QuickRead.app (downloaded as .dmg or direct .app)
2. App appears in menu bar with a welcome tooltip
3. On first trigger (hotkey or menu click), macOS prompts for:
   - **Accessibility permission** - "QuickRead wants to control your computer" (required for global hotkey)
   - **Automation permission** - Auto-prompted per browser on first use: "QuickRead wants to control Safari/Chrome"
4. That's it - no manual AppleScript setup, no browser extensions needed

**Why this works out of the box:**
- AppleScript automation permissions are granted per-app automatically when macOS detects the first script execution
- User just clicks "OK" on the system dialogs
- All browser scripts are bundled in the app - no configuration needed

**Supported browsers (pre-configured):** Safari, Chrome, Arc, Brave, Edge, Opera, Vivaldi
**Firefox:** Partial support via accessibility APIs (may require extra permission)

---

### Architecture

```
QuickRead/
├── QuickReadApp.swift              # App entry, menu bar setup
├── Core/
│   ├── BrowserBridge.swift         # AppleScript to get URL from frontmost browser
│   ├── ReadabilityParser.swift     # Extract article content via JSCore + Mozilla Readability
│   └── RSVPEngine.swift            # Word tokenization, timing, ORP calculation
├── UI/
│   ├── OverlayWindow.swift         # Borderless full-screen NSWindow
│   ├── ReaderView.swift            # Countdown, word display, progress bar
│   ├── MenuBarView.swift           # History, WPM slider, settings access
│   └── SettingsView.swift          # Preferences window
├── Models/
│   ├── ReadingSession.swift        # URL, title, position, timestamp
│   └── AppSettings.swift           # WPM, hotkey, theme preferences
└── Storage/
    └── PersistenceManager.swift    # UserDefaults for settings + history
```

---

### Menu Bar Widget

```
┌─────────────────────────────────┐
│  📖  QuickRead           [300 ▼]│  ← WPM dropdown (300-700)
├─────────────────────────────────┤
│  ▶ Resume: "Why AI Changes..."  │  ← Current/last article
│     42% complete                │
├─────────────────────────────────┤
│  History                        │
│   • Why AI Changes Everything   │  ← Click to resume
│   • The Future of Swift         │
│   • Building Native Apps        │
│   ⟳ Restart  │  ✕ Clear         │
├─────────────────────────────────┤
│  ─────────────────────────────  │
│  ⌘⇧R  Start Reading             │  ← Shows current hotkey
│  ⚙ Settings...                  │
│  ⏻ Quit QuickRead               │
└─────────────────────────────────┘
```

**Menu Bar Features:**
- Book icon (📖) - static, clean
- **WPM dropdown** - Persistent slider/stepper (300-700), saves immediately
- **Resume section** - Shows last article with progress, one-click continue
- **History list** - Last 10 articles, click to resume any
- **Hotkey hint** - Shows current shortcut
- **Settings** - Opens preferences window

---

### Settings Window

```
┌─────────────────────────────────────────┐
│  QuickRead Preferences                  │
├─────────────────────────────────────────┤
│  Reading                                │
│    Default WPM:     [400 ────●──── slider]│
│    Countdown:       [✓] Show 3-2-1      │
│                                         │
│  Hotkey                                 │
│    Trigger:         [⌘ ⇧ R] [Record]    │
│                                         │
│  Appearance                             │
│    Overlay opacity: [70% ───●───slider] │
│    Font size:       [Large ▼]           │
│    Theme:           [● Dark  ○ Light]   │
│                                         │
│  History                                │
│    Keep history:    [30 days ▼]         │
│    [Clear All History]                  │
│                                         │
│  About                                  │
│    Version 1.0.0                        │
│    [Check for Updates]                  │
└─────────────────────────────────────────┘
```

---

### Full-Screen Overlay UI

```
┌─────────────────────────────────────────────────────────┐
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░  "Why AI Changes Everything"  ░░░░░░░░░░░░░░░│  ← Title (subtle)
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░    trans|form       ░░░░░░░░░░░░░░░░░░░░│  ← Word with ORP marker
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░  ═══════════●═══════════  ░░░░░░░░░░░░░░░░░░│  ← Progress bar
│░░░░░░░░░░░░░░░░░░░  400 WPM · 2:34  ░░░░░░░░░░░░░░░░░░░░│  ← WPM + time remaining
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░  Space: pause │ Esc: exit  ░░░░░░░░░░░░░░░│  ← Hints (fade after 3s)
└─────────────────────────────────────────────────────────┘
```

**Countdown before start:** Large "3" → "2" → "1" → "GO" with smooth fade transitions

---

### Keyboard Controls

| Key | Action |
|-----|--------|
| `Space` | Play/Pause |
| `Esc` | Exit overlay (saves position) |
| `←` | Back 5 words |
| `→` | Forward 5 words |
| `↑` | Increase WPM by 50 |
| `↓` | Decrease WPM by 50 |

---

### Tech Stack

- **Swift 5.9+ / SwiftUI** - Native macOS app (macOS 13+)
- **JavaScriptCore** - Run Mozilla Readability.js for content extraction
- **KeyboardShortcuts** (sindresorhus) - Global hotkey registration
- **UserDefaults** - Settings + history persistence

---

### Permissions (Auto-prompted by macOS)

| Permission | When Prompted | User Action |
|------------|---------------|-------------|
| Accessibility | First hotkey use | Click "Open System Preferences" → Enable |
| Automation (per browser) | First read from that browser | Click "OK" |

---

### MVP Build Order

1. **Menu bar app shell** - Icon, basic menu, quit
2. **Settings persistence** - WPM, hotkey storage
3. **Overlay window** - Full-screen dimmed view with test text
4. **RSVP engine** - Word display with timing + ORP
5. **Countdown animation** - 3-2-1-GO sequence
6. **Keyboard controls** - Space, Esc, arrows
7. **Global hotkey** - Trigger overlay from anywhere
8. **Browser URL extraction** - AppleScript for all browsers
9. **Readability parsing** - JSCore + Readability.js
10. **History system** - Save/resume positions
11. **Menu bar history UI** - List + resume/restart
12. **Settings window** - Full preferences panel