//
//  CircleScoreView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 13.11.21.
//

import SwiftUI

struct CircleScoreView: View {
    
    var color = UIColor.black
    var score = 1
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: 0.75)
                .stroke(style: StrokeStyle(lineWidth: 10.0, lineCap: .round, lineJoin: .round))
                .opacity(0.3)
                .foregroundColor(Color(color))
                .rotationEffect(.init(degrees: 135))
                
                
            Circle()
                .trim(from: 0.0, to: 0.75)
                .trim(from: 0.0, to: CGFloat(min(Double(6-score)/5, 1.0)))
                
                .stroke(style: StrokeStyle(lineWidth: 10.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color(color))
                //.rotationEffect(Angle(degrees: 270.0))
                .animation(.linear).rotationEffect(.init(degrees: 135))
            VStack {
                Text("Score")
                Text("\(score)").font(.title).fontWeight(.semibold).padding(.bottom, 10)
                resultText
            }
        }.padding()
    }
    
    var resultText: some View {
        Text(score <= 2 ?
                "Test passed"
             :
                "Test failed")
            .foregroundColor(
                score <= 2 ?
                    Color(.systemGreen)
                :
                    Color(.systemRed))
            .font(.headline)
    }
}

struct CircleScoreView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CircleScoreView().frame(width: 200, height: 200, alignment: .center)
            CircleScoreView(score: 2).frame(width: 200, height: 200, alignment: .center)
            CircleScoreView(score: 3).frame(width: 200, height: 200, alignment: .center)
            CircleScoreView(score: 4).frame(width: 200, height: 200, alignment: .center)
            CircleScoreView(score: 5).frame(width: 200, height: 200, alignment: .center)
            CircleScoreView(score: 6).frame(width: 200, height: 200, alignment: .center)
        }
    }
}
