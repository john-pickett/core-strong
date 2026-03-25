//
//  SessionExercise.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import Foundation
import SwiftData

@Model
final class SessionExercise {
    var orderIndex: Int
    var exerciseName: String

    // Snapshot of targets from the routine at session creation time
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double

    // Snapshot of what was done in the most recent prior session for this exercise.
    // Populated at session creation; 0/false if no prior session exists.
    var hasPreviousData: Bool
    var previousSets: Int
    var previousReps: Int
    var previousWeight: Double

    // Snapshotted from RoutineExercise at session creation; 0 means "use app default"
    var restDuration: Int

    // Live reference kept for history queries; may become nil if exercise is deleted
    var exercise: Exercise?
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.sessionExercise)
    var sets: [SetLog] = []

    init(
        orderIndex: Int,
        exerciseName: String,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Double,
        restDuration: Int = 0,
        exercise: Exercise?
    ) {
        self.orderIndex = orderIndex
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restDuration = restDuration
        self.hasPreviousData = false
        self.previousSets = 0
        self.previousReps = 0
        self.previousWeight = 0
        self.exercise = exercise
    }

    var orderedSets: [SetLog] { sets.sorted { $0.orderIndex < $1.orderIndex } }

    var targetWeightText: String { weightLabel(targetWeight) }
    var previousWeightText: String { weightLabel(previousWeight) }

    private func weightLabel(_ value: Double) -> String {
        guard value > 0 else { return "BW" }
        let isWhole = value.truncatingRemainder(dividingBy: 1) == 0
        return isWhole ? "\(Int(value)) lbs" : String(format: "%.1f lbs", value)
    }
}
