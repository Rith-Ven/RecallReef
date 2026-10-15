//
//  ContentView.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/15/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isPolypVisible = false
    @State private var isPolypSaved = false
    @State private var saveConfirmationTask: Task <Void, Never>? // stores an optional async task
    
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
            
            if isPolypVisible {
                Button("Save polyp") {
                    savePolyp()
                }
                .buttonStyle(.bordered)
            }
            if isPolypSaved {
                Label("Polyp saved", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
            
        }
        .padding()
        .onAppear {
            loadPolyp()
        }
        .onChange(of: polyp.taskTitle) {
            isPolypSaved = false
        }
        .onChange(of: polyp.nextStep) {
            isPolypSaved = false
        }
    }
    private func savePolyp(){
        do {
            let encodedPolyp = try JSONEncoder().encode(polyp)
            savedPolypData = encodedPolyp
            isPolypSaved = true
            
            saveConfirmationTask = Task { @MainActor in
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch { return }
                withAnimation(.easeOut(duration: 0.4)) {
                    isPolypSaved = false
                }
            }
        } catch {
            isPolypSaved = false
            print("Could not save polyp: \(error)")
        }
    }
    private func loadPolyp(){
        guard !savedPolypData.isEmpty else {
            return
        }
        do {
            let decodedPolyp = try JSONDecoder().decode(
                CoralPolyp.self,
                from: savedPolypData
            )
            polyp = decodedPolyp
        } catch {
            print("Could not load polyp: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
