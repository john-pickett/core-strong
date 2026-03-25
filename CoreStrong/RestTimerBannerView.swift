//
//  RestTimerBannerView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI

struct RestTimerBannerView: View {
    @EnvironmentObject private var timerVM: RestTimerViewModel

    var body: some View {
        HStack(spacing: 16) {
            CircularTimerView(progress: timerVM.progress)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(timerVM.formattedRemaining)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.linear(duration: 1), value: timerVM.remainingSeconds)
                Text("Rest")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("+30s") {
                timerVM.extend(by: 30)
            }
            .font(.subheadline.bold())
            .buttonStyle(.bordered)
            .tint(.orange)

            Button("Skip") {
                timerVM.skip()
            }
            .font(.subheadline.bold())
            .buttonStyle(.borderedProminent)
            .tint(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - CircularTimerView

private struct CircularTimerView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}
