//
//  StartClockTestView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import SwiftUI

struct StartClockTestView: View {
    @State var testStarted = false
    @State var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Welcome!").font(.largeTitle).fontWeight(.semibold)
                        Text("Please read the information below carefully. The test will not start until you understand all the information and tap on the green area labeled 'Start'.\n\nOn the next page you will see a black circle. Please use the pen provided to draw the digits of an analog clock. Then draw the hands so that they show the time 'ten past eleven'.\n\nIf you want to correct a mistake, use the red area labeled 'Clear Clock' to start again. When you are done, press the green area labeled 'Done'.\n\nDuring the task you will not be able to ask any questions until you tap 'Done'. So if you have a question, now is the time to ask!").fixedSize(horizontal: false, vertical: true).font(.title)
                    }.padding(20)
                }
                VStack {
                    Spacer()
                    NavigationLink(
                        destination: NavigationLazyView(DrawAndClassifyClockView(rootIsActive: self.$testStarted)),
                                    isActive: self.$testStarted
                                ) {
                                    Text("Start").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
                                }
                                .isDetailLink(false).buttonStyle(PlainButtonStyle()).padding()
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .sheet(isPresented: self.$showSettings) {
                ConfigView(showModal: self.$showSettings)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
           
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct StartClockTestView_Previews: PreviewProvider {
    static var previews: some View {
        StartClockTestView()
    }
}
