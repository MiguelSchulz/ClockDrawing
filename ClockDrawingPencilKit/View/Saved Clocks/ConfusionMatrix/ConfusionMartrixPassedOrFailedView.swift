//
//  ConfusionMatrixView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 11.01.22.
//

import SwiftUI

struct ConfusionMatrixPassedOrFailedView: View {

    @State var clocks: [SavedClock]

    var body: some View {
        HStack {
            //Text("True score").fontWeight(.bold).rotationEffect(.degrees(-90))
            VStack {
                Text("Analyzed").fontWeight(.bold)
                row1
                row2
                row3

            }
        }
    }

    var row1: some View {
        HStack {
            Color.clear.format()
            Text("Pass").fontWeight(.bold).format()
            Text("Fail").fontWeight(.bold).format()
        }
    }
    var row2: some View {
        HStack {
            Text("Pass").fontWeight(.bold).format()
            cell(passedAnalyzed: true, passedActually: true)
            cell(passedAnalyzed: false, passedActually: true)
        }
    }

    var row3: some View {
        HStack {
            Text("Fail").fontWeight(.bold).format()
            cell(passedAnalyzed: true, passedActually: false)
            cell(passedAnalyzed: false, passedActually: false)
        }
    }

    func percent(_ double: Double) -> String {
        String(format: "%.2f%", double*100)
    }

    func cell(passedAnalyzed: Bool, passedActually: Bool) -> some View {
        Group {
            let number = clocks.filter({(($0.rightScore <= 2) == passedActually) && (($0.analyzedScore <= 2) == passedAnalyzed)}).count
            if passedAnalyzed == passedActually {
                Text("\(number)").format().background(Color.blue).foregroundColor(.white).font(.system(size: 12))
            } else {
                Text("\(number)").format().font(.system(size: 12))
            }
        }
    }
}


fileprivate extension View {

    func format() -> some View {
        self.frame(width: 60, height: 60)
    }

}
