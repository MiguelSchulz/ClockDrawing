//
//  ResultView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 13.11.21.
//

import SwiftUI
import PDFKit

enum ShowModal {
    case first
    case second
    case third
    case fourth
    case fifth
    case sixth
    case seventh
}

struct ResultView: View {
    
    @Binding var shouldPopToRootView: Bool
    @ObservedObject var clockAnalyzer: ClockAnalyzer
    
    @State var showModal = false
    @State var modal = ShowModal.first
    
    @State public var sharedItems : [Any] = []
    
    func exportPDF() {
        let shareDocument = PDFDocument()
        if let imagePage = PDFPage(image: screenshotBody.snapshot()) {
            shareDocument.insert(imagePage, at: 0)
        }
            
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
        
        self.modal = .sixth
        showModal = true
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    CircleDrawingImageOverlay(image: self.clockAnalyzer.analyzedResult.completeImage).frame(maxHeight: 500)
                    
                    Text("Result:").font(.title).fontWeight(.semibold)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        HStack {
                            CircleScoreView(score: self.clockAnalyzer.analyzedResult.score).frame(width: 250, height: 250)
                            Spacer()
                            detailedAnalysis
                        }.whiteRoundedBackground()
                    } else {
                        VStack {
                            CircleScoreView(score: self.clockAnalyzer.analyzedResult.score).frame(width: 250, height: 250)
                            detailedAnalysis
                        }.whiteRoundedBackground()
                    }
                }.padding()
                HStack {
                    Button {
                        self.shouldPopToRootView = false
                    } label: {
                        Text("Restart Test").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
                    }.buttonStyle(PlainButtonStyle()).padding()
                    Button {
                        self.exportPDF()
                    } label: {
                        Text("Export PDF").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.blue.cornerRadius(20))
                    }.buttonStyle(PlainButtonStyle()).padding()
                }
            }
        }.navigationBarHidden(true).sheet(isPresented: self.$showModal) {
            NavigationView {
                Group {
                    switch modal {
                    case .first: NumbersFoundAnalysisView(clockAnalyzer: self.clockAnalyzer)
                    case .second: NumbersAtRightPlaceView(clockAnalyzer: self.clockAnalyzer)
                    case .third: HorizontalAndVerticalSymmetrieDigitView(clockAnalyzer: self.clockAnalyzer)
                    case .fourth: NeighborDigitsAnalysisView(clockAnalyzer: self.clockAnalyzer)
                    case .fifth: ClockhandsAnalysisView(clockAnalyzer: self.clockAnalyzer)
                    case .sixth: ShareSheet(activityItems: sharedItems)
                    case .seventh: Text("TODO")
                    default:
                        Text("")
                    }
                }.toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showModal = false
                        } label: {
                            Text("Close")
                        }
                    }
                }
                .navigationBarTitle("", displayMode: .inline)
            }.navigationViewStyle(StackNavigationViewStyle())
            
            
        }
        .onChange(of: showModal, perform: {_ in})
        .onChange(of: modal, perform: {_ in})
        
    }
    
    var screenshotBody: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 5) {
                    CircleDrawingImageOverlay(image: self.clockAnalyzer.analyzedResult.completeImage).padding(.horizontal, 50)
                    
                    Text("Result:").font(.title).fontWeight(.semibold)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        HStack {
                            CircleScoreView(score: self.clockAnalyzer.analyzedResult.score).frame(width: 250, height: 250)
                            Spacer()
                            detailedAnalysis
                        }.whiteRoundedBackground()
                    } else {
                        VStack {
                            CircleScoreView(score: self.clockAnalyzer.analyzedResult.score).frame(width: 250, height: 250)
                            detailedAnalysis
                        }.whiteRoundedBackground()
                    }
                    Spacer().frame(height: 20)
                }.padding()
        }.frame(width: 210*5, height: 297*5)
    }
    
    var detailedAnalysis: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Digits:").font(.headline).padding(.bottom, 10)
                numbersOverallFound
                Divider()
                numbersRightPositionFound
                
            }
            VStack(alignment: .leading) {
                Text("Symmetrie:").font(.headline).padding(.vertical, 10)
                Button {
                    modal = .third
                    self.showModal = true
                } label: {
                    VStack(alignment: .leading) {
                        horizontalAngleCorrect
                        Divider()
                        verticalAngleCorrect
                    }
                }.buttonStyle(PlainButtonStyle())
                Divider()
                digitDistances
            }
            VStack(alignment: .leading) {
                Text("Clockhands:").font(.headline).padding(.vertical, 10)
                if Config.useMLforClockhands {
                    clockhandsRightML
                } else {
                    clockhandsRight
                }
            }
            VStack(alignment: .leading) {
                Text("Additional:").font(.headline).padding(.vertical, 10)
                timesRestartedDetail
                Divider()
                secondsForDrawing
            }
            
        }
        .padding()
        .background(Color( .systemGroupedBackground).cornerRadius(10))
        .addBorder(Color(.label), width: 0.5, cornerRadius: 10)
    }
    
    var numbersOverallFound: some View {
        let foundNumbers = self.clockAnalyzer.analyzedResult.numbersFoundAtLeastOnce.count
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
            CriteriaListItemView(criteriaRating: criteria, explanation: "\(foundNumbers) out of 12 digits were recognized at least once")
        }.buttonStyle(PlainButtonStyle())
    }
    
    var numbersRightPositionFound: some View {
        let foundNumbers = self.clockAnalyzer.analyzedResult.numbersFoundAtLeastOnce.count
        let foundNumbersRightPosition = self.clockAnalyzer.analyzedResult.numbersFoundInRightSpot.count
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
            CriteriaListItemView(criteriaRating: criteria, explanation: "\(foundNumbersRightPosition) out of these \(foundNumbers) digits are in the right place")
        }.buttonStyle(PlainButtonStyle())
    }
    
    var verticalAngleCorrect: some View {
        var criteria = CriteriaRating.wrong
        if self.clockAnalyzer.analyzedResult.verticalConnectionLinePerfect {
            criteria = .right
        } else if self.clockAnalyzer.analyzedResult.verticalConnectionLineOkay {
            criteria = .unsure
        }
        return Group {
            if let angleVertical = self.clockAnalyzer.analyzedResult.verticalConnectionLineAngle {
                HStack {
                    CriteriaListItemView(criteriaRating: criteria, explanation: "The connection line between the numbers on the 0 and 30 minute marks has an angle of \(String(format: "%.1f", angleVertical))° in comparison to a perfectly straight line")
                    Spacer()
                    ZStack {
                        Circle().stroke(Color.black, lineWidth: 1)
                        Color.red.frame(width: 3).rotationEffect(.degrees(Double(angleVertical)))
                    }.frame(width: 50, height: 50)
                }
            } else {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "No numbers were found that could be used to determine the vertical symmetry of the clock")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    var horizontalAngleCorrect: some View {
        var criteria = CriteriaRating.wrong
        if self.clockAnalyzer.analyzedResult.horizontalConnectionLinePerfect {
            criteria = .right
        } else if self.clockAnalyzer.analyzedResult.horizontalConnectionLineOkay {
            criteria = .unsure
        }
        return Group {
            if let angleHorizontal = self.clockAnalyzer.analyzedResult.horizontalConnectionLineAngle {
                HStack {
                    CriteriaListItemView(criteriaRating: criteria, explanation: "The connection line between the numbers on the 15 and 45 minute marks has an angle of \(String(format: "%.1f", angleHorizontal))° in comparison to a perfectly straight line")
                    Spacer()
                    ZStack {
                        Circle().stroke(Color.black, lineWidth: 1)
                        Color.red.frame(height: 3).rotationEffect(.degrees(Double(angleHorizontal)))
                    }.frame(width: 50, height: 50)
                }
            } else {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "No numbers were found that could be used to determine the horizontal symmetry of the clock")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    var digitDistances: some View {
        let variationCoefficient = self.clockAnalyzer.analyzedResult.digitDistanceVariationCoefficient
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
            CriteriaListItemView(criteriaRating: criteria, explanation: "When comparing the distance between neighboring digits, the coefficient of variation is \(String(format: "%.1f", variationCoefficient*100))% (lower is better)")
            
        }.buttonStyle(PlainButtonStyle())
    }
    
    var clockhandsRightML: some View {
        Button {
            self.modal = .seventh
            self.showModal = true
        } label: {
            if self.clockAnalyzer.analyzedResult.clockhandsRight {
                CriteriaListItemView(criteriaRating: .right, explanation: "The clock hands show the time correctly: \(String(format: "%02d", self.clockAnalyzer.analyzedResult.hour)):\(String(format: "%02d", self.clockAnalyzer.analyzedResult.minute))")
            } else if self.clockAnalyzer.analyzedResult.clockhandsAlmostRight {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "The clock hands could show the time correctly, but are not in exactly the right position: \(String(format: "%02d", self.clockAnalyzer.analyzedResult.hour)):\(String(format: "%02d", self.clockAnalyzer.analyzedResult.minute))")
            } else {
                CriteriaListItemView(criteriaRating: .wrong, explanation: "The clock hands do not show the time correctly: \(String(format: "%02d", self.clockAnalyzer.analyzedResult.hour)):\(String(format: "%02d", self.clockAnalyzer.analyzedResult.minute))")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    var clockhandsRight: some View {
        Button {
            self.modal = .fifth
            self.showModal = true
        } label: {
            if self.clockAnalyzer.analyzedResult.clockhandsRight {
                CriteriaListItemView(criteriaRating: .right, explanation: "The clock hands show the time '10 past 11' correctly")
            } else if self.clockAnalyzer.analyzedResult.clockhandsAlmostRight {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "The clock hands could show the time '10 past 11' correctly, but are not in exactly the right position")
            } else {
                CriteriaListItemView(criteriaRating: .wrong, explanation: "The clock hands do not show the time '10 past 11' correctly")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    var timesRestartedDetail: some View {
        Button {
            
        } label: {
            if self.clockAnalyzer.analyzedResult.timesRestarted == 0 {
                CriteriaListItemView(criteriaRating: .right, explanation: "The clock was deleted 0 times and drawn in the first attempt")
            } else if self.clockAnalyzer.analyzedResult.timesRestarted == 1 {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "The clock was deleted 1 time and drawn in the second attempt")
            } else {
                CriteriaListItemView(criteriaRating: .wrong, explanation: "The clock was deleted \(self.clockAnalyzer.analyzedResult.timesRestarted) times")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    var secondsForDrawing: some View {
        let (minutes, seconds) = self.clockAnalyzer.analyzedResult.secondsToComplete.secondsToMinutesSeconds()
        
        var criteria = CriteriaRating.right
        switch self.clockAnalyzer.analyzedResult.secondsToComplete {
            case let x where x <= Config.maxSecondsForPerfectRating:
            criteria = .right
            case let x where x <= Config.maxSecondsForSemiRating:
            criteria = .unsure
            default:
            criteria = .wrong
        }
        
        return Button {
            
        } label: {
            CriteriaListItemView(criteriaRating: criteria, explanation: "It took \(minutes) minutes and \(seconds) seconds from the first stroke to finish the clock")

        }.buttonStyle(PlainButtonStyle())
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        let clockAnalyzer = ClockAnalyzer()
        clockAnalyzer.analyzedResult = AnalyzedClockResult.example
        return Group {
            ResultView(shouldPopToRootView: .constant(false), clockAnalyzer: clockAnalyzer)
                .previewDevice("iPad Pro (11-inch) (3rd generation)")
            //ResultView(shouldPopToRootView: .constant(false), clockAnalyzer: clockAnalyzer)
               // .previewDevice("iPhone 12 Pro")
        }
    }
}
