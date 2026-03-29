//
//  HealthKitService.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import HealthKit

// MARK: - Error types

enum HealthKitServiceError: Error {
    /// The device does not support HealthKit (iPad, Simulator).
    case unavailable
}

// MARK: - HealthKitService

struct HealthKitService {

    private static let store = HKHealthStore()

    // MARK: - Authorization

    /// Requests authorization for all workout types the app reads and writes.
    /// Safe to call repeatedly — HealthKit only shows the system sheet for undetermined types.
    static func requestAuthorizationIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToShare: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.distanceSwimming),
        ]

        let typesToRead: Set<HKObjectType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.distanceSwimming),
            HKQuantityType(.elevationAscended),
        ]

        // requestAuthorization never throws; errors are surfaced at read/write time.
        try? await store.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }

    // MARK: - Write workout

    /// Writes a completed workout session to HealthKit and returns the HKWorkout UUID.
    /// - Throws: `HealthKitServiceError.unavailable` if HealthKit is not supported on this device.
    /// - Throws: Any `HKError` if the underlying write operation fails (e.g. permission denied).
    static func logWorkout(session: WorkoutSession) async throws -> UUID {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitServiceError.unavailable
        }

        let start = session.startedAt
        let end   = session.endedAt ?? Date()

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: config,
            device: .local()
        )

        try await builder.beginCollection(at: start)

        // MET-based calorie estimate: MET × weight_kg × duration_hours
        // MET 5.0 for moderate strength training; 70 kg default body weight.
        // TODO: Personalize by querying HKQuantityType(.bodyMass) from HealthKit.
        let durationHours = end.timeIntervalSince(start) / 3600
        let kcal          = 5.0 * 70.0 * durationHours

        let energySample = HKQuantitySample(
            type:     HKQuantityType(.activeEnergyBurned),
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal),
            start:    start,
            end:      end
        )

        // addSamples must be called before endCollection
        try await builder.addSamples([energySample])
        try await builder.endCollection(at: end)

        guard let workout = try await builder.finishWorkout() else {
            throw HealthKitServiceError.unavailable
        }
        return workout.uuid
    }
}
