//
//  NeighborDigitsAnalysisView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 14.11.21.
//

import SwiftUI


struct ClockhandsAnalysisView: View {
    
    @ObservedObject var clockAnalyzer: ClockAnalyzer
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            ScrollView {
               
                Image(uiImage: clockAnalyzer.getRecognizedClockhandsImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                
            }
        }
            
    }
}
