//
//  AnaylzedClockResult.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import Foundation
import opencv2

struct AnalyzedClockResult {
    
    var clockSize = Size2i(width: 0, height: 0)
    
    var completeImage = UIImage()
    var digitDetectionInvertedImage = UIImage()
    var clockhandDetectionInvertedImage = UIImage()
    
    var digitRectanlgeImage = UIImage()
    var handsHoughTransformImage = UIImage()
    var detectedHandsImage = UIImage()
    var classifiedDigits = [ClassifiedDigit]()
    
    var hourHandAngle: Float = 0
    var minuteHandAngle: Float = 0
    
    var secondsToComplete = 0
    var timesRestarted = 0
    
    
    
    var clockhandsRight: Bool {
        return Config.hourHandAngleRange.contains(Int(abs(self.hourHandAngle))) && Config.minuteHandAngleRange.contains(Int(abs(self.minuteHandAngle)))
    }
    var clockhandsAlmostRight: Bool {
        return Config.hourHandAngleRange2.contains(Int(abs(self.hourHandAngle))) && Config.minuteHandAngleRange2.contains(Int(abs(self.minuteHandAngle)))
    }
    
    
    var horizontalConnectionLineAngle: Float? {
        if let mostRightNumber = self.classifiedDigits.max(by: {$0.centerX > $1.centerX}), let mostLeftNumber = self.classifiedDigits.min(by: {$0.centerX > $1.centerX}) {
            return 180-abs(mostLeftNumber.center.angleTo(mostRightNumber.center))
        }
        return nil
    }
    var verticalConnectionLineAngle: Float? {
        if let mostRightNumber = self.classifiedDigits.max(by: {$0.centerY > $1.centerY}), let mostLeftNumber = self.classifiedDigits.min(by: {$0.centerY > $1.centerY}) {
            return abs(90-mostRightNumber.center.angleTo(mostLeftNumber.center))
        }
        return nil
    }
    
    var horizontalConnectionLinePerfect: Bool {
        if let angle = horizontalConnectionLineAngle {
            return angle <= Float(Config.quarterHandsSymmetrieAngleTolerance)
        }
        return false
    }
        
    var verticalConnectionLinePerfect: Bool {
        if let angle = verticalConnectionLineAngle {
            return angle <= Float(Config.quarterHandsSymmetrieAngleTolerance)
        }
        return false
    }
    
    var horizontalConnectionLineOkay: Bool {
        if let angle = horizontalConnectionLineAngle {
            return angle <= Float(Config.quarterHandsSymmetrieAngleTolerance2)
        }
        return false
    }
        
    var verticalConnectionLineOkay: Bool {
        if let angle = verticalConnectionLineAngle {
            return angle <= Float(Config.quarterHandsSymmetrieAngleTolerance2)
        }
        return false
    }
    
    var numbersFoundAtLeastOnce: Set<String> {
        return Set(self.classifiedDigits.compactMap({$0.topPrediction.classification}))
    }
    
    var numbersFoundInRightSpot: Set<String> {
        return Set(self.classifiedDigits.filter({$0.isInRightSpot}).compactMap({$0.topPrediction.classification}))
    }
    
}

extension AnalyzedClockResult {
    static var example: AnalyzedClockResult {
        let classifiedDigits = [
            ClassifiedDigit(digitImage: UIImage(named: "clock")!, predictions: [Prediction(classification: "3", confidencePercentage: 0.55)], centerX: 1000, centerY: 500),
            ClassifiedDigit(digitImage: UIImage(named: "clock")!, predictions: [Prediction(classification: "9", confidencePercentage: 0.55)], centerX: 0, centerY: 500),
            ClassifiedDigit(digitImage: UIImage(named: "clock")!, predictions: [Prediction(classification: "12", confidencePercentage: 0.55)], centerX: 500, centerY: 0),
            ClassifiedDigit(digitImage: UIImage(named: "clock")!, predictions: [Prediction(classification: "6", confidencePercentage: 0.55)], centerX: 500, centerY: 1000)
        ]
        
        return AnalyzedClockResult(completeImage: UIImage(named: "clock")!, digitDetectionInvertedImage: UIImage(named: "clock")!, clockhandDetectionInvertedImage: UIImage(named: "clock")!, digitRectanlgeImage: UIImage(named: "clock")!, handsHoughTransformImage: UIImage(named: "clock")!, detectedHandsImage: UIImage(named: "clock")!, classifiedDigits: classifiedDigits, hourHandAngle: 120, minuteHandAngle: 12, secondsToComplete: 110, timesRestarted: 0)
    }
}
