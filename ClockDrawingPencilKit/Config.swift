//
//  Config.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import Foundation

class Config {
    
    // ANGLES IN COMPARISON TO HORIZONTAL LINE IN WHICH CLOCKHANDS SHOULD BE CONSIDERED AS RIGHT (MINUTE NEEDS TO BE AT 30 AND HOUR NEEDS TO BE AT 120
    static var hourHandAngleRange = 102...138
    static var minuteHandAngleRange = 12...48
    
    // ANGLES IN COMPARISON TO HORIZONTAL LINE IN WHICH CLOCKHANDS SHOULD BE CONSIDERED AS RIGHT (MINUTE NEEDS TO BE AT 30 AND HOUR NEEDS TO BE AT 120
    static var hourHandAngleRange2 = 95...145
    static var minuteHandAngleRange2 = 5...55
    
    // MAKE DRAWN LINES THICKER OR THINNER FOR ANALYSIS
    static var changeLineWidthOfDrawingBy = 0
    
    // HOUGH TRANSFORM, change to modify how straight clockhands need to be drawn in order to be recognized
    static var minLineLengthForHoughTransform = 5
    static var houghTransformThreshold = 30
    
    /*
    lines drawn between 12 - 6 and between 3 - 9 are allowed to have a different angle in comparison to a perfects horizontal / vertical line. 0 would be a perfect straight line, while 30 would mean a that a line between the nearest neighbor digits (1 and 7) would still be considered right
    */
    static var quarterHandsSymmetrieAngleTolerance = 5
    static var quarterHandsSymmetrieAngleTolerance2 = 10
    
    static var maxSecondsForPerfectRating = 120
    static var maxSecondsForSemiRating = 180
    
    
}
