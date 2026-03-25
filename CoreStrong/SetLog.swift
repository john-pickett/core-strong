//
//  SetLog.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import Foundation
import SwiftData

@Model
final class SetLog {
    var orderIndex: Int
    var reps: Int
    var weight: Double
    var completedAt: Date?
    var sessionExercise: SessionExercise?

    init(orderIndex: Int, reps: Int, weight: Double) {
        self.orderIndex = orderIndex
        self.reps = reps
        self.weight = weight
        self.completedAt = nil
    }

    var isCompleted: Bool { completedAt != nil }
}
