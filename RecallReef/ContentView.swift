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
    
    @State private var polyps: [CoralPolyp] = []
    
    @AppStorage("savedPolyp")
    private var savedPolypData: Data = Data()
    
    @AppStorage("savedPolyps")
    private var savedPolypsData: Data = Data()
    
    @State private var isShowingNewPolyp = false
    
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
                ScrollView{
                    VStack(spacing: 16){
                        if polyps.isEmpty {
                            Text("Leave your first coral polyp.")
                                .foregroundStyle(.secondary)
                        }
                        // Creates a view for each element
                        ForEach($polyps) { $polyp in
                            VStack(alignment: .leading, spacing: 8) {
                                CoralPolypCard(polyp: $polyp)

                                Button("Delete polyp", role: .destructive) {
                                    deletePolyp(id: polyp.id)
                                }
                            }
                            .onChange(of: polyp.taskTitle) {
                                clearSaveConfirmation()
                            }
                            .onChange(of: polyp.stoppingPoint) {
                                clearSaveConfirmation()
                            }
                            .onChange(of: polyp.nextStep) {
                                clearSaveConfirmation()
                            }
                        }
                    }
                }
            }
            Button (isPolypVisible ? "Hide coral polyp" : "Show coral polyp") {
                isPolypVisible.toggle( )
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            
            if isPolypVisible {
                Button("Add coral polyp") {
                    isShowingNewPolyp = true
                }
                .buttonStyle(.bordered)
                
                Button("Save polyps") {
                    savePolyps()
                }
                .buttonStyle(.bordered)
            }
            if isPolypSaved {
                Label("Polyps saved", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
        }
        .padding()
        .sheet(isPresented: $isShowingNewPolyp) {
            NewPolypView { newPolyp in
                polyps.append(newPolyp)
                clearSaveConfirmation()
            }
        }
        .onAppear {
            loadPolyps()
    
        }
    }
    
    private func deletePolyp(id: UUID) {
        clearSaveConfirmation()

        polyps.removeAll { polyp in
            polyp.id == id
        }
    }
    
    private func clearSaveConfirmation() {
        saveConfirmationTask?.cancel()
        isPolypSaved = false
    }
    
    private func savePolyps() {
        clearSaveConfirmation()
        
        do {
            let encodedPolyps = try JSONEncoder().encode(polyps)
            savedPolypsData = encodedPolyps
            isPolypSaved = true
            
            saveConfirmationTask = Task { @MainActor in
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    return
                }
                
                withAnimation(.easeOut(duration: 0.4)) {
                    isPolypSaved = false
                }
            }
        } catch {
            print("Could not save polyps: \(error)")
        }
    }
    
    private func loadPolyps() {
        do {
            if !savedPolypsData.isEmpty {
                polyps = try JSONDecoder().decode(
                    [CoralPolyp].self,
                    from: savedPolypsData
                )
            } else if !savedPolypData.isEmpty {
                let oldPolyp = try JSONDecoder().decode(
                    CoralPolyp.self,
                    from: savedPolypData
                )
                
                polyps = [oldPolyp]
            }
        } catch {
            print("Could not load polyps: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
