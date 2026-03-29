//
//  CardioProgressView.swift
//  CoreStrong
//

import SwiftUI
import SwiftData
import Charts

// MARK: - File-private supporting types

private enum CardioChartMode: String, CaseIterable {
    case pace      = "Pace"
    case distance  = "Distance"
    case heartRate = "Heart Rate"
}

private enum DistanceGranularity: String, CaseIterable {
    case weekly  = "Weekly"
    case monthly = "Monthly"
}

private struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - CardioProgressView

struct CardioProgressView: View {

    @Query(sort: \CardioSession.date, order: .ascending)
    private var allSessions: [CardioSession]

    @State private var selectedActivity: CardioActivityType = .running
    @State private var dateRange: ProgressDateRange = .allTime
    @State private var chartMode: CardioChartMode = .pace
    @State private var distanceGranularity: DistanceGranularity = .weekly
    @State private var selectedRoute = ""

    // MARK: - Derived sessions

    /// All-time sessions for the selected activity — used for Personal Records.
    private var allTimeActivity: [CardioSession] {
        allSessions.filter { $0.activityType == selectedActivity }
    }

    /// Sessions for the selected activity filtered by date range — used for charts and route comparison.
    private var filtered: [CardioSession] {
        guard let cutoff = dateRange.cutoffDate else { return allTimeActivity }
        return allTimeActivity.filter { $0.date >= cutoff }
    }

    // MARK: - Personal Records (always all-time)

    private func paceSecPerMile(_ s: CardioSession) -> Double {
        Double(s.durationSeconds) / s.distanceMiles
    }

    private var longestDistancePR: CardioSession? {
        allTimeActivity.filter { $0.distanceMiles > 0 }
            .max(by: { $0.distanceMiles < $1.distanceMiles })
    }

    private var fastestPacePR: CardioSession? {
        allTimeActivity
            .filter { $0.distanceMiles > 0 && $0.durationSeconds > 0 }
            .min(by: { paceSecPerMile($0) < paceSecPerMile($1) })
    }

    private var longestDurationPR: CardioSession? {
        allTimeActivity.filter { $0.durationSeconds > 0 }
            .max(by: { $0.durationSeconds < $1.durationSeconds })
    }

    // MARK: - Chart data

    /// Average speed in mph — higher is better, upward trend = improvement.
    private var paceChartPoints: [ChartPoint] {
        filtered
            .filter { $0.distanceMiles > 0 && $0.durationSeconds > 0 }
            .map { ChartPoint(date: $0.date, value: 3600.0 / paceSecPerMile($0)) }
    }

    private var heartRateChartPoints: [ChartPoint] {
        filtered
            .filter { $0.averageHeartRate > 0 }
            .map { ChartPoint(date: $0.date, value: $0.averageHeartRate) }
    }

    private var distanceChartPoints: [ChartPoint] {
        let cal = Calendar.current
        var groups: [Date: Double] = [:]
        for s in filtered where s.distanceMiles > 0 {
            let comps: Set<Calendar.Component> = distanceGranularity == .weekly
                ? [.yearForWeekOfYear, .weekOfYear] : [.year, .month]
            if let bucket = cal.date(from: cal.dateComponents(comps, from: s.date)) {
                groups[bucket, default: 0] += s.distanceMiles
            }
        }
        return groups.map { ChartPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }

    private var activeChartPoints: [ChartPoint] {
        switch chartMode {
        case .pace:      return paceChartPoints
        case .distance:  return distanceChartPoints
        case .heartRate: return heartRateChartPoints
        }
    }

    // MARK: - Route comparison

    private var routeOptions: [String] {
        Array(Set(
            filtered
                .filter { $0.isOutdoor && !$0.routeDescription.isEmpty }
                .map(\.routeDescription)
        )).sorted()
    }

    private var effectiveRoute: String {
        routeOptions.contains(selectedRoute) ? selectedRoute : (routeOptions.first ?? "")
    }

    private var routeSessions: [CardioSession] {
        filtered
            .filter { $0.routeDescription == effectiveRoute }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Formatting helpers

    private func formatPace(_ secondsPerMile: Double) -> String {
        let m = Int(secondsPerMile) / 60
        let s = Int(secondsPerMile) % 60
        return String(format: "%d:%02d /mi", m, s)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let d = TimeInterval(seconds)
        let fmt = DateComponentsFormatter()
        fmt.unitsStyle = .abbreviated
        fmt.allowedUnits = d >= 3600 ? [.hour, .minute] : [.minute, .second]
        return fmt.string(from: d) ?? "—"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Activity type filter
                HStack {
                    Picker("Activity", selection: $selectedActivity) {
                        ForEach(CardioActivityType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.systemImage).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .padding(.horizontal)

                // Date range (affects charts + route comparison, not PRs)
                Picker("Range", selection: $dateRange) {
                    ForEach(ProgressDateRange.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if allTimeActivity.isEmpty {
                    ContentUnavailableView(
                        "No \(selectedActivity.displayName) Sessions",
                        systemImage: selectedActivity.systemImage,
                        description: Text("Log sessions or import from Apple Health to see your progress.")
                    )
                    .frame(height: 220)
                } else {
                    personalRecordsSection
                    chartSection
                    if !routeOptions.isEmpty {
                        RouteComparisonSection(
                            routes: routeOptions,
                            selectedRoute: Binding(
                                get: { effectiveRoute },
                                set: { selectedRoute = $0 }
                            ),
                            sessions: routeSessions
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Cardio Progress")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedActivity) { _, _ in selectedRoute = "" }
        .onChange(of: dateRange)        { _, _ in selectedRoute = "" }
    }

    // MARK: - Personal Records section

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Personal Records")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if let s = longestDurationPR {
                        RecordCard(
                            icon: "clock",
                            label: "Longest Duration",
                            value: formatDuration(s.durationSeconds),
                            date: s.date
                        )
                    }
                    if let s = longestDistancePR {
                        RecordCard(
                            icon: "arrow.right.circle",
                            label: "Longest Distance",
                            value: String(format: "%.2f mi", s.distanceMiles),
                            date: s.date
                        )
                    }
                    if let s = fastestPacePR {
                        RecordCard(
                            icon: "hare",
                            label: "Fastest Pace",
                            value: formatPace(paceSecPerMile(s)),
                            date: s.date
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Chart section

    @ViewBuilder
    private var chartSection: some View {
        VStack(spacing: 12) {
            Picker("Chart", selection: $chartMode) {
                ForEach(CardioChartMode.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if chartMode == .distance {
                Picker("Granularity", selection: $distanceGranularity) {
                    ForEach(DistanceGranularity.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

            if activeChartPoints.count < 2 {
                ContentUnavailableView(
                    "Not Enough Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Log at least 2 sessions with this metric to see a trend.")
                )
                .frame(height: 200)
            } else {
                chartContent
                    .frame(height: 240)
                    .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        switch chartMode {
        case .pace:
            Chart(paceChartPoints) { pt in
                LineMark(x: .value("Date", pt.date), y: .value("mph", pt.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.accentColor)
                PointMark(x: .value("Date", pt.date), y: .value("mph", pt.value))
                    .symbolSize(40)
                    .foregroundStyle(Color.accentColor)
            }
            .chartYAxisLabel("mph")
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }

        case .distance:
            Chart(distanceChartPoints) { pt in
                BarMark(
                    x: .value("Period", pt.date,
                              unit: distanceGranularity == .weekly ? .weekOfYear : .month),
                    y: .value("Miles", pt.value)
                )
                .foregroundStyle(Color.accentColor)
            }
            .chartYAxisLabel("miles")
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(
                        format: distanceGranularity == .weekly
                            ? .dateTime.month(.abbreviated).day()
                            : .dateTime.month(.abbreviated).year(.twoDigits)
                    )
                }
            }

        case .heartRate:
            Chart(heartRateChartPoints) { pt in
                LineMark(x: .value("Date", pt.date), y: .value("BPM", pt.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(.red)
                PointMark(x: .value("Date", pt.date), y: .value("BPM", pt.value))
                    .symbolSize(40)
                    .foregroundStyle(.red)
            }
            .chartYAxisLabel("BPM")
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
        }
    }
}

// MARK: - RecordCard

private struct RecordCard: View {
    let icon: String
    let label: String
    let value: String
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(minWidth: 130, alignment: .leading)
        .background(.fill.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - RouteComparisonSection

private struct RouteComparisonSection: View {
    let routes: [String]
    @Binding var selectedRoute: String
    let sessions: [CardioSession]

    private func pace(_ s: CardioSession) -> Double {
        Double(s.durationSeconds) / s.distanceMiles
    }

    private func formatPace(_ spm: Double) -> String {
        String(format: "%d:%02d /mi", Int(spm) / 60, Int(spm) % 60)
    }

    private func formatDuration(_ secs: Int) -> String {
        let d = TimeInterval(secs)
        let fmt = DateComponentsFormatter()
        fmt.unitsStyle = .abbreviated
        fmt.allowedUnits = d >= 3600 ? [.hour, .minute] : [.minute, .second]
        return fmt.string(from: d) ?? "—"
    }

    private var bestSessionID: PersistentIdentifier? {
        sessions
            .filter { $0.distanceMiles > 0 && $0.durationSeconds > 0 }
            .min(by: { pace($0) < pace($1) })?.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Comparison")
                .font(.headline)

            if routes.count > 1 {
                Picker("Route", selection: $selectedRoute) {
                    ForEach(routes, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.navigationLink)
            } else if let only = routes.first {
                Text(only)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if sessions.isEmpty {
                Text("No sessions on this route in the selected range.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    // Column headers
                    HStack {
                        Text("Date").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Time").frame(width: 52, alignment: .trailing)
                        Text("Dist").frame(width: 48, alignment: .trailing)
                        Text("Pace").frame(width: 72, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)

                    Divider()

                    ForEach(sessions) { session in
                        let isBest = session.id == bestSessionID
                        HStack {
                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(formatDuration(session.durationSeconds))
                                .frame(width: 52, alignment: .trailing)
                            if session.distanceMiles > 0 {
                                Text(String(format: "%.2f", session.distanceMiles))
                                    .frame(width: 48, alignment: .trailing)
                                Text(session.durationSeconds > 0
                                     ? formatPace(pace(session)) : "—")
                                    .frame(width: 72, alignment: .trailing)
                            } else {
                                Text("—").frame(width: 48, alignment: .trailing)
                                Text("—").frame(width: 72, alignment: .trailing)
                            }
                        }
                        .font(.caption)
                        .fontWeight(isBest ? .semibold : .regular)
                        .foregroundStyle(isBest ? Color.accentColor : .primary)
                        .padding(.vertical, 6)

                        if session.id != sessions.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(12)
                .background(.fill.secondary, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

#Preview {
    NavigationStack {
        CardioProgressView()
    }
    .modelContainer(for: CardioSession.self, inMemory: true)
}
