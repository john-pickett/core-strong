//
//  WorkoutHistoryView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { !$0.isActive },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    )
    private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    NavigationLink(value: session) {
                        WorkoutHistoryRow(session: session)
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: WorkoutSession.self) { session in
                WorkoutDetailView(session: session)
            }
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "calendar.badge.clock",
                        description: Text("Finish a workout to see it here.")
                    )
                }
            }
        }
    }
}

// MARK: - WorkoutHistoryRow

private struct WorkoutHistoryRow: View {
    let session: WorkoutSession

    private var completedSets: [SetLog] {
        session.exercises.flatMap(\.sets).filter(\.isCompleted)
    }

    private var formattedDuration: String {
        guard let d = session.duration else { return "—" }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = d >= 3600 ? [.hour, .minute] : [.minute, .second]
        return formatter.string(from: d) ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.routineName)
                .font(.headline)

            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label(formattedDuration, systemImage: "clock")
                Label("\(session.orderedExercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
                Label("\(completedSets.count) sets", systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
