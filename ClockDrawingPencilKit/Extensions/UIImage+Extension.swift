import UIKit
import SwiftUI

extension UIImage {
    
    func resizeImageTo(size: CGSize) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func convertToBuffer() -> CVPixelBuffer? {
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(self.size.width),
            Int(self.size.height),
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer)
        
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: pixelData,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    static func HoleShapeMask(in rect: CGRect) -> Path {
        var shape = Rectangle().path(in: CGRect(origin: CGPoint.zero, size: rect.size))
        shape.addPath(Circle().path(in: CGRect(origin: CGPoint.zero, size: rect.size).insetBy(dx: rect.width / 5, dy: rect.height / 5)))
        return shape
    }
    
    static func getCircularImage(in drawingRect: CGRect) -> UIImage {
        return UIImage(named: "circleoverlay")?.resizeImageTo(size: CGSize(width: drawingRect.size.width+10, height: drawingRect.size.height+10)) ?? UIImage()
    }
    
    func overlayed(by overlayColor: UIColor) -> UIImage {
        //  Create rect to fit the image
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)

        // Create image context. 0 means scale of device's main screen
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()!

        //  Fill the rect by the final color
        overlayColor.setFill()
        context.fill(rect)

        //  Make the final shape by masking the drawn color with the images alpha values
        self.draw(in: rect, blendMode: .destinationIn, alpha: 1)

        //  Create new image from the context
        let overlayedImage = UIGraphicsGetImageFromCurrentImageContext()!

        //  Release context
        UIGraphicsEndImageContext()

        return overlayedImage
    }
    
    func overlayed(with overlay: UIImage) -> UIImage? {
        defer {
            UIGraphicsEndImageContext()
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        overlay.draw(in: CGRect(origin: CGPoint.zero, size: size))
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return nil
    }

}

