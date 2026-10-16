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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Coral polyp")
                .font(.headline)

            if isEditing {
                TextField("Task title", text: $polyp.taskTitle)
                    .textFieldStyle(.roundedBorder)

                TextField("Where did you stop?", text: $polyp.stoppingPoint)
                    .textFieldStyle(.roundedBorder)

                TextField("What is your next step?", text: $polyp.nextStep)
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

            Button(isEditing ? "Done editing" : "Edit") {
                isEditing.toggle()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.teal.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
