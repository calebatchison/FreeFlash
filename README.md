# FreeFlash

  A native iOS flashcard app built with SwiftUI and Core Data.

  ## Features

  - **Study Sets** — Create and organize sets of flashcards, reorder them by drag, and rename them inline
  - **Card Editor** — Add and edit front/back cards with a paginated editor that navigates between cards
  and auto-saves on Done
  - **Study Mode** — Flip cards with a 3D animation, swipe left/right to navigate, and track progress with
   a live progress bar
  - **Shuffle or In Order** — Launch any set shuffled or in its original sequence
  - **Practice Streaks** — Each set tracks how many consecutive days you've studied it; the flame badge
  goes grey when a streak is active but today's session hasn't happened yet
  - **Drag to Reorder** — Tap Edit on the My Sets screen to drag sets into any order
  - **Dark Mode** — Full light and dark mode support throughout

  ## Requirements

  - Xcode 26+
  - iOS 26.2+ deployment target
  - No external dependencies or package manager

  ## Getting Started

  ```bash
  git clone <your-repo-url>
  open FreeFlash.xcodeproj

  Press Cmd+R to build and run on a simulator or device.

  Project Structure

  FreeFlash/
  ├── FreeFlashApp.swift       # App entry point
  ├── ContentView.swift        # MySetsView — main list screen
  ├── SetDetailView.swift      # Set detail, card list, CardEditorSheet
  ├── StudyView.swift          # Flip-card study session
  ├── AppTheme.swift           # Colors, StudySet extensions, streak helpers
  ├── Persistence.swift        # Core Data stack and preview data
  └── FreeFlash.xcdatamodeld   # Core Data model (StudySet, FlashCard)

  Architecture

  Three-screen navigation stack: My Sets → Set Detail → Study.

  Data is stored in Core Data. Study streak data (streak count and last practice date) is stored in
  UserDefaults keyed per set UUID. All views run on @MainActor via SWIFT_DEFAULT_ACTOR_ISOLATION =
  MainActor.
  ```
