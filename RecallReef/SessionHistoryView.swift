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
    let onUpload: (FocusSession) -> Void
    let isUploading: Bool
    let uploadMessage: String
    
    // Backend records only need to be viewed.
    var showsUploadControls = true

    var body: some View {
        NavigationStack {
            // Displays content in vertically scrolling systems list
            List {
                
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
                    if showsUploadControls {
                        Button("Upload session") {
                            onUpload(session)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isUploading)
                        .padding(.vertical, 4)
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
        sessions: [],
        onUpload: { _ in },
        isUploading: false,
        uploadMessage: ""
    )
}
