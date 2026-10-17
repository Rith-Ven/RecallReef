//
//  FocusSessionStorage.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/16/26.
//

import Foundation

struct FocusSessionStorage {
    private let storageKey = "savedFocusSessions"

    // Accepts sessions w/o requiring an argument label when called
    func save(_ sessions: [FocusSession]) throws { // error back to caller
        let data = try JSONEncoder().encode(sessions)
        // Accesses app's default local settings store and store encoded bytes
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    // Loads and returns an array or throws an error
    func load() throws -> [FocusSession] {
        guard let data = UserDefaults.standard.data(
            forKey: storageKey
        ) else {
            return []
        }

        return try JSONDecoder().decode(
            [FocusSession].self,
            from: data
        )
    }
}
