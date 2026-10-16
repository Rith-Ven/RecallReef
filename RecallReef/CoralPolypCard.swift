//
//  CoralPolypCard.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/15/26.
//

import SwiftUI

struct CoralPolypCard: View {
    @Binding var polyp: CoralPolyp
    @State private var isEditing = false
    
    // Independent state owned by the card
    @State private var draft = CoralPolyp(
        taskTitle: "",
        stoppingPoint: "",
        nextStep: ""
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Coral polyp")
                .font(.headline)

            if isEditing {
                TextField("Task title", text: $draft.taskTitle)
                    .textFieldStyle(.roundedBorder)

                TextField("Where did you stop?", text: $draft.stoppingPoint)
                    .textFieldStyle(.roundedBorder)

                TextField("What is your next step?", text: $draft.nextStep)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text(polyp.taskTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Stopped at: \(polyp.stoppingPoint)")
                    .foregroundStyle(.secondary)

                Text("Next: \(polyp.nextStep)")
                    .foregroundStyle(.secondary)
            }

            if isEditing {
                HStack {
                    Button("Cancel") {
                        isEditing = false
                    }

                    Button("Apply changes") {
                        polyp = draft
                        isEditing = false
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Button("Edit") {
                    draft = polyp
                    isEditing = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.teal.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
