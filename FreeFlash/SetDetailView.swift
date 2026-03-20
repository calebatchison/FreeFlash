//
//  SetDetailView.swift
//  FreeFlash
//
//  Created by Caleb Atchison on 3/17/26.
//

import SwiftUI
internal import CoreData

struct SetDetailView: View {
    @ObservedObject var studySet: StudySet
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest private var cards: FetchedResults<FlashCard>

    struct CardEditorConfig: Identifiable {
        let id = UUID()
        let startingIndex: Int
    }
    @State private var cardEditorConfig: CardEditorConfig?
    @FocusState private var titleFocused: Bool

    init(studySet: StudySet) {
        self.studySet = studySet
        _cards = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \FlashCard.sortOrder, ascending: true)],
            predicate: NSPredicate(format: "studySet == %@", studySet),
            animation: .default
        )
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { studySet.title ?? "" },
            set: { newValue in
                studySet.title = newValue
                try? viewContext.save()
            }
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Back button
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Editable title
                TextField("Untitled", text: titleBinding)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.appOrange)
                    .tint(Color.appOrange)
                    .textFieldStyle(.plain)
                    .focused($titleFocused)
                    .onTapGesture { titleFocused = true }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                // Practice buttons
                HStack(spacing: 12) {
                    NavigationLink {
                        StudyView(cards: Array(cards).shuffled(), studySet: studySet)
                    } label: {
                        PracticeButton(icon: "shuffle", title: "Shuffle")
                    }
                    .buttonStyle(.plain)
                    .disabled(cards.isEmpty)

                    NavigationLink {
                        StudyView(cards: Array(cards), studySet: studySet)
                    } label: {
                        PracticeButton(icon: "play.fill", title: "In Order")
                    }
                    .buttonStyle(.plain)
                    .disabled(cards.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                // Column headers
                if !cards.isEmpty {
                    HStack {
                        Text("FRONT")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Divider().frame(height: 14)
                        Text("BACK")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
                }

                // Cards list
                if cards.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.appOrange.opacity(0.4))
                            Text("No cards yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Tap + to add your first card")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(cards) { card in
                            HStack(alignment: .top, spacing: 0) {
                                Text(card.front ?? "")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.25))
                                    .frame(width: 1)
                                    .padding(.vertical, 2)
                                Text(card.back ?? "")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 12)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 13)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let idx = cards.firstIndex(where: { $0.objectID == card.objectID }) ?? 0
                                cardEditorConfig = CardEditorConfig(startingIndex: idx)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteCard(card)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 14))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        }

                        Color.clear
                            .frame(height: 80)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }

            // Floating add card button
            Button {
                cardEditorConfig = CardEditorConfig(startingIndex: cards.count)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.appOrange, in: Circle())
                    .shadow(color: Color.appOrange.opacity(0.4), radius: 12, x: 0, y: 5)
            }
            .padding(.trailing, 50)
            .padding(.bottom, 25)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $cardEditorConfig) { config in
            CardEditorSheet(studySet: studySet, startingIndex: config.startingIndex)
        }
    }

    private func deleteCard(_ card: FlashCard) {
        viewContext.delete(card)
        try? viewContext.save()
    }
}

// MARK: - Practice Button

struct PracticeButton: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
            Text(title)
                .font(.body.weight(.semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appOrange, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Card Editor Sheet

struct CardEditorSheet: View {
    @ObservedObject var studySet: StudySet
    let startingIndex: Int

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var drafts: [CardDraft]
    @State private var currentIndex: Int
    @State private var goingForward = true
    @FocusState private var focusedField: CardField?

    // Holds unsaved edits for a single card. objectID is nil for brand-new cards.
    struct CardDraft {
        var objectID: NSManagedObjectID?
        var front: String
        var back: String

        init(card: FlashCard) {
            objectID = card.objectID
            front = card.front ?? ""
            back = card.back ?? ""
        }

        init() {
            objectID = nil
            front = ""
            back = ""
        }

        var isValid: Bool {
            !front.trimmingCharacters(in: .whitespaces).isEmpty &&
            !back.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    enum CardField { case front, back }

    init(studySet: StudySet, startingIndex: Int) {
        self.studySet = studySet
        self.startingIndex = startingIndex

        let existing = studySet.cardsArray
        var initial = existing.map { CardDraft(card: $0) }

        let clampedStart: Int
        if startingIndex >= existing.count {
            initial.append(CardDraft())
            clampedStart = initial.count - 1
        } else {
            clampedStart = max(0, startingIndex)
        }

        _drafts = State(initialValue: initial)
        _currentIndex = State(initialValue: clampedStart)
    }

    var canGoBack: Bool { currentIndex > 0 }
    var canGoForward: Bool {
        currentIndex < drafts.count - 1 || drafts[currentIndex].isValid
    }

    var body: some View {
        VStack(spacing: 0) {

            // Cancel / Done
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done") { saveAndDismiss() }
                    .foregroundStyle(Color.appOrange)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            Divider()

            // Card input fields
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FRONT")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TextField("Term...", text: $drafts[currentIndex].front, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .padding(14)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        .focused($focusedField, equals: .front)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("BACK")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TextField("Definition...", text: $drafts[currentIndex].back, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .padding(14)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        .focused($focusedField, equals: .back)
                }
            }
            .id(currentIndex)
            .transition(.asymmetric(
                insertion: .move(edge: goingForward ? .trailing : .leading).combined(with: .opacity),
                removal:   .move(edge: goingForward ? .leading  : .trailing).combined(with: .opacity)
            ))
            .padding(24)
            .clipped()

            Spacer()

            Divider()

            // Navigation arrows — positioned above the keyboard
            HStack(alignment: .center) {
                Button { goBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(canGoBack ? Color.appOrange : Color.secondary.opacity(0.3))
                }
                .disabled(!canGoBack)

                Spacer()

                Text("Card \(currentIndex + 1) of \(drafts.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button { goForward() } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(canGoForward ? Color.appOrange : Color.secondary.opacity(0.3))
                }
                .disabled(!canGoForward)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .presentationDetents([.large])
        .presentationBackground(.ultraThinMaterial)
        .presentationDragIndicator(.visible)
        .onAppear { focusedField = .front }
    }

    private func goBack() {
        guard canGoBack else { return }
        goingForward = false
        withAnimation(.easeInOut(duration: 0.22)) { currentIndex -= 1 }
        focusedField = .front
    }

    private func goForward() {
        guard canGoForward else { return }
        goingForward = true
        if currentIndex == drafts.count - 1 { drafts.append(CardDraft()) }
        withAnimation(.easeInOut(duration: 0.22)) { currentIndex += 1 }
        focusedField = .front
    }

    private func saveAndDismiss() {
        let existingCards = studySet.cardsArray
        var newCardCount = 0

        for draft in drafts {
            if let objID = draft.objectID {
                if draft.isValid,
                   let card = (try? viewContext.existingObject(with: objID)) as? FlashCard {
                    card.front = draft.front.trimmingCharacters(in: .whitespaces)
                    card.back  = draft.back.trimmingCharacters(in: .whitespaces)
                }
            } else {
                if draft.isValid {
                    let card = FlashCard(context: viewContext)
                    card.id = UUID()
                    card.front = draft.front.trimmingCharacters(in: .whitespaces)
                    card.back  = draft.back.trimmingCharacters(in: .whitespaces)
                    card.sortOrder = Int32(existingCards.count + newCardCount)
                    card.studySet = studySet
                    newCardCount += 1
                }
            }
        }

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    let ctx = PersistenceController.preview.container.viewContext
    let set = try! ctx.fetch(StudySet.fetchRequest()).first!
    return NavigationStack {
        SetDetailView(studySet: set)
            .environment(\.managedObjectContext, ctx)
    }
}
