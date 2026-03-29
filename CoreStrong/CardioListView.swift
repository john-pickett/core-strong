//
//  CardioListView.swift
//  CoreStrong
//

import SwiftUI
import SwiftData

struct CardioListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CardioSession.date, order: .reverse)
    private var sessions: [CardioSession]

    @State private var showingLog = false
    @State private var showingProgress = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    NavigationLink(value: session) {
                        CardioHistoryRow(session: session)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(session)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Cardio")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingProgress = true
                    } label: {
                        Image(systemName: "chart.xyaxis.line")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingLog = true
                    } label: {
                        Label("Log Session", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingLog) {
                CardioLogView()
            }
            .navigationDestination(for: CardioSession.self) { session in
                CardioDetailView(session: session)
            }
            .navigationDestination(isPresented: $showingProgress) {
                CardioProgressView()
            }
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Cardio Logged",
                        systemImage: "figure.run",
                        description: Text("Tap + to log your first cardio session.")
                    )
                }
            }
        }
    }
}

// MARK: - CardioHistoryRow

private struct CardioHistoryRow: View {
    let session: CardioSession

    private var formattedDuration: String {
        let d = TimeInterval(session.durationSeconds)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = d >= 3600 ? [.hour, .minute] : [.minute, .second]
        return formatter.string(from: d) ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: session.activityType.systemImage)
                    .foregroundStyle(.blue)
                Text(session.activityType.displayName)
                    .font(.headline)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(session.isOutdoor ? "Outdoor" : "Indoor")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if !session.isReviewed {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }

            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label(formattedDuration, systemImage: "clock")
                if session.distanceMiles > 0 {
                    Label(String(format: "%.2f mi", session.distanceMiles),
                          systemImage: "map")
                }
                Label(session.focus.displayName, systemImage: "target")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    CardioListView()
        .modelContainer(for: CardioSession.self, inMemory: true)
}
