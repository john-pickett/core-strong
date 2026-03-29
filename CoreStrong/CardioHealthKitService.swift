//
//  CardioHealthKitService.swift
//  CoreStrong
//

import HealthKit
import SwiftData

struct CardioHealthKitService {

    private static let store = HKHealthStore()

    // MARK: - Activity Type Mapping

    static func hkActivityType(for type: CardioActivityType) -> HKWorkoutActivityType {
        switch type {
        case .running:      return .running
        case .walking:      return .walking
        case .cycling:      return .cycling
        case .rowing:       return .rowing
        case .elliptical:   return .elliptical
        case .stairClimber: return .stairClimbing
        case .swimming:     return .swimming
        }
    }

    static func cardioActivityType(for hkType: HKWorkoutActivityType) -> CardioActivityType? {
        switch hkType {
        case .running:       return .running
        case .walking:       return .walking
        case .cycling:       return .cycling
        case .rowing:        return .rowing
        case .elliptical:    return .elliptical
        case .stairClimbing: return .stairClimber
        case .swimming:      return .swimming
        default:             return nil
        }
    }

    // MARK: - Import from Apple Health

    /// Queries Apple Health for cardio workouts from the last 90 days and inserts any that
    /// aren't already in the local store. Imported sessions are marked `isReviewed = false`.
    static func importWorkouts(context: ModelContext) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        // Collect HK UUIDs already stored locally to skip duplicates.
        let existing = (try? context.fetch(FetchDescriptor<CardioSession>())) ?? []
        let existingHKIDs = Set(existing.compactMap(\.healthKitWorkoutID))

        // Compound predicate: supported activity types OR'd together, limited to 90 days.
        let supportedTypes: [HKWorkoutActivityType] = [
            .running, .walking, .cycling, .rowing, .elliptical, .stairClimbing, .swimming
        ]
        let typePredicates = supportedTypes.map { HKQuery.predicateForWorkouts(with: $0) }
        let activityPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: typePredicates)

        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        let datePredicate = HKQuery.predicateForSamples(
            withStart: cutoff, end: nil, options: .strictStartDate
        )
        let combined = NSCompoundPredicate(andPredicateWithSubpredicates: [activityPredicate, datePredicate])

        let descriptor = HKSampleQueryDescriptor(
            predicates: [HKSamplePredicate<HKWorkout>.workout(combined)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 200
        )

        guard let workouts = try? await descriptor.result(for: store) else { return }

        for workout in workouts {
            guard !existingHKIDs.contains(workout.uuid),
                  let activityType = cardioActivityType(for: workout.workoutActivityType)
            else { continue }

            let session = CardioSession(activityType: activityType)
            session.date = workout.startDate
            session.durationSeconds = Int(workout.duration)
            session.healthKitWorkoutID = workout.uuid
            session.isReviewed = false

            // Outdoor/indoor from HK metadata (true = indoor → isOutdoor = false)
            let isIndoor = workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool ?? false
            session.isOutdoor = !isIndoor

            session.distanceMiles = distanceMiles(from: workout, activityType: activityType)
            session.elevationGain = elevationFeet(from: workout)

            // Average and max heart rate computed in a single query pass.
            let hrStats = await fetchHeartRateStats(for: workout)
            session.averageHeartRate = hrStats.average
            session.maxHeartRate = hrStats.max

            context.insert(session)
        }
    }

    // MARK: - Export to Apple Health

    /// Writes a manually-logged cardio session to Apple Health and returns the HKWorkout UUID.
    /// - Throws: `HealthKitServiceError.unavailable` if HealthKit is unsupported.
    static func logWorkout(session: CardioSession) async throws -> UUID {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitServiceError.unavailable
        }

        let start = session.date
        let end = start.addingTimeInterval(TimeInterval(session.durationSeconds))

        let config = HKWorkoutConfiguration()
        config.activityType = hkActivityType(for: session.activityType)
        config.locationType = session.isOutdoor ? .outdoor : .indoor

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: config,
            device: .local()
        )

        try await builder.beginCollection(at: start)

        var samples: [HKSample] = []

        // MET-based calorie estimate; 70 kg default body weight.
        let durationHours = Double(session.durationSeconds) / 3600.0
        let met: Double = {
            switch session.activityType {
            case .running:      return 9.8
            case .cycling:      return 7.5
            case .swimming:     return 7.0
            case .rowing:       return 7.0
            case .walking:      return 3.5
            case .elliptical:   return 5.0
            case .stairClimber: return 8.0
            }
        }()
        let kcal = met * 70.0 * durationHours
        samples.append(HKQuantitySample(
            type: HKQuantityType(.activeEnergyBurned),
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal),
            start: start,
            end: end
        ))

        // Distance sample (only for activity types with a matching HK quantity type)
        if session.distanceMiles > 0, let distanceType = distanceQuantityType(for: session.activityType) {
            let meters = session.distanceMiles * 1609.344
            samples.append(HKQuantitySample(
                type: distanceType,
                quantity: HKQuantity(unit: .meter(), doubleValue: meters),
                start: start,
                end: end
            ))
        }

        try await builder.addSamples(samples)
        try await builder.endCollection(at: end)

        guard let workout = try await builder.finishWorkout() else {
            throw HealthKitServiceError.unavailable
        }
        return workout.uuid
    }

    // MARK: - Private Helpers

    private static func distanceMiles(from workout: HKWorkout, activityType: CardioActivityType) -> Double {
        guard let qType = distanceQuantityType(for: activityType),
              let stats = workout.statistics(for: qType),
              let sum = stats.sumQuantity() else { return 0.0 }
        return sum.doubleValue(for: .mile())
    }

    private static func distanceQuantityType(for activityType: CardioActivityType) -> HKQuantityType? {
        switch activityType {
        case .running, .walking, .stairClimber:
            return HKQuantityType(.distanceWalkingRunning)
        case .cycling:
            return HKQuantityType(.distanceCycling)
        case .swimming:
            return HKQuantityType(.distanceSwimming)
        case .rowing, .elliptical:
            return nil
        }
    }

    private static func elevationFeet(from workout: HKWorkout) -> Double {
        guard let quantity = workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity else {
            return 0.0
        }
        return quantity.doubleValue(for: .foot())
    }

    private static func fetchHeartRateStats(for workout: HKWorkout) async -> (average: Double, max: Double) {
        let hrType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [HKSamplePredicate<HKQuantitySample>.quantitySample(type: hrType, predicate: predicate)],
            sortDescriptors: []
        )

        guard let samples = try? await descriptor.result(for: store), !samples.isEmpty else {
            return (0.0, 0.0)
        }

        let beatsPerMin = HKUnit(from: "count/min")
        let values = samples.map { $0.quantity.doubleValue(for: beatsPerMin) }
        let average = values.reduce(0.0, +) / Double(values.count)
        let max = values.max() ?? 0.0
        return (average, max)
    }
}
