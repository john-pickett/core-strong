//
//  Routine.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import Foundation
import SwiftData

@Model
final class Routine {
    var name: String

    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var exercises: [RoutineExercise] = []

    init(name: String) {
        self.name = name
    }

    var orderedExercises: [RoutineExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}
