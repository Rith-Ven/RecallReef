//
//  ReefAPIClient.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/16/26.
//

import Foundation

struct ReefAPIClient {
    // For backend address needs valid url
    private let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    func fetchPolyps() async throws -> [CoralPolyp] {
        // Address of the backend running on Mac
        let url = baseURL.appendingPathComponent("polyps")
        
        // Send a GET request and wait for the response
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Confirm that the server returned HTTP 200 OK
        try validateResponse(
            response,
            data: data,
            expectedStatus: 200
        )
        // Conver the JSON array into Swift model values
        return try JSONDecoder().decode(
            [CoralPolyp].self, from: data
        )
    }
    // Send a POST request
    func createPolyp(_ polyp: CoralPolyp) async throws -> CoralPolyp {
       let url = baseURL.appendingPathComponent("polyps")
        
        // Configure a request that sends JSON to the server
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // creation
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type" // tells server how to interpret request body
        )
        
        // Convert our Swift model into the request's JSON body
        request.httpBody = try JSONEncoder().encode(polyp)
        
        // Send the configured request and await its response
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        // Creation succeeds when the backend returns 201 Created
        try validateResponse(
            response,
            data: data,
            expectedStatus: 201
        )
        
        // Decode the single record returned by the backend
        return try JSONDecoder().decode(
            CoralPolyp.self,
            from: data
        )
    }
    
    // Verify the expected status, or report the server's explanation
    private func validateResponse(
        _ response: URLResponse,
        data: Data,
        expectedStatus: Int
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == expectedStatus else {
            let errorResponse = try? JSONDecoder().decode(
                APIErrorResponse.self,
                from: data
            )
            
            throw ReefAPIError.server(
                statusCode: httpResponse.statusCode,
                message: errorResponse?.detail
                ?? "The server could not complete this request."
            )
        }
    }
    // Swift PUT function
    func updatePolyp(_ polyp: CoralPolyp) async throws -> CoralPolyp {
        // Build resource path from the shared server address.
        let url = baseURL
            .appendingPathComponent("polyps")
            .appendingPathComponent(polyp.id.uuidString)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        // Send the full replacement record.
        request.httpBody = try JSONEncoder().encode(polyp)
        
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        try validateResponse(
            response,
            data: data,
            expectedStatus: 200
        )
        
        return try JSONDecoder().decode(
            CoralPolyp.self,
            from: data
        )
    }
    // DELETE support
    func deletePolyp(id: UUID) async throws {
        // Identify the backend record to delete.
        let url = baseURL
            .appendingPathComponent( "polyps" )
            .appendingPathComponent(id.uuidString)
        
        // The ID is in the URL; no JSON body is needed.
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        // A successful deletion returns 204 with no body.
        try validateResponse(
            response,
            data: data,
            expectedStatus: 204
        )
    }
    // Session decoder helper
    private func makeSessionDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Accept API timestamps with or without fractional seconds.
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let timestamp = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds
            ]
            
            if let date = formatter.date(from: timestamp) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            
            if let date = formatter.date(from: timestamp) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid API timestamp: \(timestamp)"
            )
        }
        
        return decoder
    }
    // Upload function
    func createSession(_ session: FocusSession) async throws -> FocusSession {
        let url = baseURL.appendingPathComponent("sessions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        // Encode dates as timestamps understood by the backend.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(session)

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        try validateResponse(
            response,
            data: data,
            expectedStatus: 201
        )

        // Decode the created record, including its timestamp.
        return try makeSessionDecoder().decode(
            FocusSession.self,
            from: data
        )
    }
    // Session fetching.
    func fetchSessions() async throws -> [FocusSession] {
        let url = baseURL.appendingPathComponent("sessions")

        // GET returns the backend's session collection.
        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        try validateResponse(
            response,
            data: data,
            expectedStatus: 200
        )

        return try makeSessionDecoder().decode(
            [FocusSession].self,
            from: data
        )
    }
}
