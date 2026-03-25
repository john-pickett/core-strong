//
//  SettingsView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @AppStorage("defaultRestDuration") private var defaultRestDuration: Int = 90
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var exportURL: URL? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Rest Timer") {
                    Stepper(
                        value: $defaultRestDuration,
                        in: 15...600,
                        step: 15
                    ) {
                        HStack {
                            Text("Default Duration")
                            Spacer()
                            Text(formattedDuration(defaultRestDuration))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Used for exercises that have no custom rest duration set.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Data") {
                    Button {
                        exportURL = buildExportFile()
                    } label: {
                        Label("Export Workout History", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(
                isPresented: Binding(get: { exportURL != nil }, set: { if !$0 { exportURL = nil } })
            ) {
                if let url = exportURL {
                    ActivityView(url: url)
                }
            }
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }

    private func buildExportFile() -> URL? {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { !$0.isActive },
            sortBy: [SortDescriptor(\WorkoutSession.startedAt)]
        )
        guard let sessions = try? modelContext.fetch(descriptor) else { return nil }

        var rows = ["date,routine,exercise,set,reps,weight,notes"]
        let fmt = ISO8601DateFormatter()

        for session in sessions {
            let date    = fmt.string(from: session.startedAt)
            let routine = csvEscape(session.routineName)
            let notes   = csvEscape(session.notes)
            for ex in session.orderedExercises {
                let name = csvEscape(ex.exerciseName)
                for set in ex.orderedSets where set.isCompleted {
                    let weight = set.weight > 0 ? String(format: "%.1f", set.weight) : "BW"
                    rows.append("\(date),\(routine),\(name),\(set.orderIndex + 1),\(set.reps),\(weight),\(notes)")
                }
            }
        }

        let csv = rows.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("workout_history.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func csvEscape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
