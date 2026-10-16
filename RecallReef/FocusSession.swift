//
//  FocusSession.swift
//  RecallReef
//
//  Created by Rithanya Venkatesh on 10/16/26.
//

import Foundation

struct FocusSession: Codable, Identifiable {
    var id: UUID = UUID() // Which individual session is this?
    var polypID: UUID // Which coral polyp was it associated with?
    var taskTitle: String // What was the task called during this session?
    var startedAt: Date // When did the session begin?
    var focusedSeconds: Int // How many seconds did you spend focusing (excluding pauses)?
    var completedFullTimer: Bool // Did the countdown reach zero, or did you finish early?
}
