//
//  ClockAnalyzer.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import Foundation
import opencv2

class ClockAnalyzer: ObservableObject {
    
    @Published var analyzedResult = AnalyzedClockResult()
    
    private let MNISTpredictor = MNISTImagePredictor()
    private var dispatchGroup = DispatchGroup()
    
    func startAnalysis(clockImage: UIImage, onCompletion: @escaping () -> Void) {
        let drawingOnlyMat = Mat(uiImage: clockImage, alphaExist: true)
        
        // GET TRANSPARENT PIXELS AND SET THEM TO SOLID WHITE
        let transparentMask = Mat()
        Core.inRange(src: drawingOnlyMat, lowerb: Scalar(0,0,0,0), upperb: Scalar(255,255,255,1), dst: transparentMask)
        drawingOnlyMat.setTo(scalar: Scalar(255,255,255,255), mask: transparentMask)
        
        self.analyzedResult.completeImage = clockImage
        
        
        // APPLY THRESHOLDING AND CONVERT TO GRAY IMAGE
        Imgproc.cvtColor(src: drawingOnlyMat, dst: drawingOnlyMat, code: ColorConversionCodes.COLOR_RGBA2GRAY) // COLOR_BGR2GRAY
        Imgproc.threshold(src: drawingOnlyMat, dst: drawingOnlyMat, thresh: 0, maxval: 255, type: ThresholdTypes.THRESH_BINARY_INV)
        self.analyzedResult.clockSize = drawingOnlyMat.size()
        print(drawingOnlyMat.size())
        
        // PREPARE DIFFERENT IMAGES FOR CLASSIFICATION TASKS
        let digitClassificationImage = drawingOnlyMat.clone()
        let handsClassificationImage = drawingOnlyMat.clone()
        let imageWidth = drawingOnlyMat.width()
        let imageHeight = drawingOnlyMat.height()
        
    
        Imgproc.circle(img: digitClassificationImage, center: Point2i(x: imageWidth/2, y: imageHeight/2), radius: Int32(Double((imageHeight/2))*0.7), color: Scalar(0,0,0), thickness: LineTypes.FILLED.rawValue)
        Imgproc.circle(img: handsClassificationImage, center: Point2i(x: imageWidth/2, y: imageHeight/2), radius: imageHeight/2, color: Scalar(0,0,0), thickness: Int32(Double(imageHeight / 2) * 0.8))
       
        //UIImageWriteToSavedPhotosAlbum(digitClassificationImage.toUIImage(), nil, nil, nil)
        //UIImageWriteToSavedPhotosAlbum(handsClassificationImage.toUIImage(), nil, nil, nil)
        
        self.analyzedResult.digitDetectionInvertedImage = digitClassificationImage.toUIImage()
        self.analyzedResult.clockhandDetectionInvertedImage = handsClassificationImage.toUIImage()
        self.classifyDigits(clockImage: digitClassificationImage)
        self.handDetection(clockImage: handsClassificationImage)
        
        dispatchGroup.notify(queue: .main) {
            for digit in self.analyzedResult.classifiedDigits {
                //let _ = self.determineIfDigitPositionIsCorrect(digit: digit)
                self.checkForDoubleDigit(digit)
            }
            for digit in self.analyzedResult.classifiedDigits {
                //let _ = self.determineIfDigitPositionIsCorrect(digit: digit)
                let isInRightPosition = self.determineIfDigitPositionIsCorrect(digit: digit)
                if isInRightPosition {
                    if let modifyIndex = self.analyzedResult.classifiedDigits.firstIndex(where: {$0 == digit}) {
                        var modifyDigit = self.analyzedResult.classifiedDigits.remove(at: modifyIndex)
                        modifyDigit.isInRightSpot = true
                        self.analyzedResult.classifiedDigits.append(modifyDigit)
                        print("\(modifyDigit.topPrediction.classification) is in right position!")
                    }
                }
            }
            onCompletion()
        }
    }
    
    private func handDetection(clockImage: Mat) {
        let drawingMat = clockImage.clone()
        let lineDrawMat = Mat.zeros(drawingMat.size(), type: CvType.CV_8UC3)
        
        
        // CANNY EDGE DETECTION
        Imgproc.Canny(image: drawingMat, edges: drawingMat, threshold1: 50, threshold2: 200, apertureSize: 3)
        
        // DETECT LINES WITH HOUGH P
        let lines = Mat()
        
        Imgproc.HoughLinesP(image: drawingMat, lines: lines, rho: 1, theta: .pi / 180, threshold: Int32(Config.houghTransformThreshold), minLineLength: Double(Config.minLineLengthForHoughTransform))
        var points = [Point2i]()
        // SAVE ALL POINTS IN ARRAY
        for i in 0..<lines.rows() {
            let data = lines.get(row: i, col: 0)
            
            let startPoint = Point2i(x: Int32(data[0]), y: Int32(data[1]))
            let endPoint = Point2i(x: Int32(data[2]), y: Int32(data[3]))
            
            points.append(startPoint)
            points.append(endPoint)
            
            // DRAW LINES DEBUG VISUALIZATION
            Imgproc.line(img: lineDrawMat, pt1: startPoint, pt2: endPoint, color: Scalar(125, 0, 0), thickness: 6)
        }
        
        self.analyzedResult.handsHoughTransformImage = lineDrawMat.toUIImage()
        
        // GET 3 CHARACTERISTIC POINTS
        let mostRightPoint = points.max(by: { $0.x < $1.x}) ?? Point2i()
        let mostDownPoint = points.min(by: { $0.y > $1.y}) ?? Point2i()
        let mostLeftPoint = points.min(by: { $0.x < $1.x}) ?? Point2i()
        
        self.analyzedResult.hourHandAngle = mostDownPoint.angleTo(mostLeftPoint)
        self.analyzedResult.minuteHandAngle = mostDownPoint.angleTo(mostRightPoint)
        
        
        // DRAW POINTS FOR DEBUG
        
        let handsDrawMat = Mat.zeros(drawingMat.size(), type: CvType.CV_8UC3)
        if self.analyzedResult.clockhandsRight {
            Imgproc.line(img: handsDrawMat, pt1: mostDownPoint, pt2: mostRightPoint, color: Scalar(125, 0, 0), thickness: 20)
            Imgproc.line(img: handsDrawMat, pt1: mostDownPoint, pt2: mostLeftPoint, color: Scalar(0, 125, 0), thickness: 20)
        }
        self.analyzedResult.detectedHandsImage = handsDrawMat.toUIImage()
        
    }
    
    private func classifyDigits(clockImage: Mat) {
        let hierarchy = Mat()
        var contours: [[Point]] = [[]]
        let contourImage = clockImage.clone()
        
        // FIND CONTOURS
        Imgproc.findContours(image: clockImage, contours: &contours, hierarchy: hierarchy, mode: RetrievalModes.RETR_EXTERNAL, method: ContourApproximationModes.CHAIN_APPROX_SIMPLE)
        Imgproc.cvtColor(src: contourImage, dst: contourImage, code: ColorConversionCodes.COLOR_GRAY2RGB)
        
        for contour in contours {
            if
                let minX = contour.min(by: {$0.x < $1.x})?.x,
                let minY = contour.min(by: {$0.y < $1.y})?.y,
                let maxX = contour.max(by: {$0.x < $1.x})?.x,
                let maxY = contour.max(by: {$0.y < $1.y})?.y {
               
                // CALCULATE BOUDING RECT
                let width = maxX - minX
                let height = maxY - minY
                
                let pad: Int32 = 30
                
                let boundRect = Rect2i(x: minX, y: minY, width: width, height: height)
                let boundRectDraw = Rect2i(x: minX-pad, y: minY-pad, width: width+pad*2, height: height+pad*2)
                
                
                // CROP TO BOUNDING RECT AND RESIZE FOR MNIST
                let croppedImg = Imgproc.resizeAndPad(img: Mat(mat: clockImage, rect: boundRect), size: Size2i(width: 28, height: 28), padColor: 0)
                
                // DRAW CONTOUR TO IMAGE
                Imgproc.rectangle(img: contourImage, rec: boundRectDraw, color: Scalar(125,0,0), thickness: 5)
                
                dispatchGroup.enter()
                self.classifyDigit(ClassifiedDigit(digitImage: croppedImg.toUIImage(), predictions: [], centerX: (minX + width/2), centerY: (minY + height / 2), originalBoundingBox: boundRect))
               
            }
        }
        analyzedResult.digitRectanlgeImage = contourImage.toUIImage()
        
        
    }
    
    private func classifyDigit(_ digit: ClassifiedDigit) {
        do {
            try self.MNISTpredictor.makePredictions(for: digit, completionHandler: receiveClassifiedDigit)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
            dispatchGroup.leave()
        }
    }

    private func receiveClassifiedDigit(_ classifiedDigit: ClassifiedDigit) {
        self.analyzedResult.classifiedDigits.append(classifiedDigit)
        dispatchGroup.leave()
    }
    
    private func checkForDoubleDigit(_ digit: ClassifiedDigit) {
        
        let numberXDifference: ClosedRange<Int32> = 1...100
        let numberYDifference: Int32 = 20
        
        func checkNeighborsAndUpdateClassifications(digit1: ClassifiedDigit, digit2: ClassifiedDigit) {
            if digit1 != digit2 {
                let xDiff = digit2.centerX - digit1.centerX
                let yDiff = abs(digit1.centerY - digit2.centerY)
                if yDiff < numberYDifference && numberXDifference.contains(xDiff) {
                    let firstBoundRect = digit1.originalBoundingBox
                    let secondBoundRect = digit2.originalBoundingBox
                    
                    let newX = min(firstBoundRect.x, secondBoundRect.x)
                    let newY = min(firstBoundRect.y, secondBoundRect.y)
                    let newMaxX = max(firstBoundRect.x + firstBoundRect.width, secondBoundRect.x+secondBoundRect.width)
                    let newMaxY = max(firstBoundRect.y + firstBoundRect.height, secondBoundRect.y+secondBoundRect.height)
                    let newWidth = newMaxX - newX
                    let newHeight = newMaxY - newY
                    
                    let newRect = Rect2i(x: newX, y: newY, width: newWidth, height: newHeight)
                    let wholeMat = Mat(uiImage: self.analyzedResult.digitDetectionInvertedImage)
                    let newDigitImage = Mat(mat: wholeMat, rect: newRect)
                    
                    let resizedDigitImage = Imgproc.resizeAndPad(img: newDigitImage, size: Size2i(width: 28, height: 28), padColor: 0)
                    
                    let newDigitString = (digit1.topPrediction.classification + digit2.topPrediction.classification).replacingOccurrences(of: "7", with: "1") // ERROR CORRET SINCE ONLY NUMBERS UP TO 12 ARE NEEDED
                    
                    analyzedResult.classifiedDigits.append(ClassifiedDigit(digitImage: resizedDigitImage.toUIImage(), predictions: [Prediction(classification: newDigitString, confidencePercentage: 1.0)], centerX: newX + newWidth / 2, centerY: newY + newHeight / 2, originalBoundingBox: newRect, isInRightSpot: false))
                    analyzedResult.classifiedDigits.removeAll(where: {$0 == digit1 || $0 == digit2})
                    return
                }
            }
            
        }
        
        switch digit.topPrediction.classification {
        case "1":
            let allNeighborsToRight = analyzedResult.classifiedDigits.filter({["7", "2", "1", "0"].contains($0.topPrediction.classification)})
            for neighborDigit in allNeighborsToRight {
                checkNeighborsAndUpdateClassifications(digit1: digit, digit2: neighborDigit)
            }
            let allNeighborsToLeft = analyzedResult.classifiedDigits.filter({["7", "1"].contains($0.topPrediction.classification)})
            for neighborDigit in allNeighborsToLeft {
                checkNeighborsAndUpdateClassifications(digit1: neighborDigit, digit2: digit)
            }
        case "2":
            let allNeighbors = analyzedResult.classifiedDigits.filter({["7", "1"].contains($0.topPrediction.classification)})
            for neighborDigit in allNeighbors {
                checkNeighborsAndUpdateClassifications(digit1: digit, digit2: neighborDigit)
            }
        case "0":
            let allNeighborsToLeft = analyzedResult.classifiedDigits.filter({["7", "1"].contains($0.topPrediction.classification)})
            for neighborDigit in allNeighborsToLeft {
                checkNeighborsAndUpdateClassifications(digit1: neighborDigit, digit2: digit)
            }
        case "7":
            let allNeighborsToRight = analyzedResult.classifiedDigits.filter({["7", "2", "1", "0"].contains($0.topPrediction.classification)})
            for neighborDigit in allNeighborsToRight {
                checkNeighborsAndUpdateClassifications(digit1: digit, digit2: neighborDigit)
            }
            let allNeighborsToLeft = analyzedResult.classifiedDigits.filter({["7", "1"].contains($0.topPrediction.classification)})
            for neighborDigit in allNeighborsToLeft {
                checkNeighborsAndUpdateClassifications(digit1: neighborDigit, digit2: digit)
            }
        default:
            return
        }
    }
    
    private func determineIfDigitPositionIsCorrect(digit: ClassifiedDigit) -> Bool {
        
        let centerX = (analyzedResult.clockSize.width/2)
        let centerY = (analyzedResult.clockSize.height/2)
        
        let toleranceField = analyzedResult.clockSize.height / 8
        switch digit.topPrediction.classification {
        case "12":
            return (centerX-toleranceField...centerX+toleranceField).contains(digit.centerX) && (0...toleranceField*2).contains(digit.centerY)
        case "6":
            return (centerX-toleranceField...centerX+toleranceField).contains(digit.centerX) && (analyzedResult.clockSize.height-toleranceField*2...analyzedResult.clockSize.height).contains(digit.centerY)
        case "9":
            return (0...toleranceField*2).contains(digit.centerX) && (centerY-toleranceField...centerY+toleranceField).contains(digit.centerY)
        case "3":
            return (analyzedResult.clockSize.width-toleranceField*2...analyzedResult.clockSize.width).contains(digit.centerX) && (centerY-toleranceField...centerY+toleranceField).contains(digit.centerY)
        default:
            return false
        }
    }
    
    
}
