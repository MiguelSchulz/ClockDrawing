//
//  AnalyzeAllSavedClockView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 30.12.21.
//

import SwiftUI
import RealmSwift
import PDFKit

struct AnalyzeAllSavedClockView: View {
    
    @State var showModal = false
    @State var modal = ShowModal.first

    let semaphore = DispatchSemaphore(value: 5)

    @State public var sharedItems : [Any] = []
    @State var clocks: [SavedClock: AnalyzedClockResult?]
    //@State var clocks: [(savedClock: SavedClock, result: AnalyzedClockResult?)]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(clocks.keys)) { clock in
                    if let result = clocks[clock], let result = result {
                        VStack(spacing: 0) {
                            HStack {
                                CircleDrawingImageOverlay(image: clock.thumbnail).frame(minHeight: 100, maxHeight: 225)
                                CircleScoreView(color: .label, score: result.score).frame(minHeight: 100, maxHeight: 225)

                            }
                            detailedAnalysis(result: result).frame(minWidth: 0, maxWidth: .infinity)

                        }.padding().background(Color(.systemGroupedBackground).cornerRadius(10)).padding()
                        //.frame(height: 225)

                        .onChange(of: clock.analyzedResult) { _ in

                        }
                    }
                }
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportPDF()
                    } label: {
                        Text("Export")
                    }
                }
            }.onChange(of: self.showModal) { _ in
                
            }
            .onAppear {
                for clock in Array(clocks.keys) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        if !clock.drawing.strokes.isEmpty {
                            semaphore.wait()
                            let analyzer = ClockAnalyzer()
                            analyzer.startAnalysis(clockImage: generateClockImage(clock: clock), fatClockImage: generateFatClockImage(clock: clock)) {
                                DispatchQueue.main.async {
                                    semaphore.signal()
                                    clocks[clock] = analyzer.analyzedResult
                                }
                            }
                        } 
                    }
                }
            }
            
        }.navigationBarTitle("Summary", displayMode: .automatic)
            .sheet(isPresented: self.$showModal) {
                ShareSheet(activityItems: sharedItems)
            }
    }
    
    func detailedAnalysis(result: AnalyzedClockResult) -> some View  {
        return Group {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Digits:").font(.headline).padding(.bottom, 5)
                    numbersOverallFound(result: result)
                    numbersRightPositionFound(result: result)
        
                    Text("Clockhands:").font(.headline).padding(.vertical, 10)
                    if Config.useMLforClockhands {
                        clockhandsRightML(result: result)
                    } else {
                        clockhandsRight(result: result)
                    }
                }
                Spacer()
                if let horizontalAngle = result.horizontalConnectionLineAngle, let verticalAngle = result.verticalConnectionLineAngle {
                    VStack {
                        ZStack {
                            Circle().stroke(Color.black, lineWidth: 1)
                            Color.red.frame(height: 3).rotationEffect(.degrees(Double(verticalAngle)))
                        }.frame(width: 50, height: 50)
                        ZStack {
                            Circle().stroke(Color.black, lineWidth: 1)
                            Color.red.frame(width: 3).rotationEffect(.degrees(Double(horizontalAngle)))
                        }.frame(width: 50, height: 50)
                    }
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 5)  {
                    Text("Symmetrie:").font(.headline).padding(.vertical, 10)
                        
                    Button {
                        modal = .third
                        self.showModal = true
                    } label: {
                        VStack(alignment: .leading) {
                            horizontalAngleCorrect(result: result)
                            verticalAngleCorrect(result: result)
                        }
                    }.buttonStyle(PlainButtonStyle())
                    digitDistances(result: result)
                }
            }
            .padding()
            .background(Color( .systemGroupedBackground).cornerRadius(10))
            .addBorder(Color(.label), width: 0.5, cornerRadius: 10)
        }
    }
    
    func generateClockImage(clock: SavedClock) -> UIImage {
        return clock.drawing.image(from: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: CGFloat(clock.width), height: CGFloat(clock.height))), scale: 1)

    }
    
    func generateFatClockImage(clock: SavedClock) -> UIImage {
        return clock.drawing.changeLineWidth(by: CGFloat(Config.changeLineWidthOfDrawingBy)).image(from: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: CGFloat(clock.width), height: CGFloat(clock.height))), scale: 1)
    }
    
    func numbersOverallFound(result: AnalyzedClockResult) -> some View {
        let foundNumbers = result.numbersFoundAtLeastOnce.count
        var criteria = CriteriaRating.right
        switch foundNumbers {
            case let x where x >= Config.minNumbersFoundForPerfectRating:
            criteria = .right
            case let x where x >= Config.minNumbersFoundForOkayRating:
            criteria = .unsure
            default:
            criteria = .wrong
        }
        /*return NavigationLink(destination: NavigationLazyView(Text("Todo"))) {
            CriteriaListItemView(criteriaRating: criteria, explanation: "\(foundNumbers) out of 12 digits were recognized at least once")
        }.buttonStyle(PlainButtonStyle())*/
        return Button {
            modal = .first
            self.showModal = true
        } label: {
            CriteriaListItemView(criteriaRating: criteria, explanation: "\(foundNumbers) / 12 digits recognized once")
        }.buttonStyle(PlainButtonStyle())
    }
    
    func numbersRightPositionFound(result: AnalyzedClockResult) -> some View {
        let foundNumbers = result.numbersFoundAtLeastOnce.count
        let foundNumbersRightPosition = result.numbersFoundInRightSpot.count
        var criteria = CriteriaRating.right
        switch foundNumbersRightPosition {
            case let x where x >= Config.minNumbersInRightPositionForPerfectRating:
            criteria = .right
            case let x where x >= Config.minNumbersInRightPositionForOkayRating:
            criteria = .unsure
            default:
            criteria = .wrong
        }
        return Button {
            modal = .second
            self.showModal = true
        } label: {
            CriteriaListItemView(criteriaRating: criteria, explanation: "\(foundNumbersRightPosition) / \(foundNumbers) digits in the right place")
        }.buttonStyle(PlainButtonStyle())
    }
    
    func verticalAngleCorrect(result: AnalyzedClockResult) -> some View {
        var criteria = CriteriaRating.wrong
        if result.verticalConnectionLinePerfect {
            criteria = .right
        } else if result.verticalConnectionLineOkay {
            criteria = .unsure
        }
        return Group {
            if let angleVertical = result.verticalConnectionLineAngle {
                
                CriteriaListItemView(criteriaRating: criteria, explanation: "0 to 30 line: \(String(format: "%.1f", angleVertical))°")
                    
            } else {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "No vertical symmetrie lines")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    func horizontalAngleCorrect(result: AnalyzedClockResult) -> some View {
        var criteria = CriteriaRating.wrong
        if result.horizontalConnectionLinePerfect {
            criteria = .right
        } else if result.horizontalConnectionLineOkay {
            criteria = .unsure
        }
        return Group {
            if let angleHorizontal = result.horizontalConnectionLineAngle {
                
                CriteriaListItemView(criteriaRating: criteria, explanation: "15 to 45 line: \(String(format: "%.1f", angleHorizontal))°")
                
            } else {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "No horizontal symmetrie lines")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    func digitDistances(result: AnalyzedClockResult) -> some View {
        let variationCoefficient = result.digitDistanceVariationCoefficient
        var criteria = CriteriaRating.wrong
        if variationCoefficient <= Config.digitDistanceVariationCoefficient {
            criteria = .right
        } else if variationCoefficient <= Config.digitDistanceVariationCoefficient2 {
            criteria = .unsure
        }
        
        return Button {
            modal = .fourth
            self.showModal = true
        } label: {
            CriteriaListItemView(criteriaRating: criteria, explanation: "Neighbor digit coefficient of variation: \(String(format: "%.1f", variationCoefficient*100))%")
            
        }.buttonStyle(PlainButtonStyle())
    }
    
    func clockhandsRightML(result: AnalyzedClockResult) -> some View {
        Button {
            self.modal = .seventh
            self.showModal = true
        } label: {
            if result.clockhandsRight() {
                CriteriaListItemView(criteriaRating: .right, explanation: "Clock hands correct: \(String(format: "%02d", result.hour)):\(String(format: "%02d", result.minute))")
            } else if result.clockhandsAlmostRight() {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "Clock hands almost correct: \(String(format: "%02d", result.hour)):\(String(format: "%02d", result.minute))")
            } else {
                CriteriaListItemView(criteriaRating: .wrong, explanation: "The clock hands do not show the time correctly: \(String(format: "%02d", result.hour)):\(String(format: "%02d", result.minute))")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    func clockhandsRight(result: AnalyzedClockResult) -> some View {
        Button {
            self.modal = .fifth
            self.showModal = true
        } label: {
            if result.clockhandsRight() {
                CriteriaListItemView(criteriaRating: .right, explanation: "Clock hands correct")
            } else if result.clockhandsAlmostRight() {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "Clock hands almost correct")
            } else {
                CriteriaListItemView(criteriaRating: .wrong, explanation: "Clock hands wrong")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    func timesRestartedDetail(result: AnalyzedClockResult) -> some View {
        Button {
            
        } label: {
            if result.timesRestarted == 0 {
                CriteriaListItemView(criteriaRating: .right, explanation: "Drawn in first attempt")
            } else if result.timesRestarted == 1 {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "Drawn in second attempt")
            } else {
                CriteriaListItemView(criteriaRating: .wrong, explanation: "Attempt \(result.timesRestarted+1)")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    func secondsForDrawing(result: AnalyzedClockResult) -> some View {
        let (minutes, seconds) = result.secondsToComplete.secondsToMinutesSeconds()
        
        var criteria = CriteriaRating.right
        switch result.secondsToComplete {
            case let x where x <= Config.maxSecondsForPerfectRating:
            criteria = .right
            case let x where x <= Config.maxSecondsForSemiRating:
            criteria = .unsure
            default:
            criteria = .wrong
        }
        
        return Button {
            
        } label: {
            CriteriaListItemView(criteriaRating: criteria, explanation: "Finished in \(minutes)m \(seconds)s")

        }.buttonStyle(PlainButtonStyle())
    }
    
    func exportPDF() {
        let shareDocument = PDFDocument()
        
        let outgroup = DispatchGroup()
        
        for i in 0..<(Int(ceil(Double(clocks.count)/3))) {
            outgroup.enter()
            let lowestIndex = i * 3
            let higherIndex = lowestIndex + 2
            let result = Array(clocks.keys).enumerated().compactMap { test in
                (lowestIndex...higherIndex).contains(test.offset) ? test.element : nil
            }
            var clocks: [SavedClock: AnalyzedClockResult] = [:]
            for clock in result {
                let clockAnalyzer = ClockAnalyzer()
                clockAnalyzer.startAnalysis(clockImage: generateClockImage(clock: clock), fatClockImage: generateFatClockImage(clock: clock)) {
                    clocks[clock] = clockAnalyzer.analyzedResult
                    if clock == result.last {
                        let screen = getScreenshot(result: result, clocks: clocks).snapshot()
                        if let imagePage = PDFPage(image: screen) {
                            shareDocument.insert(imagePage, at: i)
                            outgroup.leave()
                        }
                    }
                    
                }
            }
            
        }
        
        outgroup.notify(queue: DispatchQueue.main) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .medium
            
            do
            {
                let filename = "\(dateFormatter.string(from: Date())).pdf"
                let tmpDirectory = FileManager.default.temporaryDirectory
                let fileURL = tmpDirectory.appendingPathComponent(filename)
                try shareDocument.dataRepresentation()?.write(to: fileURL)
                sharedItems = [fileURL]
            }
            catch
            {
                print ("Cannot write PDF: \(error)")
            }
            showModal = true
        }
    }
    
    func getScreenshot(result: [SavedClock], clocks: [SavedClock: AnalyzedClockResult?]) -> some View {
        
        
        return VStack(spacing: 0) {
            ForEach(result) { clock in
                if let result = clocks[clock], let result = result {
                    VStack(spacing: 0) {
                        HStack {
                            CircleDrawingImageOverlay(image: clock.thumbnail).frame(minHeight: 100, maxHeight: 225)
                            
                            CircleScoreView(color: .label, score: result.score).frame(minHeight: 100, maxHeight: 225)
                            
                        }
                        detailedAnalysis(result: result).frame(minWidth: 0, maxWidth: .infinity)
                        
                        
                    }.padding().background(Color(.systemGroupedBackground).cornerRadius(10)).padding()
                }
                
            }
            Spacer(minLength: 0)
        }.frame(width: 210*5, height: 297*5)
            
    }
    
}
