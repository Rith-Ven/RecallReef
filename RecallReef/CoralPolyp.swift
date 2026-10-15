//
//  CoralPolyp.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/15/26.
//

import Foundation

// Codable is a protocol - a set of requirements a type agrees to support
// Encodable (converting into JSON) and decodable (creating from saved data)
// Property names become JSON keys and contents become values

// Identifiable - id property that uniquely identifies a value


struct CoralPolyp: Codable, Identifiable{
    var id: UUID = UUID()
    var taskTitle: String
    var stoppingPoint: String
    var nextStep: String
    
    // To keep previously saved JSON loadable
    enum CodingKeys: String, CodingKey {
        case id, taskTitle, stoppingPoint, nextStep
    }
    // Lets up keep creating polyps with the initializer we already use
    init(
        id: UUID = UUID(),
        taskTitle: String,
        stoppingPoint: String,
        nextStep: String
    ) {
        self.id = id
        self.taskTitle = taskTitle
        self.stoppingPoint = stoppingPoint
        self.nextStep = nextStep
    }
    // Defines how to create a polyp from saved data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID() // Supplies new ID if none
        taskTitle = try container.decode(String.self, forKey: .taskTitle)
        stoppingPoint = try container.decode(String.self, forKey: .stoppingPoint)
        nextStep = try container.decode(String.self, forKey: .nextStep)
    }
}
//
//let examplePolyp = CoralPolyp(
//    taskTitle: "Study C pointers",
//    stoppingPoint: "Finished tracing the function call.",
//    nextStep: "Explain why the original array changes."
//)
//
