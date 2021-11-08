//
//  ImageProcessor.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 06.11.21.
//

import Foundation
import opencv2

extension Imgproc {
    /*
    static func twoImagesSideBySide(leftImg: Mat, rightImg: Mat) -> Mat {
        let newWidth = leftImg.width() + rightImg.width()
        let newMat = Mat.zeros(leftImg.height(), cols: newWidth, type: )
    }
    */
    static func resizeAndPad(img: Mat, size: Size2i, padColor: Int32 = 0) -> Mat {
        let h = img.height()
        let w = img.width()
        let sh = size.height
        let sw = size.width
        var interp = opencv2.InterpolationFlags.INTER_CUBIC
        if h > sh || w > sw {
            interp = opencv2.InterpolationFlags.INTER_AREA
        }
        let aspect = Double(w) / Double(h)
        let saspect = Double(sw) / Double(sh)
        
        var pad_top: Int32 = 0
        var pad_bot: Int32 = 0
        var pad_left: Int32 = 0
        var pad_right: Int32 = 0
        
        var new_h: Int32 = sh
        var new_w: Int32 = sw
        
        if (saspect > aspect) || (saspect == 1 && aspect <= 1) { // new horizontal image
            new_h = sh
            new_w = Int32(Double(new_h) * aspect)
            let pad_horz = Double(sw - new_w) / 2
            pad_left = Int32(pad_horz.rounded(.down))
            pad_right = Int32(pad_horz.rounded(.up))
        } else if (saspect < aspect) || (saspect == 1 && aspect >= 1) { // new vertical image
            new_w = sw
            new_h = Int32(Double(new_h) / aspect)
            let pad_vert = Double(sh - new_h) / 2
            pad_top = Int32(pad_vert.rounded(.down))
            pad_bot = Int32(pad_vert.rounded(.up))
        }
        
        let scaled_image = Mat()
        Imgproc.resize(src: img, dst: scaled_image, dsize: Size2i(width: new_w-2, height: new_h-2), fx: 0, fy: 0, interpolation: interp.rawValue)
        Core.copyMakeBorder(src: scaled_image, dst: scaled_image, top: pad_top+2, bottom: pad_bot+2, left: pad_left+2, right: pad_right+2, borderType: opencv2.BorderTypes.BORDER_CONSTANT, value: Scalar(Double(padColor)))
        return scaled_image
    }
    
    
}
