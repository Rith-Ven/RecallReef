//
//  FocusSessionView.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/16/26.
//

import SwiftUI

struct FocusSessionView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Focus session")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Make a little progress on your reef.")
                .foregroundStyle(.secondary)

            Text("25:00")
                .font(.system(size: 64, weight: .medium, design: .rounded))
                .monospacedDigit()
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    FocusSessionView()
}
