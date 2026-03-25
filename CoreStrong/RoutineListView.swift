//
//  RoutineListView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Environment(\.modelContext) private var modelContext

    @State private var path = NavigationPath()
    @State private var routineToDelete: Routine? = nil
    @State private var showingSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(routines) { routine in
                    NavigationLink(value: routine) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.name.isEmpty ? "Untitled Routine" : routine.name)
                                    .font(.body)
                                Text(exerciseSummary(for: routine))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                startWorkout(from: routine)
                            } label: {
                                Label("Start", systemImage: "play.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 2)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            routineToDelete = routine
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: createRoutine) {
                        Label("New Routine", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .navigationDestination(for: Routine.self) { routine in
                RoutineDetailView(routine: routine)
            }
            .overlay {
                if routines.isEmpty {
                    ContentUnavailableView(
                        "No Routines Yet",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Tap + to create your first routine.")
                    )
                }
            }
            .confirmationDialog(
                "Delete \"\(routineToDelete?.name ?? "Routine")\"?",
                isPresented: .init(
                    get: { routineToDelete != nil },
                    set: { if !$0 { routineToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Routine", role: .destructive) {
                    if let routine = routineToDelete {
                        modelContext.delete(routine)
                    }
                    routineToDelete = nil
                }
            } message: {
                Text("This will permanently delete the routine. Workout history will not be affected.")
            }
        }
    }

    // MARK: - Actions

    private func createRoutine() {
        let routine = Routine(name: "New Routine")
        modelContext.insert(routine)
        path.append(routine)
    }

    private func startWorkout(from routine: Routine) {
        // Fetch all prior session exercises to snapshot "previous workout" data
        let allPrior = (try? modelContext.fetch(FetchDescriptor<SessionExercise>())) ?? []

        let session = WorkoutSession(routineName: routine.name)
        modelContext.insert(session)

        for (index, slot) in routine.orderedExercises.enumerated() {
            let se = SessionExercise(
                orderIndex: index,
                exerciseName: slot.exercise?.name ?? "Unknown Exercise",
                targetSets: slot.targetSets,
                targetReps: slot.targetReps,
                targetWeight: slot.targetWeight,
                restDuration: slot.restDuration,
                exercise: slot.exercise
            )
            se.session = session

            // Find the most recent completed session's entry for the same exercise
            if let exercise = slot.exercise {
                let exerciseID = exercise.persistentModelID
                let previous = allPrior
                    .filter {
                        $0.exercise?.persistentModelID == exerciseID &&
                        $0.session?.isActive == false
                    }
                    .sorted {
                        ($0.session?.startedAt ?? .distantPast) > ($1.session?.startedAt ?? .distantPast)
                    }
                    .first

                if let prev = previous {
                    se.hasPreviousData = true
                    se.previousSets = prev.targetSets
                    se.previousReps = prev.targetReps
                    se.previousWeight = prev.targetWeight
                }
            }

            modelContext.insert(se)

            // Pre-create one pending SetLog per planned set
            for setIndex in 0..<slot.targetSets {
                let setLog = SetLog(
                    orderIndex: setIndex,
                    reps: slot.targetReps,
                    weight: slot.targetWeight
                )
                setLog.sessionExercise = se
                modelContext.insert(setLog)
            }
        }

        LiveActivityService.shared.start(session: session)
    }

    // MARK: - Helpers

    private func exerciseSummary(for routine: Routine) -> String {
        let count = routine.exercises.count
        return count == 0 ? "No exercises" : "\(count) exercise\(count == 1 ? "" : "s")"
    }
}

#Preview {
    RoutineListView()
        .modelContainer(for: [Routine.self, RoutineExercise.self, Exercise.self], inMemory: true)
}
