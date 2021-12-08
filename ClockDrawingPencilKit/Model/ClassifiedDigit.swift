//
//  ClassifiedDigit.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import Foundation
import opencv2

struct ClassifiedDigit: Identifiable, Equatable {
    
    static func == (lhs: ClassifiedDigit, rhs: ClassifiedDigit) -> Bool {
        lhs.id == rhs.id
    }
    
    
    var id = UUID()
    var digitImage: UIImage
    var predictions: [Prediction]
    var centerX, centerY: Int32
    var originalBoundingBox: Rect2i = Rect2i(x: 0, y: 0, width: 0, height: 0)
    var isInRightSpot: Bool = false
    
    var topPrediction: Prediction {
        return predictions.first ?? Prediction(classification: "nil", confidencePercentage: 0.0)
    }
    
    var center: Point2i {
        return Point2i(x: Int32(centerX), y: Int32(centerY))
    }
    
    
}
