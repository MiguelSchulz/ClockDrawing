//
//  Array+Extension.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 13.11.21.
//

import Foundation

extension Array where Element: FloatingPoint {

    func sum() -> Element {
        return self.reduce(0, +)
    }

    func avg() -> Element {
        return self.sum() / Element(self.count)
    }

    func std() -> Element {
        let mean = self.avg()
        let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
        return sqrt(v / (Element(self.count) - 1))
    }

    
    
}

extension Array where Element: Comparable {
    var rangesOfPeaksAndValleys: (peaks: [ClosedRange<Int>], valleys: [ClosedRange<Int>]) {
        guard !isEmpty else { return ([], []) }

        var peaks = [ClosedRange<Int>]()
        var valleys = [ClosedRange<Int>]()

        var previousValue = self[0]
        var lastPeakStartingIndex: Int?
        var lastValleyStartingIndex: Int?

        for (index, value) in enumerated() {
            if value > previousValue {
                if let lastValleyStartingIndexUnwrapped = lastValleyStartingIndex {
                    valleys.append(lastValleyStartingIndexUnwrapped...index - 1)
                    lastValleyStartingIndex = nil
                }

                lastPeakStartingIndex = index
            } else if value < previousValue {
                if let lastPeakStartingIndexUnwrapped = lastPeakStartingIndex {
                    peaks.append(lastPeakStartingIndexUnwrapped...index - 1)
                    lastPeakStartingIndex = nil
                }

                lastValleyStartingIndex = index
            }

            previousValue = value
        }

        return (peaks, valleys)
    }
}
