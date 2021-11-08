//
//  Sequence+Extension.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import Foundation

extension Sequence where Element: Hashable {
    var histogram: [Element: Int] {
        return self.reduce(into: [:]) { counts, elem in counts[elem, default: 0] += 1 }
    }
}
