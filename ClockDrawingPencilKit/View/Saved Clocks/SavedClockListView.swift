//
//  SavedClockListView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 29.12.21.
//

import SwiftUI
import RealmSwift

struct SavedClockListView: View {
    
    @ObservedResults(SavedClock.self) var clocks
    @State var showDetailClock = false
    @State var selectedDetailClock: SavedClock?
    @Binding var isVisible: Bool
    
    var body: some View {
        ZStack {
            if let savedClock = self.selectedDetailClock {
                NavigationLink(destination: NavigationLazyView(DrawSavedClockView(savedClock: savedClock, rootIsActive: self.$showDetailClock)), isActive: self.$showDetailClock) {
                    EmptyView()
                }
            }
            ScrollView {
                LazyVGrid(columns: .init(repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 10), count: 4), spacing: 10) {
                    ForEach(clocks) { clock in
                        SavedClockCellView(clock: clock).contextMenu {
                            Button {
                                $clocks.remove(clock)
                                
                            } label: {
                                Label("Delete", systemImage: "trash").foregroundColor(.red)
                            }
                        }.contentShape(Rectangle()).onTapGesture {
                            self.selectedDetailClock = clock
                            self.showDetailClock = true
                        }
                    }
                }
            }
            
            NavigationLink(
                destination: NavigationLazyView(AnalyzeAllSavedClockView(clocks: clockDict))
                        ) {
                            Text("Analyze all").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
                        }
                        .isDetailLink(false).buttonStyle(PlainButtonStyle()).padding()
            
        }
        .onChange(of: selectedDetailClock, perform: { newValue in
            
        })
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.selectedDetailClock = SavedClock()
                    $clocks.append(self.selectedDetailClock!)
                    self.showDetailClock = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationBarTitle("Saved Clocks", displayMode: .automatic)
    }
    
    var clockDict: [SavedClock: AnalyzedClockResult?] {
        let ret = clocks.reduce(into: [SavedClock: AnalyzedClockResult?]()) { partialResult, clock in
            print("ROUND")
            partialResult[clock] = nil as AnalyzedClockResult?
        }
        print(ret.count)
        
        return ret
    }
}

