//
//  WorkoutActivityAttributes.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//
//  NOTE: This file must be added to BOTH the CoreStrong and CoreStrongWidgets
//  targets via Xcode's File Inspector → Target Membership panel.
//

import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Anchor date for Text(startDate, style: .timer).
        /// Counts up automatically — no push updates required for the elapsed time display.
        var startDate: Date
        var currentExerciseName: String
        var setsCompleted: Int
        var totalSets: Int
    }

    /// Static — set once at activity creation and never updated.
    var routineName: String
}
