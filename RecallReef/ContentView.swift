//
//  ContentView.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/15/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isPolypVisible = true
    
    @State private var polyp = CoralPolyp(
        taskTitle: "Study C pointers",
        stoppingPoint: "Finished tracing the function call.",
        nextStep: "Explain why the original array changes."
        )
    @AppStorage("savedPolyp")
    private var savedPolypData: Data = Data()
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
                CoralPolypCard(polyp: $polyp)
            }
            
            Button (isPolypVisible ? "Hide coral polyp" : "Show coral polyp") {
                isPolypVisible.toggle( )
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            
            Button("Save polyp") {
                savePolyp()
            }
            .buttonStyle(.bordered)
            
        }
        .padding()
    }
    private func savePolyp(){
        do {
            let encodedPolyp = try JSONEncoder().encode(polyp)
            savedPolypData = encodedPolyp
        } catch {
            print("Could not save polyp: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
