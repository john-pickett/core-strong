//
//  CustomExerciseFormView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI
import SwiftData

struct CustomExerciseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var exercise: Exercise? = nil

    @State private var name = ""
    @State private var muscleGroup = "legs"
    @State private var equipment = "barbell"

    private let muscleGroups = ["arms", "back", "chest", "full body", "legs"]
    private let equipmentTypes = ["barbell", "body weight", "cable", "dumbbell", "machine"]

    private var nameIsValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $name)
                        .autocorrectionDisabled()
                }

                Section("Muscle Group") {
                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(muscleGroups, id: \.self) { group in
                            Text(group.titleCased).tag(group)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Equipment") {
                    Picker("Equipment", selection: $equipment) {
                        ForEach(equipmentTypes, id: \.self) { type in
                            Text(type.titleCased).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle(exercise == nil ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!nameIsValid)
                }
            }
            .onAppear {
                if let exercise {
                    name = exercise.name
                    muscleGroup = exercise.primaryMuscleGroup
                    equipment = exercise.equipment
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let exercise {
            exercise.name = trimmed
            exercise.primaryMuscleGroup = muscleGroup
            exercise.equipment = equipment
        } else {
            modelContext.insert(Exercise(
                name: trimmed,
                primaryMuscleGroup: muscleGroup,
                equipment: equipment,
                isCustom: true
            ))
        }
        dismiss()
    }
}

#Preview {
    CustomExerciseFormView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
