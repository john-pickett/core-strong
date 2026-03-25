//
//  HealthKitService.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import Foundation

/// Stub service for HealthKit integration.
/// Full implementation (HKHealthStore authorization + HKWorkout write) coming in a future release.
struct HealthKitService {

    /// Records a completed workout session to HealthKit.
    /// - Parameter session: The finalized `WorkoutSession` to log.
    static func logWorkout(session: WorkoutSession) {
        // TODO: Request HKHealthStore authorization and write an HKWorkout
        let seconds = session.duration?.rounded() ?? 0
        print("[HealthKit] stub — '\(session.routineName)' duration \(Int(seconds))s")
    }
}
