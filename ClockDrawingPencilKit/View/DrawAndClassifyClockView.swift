//
//  DrawAndClassifyClockView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import PencilKit
import opencv2
import SwiftUI

struct DrawAndClassifyClockView: View {
    
    @StateObject var clockAnalyzer = ClockAnalyzer()
    @State var drawingRect = CGRect()
    @State var drawing = PKDrawing()
    @State var showResult = false
    
    @Binding var rootIsActive: Bool
    
    @State var magicImage: UIImage? = nil
    
    
    
    var body: some View {
        VStack {
            NavigationLink(isActive: self.$showResult) {
                NavigationLazyView(ResultView(shouldPopToRootView: self.$rootIsActive, clockAnalyzer: self.clockAnalyzer))
            } label: {
                EmptyView()
            }.isDetailLink(false)

            ZStack {
                if let image = magicImage {
                    Image(uiImage: image).resizable()
                }
                //Image("clock")
                Circle().stroke(Color.black, lineWidth: 2).padding(10)
                DrawingView(drawing: self.$drawing, firstStrokeDate: self.$clockAnalyzer.firstStrokeDate)
            }.aspectRatio(1, contentMode: .fit).background(GeometryGetter(rect: self.$drawingRect))
            Spacer()
            HStack {
                Button {
                    self.magicImage = UIImage(named: "do_magic")
                } label: {
                    Text("Do magic").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.purple.cornerRadius(20))
                }.buttonStyle(PlainButtonStyle()).padding()
                Button {
                    self.drawing = PKDrawing()
                    self.magicImage = nil
                    self.clockAnalyzer.analyzedResult.timesRestarted += 1
                } label: {
                    Text("Clear Clock").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.red.cornerRadius(20))
                }.buttonStyle(PlainButtonStyle()).padding()
                Button {
                    
                    clockAnalyzer.startAnalysis(clockImage: generateClockImage(), fatClockImage: generateFatClockImage(), onCompletion: {
                        self.showResult = true
                    })
                } label: {
                    Text("Done").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
                }.buttonStyle(PlainButtonStyle()).padding()
                
                
            }
        }.padding(UIDevice.current.userInterfaceIdiom == .pad ? 50 : 10)
            .navigationBarHidden(true)
            
    }
    
    func generateClockImage() -> UIImage {
        var image = drawing.image(from: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: drawingRect.size.width, height: drawingRect.size.height)), scale: 1)
        
        return image
    }
    
    func generateFatClockImage() -> UIImage {
        return drawing.changeLineWidth(by: CGFloat(Config.changeLineWidthOfDrawingBy)).image(from: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: drawingRect.size.width, height: drawingRect.size.height)), scale: 1)
    }
}
