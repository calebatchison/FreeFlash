# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FreeFlash is a native iOS/iPadOS flashcard app (SwiftUI + Core Data). Users create study sets, add front/back cards, and practice with a flip-card study mode. Minimum deployment target: iOS 26.2.

## Building and Running

Pure Xcode project — open `FreeFlash.xcodeproj` in Xcode and press Cmd+R, or:

```bash
xcodebuild -scheme FreeFlash -configuration Debug
xcodebuild clean -scheme FreeFlash
```

No tests, linting tools, or external package managers.

## Architecture

Three-screen navigation within a single `NavigationStack` (root: `MySetsView`):

```
MySetsView (My Sets list — ContentView.swift)
  └─ SetDetailView (set title, practice buttons, cards table)
       └─ StudyView (flip-card study session)
```

> `MySetsView` lives in `ContentView.swift`. The struct was renamed but the file has not been renamed in Xcode yet — keep this in mind when navigating the project.

### Core Data model (`FreeFlash.xcdatamodeld`)

- `StudySet`: `id` (UUID), `title` (String), `createdAt` (Date), `sortOrder` (Int32), `cards` (to-many → FlashCard, Cascade delete)
- `FlashCard`: `id` (UUID), `front` (String), `back` (String), `sortOrder` (Int32), `studySet` (to-one → StudySet)

Both entities use `codeGenerationType="class"` — Xcode auto-generates the NSManagedObject subclasses at build time.

**Important:** `StudySet.sortOrder` was added recently. Until Xcode regenerates the class (clean build), the Swift key path `\StudySet.sortOrder` will produce a build error. Always use the string-based API for this attribute:
- Sort descriptor: `NSSortDescriptor(key: "sortOrder", ascending: true)`
- Setting: `set.setValue(Int32(n), forKey: "sortOrder")`

`FlashCard.sortOrder` pre-dates this and uses the normal key path form: `\FlashCard.sortOrder`.

### Key files

- **`AppTheme.swift`** — `Color.appBackground`, `Color.appCardBackground`, `Color.appOrange`; `StudySet` extensions: `cardsArray` (sorts `cards` NSSet by `sortOrder`), `currentStreak()`, `studiedToday()`
- **`ContentView.swift`** — `MySetsView` (My Sets list with drag-to-reorder, edit mode, streak badges) + `StreakBadge` + `NewSetSheet`
- **`SetDetailView.swift`** — `SetDetailView` (editable title, practice buttons, cards list) + `PracticeButton` + `CardEditorSheet` (add/edit cards with per-card draft state)
- **`StudyView.swift`** — `StudyView` (swipe navigation, progress bar, streak recording) + `FlashCardView` (3D flip) + `CardFaceView`
- **`Persistence.swift`** — Core Data stack; `PersistenceController.preview` provides sample sets for SwiftUI previews

## Design System

- Background: `Color.appBackground` (light matte grey in light mode, near-black in dark mode)
- Card surfaces: `Color.appCardBackground` (white in light mode, elevated dark surface in dark mode)
- Primary accent: `Color.appOrange` (`#D46229`)
- Danger/delete: `.red` (system red, swipe-to-delete actions)
- Navigation bar is hidden on all screens (`.toolbar(.hidden, for: .navigationBar)`); back navigation uses `@Environment(\.dismiss)` with a custom `chevron.left` button
- Floating action buttons: orange circle with drop shadow (`.background(Color.appOrange, in: Circle())`)
- List rows: `RoundedRectangle(cornerRadius: 14)` card style, `listRowBackground(.clear)`, `listRowSeparator(.hidden)`

## Key Patterns

### Reactive card list in SetDetailView
Cards are loaded via a `@FetchRequest` initialised in `init(studySet:)` with a predicate (`studySet == %@`) rather than a computed property off the parent object. This ensures the list updates immediately when cards are added or edited without relying on `studySet.objectWillChange`.

### Navigation in MySetsView
`MySetsView` uses two `navigationDestination(item:)` modifiers — one for `navigateToNewSet` (post-creation navigation) and one for `selectedSet` (tap-to-open). Row items are `Button` + `.buttonStyle(.plain)` with a custom `chevron.right` icon; there is no system `NavigationLink` disclosure indicator.

### Card editor sheet (CardEditorSheet)
- Opened for both adding new cards and editing existing ones via `CardEditorConfig: Identifiable` (UUID-keyed), ensuring SwiftUI always creates a fresh sheet with correct `startingIndex`
- Edits are held in `[CardDraft]` in memory; nothing is written to Core Data until "Done"
- Navigating forward past the last card appends a new blank draft automatically

### Study view swipe animation
Cards are NOT swapped via `.id()` + `.transition()`. Instead:
1. `dragOffset` tracks live finger position; `rotationEffect` tilts the card around its bottom edge
2. On release past threshold (or fast throw): `easeIn` animates the card off-screen, then `currentIndex` changes, `isFlipped` resets (no flip animation because `isSwiping == true` suppresses it), and a `spring` brings the new card in from the opposite side
3. `animateFlip: !isSwiping` on `FlashCardView` prevents the flip animation from firing during card transitions

### Drag-to-reorder sets
`MySetsView` exposes an Edit/Done toggle. `.onMove` + `moveSets(from:to:)` reassigns `sortOrder` integers on all `StudySet` objects and saves. The `@FetchRequest` sorts by `sortOrder ASC, createdAt ASC` so pre-existing sets (all `sortOrder == 0`) fall back to creation order.

### Streak tracking
Per-set streak data lives in `UserDefaults` under two keys (where `{uuid}` is `studySet.id.uuidString`):
- `streak_{uuid}` — current streak count (Int)
- `lastPractice_{uuid}` — last practice timestamp (Double / `timeIntervalSince1970`)

`StudySet.currentStreak()` and `StudySet.studiedToday()` read these. `MySetsView` forces a re-read on `.onAppear` via a `streakRefresh: UUID` state that is used as `.id()` on each `StreakBadge`.

`StreakBadge` has three visual states:
- Orange flame + orange count → studied today
- Grey flame + orange count → streak active but not studied today
- Grey flame + grey count → no streak

## Key Settings

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all code defaults to `@MainActor`
- `SWIFT_APPROACHABLE_CONCURRENCY = YES` — Swift 6 concurrency in approachable mode
- Info.plist is auto-generated (`GENERATE_INFOPLIST_FILE = YES`); do not create a manual Info.plist

## SourceKit Diagnostics

SourceKit frequently reports false-positive errors for Core Data auto-generated types (`StudySet`, `FlashCard`), cross-file extensions (`Color.appOrange`, `Color.appBackground`, `Color.appCardBackground`), and types defined in other files (`PersistenceController`, `StudyView`, `SetDetailView`). These do **not** indicate real build errors — the project compiles cleanly in Xcode.
