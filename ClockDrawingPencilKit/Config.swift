//
//  Config.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import Foundation

class Config {
    
    static var useMLforClockhands: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "useMLforClockhands")
        }
    }
    
    // ANGLES IN COMPARISON TO HORIZONTAL LINE IN WHICH CLOCKHANDS SHOULD BE CONSIDERED AS RIGHT (MINUTE NEEDS TO BE AT 30 AND HOUR NEEDS TO BE AT 120
    static var hourHandAngleRange: ClosedRange<Int32> {
        get {
            let tolerance = Int32(UserDefaults.standard.integer(forKey: "clockhandTolerance"))
            return (120-tolerance...120+tolerance)
        }
    }
    static var minuteHandAngleRange: ClosedRange<Int32> {
        get {
            let tolerance = Int32(UserDefaults.standard.integer(forKey: "clockhandTolerance"))
            return (30-tolerance...30+tolerance)
        }
    }
    
    // ANGLES IN COMPARISON TO HORIZONTAL LINE IN WHICH CLOCKHANDS SHOULD BE CONSIDERED AS RIGHT (MINUTE NEEDS TO BE AT 30 AND HOUR NEEDS TO BE AT 120
    static var hourHandAngleRange2: ClosedRange<Int32> {
        get {
            let tolerance = Int32(UserDefaults.standard.integer(forKey: "clockhandTolerance2"))
            return (120-tolerance...120+tolerance)
        }
    }
    static var minuteHandAngleRange2: ClosedRange<Int32> {
        get {
            let tolerance = Int32(UserDefaults.standard.integer(forKey: "clockhandTolerance2"))
            return (30-tolerance...30+tolerance)
        }
    }

    static var clockhandTolerance: Int32 {
        get {
            let tolerance = Int32(UserDefaults.standard.integer(forKey: "clockhandTolerance"))
            return tolerance
        }
    }

    static var clockhandTolerance2: Int32 {
        get {
            let tolerance = Int32(UserDefaults.standard.integer(forKey: "clockhandTolerance2"))
            return tolerance
        }
    }


    
    // MAKE DRAWN LINES THICKER OR THINNER FOR ANALYSIS
    static var changeLineWidthOfDrawingBy: Int {
        get {
            return UserDefaults.standard.integer(forKey: "changeDrawingLineWidth")
        }
    }
    
    // HOUGH TRANSFORM, change to modify how straight clockhands need to be drawn in order to be recognized
    static var minLineLengthForHoughTransform: Int {
        get {
            return UserDefaults.standard.integer(forKey: "minLineLengthForHoughTransform")
        }
    }
    static var houghTransformThreshold: Int {
        get {
            return UserDefaults.standard.integer(forKey: "houghTransformThreshold")
        }
    }
    
    /*
    lines drawn between 12 - 6 and between 3 - 9 are allowed to have a different angle in comparison to a perfects horizontal / vertical line. 0 would be a perfect straight line, while 30 would mean a that a line between the nearest neighbor digits (1 and 7) would still be considered right
    */
    static var quarterHandsSymmetrieAngleTolerance: Int {
        get {
            return UserDefaults.standard.integer(forKey: "quarterHandsSymmetrieAngleTolerance")
        }
    }
    static var quarterHandsSymmetrieAngleTolerance2: Int {
        get {
            return UserDefaults.standard.integer(forKey: "quarterHandsSymmetrieAngleTolerance2")
        }
    }
    
    static var maxSecondsForPerfectRating: Int {
        get {
            return UserDefaults.standard.integer(forKey: "maxSecondsForPerfectRating")
        }
    }
    static var maxSecondsForSemiRating: Int {
        get {
            return UserDefaults.standard.integer(forKey: "maxSecondsForSemiRating")
        }
    }
    
    static var digitDistanceVariationCoefficient: Float {
        get {
            return Float(UserDefaults.standard.double(forKey: "digitDistanceVariationCoefficient"))
        }
    }
    static var digitDistanceVariationCoefficient2: Float {
        get {
            return Float(UserDefaults.standard.double(forKey: "digitDistanceVariationCoefficient2"))
        }
    }
    
    static var minNumbersFoundForPerfectRating: Int {
        get {
            return UserDefaults.standard.integer(forKey: "minNumbersFoundForPerfectRating")
        }
    }
    
    static var minNumbersFoundForOkayRating: Int {
        get {
            return UserDefaults.standard.integer(forKey: "minNumbersFoundForOkayRating")
        }
    }
    
    static var minNumbersInRightPositionForPerfectRating: Int {
        get {
            return UserDefaults.standard.integer(forKey: "minNumbersInRightPositionForPerfectRating")
        }
    }
    
    static var minNumbersInRightPositionForOkayRating: Int {
        get {
            return UserDefaults.standard.integer(forKey: "minNumbersInRightPositionForOkayRating")
        }
    }
    
    static var maxTimesRestartedForPerfectRating: Int {
        get {
            return UserDefaults.standard.integer(forKey: "maxTimesRestartedForPerfectRating")
        }
    }
    
    static var maxTimesRestartedForOkayRating: Int {
        get {
            return UserDefaults.standard.integer(forKey: "maxTimesRestartedForOkayRating")
        }
    }
    
    
    
}
