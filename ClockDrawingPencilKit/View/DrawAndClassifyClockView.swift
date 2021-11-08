//
//  DrawAndClassifyClockView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import PencilKit
import SwiftUI

struct DrawAndClassifyClockView: View {
    
    @StateObject var clockAnalyzer = ClockAnalyzer()
    @State var drawingRect = CGRect()
    @State var drawing = PKDrawing()
    @State var showResult = false
    
    @Binding var rootIsActive: Bool
    
    
    var body: some View {
        VStack {
            NavigationLink(isActive: self.$showResult) {
                NavigationLazyView(DebugResultView(analyzedResult: self.clockAnalyzer.analyzedResult, shouldPopToRootView: self.$rootIsActive))
            } label: {
                EmptyView()
            }.isDetailLink(false)

            ZStack {
                Circle().stroke(Color.black, lineWidth: 3).padding(10)
                DrawingView(drawing: self.$drawing)
            }.aspectRatio(1, contentMode: .fit).background(GeometryGetter(rect: self.$drawingRect))
            Spacer()
            HStack {
                Button {
                    self.drawing = PKDrawing()
                    self.clockAnalyzer.analyzedResult.timesRestarted += 1
                } label: {
                    Text("Clear Clock").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.red.cornerRadius(20))
                }.buttonStyle(PlainButtonStyle()).padding()
                Button {
                    clockAnalyzer.startAnalysis(clockImage: generateClockImage(), onCompletion: {
                        self.showResult = true
                    })
                } label: {
                    Text("Done").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
                }.buttonStyle(PlainButtonStyle()).padding()
                
                
            }
        }.padding(50)
            .navigationBarHidden(true)
            
    }
    
    func generateClockImage() -> UIImage {
        return drawing.changeLineWidth(by: CGFloat(Config.changeLineWidthOfDrawingBy)).image(from: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: drawingRect.size.width, height: drawingRect.size.height)), scale: 1)
    }
}
