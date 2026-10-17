//
//  CoralPolypStorage.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/16/26.
//

import Foundation

struct CoralPolypStorage {
    private let collectionKey = "savedPolyps"
    
    // Key used by earlier storage format
    private let legacyKey = "savedPolyp"

    func save(_ polyps: [CoralPolyp]) throws {
        let data = try JSONEncoder().encode(polyps)
        UserDefaults.standard.set(data, forKey: collectionKey)
    }

    func load() throws -> [CoralPolyp] {
        if let data = UserDefaults.standard.data(
            forKey: collectionKey
        ), !data.isEmpty {
            return try JSONDecoder().decode(
                [CoralPolyp].self,
                from: data
            )
        }

        if let data = UserDefaults.standard.data(
            forKey: legacyKey
        ), !data.isEmpty {
            let oldPolyp = try JSONDecoder().decode(
                CoralPolyp.self,
                from: data
            )

            return [oldPolyp]
        }

        return []
    }
}
