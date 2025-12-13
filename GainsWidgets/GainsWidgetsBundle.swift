//
//  GainsWidgetsBundle.swift
//  GainsWidgets
//
//  Created by Rayaan Bokhari on 12/12/25.
//

import WidgetKit
import SwiftUI

@main
struct GainsWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Only Live Activity for workout tracking on lock screen
        WorkoutLiveActivity()
    }
}
