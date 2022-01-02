//
//  ConfigView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 14.11.21.
//

import SwiftUI

struct ConfigView: View {
    
    @Binding var showModal: Bool
    
    
    @AppStorage("useMLforClockhands") var useMLforClockhands = true
    
    
    @AppStorage("clockhandTolerance") var clockhandTolerance = 18 // DONE
    @AppStorage("clockhandTolerance2") var clockhandTolerance2 = 25 // DONE
    
    @AppStorage("maxTimesRestartedForPerfectRating") var maxTimesRestartedForPerfectRating = 1 // DONE
    @AppStorage("maxTimesRestartedForOkayRating") var maxTimesRestartedForOkayRating = 2 // DONE
    
    @AppStorage("changeDrawingLineWidth") var changeDrawingLineWidth = 12 // DONE
    
    @AppStorage("minLineLengthForHoughTransform") var minLineLengthForHoughTransform = 5
    @AppStorage("houghTransformThreshold") var houghTransformThreshold = 30
    
    @AppStorage("quarterHandsSymmetrieAngleTolerance") var quarterHandsSymmetrieAngleTolerance = 5
    @AppStorage("quarterHandsSymmetrieAngleTolerance2") var quarterHandsSymmetrieAngleTolerance2 = 10
    
    @AppStorage("maxSecondsForPerfectRating") var maxSecondsForPerfectRating = 120 // DONE
    @AppStorage("maxSecondsForSemiRating") var maxSecondsForSemiRating = 180 // DONE
    
    @AppStorage("digitDistanceVariationCoefficient") var digitDistanceVariationCoefficient = 0.2
    @AppStorage("digitDistanceVariationCoefficient2") var digitDistanceVariationCoefficient2 = 0.45
    
    @AppStorage("minNumbersFoundForPerfectRating") var minNumbersFoundForPerfectRating = 10
    @AppStorage("minNumbersFoundForOkayRating") var minNumbersFoundForOkayRating = 5
    
    @AppStorage("minNumbersInRightPositionForPerfectRating") var minNumbersInRightPositionForPerfectRating = 8
    @AppStorage("minNumbersInRightPositionForOkayRating") var minNumbersInRightPositionForOkayRating = 4
    
    var body: some View {
        NavigationView {
            
            Form {
                Section(header: Text("Basics")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Maximum times restarted for perfect rating:")
                            Text("\(maxTimesRestartedForPerfectRating)")
                        }
                        Slider(value: Binding(get: { Float(maxTimesRestartedForPerfectRating) }, set: { maxTimesRestartedForPerfectRating = Int($0) }), in: 0...4, step: 1, label: {}, minimumValueLabel: {
                            Text("0")
                        }, maximumValueLabel: {
                            Text("4")
                        })
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Maximum times restarted for accepted rating:")
                            Text("\(maxTimesRestartedForOkayRating)")
                        }
                        Slider(value: Binding(get: { Float(maxTimesRestartedForOkayRating) }, set: { maxTimesRestartedForOkayRating = Int($0) }), in: Float(maxTimesRestartedForPerfectRating)...Float(maxTimesRestartedForPerfectRating+4), step: 1, label: {}, minimumValueLabel: {
                            Text("\(maxTimesRestartedForPerfectRating)")
                        }, maximumValueLabel: {
                            Text("\(maxTimesRestartedForPerfectRating+4)")
                        })
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Maximum time for perfect rating:")
                            Text("\(maxSecondsForPerfectRating) seconds")
                        }
                        Slider(value: Binding(get: { Float(maxSecondsForPerfectRating) }, set: { maxSecondsForPerfectRating = Int($0) }), in: 0...180, step: 5, label: {}, minimumValueLabel: {
                            Text("0s")
                        }, maximumValueLabel: {
                            Text("180s")
                        })
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Maximum time for accepted rating:")
                            Text("\(maxSecondsForSemiRating) seconds")
                        }
                        Slider(value: Binding(get: { Float(maxSecondsForSemiRating) }, set: { maxSecondsForSemiRating = Int($0) }), in: Float(maxSecondsForSemiRating)...Float(maxSecondsForSemiRating+120), step: 5, label: {}, minimumValueLabel: {
                            Text("\(maxSecondsForSemiRating)s")
                        }, maximumValueLabel: {
                            Text("\(maxSecondsForSemiRating+120)s")
                        })
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Increase drawing line width for clockhand detection:")
                            Text("\(changeDrawingLineWidth) points")
                        }
                        Slider(value: Binding(get: { Float(changeDrawingLineWidth) }, set: { changeDrawingLineWidth = Int($0) }), in: 0...20, step: 1, label: {}, minimumValueLabel: {
                            Text("0")
                        }, maximumValueLabel: {
                            Text("20")
                        })
                    }
                    
                }
                Section(header: Text("Clockhand Detection")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Use ML for clockhands:")
                            Text(useMLforClockhands ? "Yes" : "No")
                        }
                        Toggle("", isOn: self.$useMLforClockhands)
                    }
                    if (!useMLforClockhands) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Perfect Clockhand Tolerance in degrees:")
                                Text("\(clockhandTolerance)")
                            }
                            Slider(value: Binding(get: { Float(clockhandTolerance) }, set: { clockhandTolerance = Int($0) }), in: 0...25, step: 1, label: {}, minimumValueLabel: {
                                Text("0")
                            }, maximumValueLabel: {
                                Text("25")
                            })
                        }
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Accepted Clockhand Tolerance in degrees:")
                                Text("\(clockhandTolerance2)")
                            }
                            Slider(value: Binding(get: { Float(clockhandTolerance2) }, set: { clockhandTolerance2 = Int($0) }), in: Float(clockhandTolerance)...Float(clockhandTolerance+15), step: 1, label: {}, minimumValueLabel: {
                                Text("\(clockhandTolerance)")
                            }, maximumValueLabel: {
                                Text("\(clockhandTolerance+15)")
                            })
                        }
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Hough Transform minimum line length:")
                                Text("\(minLineLengthForHoughTransform)")
                            }
                            Slider(value: Binding(get: { Float(minLineLengthForHoughTransform) }, set: { minLineLengthForHoughTransform = Int($0) }), in: 1...15, step: 1, label: {}, minimumValueLabel: {
                                Text("1")
                            }, maximumValueLabel: {
                                Text("15")
                            })
                        }
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Hough Transform threshold:")
                                Text("\(houghTransformThreshold)")
                            }
                            Slider(value: Binding(get: { Float(houghTransformThreshold) }, set: { houghTransformThreshold = Int($0) }), in: 5...100, step: 5, label: {}, minimumValueLabel: {
                                Text("5")
                            }, maximumValueLabel: {
                                Text("100")
                            })
                        }
                    }
                    
                }
                
                Section(header: Text("Symmetrie")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Perfect vertical and horizontal symmetrie tolerance:")
                            Text("\(quarterHandsSymmetrieAngleTolerance)")
                        }
                        Slider(value: Binding(get: { Float(quarterHandsSymmetrieAngleTolerance) }, set: { quarterHandsSymmetrieAngleTolerance = Int($0) }), in: 1...10, step: 5, label: {}, minimumValueLabel: {
                            Text("1")
                        }, maximumValueLabel: {
                            Text("10")
                        })
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Accepted vertical and horizontal symmetrie tolerance:")
                            Text("\(quarterHandsSymmetrieAngleTolerance2)")
                        }
                        Slider(value: Binding(get: { Float(quarterHandsSymmetrieAngleTolerance2) }, set: { quarterHandsSymmetrieAngleTolerance2 = Int($0) }), in: Float(quarterHandsSymmetrieAngleTolerance)...Float(quarterHandsSymmetrieAngleTolerance+10), step: 1, label: {}, minimumValueLabel: {
                            Text("\(quarterHandsSymmetrieAngleTolerance)")
                        }, maximumValueLabel: {
                            Text("\(quarterHandsSymmetrieAngleTolerance+10)")
                        })
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Perfect digit distance variation coefficient:")
                            Text("0.\(Int(digitDistanceVariationCoefficient*1000))")
                        }
                        Slider(value: Binding(get: { digitDistanceVariationCoefficient }, set: { digitDistanceVariationCoefficient = $0 }), in: 0...0.5, step: 0.025, label: {}, minimumValueLabel: {
                            Text("0")
                        }, maximumValueLabel: {
                            Text("0.5")
                        })
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Accepted digit distance variation coefficient:")
                            Text("0.\(Int(digitDistanceVariationCoefficient2*1000))")
                        }
                        Slider(value: Binding(get: { digitDistanceVariationCoefficient2 }, set: { digitDistanceVariationCoefficient2 = $0 }), in: digitDistanceVariationCoefficient...(digitDistanceVariationCoefficient+0.3), step: 0.025, label: {}, minimumValueLabel: {
                            Text("0.\(Int(digitDistanceVariationCoefficient*1000))")
                        }, maximumValueLabel: {
                            Text("0.\(Int((digitDistanceVariationCoefficient+0.3)*1000))")
                        })
                    }
                }
                Section(header: Text("Digit detection")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Minimum numbers found for perfect rating:")
                            Text("\(minNumbersFoundForPerfectRating)")
                        }
                        Slider(value: Binding(get: { Float(minNumbersFoundForPerfectRating) }, set: { minNumbersFoundForPerfectRating = Int($0) }), in: 2...12, step: 1, label: {}, minimumValueLabel: {
                            Text("2")
                        }, maximumValueLabel: {
                            Text("12")
                        })
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Minimum numbers found for accepted rating:")
                            Text("\(minNumbersFoundForOkayRating)")
                        }
                        Slider(value: Binding(get: { Float(minNumbersFoundForOkayRating) }, set: { minNumbersFoundForOkayRating = Int($0) }), in: 1...Float(minNumbersFoundForPerfectRating), step: 1, label: {}, minimumValueLabel: {
                            Text("1")
                        }, maximumValueLabel: {
                            Text("\(minNumbersFoundForPerfectRating)")
                        })
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Minimum numbers in right position for perfect rating:")
                            Text("\(minNumbersInRightPositionForPerfectRating)")
                        }
                        Slider(value: Binding(get: { Float(minNumbersInRightPositionForPerfectRating) }, set: { minNumbersInRightPositionForPerfectRating = Int($0) }), in: 2...12, step: 1, label: {}, minimumValueLabel: {
                            Text("2")
                        }, maximumValueLabel: {
                            Text("12")
                        })
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Minimum numbers in right position for accepted rating:")
                            Text("\(minNumbersInRightPositionForOkayRating)")
                        }
                        Slider(value: Binding(get: { Float(minNumbersInRightPositionForOkayRating) }, set: { minNumbersInRightPositionForOkayRating = Int($0) }), in: 1...Float(minNumbersInRightPositionForPerfectRating), step: 1, label: {}, minimumValueLabel: {
                            Text("1")
                        }, maximumValueLabel: {
                            Text("\(minNumbersInRightPositionForPerfectRating)")
                        })
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showModal = false
                    } label: {
                        Text("Close")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        useMLforClockhands = true
                        
                        clockhandTolerance = 18 
                        clockhandTolerance2 = 25
                        
                        maxTimesRestartedForPerfectRating = 1
                        maxTimesRestartedForOkayRating = 2
                        
                        changeDrawingLineWidth = 12
                        
                        minLineLengthForHoughTransform = 5
                        houghTransformThreshold = 30
                        
                        quarterHandsSymmetrieAngleTolerance = 5
                        quarterHandsSymmetrieAngleTolerance2 = 10
                        
                        maxSecondsForPerfectRating = 120
                        maxSecondsForSemiRating = 180
                        
                        digitDistanceVariationCoefficient = 0.2
                        digitDistanceVariationCoefficient2 = 0.45
                        
                        minNumbersFoundForPerfectRating = 10
                        minNumbersFoundForOkayRating = 5
                    } label: {
                        Text("Reset")
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
}
