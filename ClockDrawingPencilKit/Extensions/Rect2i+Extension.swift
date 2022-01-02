//
//  Rect2i+Extension.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 27.12.21.
//

import Foundation
import opencv2

extension Rect2i {
    
    func outsetBy(d: Int32) -> Rect2i {
        return Rect2i(x: self.x-d, y: self.y-d, width: self.width+2*d, height: self.height+2*d)
    }
}
