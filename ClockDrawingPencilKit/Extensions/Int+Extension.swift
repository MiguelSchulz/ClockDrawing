//
//  Int+Extension.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 13.11.21.
//

import Foundation

extension Int {
    func secondsToMinutesSeconds() -> (Int, Int) {
      return ((self % 3600) / 60, (self % 3600) % 60)
    }
}
