extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    public func addBorder(_ content: Color, width: CGFloat = 1, cornerRadius: CGFloat, dash: Int = 0) -> some View {
         let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
            return clipShape(roundedRect)
                .overlay(roundedRect.strokeBorder(style: dash == 0 ? StrokeStyle(lineWidth: width) : StrokeStyle(lineWidth: width, dash: [CGFloat(dash) * 5])).foregroundColor(content))
        
         
     }
}

import SwiftUI
import UIKit

extension CGImagePropertyOrientation {
    /**
     Converts a `UIImageOrientation` to a corresponding
     `CGImagePropertyOrientation`. The cases for each
     orientation are represented by different raw values.
     
     - Tag: ConvertOrientation
     */
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        default: self = .up
        }
    }
}
