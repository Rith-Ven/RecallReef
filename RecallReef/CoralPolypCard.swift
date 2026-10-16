//
//  CoralPolypCard.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/15/26.
//

import SwiftUI

struct CoralPolypCard: View {
    @Binding var polyp: CoralPolyp
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Coral polyp")
                .font(.headline)
            Text(polyp.taskTitle)
                .font(.title2)
                .fontWeight(.semibold)
            TextField("Task title", text: $polyp.taskTitle)
                .textFieldStyle(.roundedBorder)
            Text(polyp.stoppingPoint)
            TextField("Where did you stop?", text: $polyp.stoppingPoint)
                .textFieldStyle(.roundedBorder)
            Text("Next step: \(polyp.nextStep)")
                .foregroundStyle(.secondary)
            TextField("What is your next step?", text: $polyp.nextStep)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color.teal.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
