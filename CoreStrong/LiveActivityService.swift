//
//  LiveActivityService.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import ActivityKit
import Foundation

/// Manages the lifecycle of the workout Live Activity.
/// All methods are @MainActor because Activity API must be called on the main actor.
@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()
    private init() {}

    private var activity: Activity<WorkoutActivityAttributes>?
    private var lastUpdateDate: Date = .distantPast

    private var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Start

    /// Requests a new Live Activity when a workout session begins.
    /// Silently no-ops on devices that don't support Live Activities (iPad, Simulator).
    func start(session: WorkoutSession) {
        guard isEnabled else { return }

        let attributes = WorkoutActivityAttributes(routineName: session.routineName)
        let firstExercise = session.orderedExercises.first?.exerciseName ?? "—"
        let totalSets = session.exercises.map(\.targetSets).reduce(0, +)

        let state = WorkoutActivityAttributes.ContentState(
            startDate: session.startedAt,
            currentExerciseName: firstExercise,
            setsCompleted: 0,
            totalSets: totalSets
        )
        let content = ActivityContent(
            state: state,
            staleDate: Date.now.addingTimeInterval(30 * 60)
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            // Live Activities unavailable (Simulator, older OS) — fail silently
        }
    }

    // MARK: - Update

    /// Pushes a content update after a set is completed.
    /// Updates are throttled: 5 s normally, 30 s in Low Power Mode.
    func update(session: WorkoutSession, currentExerciseName: String) {
        guard let activity else { return }

        let minInterval: TimeInterval = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 5
        guard Date.now.timeIntervalSince(lastUpdateDate) >= minInterval else { return }
        lastUpdateDate = .now

        let totalSets = session.exercises.map(\.targetSets).reduce(0, +)
        let setsCompleted = session.exercises.flatMap(\.sets).filter(\.isCompleted).count

        let state = WorkoutActivityAttributes.ContentState(
            startDate: session.startedAt,
            currentExerciseName: currentExerciseName,
            setsCompleted: setsCompleted,
            totalSets: totalSets
        )
        // Rolling the staleDate forward on each update keeps the system from
        // marking the activity stale as long as the app remains alive.
        let content = ActivityContent(
            state: state,
            staleDate: Date.now.addingTimeInterval(30 * 60)
        )

        Task { await activity.update(content) }
    }

    // MARK: - End (workout finished)

    /// Ends the Live Activity with a final "Workout Complete" state and dismisses it immediately.
    func end(session: WorkoutSession) {
        guard let activity else { return }

        let totalSets = session.exercises.map(\.targetSets).reduce(0, +)
        let setsCompleted = session.exercises.flatMap(\.sets).filter(\.isCompleted).count

        let state = WorkoutActivityAttributes.ContentState(
            startDate: session.startedAt,
            currentExerciseName: "Workout Complete",
            setsCompleted: setsCompleted,
            totalSets: totalSets
        )
        let content = ActivityContent(state: state, staleDate: nil)

        Task { await activity.end(content, dismissalPolicy: .immediate) }
        self.activity = nil
    }

    // MARK: - Discard (workout abandoned)

    /// Ends and immediately removes the Live Activity when a workout is discarded.
    func discard() {
        guard let activity else { return }
        Task { await activity.end(dismissalPolicy: .immediate) }
        self.activity = nil
    }
}
