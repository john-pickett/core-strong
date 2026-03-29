//
//  CardioDetailView.swift
//  CoreStrong
//

import SwiftUI

struct CardioDetailView: View {
    let session: CardioSession

    var body: some View {
        List {
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
