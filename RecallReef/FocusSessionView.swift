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
    // Access an individual polyp
    let polyp: CoralPolyp
    
    // Lets the parent receive the updated polyp + hold local draft notes
    // Now accepts two values - updated polyp + optional session record
    let onFinish: (CoralPolyp, FocusSession?) -> Void

    @State private var isFinishing = false
    @State private var stoppingPoint = ""
    @State private var nextStep = ""
    
    @State private var startedAt: Date? // nil - opening screen doesn't mean you've started focusing
    
    // Marks beginning of current uninterrupted stretch
    @State private var runningSegmentStartedAt: Date?
    // Holds the total from stretches already finished
    @State private var accumulatedFocusSeconds: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Focus session")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(polyp.taskTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            // Makes the timestamp visible
            if let startedAt { // upwraps the optional date
                Text("Started at \(startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !polyp.nextStep.isEmpty {
                Text("Next: \(polyp.nextStep)")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text(formattedTime)
                .font(.system(size: 64, weight: .medium, design: .rounded))
                .monospacedDigit()
            if !isFinishing {
                
                Button(timerButtonTitle) {
                    if isRunning {
                        updateRemainingTime()
                        finishRunningSegment()
                        isRunning = false
                        endDate = nil
                    } else {
                        let now = Date()
                        if startedAt == nil {
                            // When this session first began (doesn't change on resume)
                            startedAt = now
                        }
                        runningSegmentStartedAt = now
                        // When the current countdown will finish (changes on resume)
                        endDate = now.addingTimeInterval(
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
                
                // "Discard this attempt and prepare a fresh one"
                Button("Reset"){
                    isRunning = false
                    endDate = nil
                    runningSegmentStartedAt = nil
                    accumulatedFocusSeconds = 0
                    remainingSeconds = sessionDuration
                    startedAt = nil
                    
                    
                }
                .buttonStyle(.bordered)
            }
            
            
            // Leave an updated polyp when you finish working
            if isFinishing {
                TextField("Where did you stop?", text: $stoppingPoint)
                    .textFieldStyle(.roundedBorder)

                TextField("What is your next step?", text: $nextStep)
                    .textFieldStyle(.roundedBorder)

                Button("Apply notes and close") {
                    var updatedPolyp = polyp // mutable copy
                    updatedPolyp.stoppingPoint = stoppingPoint
                    updatedPolyp.nextStep = nextStep

                    let session: FocusSession?

                    if let startedAt {
                        session = FocusSession(
                            polypID: polyp.id,
                            taskTitle: polyp.taskTitle,
                            startedAt: startedAt,
                            focusedSeconds:
                                // Converts measured duration to whole seconds 
                                Int(accumulatedFocusSeconds),
                            completedFullTimer: remainingSeconds == 0
                        )
                    } else {
                        session = nil
                    }

                    onFinish(updatedPolyp, session)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
            } else {
                Button("Finish and leave a polyp") {
                    if isRunning {
                        updateRemainingTime()
                    }
                    finishRunningSegment()
                    isRunning = false
                    endDate = nil

                    stoppingPoint = polyp.stoppingPoint
                    nextStep = polyp.nextStep
                    isFinishing = true
                    //print("Focused seconds: \(accumulatedFocusSeconds)")
                }
                .buttonStyle(.bordered)
            }
            
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
    
    private func finishRunningSegment() {
        guard let segmentStart = runningSegmentStartedAt else {
            return
        }

        let segmentEnd = min(Date(), endDate ?? Date())

        accumulatedFocusSeconds += max(
            0,
            segmentEnd.timeIntervalSince(segmentStart)
        )

        runningSegmentStartedAt = nil
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
            finishRunningSegment()
            isRunning = false
            self.endDate = nil
        }
    }
}

// Preview supplies a polyp
#Preview {
    FocusSessionView(
        polyp: CoralPolyp(
            taskTitle: "Study Swift",
            stoppingPoint: "Practiced bindings.",
            nextStep: "Build a focus session."
        )
    ) { _ , _ in } // empty action bc screen requires onFinish, preview ignores the returned polyp and session record
}
