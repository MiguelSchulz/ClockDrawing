//
//  PKDrawing+Extension.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 03.10.21.
//

import Foundation
import PencilKit

extension PKDrawing {
    
    func changeLineWidth(by: CGFloat) -> PKDrawing {
        
        var strokes = [PKStroke]()
        for stroke in self.strokes {
            var editStroke = stroke
            editStroke.ink = PKInkingTool(ink: .init(.pen, color: .red), width: 1).ink
            let path = editStroke.path
            var points = [PKStrokePoint]()
            for point in path {
                points.append(PKStrokePoint(location: point.location, timeOffset: point.timeOffset, size: CGSize(width: point.size.width+by, height: point.size.height+by), opacity: point.opacity, force: point.force, azimuth: point.azimuth, altitude: point.altitude))
            }
            strokes.append(PKStroke(ink: PKInk(.pen, color: .black), path: PKStrokePath(controlPoints: points, creationDate: Date())))
        }
        return PKDrawing(strokes: strokes)
    }
    
}
