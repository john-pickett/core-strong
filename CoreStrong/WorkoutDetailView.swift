//
//  WorkoutDetailView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI

struct WorkoutDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            // MARK: - Header

            Section {
                LabeledContent("Date") {
                    Text(session.startedAt.formatted(date: .long, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Duration") {
                    Text(formattedDuration)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Notes

            if !session.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Notes") {
                    Text(session.notes)
                }
            }

            // MARK: - Exercises

            if session.orderedExercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises Recorded",
                    systemImage: "figure.strengthtraining.traditional"
                )
            } else {
                ForEach(session.orderedExercises) { exercise in
                    let completedSets = exercise.orderedSets.filter(\.isCompleted)
                    Section(
                        header: NavigationLink(
                            value: ExerciseProgressRoute(exerciseName: exercise.exerciseName)
                        ) {
                            Text(exercise.exerciseName)
                                .textCase(nil)
                                .font(.headline)
                                .foregroundStyle(Color.accentColor)
                        }
                    ) {
                        ForEach(Array(completedSets.enumerated()), id: \.element.persistentModelID) { index, set in
                            HStack {
                                Text("Set \(index + 1)")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 52, alignment: .leading)
                                Spacer()
                                Text("\(set.reps) reps")
                                Text("·")
                                    .foregroundStyle(.tertiary)
                                Text(formattedWeight(set.weight))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle(session.routineName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: ExerciseProgressRoute.self) { route in
            ExerciseProgressView(exerciseName: route.exerciseName)
        }
    }

    // MARK: - Helpers

    private var formattedDuration: String {
        guard let d = session.duration else { return "—" }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = d >= 3600 ? [.hour, .minute] : [.minute, .second]
        return formatter.string(from: d) ?? "—"
    }

    private func formattedWeight(_ value: Double) -> String {
        guard value > 0 else { return "BW" }
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value)) lbs"
            : String(format: "%.1f lbs", value)
    }
}
