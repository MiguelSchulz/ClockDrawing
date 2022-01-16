//
//  ClockAnalyzer.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import Foundation
import opencv2
import UIKit

class ClockAnalyzer: ObservableObject {
    
    @Published var analyzedResult = AnalyzedClockResult()
    @Published var firstStrokeDate: Date? 
    
    private let MNISTpredictor = MNISTImagePredictor()
    private var dispatchGroup = DispatchGroup()
    
    let watchhandPredictor = WatchImagePredictor()
    
    func readClockhandsUsingML(handsClassificationImage: Mat) {
        
        let imageWidth = handsClassificationImage.width()
        let imageHeight = handsClassificationImage.height()
        
        // TRY TO REMOVE SOME OF THE DIGITS
        Imgproc.circle(img: handsClassificationImage, center: Point2i(x: imageWidth/2, y: imageHeight/2), radius: imageHeight/2, color: Scalar(255), thickness: Int32(Double(imageHeight / 2) * 0.5))
        
        // DRAW REMAINING HANDS ON BACKGROUND FOR ORIENTATION
        let backgroundImage = Mat(uiImage: UIImage(named: "clock_background")!, alphaExist: false)
        let clockhandMask = Mat()
        Core.inRange(src: handsClassificationImage, lowerb: Scalar(0), upperb: Scalar(1), dst: clockhandMask)
        
        Imgproc.resize(src: backgroundImage, dst: backgroundImage, dsize: handsClassificationImage.size())
        backgroundImage.setTo(scalar: Scalar(0), mask: clockhandMask)
        
        
        Imgproc.resize(src: backgroundImage, dst: backgroundImage, dsize: Size2i(width: 300, height: 300))
        
        do {
            try watchhandPredictor.makePredictions(image: backgroundImage.toUIImage()) { hour, minute in
                self.analyzedResult.hour = hour
                self.analyzedResult.minute = minute
            }
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
            dispatchGroup.leave()
        }
    }
    
    fileprivate func prepareImage(rawImage: UIImage) -> Mat {
        let drawingOnlyMat = Mat(uiImage: rawImage, alphaExist: true)
        
        // GET TRANSPARENT PIXELS AND SET THEM TO SOLID WHITE
        let transparentMask = Mat()
        Core.inRange(src: drawingOnlyMat, lowerb: Scalar(0,0,0,0), upperb: Scalar(255,255,255,1), dst: transparentMask)
        drawingOnlyMat.setTo(scalar: Scalar(255,255,255,255), mask: transparentMask)
        
        
        return drawingOnlyMat
    }
    
    func startAnalysis(clockImage: UIImage, fatClockImage: UIImage, onCompletion: @escaping () -> Void) {
        let digitClassificationImage = prepareImage(rawImage: clockImage)
        let handsClassificationImage = prepareImage(rawImage: fatClockImage)
        let handsClassificationImage_notInverted = handsClassificationImage.clone()
        
        //UIImageWriteToSavedPhotosAlbum(digitClassificationImage.toUIImage(), nil, nil, nil)
        //UIImageWriteToSavedPhotosAlbum(handsClassificationImage.toUIImage(), nil, nil, nil)
        
        self.analyzedResult.completeImage = clockImage
        
        if let firstStrokeDate = firstStrokeDate {
            self.analyzedResult.secondsToComplete = Int(Date().timeIntervalSince1970 - firstStrokeDate.timeIntervalSince1970)
        }
        
        
        // APPLY THRESHOLDING AND CONVERT TO GRAY IMAGE
        Imgproc.cvtColor(src: digitClassificationImage, dst: digitClassificationImage, code: ColorConversionCodes.COLOR_RGBA2GRAY) // COLOR_BGR2GRAY
        Imgproc.threshold(src: digitClassificationImage, dst: digitClassificationImage, thresh: 0, maxval: 255, type: ThresholdTypes.THRESH_BINARY_INV)
        Imgproc.cvtColor(src: handsClassificationImage, dst: handsClassificationImage, code: ColorConversionCodes.COLOR_RGBA2GRAY) // COLOR_BGR2GRAY
        Imgproc.threshold(src: handsClassificationImage, dst: handsClassificationImage, thresh: 0, maxval: 255, type: ThresholdTypes.THRESH_BINARY_INV)
        Imgproc.cvtColor(src: handsClassificationImage_notInverted, dst: handsClassificationImage_notInverted, code: ColorConversionCodes.COLOR_RGBA2GRAY) // COLOR_BGR2GRAY
        Imgproc.threshold(src: handsClassificationImage_notInverted, dst: handsClassificationImage_notInverted, thresh: 0, maxval: 255, type: ThresholdTypes.THRESH_BINARY)
        self.analyzedResult.clockSize = digitClassificationImage.size()
        
        // PREPARE DIFFERENT IMAGES FOR CLASSIFICATION TASKS
        let imageWidth = digitClassificationImage.width()
        let imageHeight = digitClassificationImage.height()

        //Imgproc.circle(img: digitClassificationImage, center: Point2i(x: imageWidth/2, y: imageHeight/2), radius: imageHeight/5, color: Scalar(0,0,0), thickness: -1)
        
        self.classifyDigits(clockImage: digitClassificationImage)
        
        
        
        dispatchGroup.notify(queue: .main) {
            for digit in self.analyzedResult.classifiedDigits {
                //let _ = self.determineIfDigitPositionIsCorrect(digit: digit)
                self.checkForDoubleDigit(digit, wholeMat: digitClassificationImage)
            }
            
            if Config.useMLforClockhands {
                self.readClockhandsUsingML(handsClassificationImage: handsClassificationImage_notInverted)
            } else {
                Imgproc.circle(img: handsClassificationImage, center: Point2i(x: imageWidth/2, y: imageHeight/2), radius: imageHeight/2, color: Scalar(0,0,0), thickness: Int32(Double(imageHeight / 2) * 0.8))
                self.handDetection(clockImage: handsClassificationImage)
            }
            
            for count in self.analyzedResult.classifiedDigits.indices {
                //let _ = self.determineIfDigitPositionIsCorrect(digit: digit)
                self.analyzedResult.classifiedDigits[count].isInRightSpot = self.determineIfDigitPositionIsCorrect(digit: self.analyzedResult.classifiedDigits[count])

                self.calculateShortestDistanceToOtherDigits(digit: self.analyzedResult.classifiedDigits[count])
            }
            let (angle2, angle11) = self.tryFindingDigitAnglesForClockhands()

            self.analyzedResult.found2angle = angle2
            self.analyzedResult.found11angle = angle11

            self.analyzedResult.score = self.makeDecision()
            onCompletion()
        }
    }

    private func tryFindingDigitAnglesForClockhands() -> (angle2: Float, angle11: Float) {
        var angle2: Float = 30
        var angle11: Float = 120

        let image = Mat(uiImage: self.analyzedResult.completeImage)

        let centerPoint = Point2i(x: image.width()/2, y: image.height()/2)


        // TRY FINDING BY NUMBER AT RIGHT POSITION
        for digit in analyzedResult.classifiedDigits.filter({$0.topPrediction.classification == "11"}) {
            let angle = centerPoint.angleTo(digit.center) * -1
            if angle11 == 120 && (105...150).contains(angle) {
                angle11 = angle
            } else if (abs(120.0 - angle) < abs(120.0 - angle11)) {
                angle11 = angle
            }
        }

        for digit in analyzedResult.classifiedDigits.filter({$0.topPrediction.classification == "2"}) {
            let angle = centerPoint.angleTo(digit.center) * -1
            if angle2 == 30 && (10...70).contains(angle) {
                angle2 = angle
            } else if (abs(30 - angle) < abs(30 - angle2)) {
                angle2 = angle
            }
        }
/*
        // TRY FINDING CLOSEST MARKER AT POSITION
        if angle2 == 30 {
            if let number2 = analyzedResult.classifiedDigits.min(by: {abs(30 - (centerPoint.angleTo($0.center) * -1)) < abs(30 - (centerPoint.angleTo($1.center) * -1))}) {
                let angle = centerPoint.angleTo(number2.center) * -1
                if abs(30 - angle) < 10 {
                    angle2 = angle
                }
            }
        }
        if angle11 == 120 {
            if let number11 = analyzedResult.classifiedDigits.min(by: {abs(120 - (centerPoint.angleTo($0.center) * -1)) < abs(120 - (centerPoint.angleTo($1.center) * -1))}) {
                let angle = centerPoint.angleTo(number11.center) * -1
                if abs(120 - angle) < 10 {
                    angle11 = angle
                }
            }
        }*/



        return (angle2: angle2, angle11: angle11)
    }
    
    private func handDetection(clockImage: Mat) {
        let drawingMat = clockImage.clone()
        let lineDrawMat = Mat.zeros(drawingMat.size(), type: CvType.CV_8UC3)
        
        let colorLineDrawMat = Mat.zeros(drawingMat.size(), type: CvType.CV_8UC3)
        colorLineDrawMat.setTo(scalar: Scalar(255,255,255))
        
        
        //Imgproc.cvtColor(src: colorLineDrawMat, dst: colorLineDrawMat, code: ColorConversionCodes.COLOR_GRAY2RGBA)
        
        // REMOVE FOUND DIGITS FROM IMAGE
        /*for digit in self.analyzedResult.classifiedDigits {
            Imgproc.rectangle(img: drawingMat, rec: digit.originalBoundingBox.outsetBy(d: Int32(Config.changeLineWidthOfDrawingBy+2)), color: Scalar(0), thickness: -1)
        }*/
        // WARP POLAR TO CREATE LINEAR IMAGE OF CIRCLE
        Imgproc.warpPolar(src: drawingMat, dst: lineDrawMat, dsize: drawingMat.size(), center: Point2f(x: Float(drawingMat.width()) / 2, y: Float(drawingMat.height()) / 2), maxRadius: Double(drawingMat.width()) / 4, flags: WarpPolarMode.WARP_POLAR_LINEAR.rawValue)
        
        
        
        // CUT LEFT TO FIX CENTER ERROR
//        Imgproc.rectangle(img: lineDrawMat, rec: Rect2i(x: 0, y: 0, width: lineDrawMat.width() / 6, height: lineDrawMat.height()), color: Scalar(0), thickness: -1)
        //Imgproc.rectangle(img: lineDrawMat, rec: Rect2i(x: 0, y: 0, width: lineDrawMat.width(), height: lineDrawMat.height()/2), color: Scalar(0), thickness: -1)
        
        // EDGE DETECTION
        Imgproc.Canny(image: lineDrawMat, edges: lineDrawMat, threshold1: 50, threshold2: 200, apertureSize: 3)
                
        // DETECT LINES WITH HOUGH P
        let lines = Mat()
        Imgproc.HoughLinesP(image: lineDrawMat, lines: lines, rho: 1, theta: .pi / 180, threshold: Int32(Config.houghTransformThreshold), minLineLength: Double(Config.minLineLengthForHoughTransform))
        
        var relevantYs = [Int32]()
        // SAVE ALL RELEVANT Ys IN ARRAY
        for i in 0..<lines.rows() {
            let data = lines.get(row: i, col: 0)
            
            let startPoint = Point2i(x: Int32(data[0]), y: Int32(data[1]))
            let endPoint = Point2i(x: Int32(data[2]), y: Int32(data[3]))
            
            // FILTER OUT ONLY HORIZONTAL LINES
            if ((-3.0)...(3.0)).contains(Double(startPoint.angleTo(endPoint))) {
                relevantYs.append(startPoint.y)
                relevantYs.append(endPoint.y)
                // DRAW LINES DEBUG VISUALIZATION
                Imgproc.line(img: colorLineDrawMat, pt1: startPoint, pt2: endPoint, color: Scalar(255, 0, 0), thickness: 6)
            }
                  
        }
        
        let kmm = KMeans<String>(labels: ["1", "2"])
        let vectors = relevantYs.map({ Vector([Double($0)])})
        
        if !vectors.isEmpty {
            kmm.trainCenters(vectors, convergeDistance: 0.01)
        }
        
        
        var angle1: Float = 0
        var angle2: Float = 0
        
        if let foundValue = kmm.centroids.first?.data.first {
            angle1 = Float((Double(lineDrawMat.width())-foundValue) / Double(lineDrawMat.width()) * 360)
        }
        if let foundValue = kmm.centroids.last?.data.first {
            angle2 = Float((Double(lineDrawMat.width())-foundValue) / Double(lineDrawMat.width()) * 360)
        }
        
        
        for i in 0..<lines.rows() {
            let data = lines.get(row: i, col: 0)
            
            let startPoint = Point2i(x: Int32(data[0]), y: Int32(data[1]))
            let endPoint = Point2i(x: Int32(data[2]), y: Int32(data[3]))
            
            if ((-3.0)...(3.0)).contains(Double(startPoint.angleTo(endPoint))) {
                var color = Scalar(0, 200, 0)
                if kmm.fit(Vector([Double(startPoint.y)])) == "1" {
                    color = Scalar(255, 200, 0)
                }
                // DRAW LINES DEBUG VISUALIZATION
                Imgproc.line(img: colorLineDrawMat, pt1: startPoint, pt2: endPoint, color: color, thickness: 10)
            }
                  
        }
        
        // DRAW ORIENTATION LINES
        for i in 0..<13 {
            var fraction = Double(i)/12
            var fracHeight = Double(lineDrawMat.height()) * fraction
            Imgproc.line(img: colorLineDrawMat, pt1: Point2i(x: 0, y: Int32(fracHeight)), pt2: Point2i(x: drawingMat.width()-60, y: Int32(fracHeight)), color: Scalar(0,0,0), thickness: 2)
            var iText = i+3
            if iText > 12 {
                iText -= 12
            }
            Imgproc.putText(img: colorLineDrawMat, text: "\(iText)", org: Point2i(x: drawingMat.width()-50, y: Int32(fracHeight)), fontFace: HersheyFonts.FONT_HERSHEY_DUPLEX, fontScale: 1, color: Scalar(0,0,0))
        }
        
        self.analyzedResult.hourHandAngle = max(angle1, angle2)
        self.analyzedResult.minuteHandAngle = min(angle1, angle2)
        
        // CREATE IMAGE
        
        self.analyzedResult.houghImage = colorLineDrawMat.toUIImage()
        
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
        var appendDigit = classifiedDigit
        
        let centerX = (analyzedResult.clockSize.width/2)
        let centerY = (analyzedResult.clockSize.height/2)
        
        let toleranceField = analyzedResult.clockSize.height / 8
        
        // DELETE NUMBERS THAT ARE TO BIG (CONFUSED WITH CLOCKHANDS)
        let maxSize = analyzedResult.clockSize.width / 6
        
        if classifiedDigit.originalBoundingBox.width > maxSize || classifiedDigit.originalBoundingBox.height > maxSize {
            dispatchGroup.leave()
            return
        }
        
        // CORRECT POSSIBLE CONFUSIONS
        if (classifiedDigit.topPrediction.classification == "7" || classifiedDigit.topPrediction.classification == "4") && (centerX...analyzedResult.clockSize.width-toleranceField).contains(classifiedDigit.centerX) && (0...toleranceField*2).contains(classifiedDigit.centerY) {
            appendDigit = ClassifiedDigit(digitImage: classifiedDigit.digitImage, predictions: [Prediction(classification: "1", confidencePercentage: 1)], centerX: classifiedDigit.centerX, centerY: classifiedDigit.centerY, originalBoundingBox: classifiedDigit.originalBoundingBox, isInRightSpot: false)
            self.analyzedResult.classifiedDigits.removeAll(where: {$0 == classifiedDigit})
            print("Fixed a seven")
        }
        if classifiedDigit.topPrediction.classification == "9" && (centerX+toleranceField...analyzedResult.clockSize.width).contains(classifiedDigit.centerX) && (centerY...analyzedResult.clockSize.height-toleranceField).contains(classifiedDigit.centerY) {
            appendDigit = ClassifiedDigit(digitImage: classifiedDigit.digitImage, predictions: [Prediction(classification: "4", confidencePercentage: 1)], centerX: classifiedDigit.centerX, centerY: classifiedDigit.centerY, originalBoundingBox: classifiedDigit.originalBoundingBox, isInRightSpot: false)
            self.analyzedResult.classifiedDigits.removeAll(where: {$0 == classifiedDigit})
            print("Fixed a nine")
        }
        self.analyzedResult.classifiedDigits.append(appendDigit)
        dispatchGroup.leave()
    }
    
    private func checkForDoubleDigit(_ digit: ClassifiedDigit, wholeMat: Mat) {
        
        let numberXDifference: ClosedRange<Int32> = 1...70
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
                    let newDigitImage = Mat(mat: wholeMat, rect: newRect)
                    
                    let resizedDigitImage = Imgproc.resizeAndPad(img: newDigitImage, size: Size2i(width: 28, height: 28), padColor: 0)
                    
                    let newDigitString = (digit1.topPrediction.classification.replacingOccurrences(of: "4", with: "1").replacingOccurrences(of: "7", with: "1").replacingOccurrences(of: "2", with: "1") + digit2.topPrediction.classification).replacingOccurrences(of: "7", with: "1").replacingOccurrences(of: "4", with: "1") // ERROR CORRET SINCE ONLY NUMBERS UP TO 12 ARE NEEDED
                    
                    analyzedResult.classifiedDigits.append(ClassifiedDigit(digitImage: resizedDigitImage.toUIImage(), predictions: [Prediction(classification: newDigitString, confidencePercentage: 1.0)], centerX: newX + newWidth / 2, centerY: newY + newHeight / 2, originalBoundingBox: newRect, isInRightSpot: false))
                    analyzedResult.classifiedDigits.removeAll(where: {$0 == digit1 || $0 == digit2})
                    return
                }
            }
            
        }
        
        switch digit.topPrediction.classification {
        case "1":
            let allNeighborsToRight = analyzedResult.classifiedDigits.filter({["7", "2", "1", "0", "4"].contains($0.topPrediction.classification)})
            for neighborDigit in allNeighborsToRight {
                checkNeighborsAndUpdateClassifications(digit1: digit, digit2: neighborDigit)
            }
            let allNeighborsToLeft = analyzedResult.classifiedDigits.filter({["7", "1", "4"].contains($0.topPrediction.classification)})
            for neighborDigit in allNeighborsToLeft {
                checkNeighborsAndUpdateClassifications(digit1: neighborDigit, digit2: digit)
            }
        case "2":
            let allNeighbors = analyzedResult.classifiedDigits.filter({["7", "1", "4"].contains($0.topPrediction.classification)})
            for neighborDigit in allNeighbors {
                checkNeighborsAndUpdateClassifications(digit1: digit, digit2: neighborDigit)
            }
        case "0":
            let allNeighborsToLeft = analyzedResult.classifiedDigits.filter({["7", "1", "4"].contains($0.topPrediction.classification)})
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
        case "4":
            let allNeighborsToRight = analyzedResult.classifiedDigits.filter({["7", "2", "1", "0", "4"].contains($0.topPrediction.classification)})
            for neighborDigit in allNeighborsToRight {
                checkNeighborsAndUpdateClassifications(digit1: digit, digit2: neighborDigit)
            }
            let allNeighborsToLeft = analyzedResult.classifiedDigits.filter({["7", "1", "4"].contains($0.topPrediction.classification)})
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
        
        
        
        let toleranceField = analyzedResult.clockSize.height / 6
        switch digit.topPrediction.classification {
            // MAIN DIGITS
        case "12":
            return (centerX-toleranceField...centerX+toleranceField).contains(digit.centerX) && (0...toleranceField*2).contains(digit.centerY)
        case "6":
            return (centerX-toleranceField...centerX+toleranceField).contains(digit.centerX) && (analyzedResult.clockSize.height-toleranceField*2...analyzedResult.clockSize.height).contains(digit.centerY)
        case "9":
            return (0...toleranceField*2).contains(digit.centerX) && (centerY-toleranceField...centerY+toleranceField).contains(digit.centerY)
        case "3":
            return (analyzedResult.clockSize.width-toleranceField*2...analyzedResult.clockSize.width).contains(digit.centerX) && (centerY-toleranceField...centerY+toleranceField).contains(digit.centerY)
            // First Quadrant
        case "1":
            return (centerX...analyzedResult.clockSize.width-toleranceField).contains(digit.centerX) && (0...toleranceField*2).contains(digit.centerY)
        case "2":
            return (centerX+toleranceField...analyzedResult.clockSize.width).contains(digit.centerX) && (toleranceField...centerY).contains(digit.centerY)
        case "4":
            return (centerX+toleranceField...analyzedResult.clockSize.width).contains(digit.centerX) && (centerY...analyzedResult.clockSize.height-toleranceField).contains(digit.centerY)
        case "5":
            return (centerX...analyzedResult.clockSize.width-toleranceField).contains(digit.centerX) && (centerY+toleranceField...analyzedResult.clockSize.height).contains(digit.centerY)
        case "11":
            return (toleranceField...centerX).contains(digit.centerX) && (0...toleranceField*2).contains(digit.centerY)
        case "10":
            return (0...toleranceField*2).contains(digit.centerX) && (toleranceField...centerY).contains(digit.centerY)
        case "8":
            return (0...toleranceField*2).contains(digit.centerX) && (centerY...analyzedResult.clockSize.height-toleranceField).contains(digit.centerY)
        case "7":
            return (toleranceField...centerX).contains(digit.centerX) && (centerY+toleranceField...analyzedResult.clockSize.height).contains(digit.centerY)
        default:
            return false
        }
    }
    
    private func calculateShortestDistanceToOtherDigits(digit: ClassifiedDigit) {
        var distancesArray = [Float]()
        let image = Mat(uiImage: self.analyzedResult.completeImage)
        let centerPoint = Point2i(x: image.width()/2, y: image.height()/2)
        for otherDigit in analyzedResult.classifiedDigits.filter({$0 != digit}) {
            if otherDigit.center.distance(to: centerPoint) > Float(image.width()) / 5 {
                distancesArray.append(digit.center.distance(to: otherDigit.center))
            }
        }
        if let firstMin = distancesArray.min() {
            analyzedResult.allShortestDistancesBetweenDigits.append(firstMin)
            distancesArray.removeAll(where: {$0 == firstMin})
            if let secondMin = distancesArray.min() {
                analyzedResult.allShortestDistancesBetweenDigits.append(secondMin)
            }
        }
        
        
    }
    
    private func makeDecision() -> Int {
        let data = self.analyzedResult
        
        var score = 6
    
        var pointsGathered = 0
        
        let numbersFound = data.numbersFoundAtLeastOnce.count
        let numbersFoundRightSpot = data.numbersFoundInRightSpot.count
        
        
        // GATHER POINTS
        pointsGathered += numbersFound // MAX 12
        pointsGathered += numbersFoundRightSpot // MAX 24
        
        if data.verticalConnectionLinePerfect { // MAX 28
            pointsGathered += 4
        } else if data.verticalConnectionLineOkay {
            pointsGathered += 2
        }
        
        if data.horizontalConnectionLinePerfect { // MAX 32
            pointsGathered += 4
        } else if data.horizontalConnectionLineOkay {
            pointsGathered += 2
        }
        
        if data.digitDistanceVariationCoefficient <= Config.digitDistanceVariationCoefficient { // MAX 37
            pointsGathered += 5
        } else if data.digitDistanceVariationCoefficient <= Config.digitDistanceVariationCoefficient2 {
            pointsGathered += 3
        }
        
        if data.secondsToComplete < Config.maxSecondsForPerfectRating { // MAX 41
            pointsGathered += 4
        } else if data.secondsToComplete < Config.maxSecondsForSemiRating {
            pointsGathered += 2
        }
        
        // TIMES RESTARTED
        if data.timesRestarted <= Config.maxTimesRestartedForPerfectRating { // MAX 45
            pointsGathered += 4
        } else if data.timesRestarted <= Config.maxTimesRestartedForOkayRating {
            pointsGathered += 2
        }
        
        var bestRatingStillPossible = 1
        
        if data.clockhandsRight() { // HARD FORK FOR CLOCKHANDS
            bestRatingStillPossible = 1
        } else if data.clockhandsAlmostRight() {
            bestRatingStillPossible = 2
        } else {
            bestRatingStillPossible = 3
        }
        
        
        
        switch pointsGathered {
            case let x where x >= 41:
            score = 1
            case let x where x >= 30:
            score = 2
            case let x where x >= 26:
            score = 3
            case let x where x >= 22:
            score = 4
            case let x where x >= 18:
            score = 5
            default:
            score = 6
        }
        
        if score < bestRatingStillPossible {
            score = bestRatingStillPossible
        }
        
        
        return score
    }
    
    
}

// MARK: Public image generation
extension ClockAnalyzer {
    
    func getAllRecognizedDigitImage() -> UIImage {
        let completeImageMat = Mat(uiImage: self.analyzedResult.completeImage, alphaExist: true)
        
        for digit in self.analyzedResult.classifiedDigits {
            let pad: Int32 = 5
            let originalRect = digit.originalBoundingBox
            
            let boundRectDraw = Rect2i(x: originalRect.x-pad, y: originalRect.y-pad, width: originalRect.width+pad*2, height: originalRect.height+pad*2)
            // DRAW CONTOUR TO IMAGE
            Imgproc.rectangle(img: completeImageMat, rec: boundRectDraw, color: Scalar(255,0,0,255), thickness: 2)
        }
        return completeImageMat.toUIImage()
    }
    
    func getNumbersWithRightSpotRating() -> UIImage {
        let completeImageMat = Mat(uiImage: self.analyzedResult.completeImage, alphaExist: true)
        
        for digit in self.analyzedResult.classifiedDigits {
            let pad: Int32 = 5
            let originalRect = digit.originalBoundingBox
            
            let boundRectDraw = Rect2i(x: originalRect.x-pad, y: originalRect.y-pad, width: originalRect.width+pad*2, height: originalRect.height+pad*2)
            // DRAW CONTOUR TO IMAGE
            Imgproc.rectangle(img: completeImageMat, rec: boundRectDraw, color: digit.isInRightSpot ? Scalar(0,255,0,255) : Scalar(255,0,0,255), thickness: 2)
        }
        return completeImageMat.toUIImage()
    }
    
    func getHorizontalAndVerticalLineImage() -> UIImage {
        let completeImageMat = Mat(uiImage: self.analyzedResult.completeImage, alphaExist: true)
        if let mostRightNumber = self.analyzedResult.classifiedDigits.max(by: {$0.centerX > $1.centerX}), let mostLeftNumber = self.analyzedResult.classifiedDigits.min(by: {$0.centerX > $1.centerX}) {
            var color = Scalar(255,0,0,255)
            if self.analyzedResult.horizontalConnectionLinePerfect {
                color = Scalar(0,255,0,255)
            } else if self.analyzedResult.horizontalConnectionLineOkay {
                color = Scalar(255,255,0,255)
            }
            Imgproc.line(img: completeImageMat, pt1: mostLeftNumber.center, pt2: mostRightNumber.center, color: color, thickness: 3)
        }
        if let mostTopNumber = self.analyzedResult.classifiedDigits.max(by: {$0.centerY > $1.centerY}), let mostDownNumber = self.analyzedResult.classifiedDigits.min(by: {$0.centerY > $1.centerY}) {
            var color = Scalar(255,0,0,255)
            if self.analyzedResult.verticalConnectionLinePerfect {
                color = Scalar(0,255,0,255)
            } else if self.analyzedResult.verticalConnectionLineOkay {
                color = Scalar(255,255,0,255)
            }
            Imgproc.line(img: completeImageMat, pt1: mostTopNumber.center, pt2: mostDownNumber.center, color: color, thickness: 3)
        }
        return completeImageMat.toUIImage()
    }
    
    func getDigitDistancesImage() -> UIImage {
        
        let std = self.analyzedResult.digitDistancesStd
        let mean = self.analyzedResult.digitDistancesMean
        
        let smallRange = (mean-std...mean+std)
        let bigRange = (mean-2*std...mean+2*std)
        
        let completeImageMat = Mat(uiImage: self.analyzedResult.completeImage, alphaExist: true)
        //let allLinesImage = Mat(uiImage: self.analyzedResult.completeImage, alphaExist: true)

        let centerPoint = Point2i(x: completeImageMat.width()/2, y: completeImageMat.height()/2)

        func draw(from point1: Point2i, to point2: Point2i, distance: Float) {
            let minDistance = Float(completeImageMat.width()) / 5
            if centerPoint.distance(to: point1) > minDistance && centerPoint.distance(to: point2) > minDistance{
                var color = Scalar(255,0,0,255)
                if smallRange.contains(distance) {
                    color = Scalar(0,255,0,255)
                } else if bigRange.contains(distance) {
                    color = Scalar(255,255,0,255)
                }
                Imgproc.line(img: completeImageMat, pt1: point1, pt2: point2, color: color, thickness: 2)
            }

        }
        
        
        for digit in self.analyzedResult.classifiedDigits {
            var otherDigits = analyzedResult.classifiedDigits.filter({$0 != digit})
            /*for otherDigit in otherDigits {
                Imgproc.line(img: allLinesImage, pt1: digit.center, pt2: otherDigit.center, color: Scalar(0,255,0,255), thickness: 2)
            }*/
            if let firstMinDigit = otherDigits.min(by: { digit.center.distance(to: $0.center) < digit.center.distance(to: $1.center)} ) {
                draw(from: digit.center, to: firstMinDigit.center, distance: digit.center.distance(to: firstMinDigit.center))
                otherDigits.removeAll(where: {$0 == firstMinDigit})
                if let secondMinDigit = otherDigits.min(by: { digit.center.distance(to: $0.center) < digit.center.distance(to: $1.center)}) {
                    draw(from: digit.center, to: secondMinDigit.center, distance: digit.center.distance(to: secondMinDigit.center))
                }
            }
        }
        return completeImageMat.toUIImage()
    }
    
    func getRecognizedClockhandsImage() -> UIImage {
        return self.analyzedResult.houghImage
    }
    
}


