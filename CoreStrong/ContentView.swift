//
//  ContentView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    // Any session with isActive == true — survives app restarts automatically
    @Query(filter: #Predicate<WorkoutSession> { $0.isActive })
    private var activeSessions: [WorkoutSession]

    private var activeSession: WorkoutSession? { activeSessions.first }

    var body: some View {
        TabView {
            Tab("Routines", systemImage: "list.bullet.clipboard") {
                RoutineListView()
            }
            Tab("Exercises", systemImage: "dumbbell") {
                ExerciseLibraryView()
            }
            Tab("History", systemImage: "clock.arrow.counterclockwise") {
                WorkoutHistoryView()
            }
        }
        .onAppear {
            ExerciseSeeder.seedIfNeeded(context: modelContext)
        }
        // Presented as a full-screen cover so the tab bar is hidden during a workout.
        // Dismisses automatically when activeSession becomes nil (finish or discard).
        .fullScreenCover(
            isPresented: Binding(
                get: { activeSession != nil },
                set: { _ in }
            )
        ) {
            if let session = activeSession {
                ActiveWorkoutView(session: session)
                    .interactiveDismissDisabled()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [Exercise.self, Routine.self, RoutineExercise.self,
                  WorkoutSession.self, SessionExercise.self, SetLog.self],
            inMemory: true
        )
}
