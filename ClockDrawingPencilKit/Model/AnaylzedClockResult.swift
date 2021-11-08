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
    
    
    var _3to9Angle: Float {
        let all3 = self.classifiedDigits.filter({$0.topPrediction.classification == "3"})
        let all9 = self.classifiedDigits.filter({$0.topPrediction.classification == "9"})
        var possibleAngles: [Float] = [0]
        for threeDigit in all3 {
            for nineDigit in all9 {
                print("Angle found")
                possibleAngles.append(180-abs(threeDigit.center.angleTo(nineDigit.center)))
            }
        }
        return possibleAngles.min() ?? 0
    }
    var _12to6Angle: Float {
        let all6 = self.classifiedDigits.filter({$0.topPrediction.classification == "6"})
        let all12 = self.classifiedDigits.filter({$0.topPrediction.classification == "12"})
        var possibleAngles: [Float] = [0]
        for threeDigit in all6 {
            for nineDigit in all12 {
                print("Angle found")
                possibleAngles.append(threeDigit.center.angleTo(nineDigit.center))
            }
        }
        return possibleAngles.min() ?? 0
    }
    
    var numbersFoundAtLeastOnce: Set<String> {
        return Set(self.classifiedDigits.compactMap({$0.topPrediction.classification}))
    }
    
}

extension AnalyzedClockResult {
    static var example: AnalyzedClockResult {
        return AnalyzedClockResult(completeImage: UIImage(named: "clock")!, digitDetectionInvertedImage: UIImage(named: "clock")!, clockhandDetectionInvertedImage: UIImage(named: "clock")!, digitRectanlgeImage: UIImage(named: "clock")!, handsHoughTransformImage: UIImage(named: "clock")!, detectedHandsImage: UIImage(named: "clock")!, classifiedDigits: [ClassifiedDigit(digitImage: UIImage(named: "clock")!, predictions: [Prediction(classification: "3", confidencePercentage: 0.55)], centerX: 0, centerY: 0), ClassifiedDigit(digitImage: UIImage(named: "clock")!, predictions: [Prediction(classification: "3", confidencePercentage: 0.55)], centerX: 0, centerY: 0)], hourHandAngle: 120, minuteHandAngle: 30, secondsToComplete: 90, timesRestarted: 0)
    }
}
