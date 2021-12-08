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
    @Published var firstStrokeDate: Date? 
    
    private let MNISTpredictor = MNISTImagePredictor()
    private var dispatchGroup = DispatchGroup()
    
    fileprivate func prepareImage(rawClockImage: UIImage, fatClockImage: UIImage) -> (Mat, Mat) {
        let drawingOnlyMat = Mat(uiImage: rawClockImage, alphaExist: true)
        let drawingOnlyMatFat = Mat(uiImage: fatClockImage, alphaExist: true)
        
        // GET TRANSPARENT PIXELS AND SET THEM TO SOLID WHITE
        let transparentMask = Mat()
        let transparentMask2 = Mat()
        Core.inRange(src: drawingOnlyMat, lowerb: Scalar(0,0,0,0), upperb: Scalar(255,255,255,1), dst: transparentMask)
        drawingOnlyMat.setTo(scalar: Scalar(255,255,255,255), mask: transparentMask)
        
        Core.inRange(src: drawingOnlyMatFat, lowerb: Scalar(0,0,0,0), upperb: Scalar(255,255,255,1), dst: transparentMask2)
        drawingOnlyMatFat.setTo(scalar: Scalar(255,255,255,255), mask: transparentMask2)
        
        return (drawingOnlyMat, drawingOnlyMatFat)
    }
    
    func startAnalysis(clockImage: UIImage, fatClockImage: UIImage, onCompletion: @escaping () -> Void) {
        let (drawingOnlyMat, drawingOnlyMatFat) = prepareImage(rawClockImage: clockImage, fatClockImage: fatClockImage)
        
        self.analyzedResult.completeImage = clockImage
        
        if let firstStrokeDate = firstStrokeDate {
            self.analyzedResult.secondsToComplete = Int(Date().timeIntervalSince1970 - firstStrokeDate.timeIntervalSince1970)
        }
        
        
        // APPLY THRESHOLDING AND CONVERT TO GRAY IMAGE
        Imgproc.cvtColor(src: drawingOnlyMat, dst: drawingOnlyMat, code: ColorConversionCodes.COLOR_RGBA2GRAY) // COLOR_BGR2GRAY
        Imgproc.threshold(src: drawingOnlyMat, dst: drawingOnlyMat, thresh: 0, maxval: 255, type: ThresholdTypes.THRESH_BINARY_INV)
        Imgproc.cvtColor(src: drawingOnlyMatFat, dst: drawingOnlyMatFat, code: ColorConversionCodes.COLOR_RGBA2GRAY) // COLOR_BGR2GRAY
        Imgproc.threshold(src: drawingOnlyMatFat, dst: drawingOnlyMatFat, thresh: 0, maxval: 255, type: ThresholdTypes.THRESH_BINARY_INV)
        self.analyzedResult.clockSize = drawingOnlyMat.size()
        
        // PREPARE DIFFERENT IMAGES FOR CLASSIFICATION TASKS
        let digitClassificationImage = drawingOnlyMat.clone()
        let handsClassificationImage = drawingOnlyMatFat.clone()
        let imageWidth = drawingOnlyMat.width()
        let imageHeight = drawingOnlyMat.height()
        
    
        //Imgproc.circle(img: digitClassificationImage, center: Point2i(x: imageWidth/2, y: imageHeight/2), radius: Int32(Double((imageHeight/2))*0.7), color: Scalar(0,0,0), thickness: LineTypes.FILLED.rawValue)
        Imgproc.circle(img: handsClassificationImage, center: Point2i(x: imageWidth/2, y: imageHeight/2), radius: imageHeight/2, color: Scalar(0,0,0), thickness: Int32(Double(imageHeight / 2) * 0.8))
       
        //UIImageWriteToSavedPhotosAlbum(digitClassificationImage.toUIImage(), nil, nil, nil)
        //UIImageWriteToSavedPhotosAlbum(handsClassificationImage.toUIImage(), nil, nil, nil)
        
        self.classifyDigits(clockImage: digitClassificationImage)
        self.handDetection(clockImage: handsClassificationImage)
        
        dispatchGroup.notify(queue: .main) {
            for digit in self.analyzedResult.classifiedDigits {
                //let _ = self.determineIfDigitPositionIsCorrect(digit: digit)
                self.checkForDoubleDigit(digit, wholeMat: digitClassificationImage)
            }
            for count in self.analyzedResult.classifiedDigits.indices {
                //let _ = self.determineIfDigitPositionIsCorrect(digit: digit)
                self.analyzedResult.classifiedDigits[count].isInRightSpot = self.determineIfDigitPositionIsCorrect(digit: self.analyzedResult.classifiedDigits[count])
                self.calculateShortestDistanceToOtherDigits(digit: self.analyzedResult.classifiedDigits[count])
            }
            self.analyzedResult.score = self.makeDecision()
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
        analyzedResult.houghLines = lines
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
        
        
        // GET 3 CHARACTERISTIC POINTS
        let mostRightPoint = points.max(by: { $0.x < $1.x}) ?? Point2i()
        let mostDownPoint = points.min(by: { $0.y > $1.y}) ?? Point2i()
        let mostLeftPoint = points.min(by: { $0.x < $1.x}) ?? Point2i()
        
        self.analyzedResult.hourHandAngle = mostDownPoint.angleTo(mostLeftPoint)
        self.analyzedResult.minuteHandAngle = mostDownPoint.angleTo(mostRightPoint)
        
        
        
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
        if classifiedDigit.topPrediction.classification == "7" && (centerX...analyzedResult.clockSize.width-toleranceField).contains(classifiedDigit.centerX) && (0...toleranceField*2).contains(classifiedDigit.centerY) {
            appendDigit = ClassifiedDigit(digitImage: classifiedDigit.digitImage, predictions: [Prediction(classification: "1", confidencePercentage: 1)], centerX: classifiedDigit.centerX, centerY: classifiedDigit.centerY, originalBoundingBox: classifiedDigit.originalBoundingBox, isInRightSpot: false)
            self.analyzedResult.classifiedDigits.removeAll(where: {$0 == classifiedDigit})
            print("Fixed a seven")
        }
        if classifiedDigit.topPrediction.classification == "9" && (centerX+toleranceField...analyzedResult.clockSize.width).contains(classifiedDigit.centerX) && (centerY...analyzedResult.clockSize.height-toleranceField).contains(classifiedDigit.centerY) {
            appendDigit = ClassifiedDigit(digitImage: classifiedDigit.digitImage, predictions: [Prediction(classification: "4", confidencePercentage: 1)], centerX: classifiedDigit.centerX, centerY: classifiedDigit.centerY, originalBoundingBox: classifiedDigit.originalBoundingBox, isInRightSpot: false)
            self.analyzedResult.classifiedDigits.removeAll(where: {$0 == classifiedDigit})
            print("Fixed a seven")
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
                    
                    let newDigitString = (digit1.topPrediction.classification.replacingOccurrences(of: "4", with: "1") + digit2.topPrediction.classification).replacingOccurrences(of: "7", with: "1") // ERROR CORRET SINCE ONLY NUMBERS UP TO 12 ARE NEEDED
                    
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
        for otherDigit in analyzedResult.classifiedDigits.filter({$0 != digit}) {
            distancesArray.append(digit.center.distance(to: otherDigit.center))
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
        
        
        var decreaseScoreByAndCriteria: Float {
            var decreaseScoreBy: Float = 0.0
            if data.verticalConnectionLinePerfect && data.horizontalConnectionLinePerfect {
                decreaseScoreBy += 1
            } else if data.verticalConnectionLineOkay && data.horizontalConnectionLineOkay {
                decreaseScoreBy += 0.5
            }
            
            // DIGIT DISTANCE SYMMETRIE
            if data.digitDistanceVariationCoefficient <= Config.digitDistanceVariationCoefficient {
                decreaseScoreBy += 1
            } else if data.digitDistanceVariationCoefficient <= Config.digitDistanceVariationCoefficient2 {
                decreaseScoreBy += 0.5
            }
            
            // TIME TO DRAW
            if data.secondsToComplete < Config.maxSecondsForPerfectRating {
                decreaseScoreBy += 1
            } else if data.secondsToComplete < Config.maxSecondsForSemiRating {
                decreaseScoreBy += 0.5
            }
            
            // TIMES RESTARTED
            if data.timesRestarted <= Config.maxTimesRestartedForPerfectRating {
                decreaseScoreBy += 1
            } else if data.timesRestarted <= Config.maxTimesRestartedForOkayRating {
                decreaseScoreBy += 0.5
            }
            return decreaseScoreBy
        }
        
        // GATHER POINTS
        pointsGathered += numbersFound // MAX 12
        pointsGathered += numbersFoundRightSpot // MAX 24
        
        if data.verticalConnectionLinePerfect { // MAX 29
            pointsGathered += 5
        } else if data.verticalConnectionLineOkay {
            pointsGathered += 3
        }
        
        if data.horizontalConnectionLinePerfect { // MAX 34
            pointsGathered += 5
        } else if data.horizontalConnectionLineOkay {
            pointsGathered += 3
        }
        
        if data.digitDistanceVariationCoefficient <= Config.digitDistanceVariationCoefficient { // MAX 42
            pointsGathered += 8
        } else if data.digitDistanceVariationCoefficient <= Config.digitDistanceVariationCoefficient2 {
            pointsGathered += 4
        }
        
        if data.secondsToComplete < Config.maxSecondsForPerfectRating { // MAX 47
            pointsGathered += 5
        } else if data.secondsToComplete < Config.maxSecondsForSemiRating {
            pointsGathered += 3
        }
        
        // TIMES RESTARTED
        if data.timesRestarted <= Config.maxTimesRestartedForPerfectRating { // MAX 52
            pointsGathered += 5
        } else if data.timesRestarted <= Config.maxTimesRestartedForOkayRating {
            pointsGathered += 3
        }
        
        var bestRatingStillPossible = 1
        
        if data.clockhandsRight { // HARD FORK FOR CLOCKHANDS
            bestRatingStillPossible = 1
        } else if data.clockhandsAlmostRight {
            bestRatingStillPossible = 2
        } else {
            bestRatingStillPossible = 3
        }
        
        
        
        switch pointsGathered {
            case let x where x >= 48:
            score = 1
            case let x where x >= 42:
            score = 2
            case let x where x >= 34:
            score = 3
            case let x where x >= 26:
            score = 4
            case let x where x >= 18:
            score = 5
            default:
            score = 6
        }
        
        if score < bestRatingStillPossible {
            score = bestRatingStillPossible
        }
        
        
        /*
        // HARD FORK FOR CLOCKHANDS
        if data.clockhandsRight {
            if numbersFound <= Config.minNumbersFoundForPerfectRating && numbersFoundRightSpot <= Config.minNumbersInRightPositionForPerfectRating {
                bestRatingStillPossible = 2
            } else if (decreaseScoreByAndCriteria >= 3.5) { // ONLY WAY TO GET A PERFECT SCORE
                score = 1
                return score
            }
        } else if data.clockhandsAlmostRight {
            bestRatingStillPossible = 2
            if (numbersFound <= Config.minNumbersFoundForPerfectRating && numbersFoundRightSpot <= Config.minNumbersInRightPositionForOkayRating) || (numbersFound <= Config.minNumbersFoundForOkayRating && numbersFoundRightSpot <= Config.minNumbersInRightPositionForPerfectRating) {
                bestRatingStillPossible = 3
            }
        } else {
            bestRatingStillPossible = 3
            if numbersFound <= 3 { // NO CLOCK AT ALL
                bestRatingStillPossible = 6
            } else if numbersFound <= 4 && numbersFoundRightSpot <= 2 { // COULD STILL HAVE AT LEAST SOME ELEMENTS OF A CLOCK
                bestRatingStillPossible = 5
            } else if numbersFound <= Config.minNumbersFoundForOkayRating && numbersFoundRightSpot <= Config.minNumbersInRightPositionForOkayRating {
                bestRatingStillPossible = 4
            }
        }
        score = score - Int(decreaseScoreByAndCriteria.rounded(.up))
        if score < bestRatingStillPossible {
            score = bestRatingStillPossible
        }
        
        if data.clockhandsRight {
            if numbersFound >= Config.minNumbersFoundForPerfectRating && numbersFoundRightSpot >= Config.minNumbersInRightPositionForPerfectRating {
                if onlyOnePerfectCriteriaWrong {
                    score = 1
                } else if onlyTwoPerfectCriteriaWrong && noOkayCriteriaWrong {
                    score = 2
                } else {
                    
                    // CONTINUE WITH WORSE
                }
            } else {
                
                // CONTINUE WITH WORSE
            }
        } else if data.clockhandsAlmostRight {
            // MARK: 2 or worse
            score = 2
        } else {
            // MARK: 3 or worse
            score = 3
        }*/
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
        
        func draw(from point1: Point2i, to point2: Point2i, distance: Float) {
            var color = Scalar(255,0,0,255)
            if smallRange.contains(distance) {
                color = Scalar(0,255,0,255)
            } else if bigRange.contains(distance) {
                color = Scalar(255,255,0,255)
            }
            Imgproc.line(img: completeImageMat, pt1: point1, pt2: point2, color: color, thickness: 2)
        }
        
        
        for digit in self.analyzedResult.classifiedDigits {
            var otherDigits = analyzedResult.classifiedDigits.filter({$0 != digit})
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
        let completeImageMat = Mat(uiImage: self.analyzedResult.completeImage, alphaExist: true)
        var color = Scalar(255,0,0,255)
        
        if analyzedResult.clockhandsRight {
            color = Scalar(0,255,0,255)
        } else if analyzedResult.clockhandsAlmostRight {
            color = Scalar(255,255,0,255)
        }
        
        for i in 0..<analyzedResult.houghLines.rows() {
            let data = analyzedResult.houghLines.get(row: i, col: 0)
            
            let startPoint = Point2i(x: Int32(data[0]), y: Int32(data[1]))
            let endPoint = Point2i(x: Int32(data[2]), y: Int32(data[3]))
            
            // DRAW LINES DEBUG VISUALIZATION
            Imgproc.line(img: completeImageMat, pt1: startPoint, pt2: endPoint, color: color, thickness: 10)
        }
        
        return completeImageMat.toUIImage()
    }
    
}
