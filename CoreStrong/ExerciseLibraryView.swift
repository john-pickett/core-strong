//
//  ExerciseLibraryView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String? = nil
    @State private var selectedEquipment: String? = nil
    @State private var showingCreate = false
    @State private var exerciseToEdit: Exercise? = nil

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
            .navigationTitle("Exercise Library")
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreate = true
                    } label: {
                        Label("New Exercise", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CustomExerciseFormView()
            }
            .sheet(item: $exerciseToEdit) { exercise in
                CustomExerciseFormView(exercise: exercise)
            }
            .navigationDestination(for: ExerciseProgressRoute.self) { route in
                ExerciseProgressView(exerciseName: route.exerciseName)
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
            NavigationLink(value: ExerciseProgressRoute(exerciseName: exercise.name)) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(exercise.name)
                            .font(.body)
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
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if exercise.isCustom {
                    Button(role: .destructive) {
                        exercise.isArchived = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        exerciseToEdit = exercise
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
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

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

extension String {
    var titleCased: String {
        split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

#Preview {
    ExerciseLibraryView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
