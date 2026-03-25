//
//  RoutineDetailView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingExercisePicker = false
    @State private var exerciseSlotToEdit: RoutineExercise? = nil
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                TextField("Routine name", text: $routine.name)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Section {
                ForEach(routine.orderedExercises) { slot in
                    exerciseRow(slot)
                }
                .onMove(perform: moveExercises)
                .onDelete(perform: deleteExercises)
            } header: {
                Text("Exercises (\(routine.exercises.count))")
            } footer: {
                if routine.exercises.isEmpty {
                    Text("Tap + to add exercises from the library.")
                }
            }

            Section {
                Button("Delete Routine", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(routine.name.isEmpty ? "New Routine" : routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .sheet(item: $exerciseSlotToEdit) { slot in
            RoutineExerciseEditView(routineExercise: slot)
        }
        .confirmationDialog(
            "Delete \"\(routine.name.isEmpty ? "Routine" : routine.name)\"?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Routine", role: .destructive) {
                modelContext.delete(routine)
                dismiss()
            }
        } message: {
            Text("This will permanently delete the routine. Workout history will not be affected.")
        }
    }

    private func exerciseRow(_ slot: RoutineExercise) -> some View {
        Button {
            exerciseSlotToEdit = slot
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(slot.exercise?.name ?? "Deleted Exercise")
                    .font(.body)
                    .foregroundStyle(slot.exercise?.isArchived == true ? .secondary : .primary)
                HStack(spacing: 4) {
                    Text("\(slot.targetSets) sets")
                    Text("×")
                    Text("\(slot.targetReps) reps")
                    Text("·")
                    Text(slot.weightText)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    private func addExercise(_ exercise: Exercise) {
        let nextIndex = (routine.exercises.map(\.orderIndex).max() ?? -1) + 1
        let slot = RoutineExercise(orderIndex: nextIndex, exercise: exercise)
        slot.routine = routine
        modelContext.insert(slot)
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var ordered = routine.orderedExercises
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, slot) in ordered.enumerated() {
            slot.orderIndex = index
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        var ordered = routine.orderedExercises
        for index in offsets.reversed() {
            modelContext.delete(ordered[index])
            ordered.remove(at: index)
        }
        for (index, slot) in ordered.enumerated() {
            slot.orderIndex = index
        }
    }
}
