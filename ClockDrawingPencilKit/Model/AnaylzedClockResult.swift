//
//  AnaylzedClockResult.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import Foundation
import opencv2

struct AnalyzedClockResult: Equatable {
    
    var minute = 0
    var hour = 0
    
    var score = 0
    
    var clockSize = Size2i(width: 0, height: 0)
    
    var completeImage = UIImage()
    var houghImage = UIImage()
    
    var classifiedDigits = [ClassifiedDigit]()
    
    
    var hourHandAngle: Float = 0
    var minuteHandAngle: Float = 0
    
    var secondsToComplete = 0
    var timesRestarted = 0
    
    
    
    var clockhandsRight: Bool {
        if Config.useMLforClockhands {
            return hour == 11 && minute == 10
        } else {
            return Config.hourHandAngleRange.contains(abs(Int32(self.hourHandAngle))) && Config.minuteHandAngleRange.contains(abs(Int32(self.minuteHandAngle)))
        }
        
    }
    var clockhandsAlmostRight: Bool {
        if Config.useMLforClockhands {
            return (10...12).contains(hour) && (5...15).contains(minute)
        } else {
            return Config.hourHandAngleRange2.contains(abs(Int32(self.hourHandAngle))) && Config.minuteHandAngleRange2.contains(abs(Int32(self.minuteHandAngle)))
        }
        
    }
    
    
    var horizontalConnectionLineAngle: Float? {
        if let mostRightNumber = self.classifiedDigits.max(by: {$0.centerX > $1.centerX}), let mostLeftNumber = self.classifiedDigits.min(by: {$0.centerX > $1.centerX}) {
            
            let angle = mostLeftNumber.center.angleTo(mostRightNumber.center)
            
            if angle < 0 {
                return angle + 180
            }
            return angle - 180
        }
        return nil
    }
    var verticalConnectionLineAngle: Float? {
        if let mostRightNumber = self.classifiedDigits.max(by: {$0.centerY > $1.centerY}), let mostLeftNumber = self.classifiedDigits.min(by: {$0.centerY > $1.centerY}) {
            return mostRightNumber.center.angleTo(mostLeftNumber.center) - 90
        }
        return nil
    }
    
    var horizontalConnectionLinePerfect: Bool {
        if let angle = horizontalConnectionLineAngle {
            let tolerance = Float(Config.quarterHandsSymmetrieAngleTolerance)
            return (-tolerance...tolerance).contains(angle)
        }
        return false
    }
        
    var verticalConnectionLinePerfect: Bool {
        if let angle = verticalConnectionLineAngle {
            let tolerance = Float(Config.quarterHandsSymmetrieAngleTolerance)
            return (-tolerance...tolerance).contains(angle)
        }
        return false
    }
    
    var horizontalConnectionLineOkay: Bool {
        if let angle = horizontalConnectionLineAngle {
            let tolerance = Float(Config.quarterHandsSymmetrieAngleTolerance2)
            return (-tolerance...tolerance).contains(angle)
        }
        return false
    }
        
    var verticalConnectionLineOkay: Bool {
        if let angle = verticalConnectionLineAngle {
            let tolerance = Float(Config.quarterHandsSymmetrieAngleTolerance2)
            return (-tolerance...tolerance).contains(angle)
        }
        return false
    }
    
    var numbersFoundAtLeastOnce: Set<String> {
        return Set(self.classifiedDigits.compactMap({$0.topPrediction.classification}))
    }
    
    var numbersFoundInRightSpot: Set<String> {
        return Set(self.classifiedDigits.filter({$0.isInRightSpot}).compactMap({$0.topPrediction.classification}))
    }
    
    var allShortestDistancesBetweenDigits = [Float]()
    var digitDistancesMean: Float {
        return allShortestDistancesBetweenDigits.avg()
    }
    var digitDistancesStd: Float {
        return allShortestDistancesBetweenDigits.std()
    }
    var digitDistanceVariationCoefficient: Float {
        return digitDistancesStd / digitDistancesMean
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
        
        return AnalyzedClockResult(completeImage: UIImage(named: "clock")!, classifiedDigits: classifiedDigits, hourHandAngle: 120, minuteHandAngle: 12, secondsToComplete: 110, timesRestarted: 0)
    }
}
