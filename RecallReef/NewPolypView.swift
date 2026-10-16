//
//  NewPolypView.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/16/26.
//

import SwiftUI

struct NewPolypView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var taskTitle = ""
    @State private var stoppingPoint = ""
    @State private var nextStep = ""

    let onAdd: (CoralPolyp) -> Void

    private var trimmedTitle: String {
        taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Task title", text: $taskTitle)
                }

                Section("Leave a coral polyp") {
                    TextField(
                        "Where did you stop?",
                        text: $stoppingPoint
                    )

                    TextField(
                        "What is your next step?",
                        text: $nextStep
                    )
                }
            }
            .navigationTitle("New coral polyp")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let polyp = CoralPolyp(
                            taskTitle: trimmedTitle,
                            stoppingPoint: stoppingPoint,
                            nextStep: nextStep
                        )

                        onAdd(polyp)
                        dismiss()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
        }
    }
}
