//
//  MySetsView.swift
//  FreeFlash
//
//  Created by Caleb Atchison on 3/17/26.
//

import SwiftUI
internal import CoreData

struct MySetsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "sortOrder", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ],
        animation: .default
    )
    private var studySets: FetchedResults<StudySet>

    @State private var showNewSetSheet = false
    @State private var newSetTitle = ""
    @State private var navigateToNewSet: StudySet?
    @State private var selectedSet: StudySet?
    @State private var streakRefresh = UUID()
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.appBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("My Sets")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.appOrange)
                        Spacer()
                        if !studySets.isEmpty {
                            Button(editMode == .active ? "Done" : "Edit") {
                                withAnimation { editMode = editMode == .active ? .inactive : .active }
                            }
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.appOrange)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    if studySets.isEmpty {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 10) {
                                Image(systemName: "rectangle.stack")
                                    .font(.system(size: 52))
                                    .foregroundStyle(Color.appOrange.opacity(0.4))
                                Text("No sets yet")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Tap + to create your first study set")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(studySets) { set in
                                Button {
                                    if editMode == .inactive { selectedSet = set }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(set.title ?? "Untitled")
                                                .font(.headline)
                                            Text("\(set.cardsArray.count) \(set.cardsArray.count == 1 ? "term" : "terms")")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        StreakBadge(streak: set.currentStreak(), studiedToday: set.studiedToday())
                                            .id(streakRefresh)
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.tertiary)
                                            .padding(.trailing, 6)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.leading, 13)
                                    .padding(.trailing, 8)
                                    .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 14))
                                    .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                            }
                            .onDelete(perform: deleteSets)
                            .onMove(perform: moveSets)

                            Color.clear
                                .frame(height: 80)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .environment(\.editMode, $editMode)
                    }
                }

                Button {
                    newSetTitle = ""
                    showNewSetSheet = true
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
            .navigationDestination(item: $navigateToNewSet) { set in
                SetDetailView(studySet: set)
            }
            .navigationDestination(item: $selectedSet) { set in
                SetDetailView(studySet: set)
            }
            .onAppear {
                streakRefresh = UUID()
                editMode = .inactive
            }
        }
        .sheet(isPresented: $showNewSetSheet) {
            NewSetSheet(title: $newSetTitle, onCreate: createSet)
        }
    }

    private func createSet(title: String) {
        let newSet = StudySet(context: viewContext)
        newSet.id = UUID()
        newSet.title = title
        newSet.createdAt = Date()
        newSet.setValue(Int32(studySets.count), forKey: "sortOrder")
        try? viewContext.save()
        showNewSetSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            navigateToNewSet = newSet
        }
    }

    private func deleteSets(offsets: IndexSet) {
        offsets.map { studySets[$0] }.forEach(viewContext.delete)
        try? viewContext.save()
    }

    private func moveSets(from source: IndexSet, to destination: Int) {
        var reordered = Array(studySets)
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, set) in reordered.enumerated() {
            set.setValue(Int32(index), forKey: "sortOrder")
        }
        try? viewContext.save()
    }
}

// MARK: - Streak Badge

/// Flame icon + count.
/// - Orange flame + orange count: studied today
/// - Grey flame + orange count: streak active but not studied today
/// - Grey flame + grey count: no streak
struct StreakBadge: View {
    let streak: Int
    let studiedToday: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(streak > 0 && studiedToday ? Color.appOrange : Color(.tertiaryLabel))
            Text("\(streak)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(streak > 0 ? Color.appOrange : Color(.tertiaryLabel))
        }
    }
}

// MARK: - New Set Sheet

struct NewSetSheet: View {
    @Binding var title: String
    let onCreate: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Study Set")
                .font(.title2.bold())

            TextField("Enter a title...", text: $title)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit {
                    if isValid { onCreate(title) }
                }

            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Create") { onCreate(title) }
                    .foregroundStyle(Color.appOrange)
                    .fontWeight(.semibold)
                    .disabled(!isValid)
            }
        }
        .padding(24)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
        .onAppear { isFocused = true }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

#Preview {
    MySetsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
