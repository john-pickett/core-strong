//
//  WorkoutLiveActivity.swift
//  CoreStrongWidgets
//
//  Created by John Pickett on 3/9/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Widget

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Expanded — appears when user long-presses the pill
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.routineName)
                            .font(.headline)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(.green)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startDate, style: .timer)
                        .font(.title3.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.isStale
                             ? "Workout paused"
                             : context.state.currentExerciseName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(context.state.setsCompleted)/\(context.state.totalSets) sets")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                // MARK: Compact leading — visible in the pill when another app is foregrounded
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundStyle(.green)
            } compactTrailing: {
                // MARK: Compact trailing
                Text(context.state.startDate, style: .timer)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.green)
            } minimal: {
                // MARK: Minimal — shown when two Live Activities are active simultaneously
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Lock Screen / Banner View

struct WorkoutLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.routineName)
                    .font(.headline)
                    .lineLimit(1)
                Text(context.isStale
                     ? "Workout paused"
                     : context.state.currentExerciseName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(context.state.startDate, style: .timer)
                    .font(.title3.monospacedDigit())
                    .fontWeight(.semibold)
                Text("\(context.state.setsCompleted)/\(context.state.totalSets) sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .activityBackgroundTint(Color(.systemBackground))
    }
}
