//
//  AppTheme.swift
//  FreeFlash
//
//  Created by Caleb Atchison on 3/17/26.
//

import SwiftUI
internal import CoreData

extension Color {
    /// Matte grey in light mode, near-black in dark mode.
    static let appBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 1)
            : UIColor(red: 0.93, green: 0.93, blue: 0.94, alpha: 1)
    })

    /// White in light mode, elevated dark surface in dark mode.
    static let appCardBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.19, alpha: 1)
            : UIColor.white
    })

    static let appOrange = Color(red: 0.831, green: 0.384, blue: 0.165)
}

extension StudySet {
    var cardsArray: [FlashCard] {
        (cards as? Set<FlashCard> ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Reads the per-set practice streak from UserDefaults.
    func currentStreak() -> Int {
        guard let id = id?.uuidString else { return 0 }
        return UserDefaults.standard.integer(forKey: "streak_\(id)")
    }

    /// Returns true if the set was practiced today.
    func studiedToday() -> Bool {
        guard let id = id?.uuidString else { return false }
        let timestamp = UserDefaults.standard.double(forKey: "lastPractice_\(id)")
        guard timestamp > 0 else { return false }
        return Calendar.current.isDateInToday(Date(timeIntervalSince1970: timestamp))
    }
}
