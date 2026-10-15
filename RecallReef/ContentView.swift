//
//  ContentView.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/15/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isPolypVisible = true
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
                VStack(alignment: .leading, spacing: 8){
                    Text("Your last coral polyp")
                        .font(.headline)
                    Text("Study C pointers")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Next: trace how the array changes inside createArr.")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.teal.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
