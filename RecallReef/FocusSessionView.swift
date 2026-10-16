//
//  FocusSessionView.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/16/26.
//

import SwiftUI

struct FocusSessionView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var remainingSeconds = 25 * 60
    
    // Computed property
    private var formattedTime: String {
        let minutes = remainingSeconds / 60 // int div gives whole mins
        let seconds = remainingSeconds % 60 // remainder is leftover secs

        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Focus session")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Make a little progress on your reef.")
                .foregroundStyle(.secondary)

            Text(formattedTime)
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
