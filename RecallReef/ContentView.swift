//
//  ContentView.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/15/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isPolypVisible = true
    @AppStorage("nextStep") // name in persistent storage (local persistence on the device)
    private var nextStep = "Trace how the array changes inside createArr." // name used in swift code
    private let examplePolyp = CoralPolyp(
        taskTitle: "Study C pointers",
        stoppingPoint: "Finished tracing the function call.",
        nextStep: "Explain why the original array changes."
    )
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Recall Reef")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Pick up where you left off.")
                .foregroundStyle(.secondary)
            
            if isPolypVisible {
                CoralPolypCard(
                    polyp: examplePolyp,
                    nextStep: $nextStep
                )
            }
            Button (isPolypVisible ? "Hide coral polyp" : "Show coral polyp") {
                isPolypVisible.toggle( )
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
