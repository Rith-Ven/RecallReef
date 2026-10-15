//
//  CoralPolyp.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/15/26.
//

import Foundation

// Codable is a protocol - a set of requirements a type agrees to support
// Encodable (converting into JSON) and decodable (creating from saved data)

struct CoralPolyp: Codable{
    var taskTitle: String
    var stoppingPoint: String
    var nextStep: String
}
//
//let examplePolyp = CoralPolyp(
//    taskTitle: "Study C pointers",
//    stoppingPoint: "Finished tracing the function call.",
//    nextStep: "Explain why the original array changes."
//)
//
