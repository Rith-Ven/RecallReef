//
//  SessionHistoryView.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/16/26.
//

import SwiftUI

struct SessionHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    // Receives a read-only array from the parent
    let sessions: [FocusSession]
    
    // The parent supplies the networking action and its status.
    // No upload action means this screen is read-only.
    var onUpload: ((FocusSession) -> Void)? = nil
    
    let isUploading: Bool
    let uploadMessage: String
    
    private var totalFocusedSeconds: Int {
        // Add the duration of every session shown on this screen.
        sessions.reduce(0) { total, session in
            total + session.focusedSeconds
        }
    }
    
    var body: some View {
        NavigationStack {
            // Displays content in vertically scrolling systems list
            List {
                Section("Overview") {
                    HStack {
                        Text("Sessions")
                        Spacer()
                        Text("\(sessions.count)")
                    }

                    HStack {
                        Text("Focused time")
                        Spacer()

                        Text(
                            "\(totalFocusedSeconds / 3600) hr "
                            + "\((totalFocusedSeconds % 3600) / 60) min "
                            + "\(totalFocusedSeconds % 60) sec"
                        )
                    }
                }
                
                if sessions.isEmpty {
                    Text("Your finished focus sessions will appear here.")
                        .foregroundStyle(.secondary)
                }
                // Display upload feedback
                if isUploading {
                    ProgressView("Uploading session")
                }

                if !uploadMessage.isEmpty {
                    Text(uploadMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(
                    // Returns new array ordered from newest to oldest
                    sessions.sorted { $0.startedAt > $1.startedAt }
                ) { session in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.taskTitle)
                            .font(.headline)

                        Text(
                            session.startedAt.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Text(
                            "\(session.focusedSeconds / 60) min "
                            + "\(session.focusedSeconds % 60) sec focused"
                        )

                        Text(
                            session.completedFullTimer
                                ? "Full timer completed"
                                : "Finished early"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    if let onUpload {
                        Button("Upload session") {
                            onUpload(session)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isUploading)
                    }
                }
            }
            .navigationTitle("Session history")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SessionHistoryView(
        sessions: [
            FocusSession(
                polypID: UUID(),
                taskTitle: "Summary test",
                startedAt: Date(),
                focusedSeconds: 3725,
                completedFullTimer: false
            )
        ],
        isUploading: false,
        uploadMessage: ""
    )
}
