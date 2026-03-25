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

    @State private var showingResumePrompt = false
    @State private var launchResumeHandled = false

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
            if activeSession != nil && !launchResumeHandled {
                launchResumeHandled = true
                showingResumePrompt = true
            }
        }
        // Presented as a full-screen cover so the tab bar is hidden during a workout.
        // Dismisses automatically when activeSession becomes nil (finish or discard).
        .fullScreenCover(
            isPresented: Binding(
                get: { activeSession != nil && !showingResumePrompt },
                set: { _ in }
            )
        ) {
            if let session = activeSession {
                ActiveWorkoutView(session: session)
                    .interactiveDismissDisabled()
            }
        }
        .alert("Resume Workout?", isPresented: $showingResumePrompt) {
            Button("Resume") { }
            Button("Discard", role: .destructive) {
                if let session = activeSession {
                    LiveActivityService.shared.discard()
                    modelContext.delete(session)
                }
            }
        } message: {
            Text("You have an unfinished workout. Would you like to continue where you left off?")
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
