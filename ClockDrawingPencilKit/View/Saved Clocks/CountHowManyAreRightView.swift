//
//  CountHowManyAreRightView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 11.01.22.
//

import SwiftUI
import RealmSwift

struct CountHowManyAreRightView: View {

    let analyzer = ClockAnalyzer()

    @State var done = false
    @State var howManyDone = 0.0

    @State var clocks: [SavedClock]
    //@ObservedResults(SavedClock.self, sortDescriptor: SortDescriptor(keyPath: "rightScore", ascending: true)) var clocks
    
    var body: some View {
        if done {
            ScrollView {
                HStack {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text("Scoring exactly right:")
                                .font(.title)
                            Text("Overall: \(clocksExactlyRight) of \(clocks.count). (\(getPercentString(from: Double(clocksExactlyRight) / Double(clocks.count)))%)")
                            Text("Score 1: \(countRightScored(score: 1)) of \(countAllWithSetScore(score: 1))")
                            Text("Score 2: \(countRightScored(score: 2)) of \(countAllWithSetScore(score: 2))")
                            Text("Score 3: \(countRightScored(score: 3)) of \(countAllWithSetScore(score: 3))")
                            Text("Score 4: \(countRightScored(score: 4)) of \(countAllWithSetScore(score: 4))")
                            Text("Score 5: \(countRightScored(score: 5)) of \(countAllWithSetScore(score: 5))")
                            Text("Score 6: \(countRightScored(score: 6)) of \(countAllWithSetScore(score: 6))")
                        }

                        VStack(alignment: .leading) {
                            Text("Scoring off by one at max:")
                                .font(.title)
                            Text("Overall: \(offByOneOrLess) of \(clocks.count). (\(getPercentString(from: Double(offByOneOrLess) / Double(clocks.count)))%)")
                            Text("By pass or fail:")
                                .font(.title)
                            Text("Overall: \(testPassOrFailRightOverall) of \(clocks.count). (\(getPercentString(from: Double(testPassOrFailRightOverall) / Double(clocks.count)))%)")
                            Text("Test passed: \(testRatedAsPassRightfully) of \(testPassedTotal). (\(getPercentString(from: Double(testRatedAsPassRightfully) / Double(testPassedTotal)))%)")
                            Text("Test failed: \(testRatedAsFailRightfully) of \(testFailedTotal). (\(getPercentString(from: Double(testRatedAsFailRightfully) / Double(testFailedTotal)))%)")
                        }

                        VStack(alignment: .leading) {
                            Text("Falsely rated as pass or fail:")
                                .font(.title)
                            Text("Overall: \(testFalseRated) of \(clocks.count). (\(getPercentString(from: Double(testFalseRated) / Double(clocks.count)))%)")
                            Text("Right rated as wrong: \(rightTestRatedAsWrong) of \(testPassedTotal). (\(getPercentString(from: Double(rightTestRatedAsWrong) / Double(testPassedTotal)))%)")
                            Text("Wrong rated as right: \(wrongTestRatedAsRight) of \(testFailedTotal). (\(getPercentString(from: Double(wrongTestRatedAsRight) / Double(testFailedTotal)))%)")
                        }

                        VStack(alignment: .leading) {
                            Text("Number ratings:")
                                .font(.title)
                            Text("Min 10 found: \(clocksWithMin10Numbers) of \(clocksWithActuallyAll12Numbers). (\(getPercentString(from: Double(clocksWithMin10Numbers) / Double(clocksWithActuallyAll12Numbers)))%)")
                            Text("Min 10 found in right spot: \(clocksWithMin10NumbersInRightSpot) of \(clocksWithActuallyAll12Numbers). (\(getPercentString(from: Double(clocksWithMin10NumbersInRightSpot) / Double(clocksWithActuallyAll12Numbers)))%)")

                            Text("Symmetrie ratings:")
                                .font(.title)
                            Text("Distances perfect: \(clocksWithGoodDistances) of \(symmetricClocks). (\(getPercentString(from: Double(clocksWithGoodDistances) / Double(symmetricClocks)))%)")
                            Text("Symmetrie perfect: \(clocksWithGoodSymmetrie) of \(symmetricClocks). (\(getPercentString(from: Double(clocksWithGoodSymmetrie) / Double(symmetricClocks)))%)")
                        }
                    }
                    VStack {
                        Text("Confusion matrix:")
                            .font(.title)
                        ConfusionMatrixView(clocks: clocks)
                        Text("Confusion matrix off diagonal:")
                            .font(.title)
                        ConfusionMatrixView(clocks: clocks,offDiagonal: true)
                        Text("Confusion matrix pass/fail:")
                            .font(.title)
                        ConfusionMatrixPassedOrFailedView(clocks: clocks)
                    }
                }.padding()
            }
        } else {
            VStack {
                ProgressView("Analyzing...", value: self.howManyDone, total: Double(clocks.count)).padding()
            }.onAppear {
                for arrayChunk in clocks.chunked(into: 7) {
                    analyzeClockAt(array: arrayChunk, i: 0)
                }
            }
        }
    }

    func getPercentString(from double: Double) -> String {
        String(format: "%.2f%", double*100)
    }

    var clocksWithMin10Numbers: Int
    {
        clocks.filter({ ($0.rightScore <= 3) && ($0.analyzedResult?.numbersFoundAtLeastOnce.count ?? 0 >= 10)}).count
    }

    var clocksWithActuallyAll12Numbers: Int
    {
        clocks.filter({ ($0.rightScore <= 3)}).count
    }

    var clocksWithMin10NumbersInRightSpot: Int
    {
        clocks.filter({ ($0.rightScore <= 3) && ($0.analyzedResult?.numbersFoundInRightSpot.count ?? 0 >= 10)}).count
    }

    var clocksWithGoodDistances: Int
    {
        clocks.filter({ ($0.analyzedResult?.digitDistanceVariationCoefficient ?? 1 <= 0.25)}).count
    }

    var clocksWithGoodSymmetrie: Int
    {
        clocks.filter({ ($0.analyzedResult?.horizontalConnectionLinePerfect ?? false && $0.analyzedResult?.verticalConnectionLinePerfect ?? true)}).count
    }

    var symmetricClocks: Int
    {
        77
    }


    var testPassOrFailRightOverall: Int
    {
        clocks.filter({ ($0.rightScore <= 2) == ($0.analyzedScore <= 2)}).count
    }

    var testPassedTotal: Int
    {
        clocks.filter({ $0.rightScore <= 2}).count
    }

    var testRatedAsPassRightfully: Int
    {
        clocks.filter({ $0.analyzedScore <= 2  && $0.rightScore <= 2}).count
    }

    var testFailedTotal: Int
    {
        clocks.filter({ $0.rightScore > 2}).count
    }

    var testRatedAsFailRightfully: Int
    {
        clocks.filter({ $0.analyzedScore > 2 && $0.rightScore > 2}).count
    }

    var testFalseRated: Int
    {
        clocks.count - testPassOrFailRightOverall
    }

    var wrongTestRatedAsRight: Int
    {
        clocks.filter({ ($0.rightScore > 2) == ($0.analyzedScore <= 2)}).count
    }

    var rightTestRatedAsWrong: Int
    {
        clocks.filter({ ($0.rightScore <= 2) == ($0.analyzedScore > 2)}).count
    }

    var offByOneOrLess: Int
    {
        clocks.filter({($0.rightScore-1...$0.rightScore+1).contains($0.analyzedScore)}).count
    }

    var clocksExactlyRight: Int {
        clocks.filter({$0.rightScore == $0.analyzedScore}).count
    }

    func analyzeClockAt(array: [SavedClock], i: Int) {
        if array.indices.contains(i) {
            let analyzer = ClockAnalyzer()
            analyzer.startAnalysis(clockImage: generateClockImage(clock: array[i]), fatClockImage: generateFatClockImage(clock: array[i])) {
                //
                if let findIndex = self.clocks.firstIndex(where: {$0 == array[i]}) {
                    clocks[findIndex].analyzedScore = analyzer.analyzedResult.score
                    clocks[findIndex].analyzedResult = analyzer.analyzedResult
                    //print("\(analyzer.analyzedResult.score) at \(clocks[findIndex].rightScore)")
                }
                self.howManyDone = Double(clocks.filter({$0.analyzedScore != 0}).count)
                analyzeClockAt(array: array, i: i+1)
                print(clocks.filter({$0.analyzedScore == 0}).count)
                if clocks.filter({$0.analyzedScore == 0}).count == 0 {
                    self.done = true
                }
            }
        }
    }

    func generateClockImage(clock: SavedClock) -> UIImage {
        return clock.drawing.image(from: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: CGFloat(clock.width), height: CGFloat(clock.height))), scale: 1)

    }

    func generateFatClockImage(clock: SavedClock) -> UIImage {
        return clock.drawing.changeLineWidth(by: CGFloat(Config.changeLineWidthOfDrawingBy)).image(from: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: CGFloat(clock.width), height: CGFloat(clock.height))), scale: 1)
    }

    func countRightScored(score: Int) -> Int {
        return clocks.filter({$0.analyzedScore == score && $0.rightScore == score}).count
    }

    func countAllWithSetScore(score: Int) -> Int {
        return clocks.filter({$0.rightScore == score}).count
    }
}

struct CountHowManyAreRightView_Previews: PreviewProvider {
    static var previews: some View {
        CountHowManyAreRightView(clocks: [])
    }
}
