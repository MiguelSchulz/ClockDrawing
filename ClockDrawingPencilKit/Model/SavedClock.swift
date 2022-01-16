//
//  SavedClock.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 29.12.21.
//

import Foundation
import RealmSwift
import PencilKit


class SavedClock: Object, ObjectKeyIdentifiable {
    @Persisted var _id: ObjectId = ObjectId.generate()
    @Persisted var name: String = ""
    @Persisted private var drawingData = PKDrawing().dataRepresentation()
    @Persisted private var thumbnailImageData = Data()
    @Persisted private var backgroundImageData = Data()
    @Persisted var width: Float = 0
    @Persisted var height: Float = 0
    
    @Persisted var backgroundZoom: Float = 1
    @Persisted var backgroundOffsetX: Int = 0
    @Persisted var backgroundOffsetY: Int = 0

    @Persisted var rightScore = 1
    
    var drawing: PKDrawing {
        get {
            do {
                if let drawing = try? PKDrawing(data: drawingData) {
                    return drawing
                }
                return PKDrawing()
            } //catch { return PKDrawing() }
        }
        set {
            self.drawingData = newValue.dataRepresentation()
        }
    }
    var backgroundImage: UIImage {
        get {
            UIImage(data: backgroundImageData) ?? UIImage()
        }
        set {
            self.backgroundImageData = newValue.resizeImageTo(size: CGSize(width: 512, height: 512))?.pngData() ?? Data()
        }
    }
    var thumbnail: UIImage {
        get {
            UIImage(data: thumbnailImageData) ?? UIImage()
        }
        set {
            self.thumbnailImageData = newValue.resizeImageTo(size: CGSize(width: 200, height: 200))?.pngData() ?? Data()
        }
    }
    //@Persisted var _partition: String = "shared"
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
    @Published var analyzedResult: AnalyzedClockResult?
    @Published var analyzedScore: Int = 0
    

}

extension SavedClock: Identifiable {
    var id: String {
        _id.stringValue
    }
}
