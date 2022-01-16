//
//  SavedClockListView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 29.12.21.
//

import SwiftUI
import RealmSwift
import PDFKit

struct SavedClockListView: View {
    
    @ObservedResults(SavedClock.self, sortDescriptor: SortDescriptor(keyPath: "rightScore", ascending: true)) var clocks
    @State var showDetailClock = false
    @State var selectedDetailClock: SavedClock?
    @Binding var isVisible: Bool

    @State var showModal = false
    @State public var sharedItems : [Any] = []
    
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
                            Button {
                                let image = clock.drawing.image(from: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: CGFloat(clock.width), height: CGFloat(clock.height))), scale: 1)
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)


                            } label: {
                                Label("Save", systemImage: "photo").foregroundColor(.red)
                            }
                        }.contentShape(Rectangle()).onTapGesture {
                            self.selectedDetailClock = clock
                            self.showDetailClock = true
                        }
                    }
                }
            }
            
            VStack {
                Spacer()
                NavigationLink(
                    destination: NavigationLazyView(CountHowManyAreRightView(clocks: Array(clocks))/*AnalyzeAllSavedClockView(clocks: getClockDict())*/)
                            ) {
                                Text("Analyze all").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
                            }
                            .isDetailLink(false).buttonStyle(PlainButtonStyle()).padding()
            }
            
        }
        .sheet(isPresented: self.$showModal) {
            ShareSheet(activityItems: sharedItems)
        }
        .onChange(of: selectedDetailClock, perform: { newValue in
            
        })
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    exportPDF()
                } label: {
                    Text("Export")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.selectedDetailClock = SavedClock()
                    $clocks.append(self.selectedDetailClock!)
                    /*for i in 0..<100 {
                        $clocks.append(SavedClock())
                    }*/
                    self.showDetailClock = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onChange(of: self.showModal) { _ in

        }
        .navigationBarTitle("Saved Clocks", displayMode: .automatic)
    }
    
    func getClockDict() -> [SavedClock: AnalyzedClockResult?] {
        let ret = clocks.reduce(into: [SavedClock: AnalyzedClockResult?]()) { partialResult, clock in
            print("ROUND")
            partialResult[clock] = nil as AnalyzedClockResult?
        }
        print(ret.count)
        
        return ret
    }

    func exportPDF() {
        let shareDocument = PDFDocument()

        let outgroup = DispatchGroup()

        let clockSubset = Array(clocks).chunked(into: 20)

        for (i, clockChunk) in clockSubset.enumerated() {
            outgroup.enter()

            let screenshot = AnyView(
                VStack {
                    LazyVGrid(columns: .init(repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 10), count: 4), spacing: 10) {
                        ForEach(clockChunk) { clock in
                            SavedClockCellView(clock: clock)
                        }
                    }
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        Text("Page \(i)")
                    }
                }.padding(10).frame(width: 210*5, height: 297*5)
            ).snapshot()
            if let page = PDFPage(image: screenshot) {
                shareDocument.insert(page, at: i)
            }

            outgroup.leave()
        }

        outgroup.notify(queue: DispatchQueue.main) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .medium

            do
            {
                let filename = "\(dateFormatter.string(from: Date())).pdf"
                let tmpDirectory = FileManager.default.temporaryDirectory
                let fileURL = tmpDirectory.appendingPathComponent(filename)
                try shareDocument.dataRepresentation()?.write(to: fileURL)
                sharedItems = [fileURL]
            }
            catch
            {
                print ("Cannot write PDF: \(error)")
            }
            showModal = true
        }
    }
}

