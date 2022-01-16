//
//  ConfusionMatrixView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 11.01.22.
//

import SwiftUI

struct ConfusionMatrixView: View {

    @State var clocks: [SavedClock]
    var offDiagonal = false

    var body: some View {
        HStack {
            //Text("True score")..fontWeight(.bold).rotationEffect(.degrees(-90))
            VStack {
                Text("Analyzed").fontWeight(.bold)
                row1
                row2
                row3
                row4
                row5
                row6
                row7
            }
        }
    }

    var row1: some View {
        HStack {
            Color.clear.format()
            Text("1").fontWeight(.bold).format()
            Text("2").fontWeight(.bold).format()
            Text("3").fontWeight(.bold).format()
            Text("4").fontWeight(.bold).format()
            Text("5").fontWeight(.bold).format()
            Text("6").fontWeight(.bold).format()
        }
    }
    var row2: some View {
        HStack {
            Text("1").fontWeight(.bold).format()
            cell(analyzed: 1, actually: 1)
            cell(analyzed: 2, actually: 1)
            cell(analyzed: 3, actually: 1)
            cell(analyzed: 4, actually: 1)
            cell(analyzed: 5, actually: 1)
            cell(analyzed: 6, actually: 1)
        }
    }

    var row3: some View {
        HStack {
            Text("2").fontWeight(.bold).format()
            cell(analyzed: 1, actually: 2)
            cell(analyzed: 2, actually: 2)
            cell(analyzed: 3, actually: 2)
            cell(analyzed: 4, actually: 2)
            cell(analyzed: 5, actually: 2)
            cell(analyzed: 6, actually: 2)
        }
    }

    var row4: some View {
        HStack {
            Text("3").fontWeight(.bold).format()
            cell(analyzed: 1, actually: 3)
            cell(analyzed: 2, actually: 3)
            cell(analyzed: 3, actually: 3)
            cell(analyzed: 4, actually: 3)
            cell(analyzed: 5, actually: 3)
            cell(analyzed: 6, actually: 3)
        }
    }

    var row5: some View {
        HStack {
            Text("4").fontWeight(.bold).format()
            cell(analyzed: 1, actually: 4)
            cell(analyzed: 2, actually: 4)
            cell(analyzed: 3, actually: 4)
            cell(analyzed: 4, actually: 4)
            cell(analyzed: 5, actually: 4)
            cell(analyzed: 6, actually: 4)
        }
    }

    var row6: some View {
        HStack {
            Text("5").fontWeight(.bold).format()
            cell(analyzed: 1, actually: 5)
            cell(analyzed: 2, actually: 5)
            cell(analyzed: 3, actually: 5)
            cell(analyzed: 4, actually: 5)
            cell(analyzed: 5, actually: 5)
            cell(analyzed: 6, actually: 5)
        }
    }

    var row7: some View {
        HStack {
            Text("6").fontWeight(.bold).format()
            cell(analyzed: 1, actually: 6)
            cell(analyzed: 2, actually: 6)
            cell(analyzed: 3, actually: 6)
            cell(analyzed: 4, actually: 6)
            cell(analyzed: 5, actually: 6)
            cell(analyzed: 6, actually: 6)
        }
    }

    func percent(_ double: Double) -> String {
        String(format: "%.2f%", double*100)
    }

    func cell(analyzed: Int, actually: Int) -> some View {
        Group {
            if offDiagonal {
                let number = getOffDiagonalPercentage(analyzed: analyzed, actually: actually)

                if analyzed == actually {
                    Text("\(percent(number))%").format().background(Color.blue).foregroundColor(.white).font(.system(size: 12))
                } else {
                    if number > 0.25 {
                        Text("\(percent(number))%").format().background(Color.red).font(.system(size: 12))
                    } else {
                        Text("\(percent(number))%").format().font(.system(size: 12))
                    }
                }
            } else {
                let countTrueLabel = clocks.filter{$0.rightScore == actually}.count
                let number = Double(clocks.filter({$0.rightScore == actually && $0.analyzedScore == analyzed}).count) / Double(countTrueLabel)
                if analyzed == actually {
                    Text("\(percent(number))%").format().background(Color.blue).foregroundColor(.white).font(.system(size: 12))
                } else {
                    if number > 0.25 {
                        Text("\(percent(number))%").format().background(Color.red).font(.system(size: 12))
                    } else {
                        Text("\(percent(number))%").format().font(.system(size: 12))
                    }
                }
            }
        }
    }

    func getOffDiagonalPercentage(analyzed: Int, actually: Int) -> Double {
        let countTrueLabel = clocks.filter{$0.rightScore == actually}.count
        var number = Double(clocks.filter({$0.rightScore == actually && $0.analyzedScore == analyzed}).count) / Double(countTrueLabel)
        if analyzed == actually {
            number += Double(clocks.filter({$0.rightScore == actually && $0.analyzedScore == analyzed+1}).count) / Double(countTrueLabel)
            number += Double(clocks.filter({$0.rightScore == actually && $0.analyzedScore == analyzed-1}).count) / Double(countTrueLabel)
        } else if abs(analyzed-actually) == 1 {
            number = 0
        }
        return number
    }
}


fileprivate extension View {

    func format() -> some View {
        self.frame(width: 60, height: 60)
    }

}
