//
//  StudyView.swift
//  FreeFlash
//
//  Created by Caleb Atchison on 3/17/26.
//

import SwiftUI
internal import CoreData

struct StudyView: View {
    let cards: [FlashCard]
    let studySet: StudySet

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var dragOffset: CGFloat = 0
    @State private var isSwiping = false
    @State private var showEndAlert = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress counter
                    Text("\(currentIndex + 1) of \(cards.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 21)

                    // Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appOrange)
                            .frame(width: (geo.size.width - 48) * CGFloat(currentIndex + 1) / CGFloat(max(cards.count, 1)))
                            .animation(.easeInOut, value: currentIndex)
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 40)

                    Spacer()

                    // Flash card
                    FlashCardView(card: cards[currentIndex], isFlipped: $isFlipped, animateFlip: !isSwiping)
                        .offset(x: dragOffset)
                        .rotationEffect(.degrees(dragOffset / 22), anchor: .bottom)
                        .shadow(
                            color: .black.opacity(abs(dragOffset) > 10 ? 0.18 : 0.08),
                            radius: abs(dragOffset) > 10 ? 24 : 14,
                            x: 0, y: 8
                        )
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    guard !isSwiping else { return }
                                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
                                        dragOffset = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    guard !isSwiping else { return }
                                    let distance = value.translation.width
                                    let velocity = value.predictedEndTranslation.width - value.translation.width
                                    let threshold: CGFloat = 80

                                    if distance < -threshold || (distance < -30 && velocity < -250) {
                                        navigateCard(forward: true, screenWidth: geo.size.width)
                                    } else if distance > threshold || (distance > 30 && velocity > 250) {
                                        navigateCard(forward: false, screenWidth: geo.size.width)
                                    } else {
                                        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                        .padding(.horizontal, 24)

                    Spacer()

                    Text("Tap to flip  •  Swipe to navigate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .topLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(20)
                }
            }
            .alert("Set Complete!", isPresented: $showEndAlert) {
                Button("Study Again") { restart() }
                Button("Return to Set", role: .cancel) { dismiss() }
            } message: {
                Text("You've gone through all \(cards.count) \(cards.count == 1 ? "card" : "cards").")
            }
            .onAppear { recordPractice() }
        }
    }

    private func navigateCard(forward: Bool, screenWidth: CGFloat) {
        if forward && currentIndex >= cards.count - 1 {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) { dragOffset = 0 }
            showEndAlert = true
            return
        }
        if !forward && currentIndex <= 0 {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) { dragOffset = 0 }
            return
        }

        isSwiping = true
        let exitX: CGFloat = forward ? -(screenWidth * 1.4) : (screenWidth * 1.4)
        let enterX: CGFloat = forward ? (screenWidth * 1.4) : -(screenWidth * 1.4)

        // Phase 1 — fly current card off screen
        withAnimation(.easeIn(duration: 0.2)) {
            dragOffset = exitX
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))

            // Swap card content and snap to the opposite off-screen position (no animation)
            currentIndex += forward ? 1 : -1
            isFlipped = false
            dragOffset = enterX

            // Phase 2 — spring new card into place
            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                dragOffset = 0
            }
            isSwiping = false
        }
    }

    private func restart() {
        currentIndex = 0
        isFlipped = false
        dragOffset = 0
    }

    /// Records a practice day for this specific set and updates its streak.
    private func recordPractice() {
        guard let idString = studySet.id?.uuidString else { return }
        let streakKey = "streak_\(idString)"
        let timestampKey = "lastPractice_\(idString)"

        let lastTimestamp = UserDefaults.standard.double(forKey: timestampKey)
        let lastDate = Date(timeIntervalSince1970: lastTimestamp)
        let cal = Calendar.current

        var streak = UserDefaults.standard.integer(forKey: streakKey)

        if cal.isDateInToday(lastDate) {
            return
        } else if lastTimestamp > 0 && cal.isDateInYesterday(lastDate) {
            streak += 1
        } else {
            streak = 1
        }

        UserDefaults.standard.set(streak, forKey: streakKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: timestampKey)
    }
}

// MARK: - Flash Card View

struct FlashCardView: View {
    let card: FlashCard
    @Binding var isFlipped: Bool
    var animateFlip: Bool = true

    var body: some View {
        ZStack {
            // Front face
            CardFaceView(
                sideLabel: "FRONT",
                content: card.front ?? "",
                backgroundColor: Color.appCardBackground
            )
            .opacity(isFlipped ? 0 : 1)

            // Back face — pre-rotated 180° so it appears correctly when the card flips
            CardFaceView(
                sideLabel: "BACK",
                content: card.back ?? "",
                backgroundColor: Color.appOrange.opacity(0.12)
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(animateFlip ? .easeInOut(duration: 0.35) : nil, value: isFlipped)
        .onTapGesture { isFlipped.toggle() }
    }
}

struct CardFaceView: View {
    let sideLabel: String
    let content: String
    let backgroundColor: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)

            VStack(alignment: .leading, spacing: 0) {
                Text(sideLabel)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                Spacer()

                Text(content)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 460)
    }
}

#Preview {
    let ctx = PersistenceController.preview.container.viewContext
    let set = try! ctx.fetch(StudySet.fetchRequest()).first!
    return NavigationStack {
        StudyView(cards: set.cardsArray, studySet: set)
            .environment(\.managedObjectContext, ctx)
    }
}
