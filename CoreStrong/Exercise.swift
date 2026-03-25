//
//  Exercise.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var primaryMuscleGroup: String
    var equipment: String
    var isCustom: Bool
    var isArchived: Bool

    init(
        name: String,
        primaryMuscleGroup: String,
        equipment: String,
        isCustom: Bool = false,
        isArchived: Bool = false
    ) {
        self.name = name
        self.primaryMuscleGroup = primaryMuscleGroup
        self.equipment = equipment
        self.isCustom = isCustom
        self.isArchived = isArchived
    }
}
