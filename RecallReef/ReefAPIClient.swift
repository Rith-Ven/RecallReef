//
//  ReefAPIClient.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/16/26.
//

import Foundation

struct ReefAPIClient {
    func fetchPolyps() async throws -> [CoralPolyp] {
        // Address of the backend running on Mac
        guard let url = URL(
            string: "http://127.0.0.1:8000/polyps"
        ) else {
            throw URLError(.badURL)
        }
        
        // Send a GET request and wait for the response
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Confirm that the server returned HTTP 200 OK
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        // Conver the JSON array into Swift model values
        return try JSONDecoder().decode(
            [CoralPolyp].self, from: data
        )
    }
}
