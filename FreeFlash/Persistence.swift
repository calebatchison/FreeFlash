//
//  Persistence.swift
//  FreeFlash
//
//  Created by Caleb Atchison on 3/17/26.
//

internal import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let sampleData: [(String, [(String, String)])] = [
            ("Spanish Basics", [
                ("Hola", "Hello"),
                ("Gracias", "Thank you"),
                ("Por favor", "Please"),
                ("Sí", "Yes"),
                ("No", "No")
            ]),
            ("Capital Cities", [
                ("France", "Paris"),
                ("Japan", "Tokyo"),
                ("Australia", "Canberra"),
                ("Brazil", "Brasília")
            ])
        ]

        for (title, terms) in sampleData {
            let set = StudySet(context: viewContext)
            set.id = UUID()
            set.title = title
            set.createdAt = Date()
            for (index, (front, back)) in terms.enumerated() {
                let card = FlashCard(context: viewContext)
                card.id = UUID()
                card.front = front
                card.back = back
                card.sortOrder = Int32(index)
                card.studySet = set
            }
        }

        try! viewContext.save()
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FreeFlash")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
