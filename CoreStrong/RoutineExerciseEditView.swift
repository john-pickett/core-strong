//
//  RoutineExerciseEditView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI

struct RoutineExerciseEditView: View {
    @Bindable var routineExercise: RoutineExercise
    @Environment(\.dismiss) private var dismiss

    @State private var weightText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(routineExercise.exercise?.name ?? "Unknown Exercise")
                        .font(.headline)
                }

                Section("Target") {
                    Stepper("Sets: \(routineExercise.targetSets)", value: $routineExercise.targetSets, in: 1...20)
                    Stepper("Reps: \(routineExercise.targetReps)", value: $routineExercise.targetReps, in: 1...100)
                }

                Section("Starting Weight") {
                    HStack {
                        TextField("0", text: $weightText)
                            .keyboardType(.decimalPad)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }
                    Text("Enter 0 for bodyweight exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Rest Timer") {
                    Stepper(
                        value: $routineExercise.restDuration,
                        in: 0...600,
                        step: 15
                    ) {
                        HStack {
                            Text("Rest Duration")
                            Spacer()
                            Text(restDurationLabel(routineExercise.restDuration))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if routineExercise.restDuration == 0 {
                        Text("Uses app default (configurable in Settings)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Slot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        routineExercise.targetWeight = Double(weightText) ?? 0
                        dismiss()
                    }
                }
            }
            .onAppear {
                weightText = routineExercise.targetWeight > 0
                    ? routineExercise.weightText.replacingOccurrences(of: " lbs", with: "")
                    : ""
            }
        }
    }

    private func restDurationLabel(_ seconds: Int) -> String {
        guard seconds > 0 else { return "App Default" }
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }
}
