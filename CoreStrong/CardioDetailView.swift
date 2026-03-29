//
//  CardioDetailView.swift
//  CoreStrong
//

import SwiftUI

struct CardioDetailView: View {
    let session: CardioSession

    @State private var showingEdit = false

    var body: some View {
        List {
            // Banner prompting review of imported sessions
            if !session.isReviewed {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Imported from Apple Health")
                                .font(.subheadline.bold())
                            Text("Add focus and notes to complete this session.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Review") { showingEdit = true }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                LabeledContent("Date") {
                    Text(session.date.formatted(date: .long, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Activity") {
                    Label(session.activityType.displayName,
                          systemImage: session.activityType.systemImage)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Context") {
                    Text(session.isOutdoor ? "Outdoor" : "Indoor / Treadmill")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Focus") {
                    Text(session.focus.displayName)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Performance") {
                LabeledContent("Duration") {
                    Text(formattedDuration)
                        .foregroundStyle(.secondary)
                }
                if session.distanceMiles > 0 {
                    LabeledContent("Distance") {
                        Text(formattedDistance)
                            .foregroundStyle(.secondary)
                    }
                }
                if session.distanceMiles > 0 && session.durationSeconds > 0 {
                    LabeledContent("Avg. Pace") {
                        Text(formattedPace)
                            .foregroundStyle(.secondary)
                    }
                }
                if session.averageHeartRate > 0 {
                    LabeledContent("Avg. Heart Rate") {
                        Label(String(format: "%.0f BPM", session.averageHeartRate),
                              systemImage: "heart.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                if session.maxHeartRate > 0 {
                    LabeledContent("Max Heart Rate") {
                        Label(String(format: "%.0f BPM", session.maxHeartRate),
                              systemImage: "heart.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                if session.elevationGain > 0 {
                    LabeledContent("Elevation Gain") {
                        Label(String(format: "%.0f ft", session.elevationGain),
                              systemImage: "arrow.up.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if session.isOutdoor && !session.routeDescription.isEmpty {
                Section("Route") {
                    Text(session.routeDescription)
                }
            }

            if !session.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Notes") {
                    Text(session.notes)
                }
            }
        }
        .navigationTitle(session.activityType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            CardioLogView(existingSession: session)
        }
    }

    private var formattedDuration: String {
        let d = TimeInterval(session.durationSeconds)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = d >= 3600 ? [.hour, .minute] : [.minute, .second]
        return formatter.string(from: d) ?? "—"
    }

    private var formattedDistance: String {
        String(format: "%.2f mi", session.distanceMiles)
    }

    private var formattedPace: String {
        let secondsPerMile = Double(session.durationSeconds) / session.distanceMiles
        let minutes = Int(secondsPerMile) / 60
        let seconds = Int(secondsPerMile) % 60
        return String(format: "%d:%02d / mi", minutes, seconds)
    }
}
