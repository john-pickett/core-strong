//
//  WorkoutFinishSheet.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI

struct WorkoutFinishSheet: View {
    let session: WorkoutSession
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed stats

    private var elapsedDuration: TimeInterval {
        Date().timeIntervalSince(session.startedAt)
    }

    private var exerciseCount: Int {
        session.exercises.filter { $0.sets.contains(where: \.isCompleted) }.count
    }

    private var completedSets: [SetLog] {
        session.exercises.flatMap(\.sets).filter(\.isCompleted)
    }

    private var totalSets: Int { completedSets.count }

    private var totalVolume: Double {
        completedSets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    // MARK: - Formatting

    private var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = elapsedDuration >= 3600 ? [.hour, .minute] : [.minute, .second]
        return formatter.string(from: elapsedDuration) ?? "—"
    }

    private var volumeText: String {
        guard totalVolume > 0 else { return "Bodyweight" }
        let formatted = totalVolume.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(totalVolume))"
            : String(format: "%.1f", totalVolume)
        return "\(formatted) lbs"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    StatRow(icon: "clock",
                            label: "Duration",
                            value: formattedDuration)
                    StatRow(icon: "figure.strengthtraining.traditional",
                            label: "Exercises",
                            value: "\(exerciseCount)")
                    StatRow(icon: "checkmark.circle",
                            label: "Sets Completed",
                            value: "\(totalSets)")
                    StatRow(icon: "scalemass",
                            label: "Est. Volume",
                            value: volumeText)
                }

                Section {
                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Save Workout", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.green)
                }
            }
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - StatRow

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
