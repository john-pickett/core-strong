//
//  RestTimerViewModel.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import Combine
import UIKit
import AudioToolbox
import UserNotifications

@MainActor
final class RestTimerViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var totalSeconds: Int = 0

    // MARK: - Private

    private var endDate: Date?
    private var timerSubscription: AnyCancellable?
    private static let notificationID = "com.corestrong.restTimer"

    // MARK: - Public API

    func start(duration: Int) {
        stop()
        totalSeconds = duration
        remainingSeconds = duration
        endDate = Date().addingTimeInterval(TimeInterval(duration))
        isRunning = true
        scheduleNotification(in: duration)
        startTicking()
    }

    func skip() {
        stop()
    }

    func extend(by seconds: Int = 30) {
        guard isRunning, let current = endDate else { return }
        endDate = current.addingTimeInterval(TimeInterval(seconds))
        totalSeconds += seconds
        remainingSeconds += seconds
        cancelNotification()
        scheduleNotification(in: remainingSeconds)
    }

    func reconcileAfterForeground() {
        guard isRunning, let end = endDate else { return }
        let remaining = Int(end.timeIntervalSinceNow.rounded())
        if remaining <= 0 {
            remainingSeconds = 0
            expire()
        } else {
            remainingSeconds = remaining
            // Restart ticking since the timer may have been suspended
            startTicking()
        }
    }

    // MARK: - Notification permission

    static func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    // MARK: - Computed

    var progress: Double {
        guard isRunning, totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var formattedRemaining: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Private helpers

    private func startTicking() {
        timerSubscription?.cancel()
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard let end = endDate else { return }
        let remaining = Int(end.timeIntervalSinceNow.rounded())
        if remaining <= 0 {
            remainingSeconds = 0
            expire()
        } else {
            remainingSeconds = remaining
        }
    }

    private func expire() {
        timerSubscription?.cancel()
        timerSubscription = nil
        isRunning = false
        cancelNotification()
        fireHaptic()
        playSound()
    }

    private func stop() {
        timerSubscription?.cancel()
        timerSubscription = nil
        isRunning = false
        remainingSeconds = 0
        totalSeconds = 0
        endDate = nil
        cancelNotification()
    }

    private func fireHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func playSound() {
        // System sound 1322 respects the device silent switch
        AudioServicesPlaySystemSound(1322)
    }

    private func scheduleNotification(in seconds: Int) {
        cancelNotification()
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time to get back to it."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(1, seconds)),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Self.notificationID,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
    }
}
