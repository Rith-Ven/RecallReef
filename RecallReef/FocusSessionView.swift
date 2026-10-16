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
    
    // Computed property to find mins and seconds
    private var formattedTime: String {
        let minutes = remainingSeconds / 60 // int div gives whole mins
        let seconds = remainingSeconds % 60 // remainder is leftover secs

        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    @State private var isRunning = false
    
    @State private var endDate: Date?
    
    private let sessionDuration = 25 * 60
    
    // Chooses button label based on the current state
    private var timerButtonTitle: String {
        if isRunning {
            return "Pause"
        }

        if remainingSeconds < sessionDuration {
            return "Resume"
        }

        return "Start"
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
            
            
            Button(timerButtonTitle) {
                if isRunning {
                    updateRemainingTime()
                    isRunning = false
                    endDate = nil
                } else {
                    endDate = Date().addingTimeInterval(
                        TimeInterval(remainingSeconds)
                    )
                    isRunning = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .disabled(remainingSeconds == 0)
            
            if remainingSeconds == 0 {
                Label("Focus session complete!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.teal)

                Text("Before you leave, think about where you stopped and what comes next.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            
            Button("Reset"){
                isRunning = false
                endDate = nil
                remainingSeconds = sessionDuration
                
            }
            .buttonStyle(.bordered)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        
        .task(id: isRunning) {
            guard isRunning else {
                return
            }

            while !Task.isCancelled && isRunning {
                updateRemainingTime()

                guard isRunning else {
                    return
                }

                do {
                    try await Task.sleep(for: .milliseconds(200))
                } catch {
                    return
                }
            }
        }
        
    }
    
    private func updateRemainingTime() {
        guard let endDate else {
            return
        }

        remainingSeconds = max(
            0,
            Int(ceil(endDate.timeIntervalSinceNow))
        )

        if remainingSeconds == 0 {
            isRunning = false
            self.endDate = nil
        }
    }
}

#Preview {
    FocusSessionView()
}
