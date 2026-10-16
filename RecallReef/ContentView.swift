//
//  ContentView.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/15/26.
//

// Binding - read and edit this value I own
// Closure - call this action when something happens
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
    
    // To delete a polyp
    @State private var isShowingDeleteConfirmation = false
    @State private var polypIDToDelete: UUID?
    
    // To find a polyp by task title
    @State private var searchText = ""
    
    // To show feedback when nothing matches
    private var hasSearchResults: Bool {
        polyps.contains { polyp in
            polyp.taskTitle.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // To make unsaved changes clear
    @State private var hasUnsavedChanges = false
    
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
                TextField("Search tasks", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                ScrollView{
                    VStack(spacing: 16){
                        if polyps.isEmpty {
                            Text("Leave your first coral polyp.")
                                .foregroundStyle(.secondary)
                        }
                        // No search matches
                        if !polyps.isEmpty && !searchText.isEmpty && !hasSearchResults {
                            Text("No matching tasks.")
                                .foregroundStyle(.secondary)
                        }
                        
                        // Creates a view for each element
                        ForEach($polyps) { $polyp in
                            if searchText.isEmpty ||
                                polyp.taskTitle.localizedCaseInsensitiveContains(searchText) {

                                VStack(alignment: .leading, spacing: 8) {
                                    CoralPolypCard(polyp: $polyp)

                                    Button("Delete polyp", role: .destructive) {
                                        polypIDToDelete = polyp.id
                                        isShowingDeleteConfirmation = true
                                    }
                                }
                                .onChange(of: polyp.taskTitle) {
                                    markAsChanged()
                                }
                                .onChange(of: polyp.stoppingPoint) {
                                    markAsChanged()
                                }
                                .onChange(of: polyp.nextStep) {
                                    markAsChanged()
                                }
                            }
                        }
                    }
                }
            }
            Button (isPolypVisible ? "Hide coral polyps" : "Show coral polyps") {
                isPolypVisible.toggle( )
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            
            if isPolypVisible {
                Button("Add coral polyp") {
                    isShowingNewPolyp = true
                }
                .buttonStyle(.bordered)
                
                if hasUnsavedChanges {
                    Text("You have unsaved changes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
               
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
                markAsChanged()
            }
        }
        .onAppear {
            loadPolyps()
    
        }
        .alert(
            "Delete this coral polyp?",
            isPresented: $isShowingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                if let id = polypIDToDelete {
                    deletePolyp(id: id)
                }

                polypIDToDelete = nil
            }

            Button("Cancel", role: .cancel) {
                polypIDToDelete = nil
            }
        } message: {
            Text("This removes the polyp from your current collection.")
        }
    }
    
    
    // Helper Functions
    
    private func markAsChanged() {
        clearSaveConfirmation()
        hasUnsavedChanges = true
    }
    
    private func deletePolyp(id: UUID) {
        markAsChanged()

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
            hasUnsavedChanges = false
            
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
