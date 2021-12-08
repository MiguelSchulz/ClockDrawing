//
//  NumbersFoundAnalysisView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 14.11.21.
//

import SwiftUI

struct NumbersFoundAnalysisView: View {
    
    @ObservedObject var clockAnalyzer: ClockAnalyzer
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack {
                    CircleDrawingImageOverlay(image: self.clockAnalyzer.getAllRecognizedDigitImage())
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(self.clockAnalyzer.analyzedResult.classifiedDigits) { digit in
                                VStack {
                                    Image(uiImage: digit.digitImage).resizable().aspectRatio(contentMode: .fit).frame(width:100, height: 100).cornerRadius(10)
                                    HStack {
                                        Text(digit.topPrediction.classification).font(.system(size: 20, weight: .semibold, design: .default))
                                        Spacer()
                                        Text("\(Int(digit.topPrediction.confidencePercentage*100))%")
                                    }
                                }
                            }
                        }
                    }.whiteRoundedBackground().padding()
                }
            }
        }
            
    }
}
