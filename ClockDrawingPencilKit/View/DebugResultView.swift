//
//  DebugResultView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import SwiftUI

struct DebugResultView: View {
    
    @State var analyzedResult: AnalyzedClockResult
    @Binding var shouldPopToRootView: Bool
    
    var body: some View {
            List {
                Section {
                    HStack {
                        ZStack {
                            Circle().stroke(Color.black, lineWidth: 3).padding(10)
                            Image(uiImage: analyzedResult.completeImage).resizable().aspectRatio(contentMode: .fit).padding(10).frame(maxHeight: 400)
                        }
                        VStack(alignment: .leading) {
                            Text("Additional Information").font(.headline)
                            Text("Time: xx:xx")
                            Text("Times restarted: X")
                        }.padding().background(Color( .systemGroupedBackground).cornerRadius(10))
                        Spacer()
                    }.background(Color.white.cornerRadius(10))
                } header: {
                    Text("Input Image:")
                }
                Section {
                    HStack(alignment: .top) {
                        VStack(alignment: .center) {
                            Text("Digit Detection: Invert image, threshold, crop to remove inner part (clockhands)")
                            
                            Image(uiImage: analyzedResult.digitDetectionInvertedImage).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 400)
                            Text("Find contours to detected rectangles around digits")
                            Image(uiImage: analyzedResult.digitRectanlgeImage).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 400)
                            Text("Crop digits from image, resize to 28x28 and classify with MNIST dataset")
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack {
                                    ForEach(analyzedResult.classifiedDigits) { digit in
                                        VStack {
                                            Image(uiImage: digit.digitImage).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 100)
                                            HStack {
                                                Text(digit.topPrediction.classification).font(.system(size: 20, weight: .semibold, design: .default))
                                                Spacer()
                                                Text("\(Int(digit.topPrediction.confidencePercentage*100))%")
                                            }
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }.padding().background(Color.white.cornerRadius(10))
                        Spacer(minLength: 20)
                        VStack(alignment: .leading) {
                            Text("Digit Detection: Invert image, threshold, crop to remove outer part (digits)")
                            Image(uiImage: analyzedResult.clockhandDetectionInvertedImage).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 400)
                            Text("HoughLinesP transform with minLength to only pick up straight lines")
                            Image(uiImage: analyzedResult.handsHoughTransformImage).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 400)
                            Text("Detect angle of both hands in comparison to horizontal axis:")
                            Image(uiImage: analyzedResult.detectedHandsImage).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 400)
                        }.padding().background(Color.white.cornerRadius(10))
                    }
                } header: {
                    Text("Steps to analyze:")
                }
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Clockhands").font(.headline)
                            Text("\(String(format: "Minute hand angle: %.0f", abs(analyzedResult.minuteHandAngle)))°")
                            Text("\(String(format: "Hour hand angle: %.0f", abs(analyzedResult.hourHandAngle)))°")
                            if analyzedResult.clockhandsRight {
                                Text("Clockhands right!").padding().background(Color.green.cornerRadius(5))
                            } else {
                                Text("Clockhands wrong!").padding().background(Color.red.cornerRadius(5))
                            }
                        }.padding().background(Color( .systemGroupedBackground).cornerRadius(10)).padding()
                        VStack(alignment: .leading) {
                            Text("Digits").font(.headline)
                            Text("No Information")
                        }.padding().background(Color( .systemGroupedBackground).cornerRadius(10)).padding()
                        Spacer()
                        Button {
                            self.shouldPopToRootView = false
                        } label: {
                            Text("Restart Test").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
                        }.buttonStyle(PlainButtonStyle()).padding()
                    }.background(Color.white.cornerRadius(10))
                } header: {
                    Text("Summary:")
                }
                
            }.listStyle(SidebarListStyle()).navigationBarHidden(true)
    }
}

struct DebugResultView_Previews: PreviewProvider {
    static var previews: some View {
        DebugResultView(analyzedResult: AnalyzedClockResult.example, shouldPopToRootView: .constant(false))
    }
}
