//
//  RoutineExercise.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import Foundation
import SwiftData

@Model
final class RoutineExercise {
    var orderIndex: Int
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double
    var restDuration: Int   // seconds; 0 means "use app default"

    var routine: Routine?
    var exercise: Exercise?

    init(
        orderIndex: Int,
        targetSets: Int = 3,
        targetReps: Int = 10,
        targetWeight: Double = 0,
        restDuration: Int = 0,
        exercise: Exercise
    ) {
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restDuration = restDuration
        self.exercise = exercise
    }

    var weightText: String {
        guard targetWeight > 0 else { return "BW" }
        let isWhole = targetWeight.truncatingRemainder(dividingBy: 1) == 0
        return isWhole ? "\(Int(targetWeight)) lbs" : String(format: "%.1f lbs", targetWeight)
    }
}
