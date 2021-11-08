//
//  Prediction.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import Foundation

struct Prediction {
    /// The name of the object or scene the image classifier recognizes in an image.
    let classification: String

    /// The image classifier's confidence as a percentage string.
    ///
    /// The prediction string doesn't include the % symbol in the string.
    let confidencePercentage: Double
}
