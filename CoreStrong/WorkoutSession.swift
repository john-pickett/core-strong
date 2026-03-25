//
//  WorkoutSession.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var startedAt: Date
    var endedAt: Date?
    var isActive: Bool
    var routineName: String
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise] = []

    init(routineName: String) {
        self.startedAt = Date()
        self.isActive = true
        self.routineName = routineName
    }

    var orderedExercises: [SessionExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Elapsed seconds between start and end. Non-nil only for finalized sessions.
    var duration: TimeInterval? {
        guard let end = endedAt else { return nil }
        return end.timeIntervalSince(startedAt)
    }
}
