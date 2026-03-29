//
//  CardioLogView.swift
//  CoreStrong
//

import SwiftUI
import SwiftData

struct CardioLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var activityType: CardioActivityType = .running
    @State private var isOutdoor = true
    @State private var routeDescription = ""
    @State private var focus: CardioFocus = .easyRecovery
    @State private var durationHours = 0
    @State private var durationMinutes = 0
    @State private var durationSecs = 0
    @State private var distanceText = ""
    @State private var notes = ""

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case route, hours, minutes, seconds, distance, notes
    }

    private var totalDurationSeconds: Int {
        durationHours * 3600 + durationMinutes * 60 + durationSecs
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    DatePicker(
                        "Date & Time",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Picker("Activity", selection: $activityType) {
                        ForEach(CardioActivityType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.systemImage).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Context") {
                    Toggle("Outdoor", isOn: $isOutdoor)

                    if isOutdoor {
                        TextField("Route description (optional)", text: $routeDescription)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .route)
                    }
                }

                Section("Focus") {
                    Picker("Session Focus", selection: $focus) {
                        ForEach(CardioFocus.allCases, id: \.self) { f in
                            Text(f.displayName).tag(f)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Duration") {
                    HStack(spacing: 16) {
                        durationField(value: $durationHours, label: "hr", focus: .hours)
                        Spacer()
                        durationField(value: $durationMinutes, label: "min", focus: .minutes)
                        Spacer()
                        durationField(value: $durationSecs, label: "sec", focus: .seconds)
                    }
                    .padding(.vertical, 4)
                }

                Section("Distance") {
                    HStack {
                        TextField("0.0", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .distance)
                        Text("miles")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                }
            }
            .navigationTitle("Log Cardio Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(totalDurationSeconds == 0)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
    }

    private func durationField(value: Binding<Int>, label: String, focus: Field) -> some View {
        VStack(spacing: 4) {
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 64)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: focus)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func save() {
        let session = CardioSession(activityType: activityType)
        session.date = date
        session.isOutdoor = isOutdoor
        session.routeDescription = isOutdoor
            ? routeDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            : ""
        session.focus = focus
        session.durationSeconds = totalDurationSeconds
        session.distanceMiles = Double(distanceText) ?? 0.0
        session.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        modelContext.insert(session)
        dismiss()
    }
}

#Preview {
    CardioLogView()
        .modelContainer(for: CardioSession.self, inMemory: true)
}
