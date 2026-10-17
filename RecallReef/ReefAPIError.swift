//
//  ReefAPIError.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/17/26.
//

import Foundation

// The shape of our backend's simple error responses
struct APIErrorResponse: Decodable {
    let detail: String
}

// An error with a message suitable for the interface
// Stores status code and message together in custom explanation
enum ReefAPIError: LocalizedError {
    case server(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case let .server(statusCode, message):
            return "\(message) (HTTP \(statusCode))"
        }
    }
}
