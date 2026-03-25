//
//  ActiveWorkoutView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var timerVM = RestTimerViewModel()
    @AppStorage("defaultRestDuration") private var defaultRestDuration: Int = 90

    @State private var showingFinishSheet           = false
    @State private var showingZeroSetsWarning       = false
    @State private var showingDiscardConfirmation   = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                List {
                    Section {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text("Started \(session.startedAt.formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(session.orderedExercises) { se in
                        SessionExerciseSection(
                            sessionExercise: se,
                            defaultRestDuration: defaultRestDuration
                        )
                    }

                    Section("Notes") {
                        TextField("Add a note…", text: $session.notes, axis: .vertical)
                            .lineLimit(3...)
                    }

                    Section {
                        Button {
                            attemptFinish()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Finish Workout", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.green)
                    }

                    Section {
                        Button("Discard Workout", role: .destructive) {
                            showingDiscardConfirmation = true
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if timerVM.isRunning {
                        Color.clear.frame(height: 88)
                    }
                }

                if timerVM.isRunning {
                    RestTimerBannerView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: timerVM.isRunning)
            .navigationTitle(session.routineName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Finish") {
                        attemptFinish()
                    }
                    .fontWeight(.semibold)
                    .tint(.green)
                }
            }
            .confirmationDialog(
                "Discard Workout?",
                isPresented: $showingDiscardConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) {
                    timerVM.skip()
                    modelContext.delete(session)
                }
            } message: {
                Text("This workout will not be saved.")
            }
            .sheet(isPresented: $showingFinishSheet) {
                WorkoutFinishSheet(session: session, onConfirm: confirmFinish)
            }
            .alert("No Sets Logged", isPresented: $showingZeroSetsWarning) {
                Button("Save Anyway") { showingFinishSheet = true }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You haven't completed any sets. Save this workout anyway?")
            }
        }
        .environmentObject(timerVM)
        .onAppear {
            RestTimerViewModel.requestPermissionIfNeeded()
            Task { await HealthKitService.requestAuthorizationIfNeeded() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                timerVM.reconcileAfterForeground()
            }
        }
    }

    private func attemptFinish() {
        let completed = session.exercises.flatMap(\.sets).filter(\.isCompleted)
        if completed.isEmpty {
            showingZeroSetsWarning = true
        } else {
            showingFinishSheet = true
        }
    }

    private func confirmFinish() {
        timerVM.skip()

        // Prune exercises the user never started.
        // The cascade delete rule on SessionExercise.sets handles child SetLogs automatically.
        for se in session.exercises where !se.sets.contains(where: \.isCompleted) {
            modelContext.delete(se)
        }

        session.endedAt = Date()

        let snapSession = session   // capture reference before possible dismiss

        Task {
            do {
                let id = try await HealthKitService.logWorkout(session: snapSession)
                snapSession.healthKitWorkoutID = id
                snapSession.isActive = false   // triggers fullScreenCover dismiss
            } catch {
                // Unavailable (iPad/Simulator), denied, or unexpected write failure — save locally and dismiss
                snapSession.isActive = false
            }
        }
    }
}

// MARK: - SessionExerciseSection

private struct SessionExerciseSection: View {
    @Bindable var sessionExercise: SessionExercise
    let defaultRestDuration: Int
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var timerVM: RestTimerViewModel

    @State private var repsText:   [PersistentIdentifier: String] = [:]
    @State private var weightText: [PersistentIdentifier: String] = [:]

    var body: some View {
        Section {
            // Header: name + targets + previous badge
            VStack(alignment: .leading, spacing: 4) {
                Text(sessionExercise.exerciseName)
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(sessionExercise.targetSets) sets × \(sessionExercise.targetReps) reps · \(sessionExercise.targetWeightText)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if sessionExercise.hasPreviousData {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                        Text("Last: \(sessionExercise.previousSets) × \(sessionExercise.previousReps) reps · \(sessionExercise.previousWeightText)")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 4)
            .listRowSeparator(.hidden, edges: .bottom)

            // One row per set
            ForEach(sessionExercise.orderedSets) { set in
                SetLogRow(
                    set: set,
                    repsText: repsBinding(for: set),
                    weightText: weightBinding(for: set),
                    onComplete: { completeSet(set) },
                    onDelete:   { deleteSet(set) }
                )
            }

            // Add extra set
            Button {
                addSet()
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline)
            }
            .foregroundStyle(Color.accentColor)
        }
    }

    // MARK: - Bindings

    private func repsBinding(for set: SetLog) -> Binding<String> {
        Binding(
            get: { repsText[set.persistentModelID] ?? String(set.reps) },
            set: { repsText[set.persistentModelID] = $0 }
        )
    }

    private func weightBinding(for set: SetLog) -> Binding<String> {
        Binding(
            get: { weightText[set.persistentModelID] ?? formattedWeightForField(set.weight) },
            set: { weightText[set.persistentModelID] = $0 }
        )
    }

    // MARK: - Actions

    private func completeSet(_ set: SetLog) {
        let id = set.persistentModelID
        set.reps        = Int(repsText[id] ?? "")      ?? set.reps
        set.weight      = Double(weightText[id] ?? "") ?? set.weight
        set.completedAt = Date()

        let duration = sessionExercise.restDuration > 0
            ? sessionExercise.restDuration
            : defaultRestDuration
        timerVM.start(duration: duration)
    }

    private func addSet() {
        let nextIndex = (sessionExercise.sets.map(\.orderIndex).max() ?? -1) + 1
        let newSet = SetLog(
            orderIndex: nextIndex,
            reps: sessionExercise.targetReps,
            weight: sessionExercise.targetWeight
        )
        newSet.sessionExercise = sessionExercise
        modelContext.insert(newSet)
    }

    private func deleteSet(_ set: SetLog) {
        let id = set.persistentModelID
        let siblings = sessionExercise.orderedSets.filter { $0.persistentModelID != id }
        modelContext.delete(set)
        for (i, s) in siblings.enumerated() { s.orderIndex = i }
        repsText.removeValue(forKey: id)
        weightText.removeValue(forKey: id)
    }

    // MARK: - Helpers

    private func formattedWeightForField(_ value: Double) -> String {
        guard value > 0 else { return "" }
        return value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

// MARK: - SetLogRow

private struct SetLogRow: View {
    let set: SetLog
    @Binding var repsText: String
    @Binding var weightText: String
    let onComplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Set badge
            if set.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .frame(width: 24)
            } else {
                Text("\(set.orderIndex + 1)")
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 24, alignment: .center)
                    .foregroundStyle(.secondary)
            }

            if set.isCompleted {
                // Read-only committed values
                Text("\(set.reps)")
                    .frame(width: 52)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Text("×")
                    .foregroundStyle(.secondary)
                Text(formattedWeight(set.weight))
                    .frame(width: 72)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Text("lbs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Editable fields
                TextField("Reps", text: $repsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 52)
                    .padding(.vertical, 6)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
                Text("×")
                    .foregroundStyle(.secondary)
                TextField("lbs", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 72)
                    .padding(.vertical, 6)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
                Text("lbs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !set.isCompleted {
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .listRowBackground(set.isCompleted ? Color.green.opacity(0.08) : nil)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formattedWeight(_ value: Double) -> String {
        guard value > 0 else { return "BW" }
        return value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
