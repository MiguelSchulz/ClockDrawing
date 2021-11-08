//
//  Point2i.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import Foundation
import opencv2
extension Point2i {
    
    func angleTo(_ point2: Point2i) -> Float {
        let angle = atan2f(Float(point2.y - self.y), Float(point2.x - self.x));
        return angle * 180 / .pi
    }
    
    func distanceSquared(to: Point2i) -> Float {
        let first = (self.x - to.x) * (self.x - to.x)
        let second = (self.y - to.y) * (self.y - to.y)
        return  Float(first + second)
    }

    func distance(to: Point2i) -> Float {
        return sqrt(distanceSquared(to: to))
    }
}
