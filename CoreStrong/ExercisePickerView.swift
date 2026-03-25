//
//  ExercisePickerView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.dismiss) private var dismiss

    let onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var selectedMuscleGroup: String? = nil
    @State private var selectedEquipment: String? = nil

    private let muscleGroups = ["arms", "back", "chest", "full body", "legs"]
    private let equipmentTypes = ["barbell", "body weight", "cable", "dumbbell", "machine"]

    private var filtered: [Exercise] {
        exercises.filter { exercise in
            guard !exercise.isArchived else { return false }
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscleGroup == nil ||
                exercise.primaryMuscleGroup == selectedMuscleGroup
            let matchesEquip = selectedEquipment == nil ||
                exercise.equipment == selectedEquipment
            return matchesSearch && matchesMuscle && matchesEquip
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterSection(items: muscleGroups, selected: $selectedMuscleGroup)
                Divider()
                filterSection(items: equipmentTypes, selected: $selectedEquipment)
                Divider()
                exerciseList
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func filterSection(items: [String], selected: Binding<String?>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: selected.wrappedValue == nil) {
                    selected.wrappedValue = nil
                }
                ForEach(items, id: \.self) { item in
                    FilterChip(label: item.titleCased, isSelected: selected.wrappedValue == item) {
                        selected.wrappedValue = selected.wrappedValue == item ? nil : item
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var exerciseList: some View {
        List(filtered) { exercise in
            Button {
                onSelect(exercise)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(exercise.name)
                            .font(.body)
                            .foregroundStyle(.primary)
                        if exercise.isCustom {
                            Text("Custom")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: 4) {
                        Text(exercise.primaryMuscleGroup.titleCased)
                        Text("·")
                        Text(exercise.equipment.titleCased)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.plain)
        .overlay {
            if filtered.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "No Exercises Found",
                        systemImage: "dumbbell.fill",
                        description: Text("Try different filters")
                    )
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
}
