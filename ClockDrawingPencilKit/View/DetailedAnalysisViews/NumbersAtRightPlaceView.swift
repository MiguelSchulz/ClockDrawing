//
//  NumbersAtRightPlaceView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 14.11.21.
//

import SwiftUI

struct NumbersAtRightPlaceView: View {
    
    @ObservedObject var clockAnalyzer: ClockAnalyzer
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack {
                    CircleDrawingImageOverlay(image: self.clockAnalyzer.getNumbersWithRightSpotRating())
                }
            }
        }
            
    }
}