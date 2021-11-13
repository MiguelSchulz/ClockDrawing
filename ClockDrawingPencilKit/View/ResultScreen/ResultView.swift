//
//  ResultView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 13.11.21.
//

import SwiftUI

struct ResultView: View {
    
    @Binding var shouldPopToRootView: Bool
    @ObservedObject var clockAnalyzer: ClockAnalyzer
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ZStack {
                        Circle().stroke(Color.black, lineWidth: 3).padding(10)
                        Image(uiImage: self.clockAnalyzer.analyzedResult.completeImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(10)
                            .frame(maxHeight: 500)
                    }
                    Text("Result:").font(.title).fontWeight(.semibold)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        HStack {
                            CircleScoreView(score: 1).frame(width: 250, height: 250)
                            Spacer()
                            detailedAnalysis
                        }.whiteRoundedBackground()
                    } else {
                        VStack {
                            CircleScoreView(score: 1).frame(width: 250, height: 250)
                            detailedAnalysis
                        }.whiteRoundedBackground()
                    }
                }.padding()
                Button {
                    self.shouldPopToRootView = false
                } label: {
                    Text("Restart Test").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
                }.buttonStyle(PlainButtonStyle()).padding()
            }
        }.navigationBarHidden(true)
        
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
                horizontalAngleCorrect
                Divider()
                verticalAngleCorrect
            }
            VStack(alignment: .leading) {
                Text("Clockhands:").font(.headline).padding(.vertical, 10)
                clockhandsRight
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
            case let x where x >= 10:
            criteria = .right
            case let x where x >= 6:
            criteria = .unsure
            default:
            criteria = .wrong
        }
        return NavigationLink(destination: NavigationLazyView(Text("Todo"))) {
            CriteriaListItemView(criteriaRating: criteria, explanation: "\(foundNumbers) out of 12 digits were recognized at least once")
        }.buttonStyle(PlainButtonStyle())
    }
    
    var numbersRightPositionFound: some View {
        let foundNumbers = self.clockAnalyzer.analyzedResult.numbersFoundAtLeastOnce.count
        let foundNumbersRightPosition = self.clockAnalyzer.analyzedResult.numbersFoundInRightSpot.count
        var criteria = CriteriaRating.right
        switch foundNumbersRightPosition {
            case let x where x >= 10:
            criteria = .right
            case let x where x >= 6:
            criteria = .unsure
            default:
            criteria = .wrong
        }
        return NavigationLink(destination: NavigationLazyView(Text("Todo"))) {
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
        return NavigationLink(destination: NavigationLazyView(Text("Todo"))) {
            if let angleVertical = self.clockAnalyzer.analyzedResult.verticalConnectionLineAngle {
                CriteriaListItemView(criteriaRating: criteria, explanation: "The connection line between the numbers on the 0 and 30 minute marks has an angle of \(String(format: "%.1f", angleVertical))° in comparison to a perfectly straight line")
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
        return NavigationLink(destination: NavigationLazyView(Text("Todo"))) {
            if let angleHorizontal = self.clockAnalyzer.analyzedResult.horizontalConnectionLineAngle {
                CriteriaListItemView(criteriaRating: criteria, explanation: "The connection line between the numbers on the 15 and 45 minute marks has an angle of \(String(format: "%.1f", angleHorizontal))° in comparison to a perfectly straight line")
            } else {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "No numbers were found that could be used to determine the horizontal symmetry of the clock")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    var clockhandsRight: some View {
        NavigationLink(destination: NavigationLazyView(Text("Todo"))) {
            if self.clockAnalyzer.analyzedResult.clockhandsRight {
                CriteriaListItemView(criteriaRating: .right, explanation: "The clock hands show the time '10 past 11' correctly")
            } else if self.clockAnalyzer.analyzedResult.clockhandsAlmostRight {
                CriteriaListItemView(criteriaRating: .unsure, explanation: "The clock hands probably show the time '10 past 11' correctly, but are not in exactly the right position")
            } else {
                CriteriaListItemView(criteriaRating: .wrong, explanation: "The clock hands do not show the time '10 past 11' correctly")
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    var timesRestartedDetail: some View {
        NavigationLink(destination: NavigationLazyView(Text("Todo"))) {
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
            case let x where x <= 120:
            criteria = .right
            case let x where x <= 180:
            criteria = .unsure
            default:
            criteria = .wrong
        }
        
        return NavigationLink(destination: NavigationLazyView(Text("Todo"))) {
            
                CriteriaListItemView(criteriaRating: criteria, explanation: "It took \(minutes) minutes and \(seconds) seconds from the first stroke to finish the clock")

        }.buttonStyle(PlainButtonStyle())
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        let clockAnalyzer = ClockAnalyzer()
        clockAnalyzer.analyzedResult = AnalyzedClockResult.example
        return NavigationView {
            ResultView(shouldPopToRootView: .constant(false), clockAnalyzer: clockAnalyzer)
                .previewDevice("iPad Pro")
            ResultView(shouldPopToRootView: .constant(false), clockAnalyzer: clockAnalyzer)
                .previewDevice("iPhone 12 Pro")
        }
    }
}
