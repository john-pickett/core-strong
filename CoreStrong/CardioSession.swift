//
//  CardioSession.swift
//  CoreStrong
//

import SwiftData
import Foundation

// MARK: - Supporting Enums

enum CardioActivityType: String, Codable, CaseIterable {
    case running
    case walking
    case cycling
    case rowing
    case elliptical
    case stairClimber
    case swimming

    var displayName: String {
        switch self {
        case .running:     return "Running"
        case .walking:     return "Walking"
        case .cycling:     return "Cycling"
        case .rowing:      return "Rowing"
        case .elliptical:  return "Elliptical"
        case .stairClimber: return "Stair Climber"
        case .swimming:    return "Swimming"
        }
    }

    var systemImage: String {
        switch self {
        case .running:     return "figure.run"
        case .walking:     return "figure.walk"
        case .cycling:     return "figure.outdoor.cycle"
        case .rowing:      return "figure.rowing"
        case .elliptical:  return "figure.elliptical"
        case .stairClimber: return "figure.stair.stepper"
        case .swimming:    return "figure.pool.swim"
        }
    }
}

enum CardioFocus: String, Codable, CaseIterable {
    case distanceGoal
    case paceGoal
    case timeGoal
    case easyRecovery

    var displayName: String {
        switch self {
        case .distanceGoal: return "Distance Goal"
        case .paceGoal:     return "Pace Goal"
        case .timeGoal:     return "Time Goal"
        case .easyRecovery: return "Easy / Recovery"
        }
    }
}

// MARK: - Model

@Model
final class CardioSession {
    var date: Date
    var activityType: CardioActivityType
    var isOutdoor: Bool
    var routeDescription: String
    var focus: CardioFocus
    var durationSeconds: Int
    var distanceMiles: Double
    var notes: String

    init(activityType: CardioActivityType = .running) {
        self.date = Date()
        self.activityType = activityType
        self.isOutdoor = true
        self.routeDescription = ""
        self.focus = .easyRecovery
        self.durationSeconds = 0
        self.distanceMiles = 0.0
        self.notes = ""
    }
}
