//
//  ClockDrawingPencilKitApp.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 01.10.21.
//

import SwiftUI
@main
struct ClockDrawingPencilKitApp: App {
    var body: some Scene {
        WindowGroup {
            //ContentView()
            StartClockTestView().onAppear(perform: self.setupUserDefaults)
        }
    }
    
    func setupUserDefaults() {
        if !UserDefaults.standard.bool(forKey: "startedVersion1.1") {
            
            UserDefaults.standard.set(true, forKey: "useMLforClockhands")
            
            UserDefaults.standard.set(18, forKey: "clockhandTolerance")
            UserDefaults.standard.set(25, forKey: "clockhandTolerance2")
            
            UserDefaults.standard.set(1, forKey: "maxTimesRestartedForPerfectRating")
            UserDefaults.standard.set(2, forKey: "maxTimesRestartedForOkayRating")
            
            UserDefaults.standard.set(12, forKey: "changeDrawingLineWidth")
            
            UserDefaults.standard.set(5, forKey: "minLineLengthForHoughTransform")
            UserDefaults.standard.set(30, forKey: "houghTransformThreshold")
            
            UserDefaults.standard.set(5, forKey: "quarterHandsSymmetrieAngleTolerance")
            UserDefaults.standard.set(10, forKey: "quarterHandsSymmetrieAngleTolerance2")
            
            UserDefaults.standard.set(120, forKey: "maxSecondsForPerfectRating")
            UserDefaults.standard.set(180, forKey: "maxSecondsForSemiRating")
            
            UserDefaults.standard.set(0.2, forKey: "digitDistanceVariationCoefficient")
            UserDefaults.standard.set(0.45, forKey: "digitDistanceVariationCoefficient2")
            
            UserDefaults.standard.set(10, forKey: "minNumbersFoundForPerfectRating")
            UserDefaults.standard.set(5, forKey: "minNumbersFoundForOkayRating")
            
            UserDefaults.standard.set(8, forKey: "minNumbersInRightPositionForPerfectRating")
            UserDefaults.standard.set(4, forKey: "minNumbersInRightPositionForOkayRating")
            print("UserDefaults set")
            
            UserDefaults.standard.set(true, forKey: "startedVersion1.1")
        }
    }
}
