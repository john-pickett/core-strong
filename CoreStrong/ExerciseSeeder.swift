//
//  ExerciseSeeder.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import Foundation
import SwiftData

private struct ExerciseSeed: Decodable {
    let name: String
    let primaryMuscleGroup: String
    let equipment: String
}

struct ExerciseSeeder {
    private static let seededKey = "exerciseLibrarySeeded"

    static func seedIfNeeded(context: ModelContext) {
        if UserDefaults.standard.bool(forKey: seededKey) {
            // If the flag is set but the store was wiped (e.g. after a schema migration),
            // the count will be zero — fall through and re-seed.
            let existingCount = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
            guard existingCount == 0 else { return }
        }

        guard
            let url = Bundle.main.url(forResource: "exercise", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let seeds = try? JSONDecoder().decode([ExerciseSeed].self, from: data)
        else { return }

        for seed in seeds {
            context.insert(Exercise(
                name: seed.name,
                primaryMuscleGroup: seed.primaryMuscleGroup,
                equipment: seed.equipment,
                isCustom: false
            ))
        }

        UserDefaults.standard.set(true, forKey: seededKey)
    }
}
