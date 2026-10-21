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
    private let apiClient = ReefAPIClient(
        baseURL: URL(string: "http://127.0.0.1:8000")!
        )
    
    @State private var isCheckingBackend = false
    @State private var backendMessage = ""
    
    // Records received from the API, separate from local polyps
    @State private var remotePolyps: [CoralPolyp] = []
    
    // Add upload to backend state
    @State private var isUploadingPolyp = false
    @State private var uploadMessage = ""
    
    // TEMPORARY CHECK VAR
    @State private var isBackendToolsExpanded = false

    // Backend deletion
    @State private var isShowingBackendDeleteConfirmation = false
    @State private var backendPolypIDToDelete: UUID?
    
    @State private var isUploadingSession = false
    @State private var sessionUploadMessage = ""
    
    // Keep fetched history separate from locally saved sessions.
    @State private var remoteSessions: [FocusSession] = []
    @State private var isFetchingSessions = false
    @State private var sessionFetchMessage = ""
    @State private var isShowingBackendHistory = false
    
    
    @State private var sessionImportMessage = ""
    
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
            
            DisclosureGroup(
                "Backend testing",
                isExpanded: $isBackendToolsExpanded
            ) {
                VStack(alignment:.leading,spacing:12) {
                    
                    Button("Check backend connection") {
                        // Start asynchronous work from the button's action
                        Task {
                            await checkBackend()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isCheckingBackend)
                    
                    Button("Fetch backend session history") {
                        Task {
                            await fetchBackendHistory()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isFetchingSessions)

                    if isFetchingSessions {
                        ProgressView("Fetching history")
                    }

                    if !sessionFetchMessage.isEmpty {
                        Text(sessionFetchMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !remoteSessions.isEmpty {
                        Button("Import fetched sessions") {
                            importBackendSessions()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isFetchingSessions || !canSaveFocusSessions)
                    }

                    if !sessionImportMessage.isEmpty {
                        Text(sessionImportMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Upload missing local sessions") {
                        Task {
                            await uploadMissingSessions()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isUploadingSession || focusSessions.isEmpty)

                    if isUploadingSession {
                        ProgressView("Backing up sessions")
                    }

                    if !sessionUploadMessage.isEmpty {
                        Text(sessionUploadMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    // Feedback for uploading a local polyp.
                    if isUploadingPolyp {
                        ProgressView("Contacting backend")
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
                }
                .padding(.top,8)
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
                                    
                                    Button("Update backend copy") {
                                        Task {
                                            await updateBackendPolyp(polyp)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isUploadingPolyp)
                                    
                                    
                                    Button("Delete backend copy", role: .destructive) {
                                        backendPolypIDToDelete = polyp.id
                                        isShowingBackendDeleteConfirmation = true
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
            SessionHistoryView(
                sessions: focusSessions,
                onUpload: { session in
                    Task {
                        await uploadSession(session)
                    }
                },
                isUploading: isUploadingSession,
                uploadMessage: sessionUploadMessage
            )
        }
        .alert(
            "Delete the backend copy?",
            isPresented: $isShowingBackendDeleteConfirmation
        ) {
            Button("Delete backend copy", role: .destructive) {
                if let id = backendPolypIDToDelete {
                    Task {
                        await deleteBackendPolyp(id: id)
                    }
                }

                backendPolypIDToDelete = nil
            }

            Button("Cancel", role: .cancel) {
                backendPolypIDToDelete = nil
            }
        } message: {
            Text("This deletes the server record. Your local polyp will remain.")
        }
        .sheet(isPresented: $isShowingBackendHistory) {
            SessionHistoryView(
                sessions: remoteSessions,
                isUploading: false,
                uploadMessage: ""
            )
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
    // Helper to connect update action
    @MainActor
    private func updateBackendPolyp(_ polyp: CoralPolyp) async {
        isUploadingPolyp = true
        uploadMessage = "Updating backend..."

        defer {
            isUploadingPolyp = false
        }

        do {
            let updatedPolyp = try await apiClient.updatePolyp(polyp)
            uploadMessage = "Updated: \(updatedPolyp.taskTitle)"
        } catch {
            uploadMessage = "Update failed: \(error.localizedDescription)"
            print("Backend update failed: \(error)")
        }
    }
    // Backend-delete helper
    @MainActor
    private func deleteBackendPolyp(id: UUID) async {
        // Reuse the flag that prevents overlapping backend writes.
        isUploadingPolyp = true
        uploadMessage = "Deleting backend copy..."

        defer {
            isUploadingPolyp = false
        }

        do {
            try await apiClient.deletePolyp(id: id)

            // Remove the deleted record from the displayed backend preview.
            remotePolyps.removeAll { $0.id == id }

            uploadMessage = "Backend copy deleted. Local polyp kept."
        } catch {
            uploadMessage = "Deletion failed: \(error.localizedDescription)"
            print("Backend deletion failed: \(error)")
        }
    }
    
    @MainActor
    private func uploadSession(_ session: FocusSession) async {
        isUploadingSession = true
        sessionUploadMessage = "Uploading..."

        // Clear loading whether the request succeeds or fails.
        defer {
            isUploadingSession = false
        }

        do {
            // Send this existing record, preserving its session ID.
            let createdSession = try await apiClient.createSession(session)

            sessionUploadMessage = "Uploaded: \(createdSession.taskTitle)"
        } catch {
            sessionUploadMessage = "Upload failed: \(error.localizedDescription)"
            print("Session upload failed: \(error)")
        }
    }
    
    @MainActor
    private func uploadMissingSessions() async {
        // Avoid starting another session upload while one is running.
        guard !isUploadingSession else {
            return
        }

        isUploadingSession = true
        sessionUploadMessage = "Checking backend history..."

        // Use a snapshot of local history for this operation.
        let localSessions = focusSessions
        var uploadedCount = 0

        defer {
            isUploadingSession = false
        }

        do {
            // Determine which session IDs already exist remotely.
            let backendSessions = try await apiClient.fetchSessions()
            let backendIDs = Set(backendSessions.map { $0.id })

            let missingSessions = localSessions.filter { session in
                !backendIDs.contains(session.id)
            }

            guard !missingSessions.isEmpty else {
                sessionUploadMessage =
                    "All local sessions already exist on the backend."
                return
            }

            // Wait for each upload before starting the next.
            for session in missingSessions {
                _ = try await apiClient.createSession(session)
                uploadedCount += 1

                sessionUploadMessage =
                    "Uploaded \(uploadedCount) of \(missingSessions.count) sessions."
            }

            sessionUploadMessage =
                "Finished uploading \(uploadedCount) session(s)."
        } catch {
            // Earlier successful uploads remain stored on the backend.
            sessionUploadMessage =
                "Stopped after \(uploadedCount) upload(s): \(error.localizedDescription)"

            print("Session backup failed: \(error)")
        }
    }
    // Fetching function
    @MainActor
    private func fetchBackendHistory() async {
        // Clear feedback from the previous import.
        sessionImportMessage = ""
        isFetchingSessions = true
        sessionFetchMessage = ""

        defer {
            isFetchingSessions = false
        }

        do {
            // Replace the preview only after a successful request.
            remoteSessions = try await apiClient.fetchSessions()

            sessionFetchMessage = "Received \(remoteSessions.count) session(s)."
            isShowingBackendHistory = true
        } catch {
            sessionFetchMessage = "Fetch failed: \(error.localizedDescription)"
            print("Session history fetch failed: \(error)")
        }
    }
    
    private func importBackendSessions() {
        // Protect local history if its initial load failed.
        guard canSaveFocusSessions else {
            showStorageError(
                "Import is unavailable because local session history could not be loaded."
            )
            return
        }

        // Collect the identities already present on this device.
        let existingIDs = Set(focusSessions.map { $0.id })

        // Import only records whose IDs are not already present.
        let newSessions = remoteSessions.filter { session in
            !existingIDs.contains(session.id)
        }

        guard !newSessions.isEmpty else {
            sessionImportMessage = "No new sessions to import."
            return
        }

        focusSessions.append(contentsOf: newSessions)
        saveFocusSessions()

        sessionImportMessage =
            "Added \(newSessions.count) session(s) to local history."
    }
    
}

#Preview {
    ContentView()
}
