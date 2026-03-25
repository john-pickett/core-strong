//
//  CoreStrongWorkoutsBundle.swift
//  CoreStrongWorkouts
//
//  Created by John Pickett on 3/25/26.
//

import WidgetKit
import SwiftUI

@main
struct CoreStrongWorkoutsBundle: WidgetBundle {
    var body: some Widget {
        CoreStrongWorkouts()
        CoreStrongWorkoutsControl()
        CoreStrongWorkoutsLiveActivity()
    }
}
