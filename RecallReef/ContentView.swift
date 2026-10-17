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
    
    // Storage - views handle interaction, storage types handle encoding, decoding and storage keys
    private let polypStorage = CoralPolypStorage()
    
    private let sessionStorage = FocusSessionStorage()
    
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
    
    // Prevent repeated loading
    @State private var hasLoadedData = false
    
    // Store selected polyp
    @State private var selectedFocusPolyp: CoralPolyp?
    
    // Receive the record
    @State private var focusSessions: [FocusSession] = []
    
    // Displays Session History
    @State private var isShowingSessionHistory = false
    
    // Make storage errors visible
    @State private var isShowingStorageError = false
    @State private var storageErrorMessage = ""
    
    // Saving should only be allowed only after corresponding data loaded successfully
    @State private var canSavePolyps = false
    @State private var canSaveFocusSessions = false
    
    //----------backend-------------
    
    // Call API from app
    private let apiClient = ReefAPIClient()
    
    @State private var isCheckingBackend = false
    @State private var backendMessage = ""
    
    // Records received from the API, separate from local polyps
    @State private var remotePolyps: [CoralPolyp] = []
    
    // Add upload to backend state
    @State private var isUploadingPolyp = false
    @State private var uploadMessage = ""
    
    // ---------------------------------
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
            
            
            Button("Check backend connection") {
                // Start asynchronous work from the button's action
                Task {
                    await checkBackend()
                }
            }
            .buttonStyle(.bordered)
            .disabled(isCheckingBackend)

            // Feedback for uploading a local polyp.
            if isUploadingPolyp {
                ProgressView("Uploading polyp")
            }

            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Existing feedback for fetching backend records
            if isCheckingBackend {
                ProgressView()
            }

            if !backendMessage.isEmpty {
                Text(backendMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            // Display a read-only backend preview
            if !remotePolyps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Backend preview")
                        .font(.headline)

                    // Display each decoded record without editing local data.
                    ForEach(remotePolyps) { polyp in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(polyp.taskTitle)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Stopped at: \(polyp.stoppingPoint)")

                            Text("Next: \(polyp.nextStep)")
                        }
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            Text("Recorded sessions: \(focusSessions.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("View session history") {
                isShowingSessionHistory = true
            }
            .buttonStyle(.bordered)
            
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
                        // Parent receives an explicit notif when you apply an edit
                        ForEach($polyps) { $polyp in
                            if searchText.isEmpty ||
                                polyp.taskTitle.localizedCaseInsensitiveContains(searchText) {
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    CoralPolypCard(polyp: $polyp){
                                        markAsChanged()
                                    }
                                    
                                    Button("Focus on this task") {
                                        selectedFocusPolyp = polyp
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.teal)
                                    
                                    // Add button to upload
                                    Button("Upload to backend") {
                                        Task {
                                            await uploadPolyp(polyp)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isUploadingPolyp)
                                    
                                    Button("Delete polyp", role: .destructive) {
                                        polypIDToDelete = polyp.id
                                        isShowingDeleteConfirmation = true
                                    }
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
        // To open and close the Focus Screen
        //
        .fullScreenCover(item: $selectedFocusPolyp) { polyp in
            FocusSessionView(polyp: polyp) { updatedPolyp, session in
                if let index = polyps.firstIndex(where: {
                    $0.id == updatedPolyp.id
                }) {
                    polyps[index] = updatedPolyp
                    markAsChanged()
                }
                
                if let session {
                    focusSessions.append(session)
                    saveFocusSessions()
                }
            }
        }
        
        .onAppear {
            guard !hasLoadedData else{
                return
            }
            loadPolyps()
            loadFocusSessions()
            hasLoadedData = true
            
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
        .alert(
            "Storage problem",
            isPresented: $isShowingStorageError
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(storageErrorMessage)
        }
        .sheet(isPresented: $isShowingSessionHistory) {
            SessionHistoryView(sessions: focusSessions)
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
        guard canSavePolyps else {
            showStorageError("Saving is unavailable because your existing coral polyps could not be loaded. Your stored data has not been replaced."
            )
            return
        }
        clearSaveConfirmation()
        
        do {
            try polypStorage.save(polyps)
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
            showStorageError("Could not save your coral polyps. Your changes are still in memory. Please try saving again.")
        }
    }
    
    private func loadPolyps() {
        do {
            polyps = try polypStorage.load()
            canSavePolyps = true
        } catch {
            canSavePolyps = false
            print("Could not load polyps: \(error)")
            showStorageError("Could not load your saved coral polyps.")
        }
    }
    private func saveFocusSessions() {
        guard canSaveFocusSessions else {
            showStorageError(
                "Saving is unavailable because your existing session history could not be loaded. Your stored data has not been replaced."
            )
            return
        }
        do {
            try sessionStorage.save(focusSessions)
        } catch {
            print("Could not save focus sessions: \(error)")
            showStorageError(
                "Could not save your session history. The new record is still in memory."
            )
        }
    }
    
    private func loadFocusSessions() {
        do {
            focusSessions = try sessionStorage.load()
            canSaveFocusSessions = true
        } catch {
            canSaveFocusSessions = false
            print("Could not load focus sessions: \(error)")
            showStorageError("Could not load your saved session history.")
        }
    }
    
    private func showStorageError(_ message: String) {
        storageErrorMessage = message
        isShowingStorageError = true
    }
    
    // Backend helper function
    @MainActor // keeps this func interface-state updates on the main actor, awaiting network request still allows interface to be responsive
    private func checkBackend() async {
        isCheckingBackend = true
        backendMessage = "Connecting..."
        // Clear previous results before requesting fresh data.
        remotePolyps = []

        // Always clear the loading state when this function exits
        // Schedules code to run when func exits
        defer {
            isCheckingBackend = false
        }

        do {
            // Store the decoded records so the interface can display them.
            remotePolyps = try await apiClient.fetchPolyps()
            backendMessage = "Connected! Received \(remotePolyps.count) polyp(s)."
        } catch {
            backendMessage = "Connection failed: \(error.localizedDescription)"
            print("Backend connection failed: \(error)")
        }
    }
    
    @MainActor
    private func uploadPolyp(_ polyp: CoralPolyp) async {
        isUploadingPolyp = true
        uploadMessage = "Uploading..."

        // Clear the loading flag on success or failure.
        defer {
            isUploadingPolyp = false
        }

        do {
            // Send a snapshot of this local polyp to the API.
            let createdPolyp = try await apiClient.createPolyp(polyp)

            uploadMessage = "Uploaded: \(createdPolyp.taskTitle)"
        } catch {
            uploadMessage = "Upload failed: \(error.localizedDescription)"
            print("Polyp upload failed: \(error)")
        }
    }
    
    
}

#Preview {
    ContentView()
}
