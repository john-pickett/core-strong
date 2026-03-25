//
//  ExerciseProgressView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Navigation routing type

struct ExerciseProgressRoute: Hashable {
    let exerciseName: String
}

// MARK: - Supporting types

enum ProgressChartMode: String, CaseIterable {
    case oneRepMax = "Est. 1RM"
    case volume    = "Volume"
}

enum ProgressDateRange: String, CaseIterable {
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case oneYear    = "1Y"
    case allTime    = "All"

    var cutoffDate: Date? {
        let cal = Calendar.current
        switch self {
        case .thirtyDays: return cal.date(byAdding: .day,  value: -30, to: .now)
        case .ninetyDays: return cal.date(byAdding: .day,  value: -90, to: .now)
        case .oneYear:    return cal.date(byAdding: .year, value: -1,  to: .now)
        case .allTime:    return nil
        }
    }
}

private struct ProgressPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - ExerciseProgressView

struct ExerciseProgressView: View {
    let exerciseName: String

    @Query private var sessionExercises: [SessionExercise]

    @State private var dateRange: ProgressDateRange = .allTime
    @State private var chartMode: ProgressChartMode = .oneRepMax

    init(exerciseName: String) {
        self.exerciseName = exerciseName
        _sessionExercises = Query(
            filter: #Predicate<SessionExercise> { $0.exerciseName == exerciseName },
            sort: \SessionExercise.orderIndex
        )
    }

    // MARK: - Computed chart data

    private var chartPoints: [ProgressPoint] {
        let cutoff = dateRange.cutoffDate
        return sessionExercises
            .compactMap { se -> ProgressPoint? in
                guard let session = se.session, !session.isActive else { return nil }
                let date = session.startedAt
                if let cutoff, date < cutoff { return nil }
                let completed = se.orderedSets.filter(\.isCompleted)
                guard !completed.isEmpty else { return nil }
                let value: Double
                switch chartMode {
                case .oneRepMax:
                    // Epley formula: weight × (1 + reps / 30)
                    let best = completed
                        .filter { $0.weight > 0 }
                        .map { $0.weight * (1 + Double($0.reps) / 30) }
                        .max() ?? 0
                    guard best > 0 else { return nil }
                    value = best
                case .volume:
                    let vol = completed.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
                    guard vol > 0 else { return nil }
                    value = vol
                }
                return ProgressPoint(date: date, value: value)
            }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Date range picker
                Picker("Range", selection: $dateRange) {
                    ForEach(ProgressDateRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Chart mode picker
                Picker("Chart", selection: $chartMode) {
                    ForEach(ProgressChartMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Chart or placeholder
                if chartPoints.count < 2 {
                    ContentUnavailableView(
                        "Not Enough Data",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Log at least 2 workouts with this exercise to see a trend.")
                    )
                    .frame(height: 220)
                } else {
                    Chart(chartPoints) { point in
                        LineMark(
                            x: .value("Date",  point.date),
                            y: .value(chartMode.rawValue, point.value)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.accentColor)

                        PointMark(
                            x: .value("Date",  point.date),
                            y: .value(chartMode.rawValue, point.value)
                        )
                        .symbolSize(40)
                        .foregroundStyle(Color.accentColor)
                    }
                    .chartYAxisLabel(chartMode == .oneRepMax ? "lbs (est.)" : "lbs")
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                    .frame(height: 220)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
