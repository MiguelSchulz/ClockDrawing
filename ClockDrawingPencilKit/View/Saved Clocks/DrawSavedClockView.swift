//
//  DrawSavedClockView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 29.12.21.
//

import PencilKit
import opencv2
import SwiftUI
import RealmSwift

struct DrawSavedClockView: View {
    
    @StateRealmObject var savedClock: SavedClock
    
    @State var showImagePicker = false
    @StateObject var clockAnalyzer = ClockAnalyzer()
    @State var drawingRect = CGRect()
    @State var drawing = PKDrawing()
    
    //@State var backgroundImage = UIImage()
    
    @State var showResult = false
    
    @Binding var rootIsActive: Bool
    
    
    
    var body: some View {
        VStack {
            NavigationLink(isActive: self.$showResult) {
                NavigationLazyView(ResultView(shouldPopToRootView: self.$rootIsActive, clockAnalyzer: self.clockAnalyzer))
            } label: {
                EmptyView()
            }.isDetailLink(false)

            ZStack {
                Image(uiImage: self.savedClock.backgroundImage).resizable().aspectRatio(contentMode: .fit)
                    .offset(x: CGFloat(savedClock.backgroundOffsetX), y: CGFloat(savedClock.backgroundOffsetY))
                    .scaleEffect(CGFloat(savedClock.backgroundZoom))
                Circle().stroke(Color.black, lineWidth: 2).padding(10)
                DrawingView(drawing: self.$drawing, firstStrokeDate: self.$clockAnalyzer.firstStrokeDate)
            }.aspectRatio(1, contentMode: .fit).background(GeometryGetter(rect: self.$drawingRect))
            Spacer()
            HStack {
                Button {
                    showImagePicker = true
                } label: {
                    Text("Choose Background").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.purple.cornerRadius(20))
                }.buttonStyle(PlainButtonStyle()).padding()
                Button {
                    self.drawing = PKDrawing()
                } label: {
                    Text("Clear Clock").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.red.cornerRadius(20))
                }.buttonStyle(PlainButtonStyle()).padding()
                Button {
                    clockAnalyzer.startAnalysis(clockImage: generateClockImage(), fatClockImage: generateFatClockImage(), onCompletion: {
                        self.showResult = true
                    })
                } label: {
                    Text("Analyze").font(.system(size: 25, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
                }.buttonStyle(PlainButtonStyle()).padding()
                
                
            }
            buttonStack
        }.padding(UIDevice.current.userInterfaceIdiom == .pad ? 50 : 10)
            .onAppear {
                self.drawing = self.savedClock.drawing
            }
            .onDisappear {
                let thawed = self.$savedClock.wrappedValue
                if let realm = thawed.realm {
                    try! realm.write {
                        thawed.drawing = self.drawing
                        thawed.thumbnail = self.generateClockImage()
                        thawed.width = Float(drawingRect.width)
                        thawed.height = Float(drawingRect.height)
                    }
                }
               
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: .photoLibrary) { image in
                    let thawed = self.$savedClock.wrappedValue
                    if let realm = thawed.realm {
                        try! realm.write {
                            thawed.backgroundImage = cutImageToCircle(image: image)
                            print("Save")
                        }
                    }
                    
                }
            }
            
    }
    
    var buttonStack: some View {
        HStack {
            let fontSize: CGFloat = 20
            Button {
                let thawed = self.$savedClock.wrappedValue
                if let realm = thawed.realm {
                    try! realm.write {
                        thawed.backgroundOffsetX -= 5
                    }
                }
            } label: {
                Image(systemName: "arrow.left").font(.system(size: fontSize, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
            }.buttonStyle(PlainButtonStyle()).padding()
            Button {
                let thawed = self.$savedClock.wrappedValue
                if let realm = thawed.realm {
                    try! realm.write {
                        thawed.backgroundOffsetX += 5
                    }
                }
            } label: {
                Image(systemName: "arrow.right").font(.system(size: fontSize, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
            }.buttonStyle(PlainButtonStyle()).padding()
            
            Button {
                let thawed = self.$savedClock.wrappedValue
                if let realm = thawed.realm {
                    try! realm.write {
                        thawed.backgroundOffsetY += 5
                    }
                }
            } label: {
                Image(systemName: "arrow.up").font(.system(size: fontSize, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
            }.buttonStyle(PlainButtonStyle()).padding()
            Button {
                let thawed = self.$savedClock.wrappedValue
                if let realm = thawed.realm {
                    try! realm.write {
                        thawed.backgroundOffsetY -= 5
                    }
                }
            } label: {
                Image(systemName: "arrow.down").font(.system(size: fontSize, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
            }.buttonStyle(PlainButtonStyle()).padding()
            
            Button {
                let thawed = self.$savedClock.wrappedValue
                if let realm = thawed.realm {
                    try! realm.write {
                        thawed.backgroundZoom += 0.05
                    }
                }
            } label: {
                Image(systemName: "plus").font(.system(size: fontSize, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
            }.buttonStyle(PlainButtonStyle()).padding()
            Button {
                let thawed = self.$savedClock.wrappedValue
                if let realm = thawed.realm {
                    try! realm.write {
                        thawed.backgroundZoom -= 0.05
                    }
                }
            } label: {
                Image(systemName: "minus").font(.system(size: fontSize, weight: .semibold, design: .default)).foregroundColor(.white).font(.title).padding().background(Color.green.cornerRadius(20))
            }.buttonStyle(PlainButtonStyle()).padding()
        }
    }
    
    func cutImageToCircle(image: UIImage) -> UIImage {
        var imageMat = Mat(uiImage: image, alphaExist: false)
        var safeMat = Mat(uiImage: image, alphaExist: false)
        
        Imgproc.cvtColor(src: imageMat, dst: imageMat, code: ColorConversionCodes.COLOR_RGB2GRAY) // COLOR_BGR2GRAY
        Imgproc.threshold(src: imageMat, dst: imageMat, thresh: 200, maxval: 255, type: ThresholdTypes.THRESH_BINARY_INV)
        
        var kernel = Imgproc.getStructuringElement(shape: MorphShapes.MORPH_RECT, ksize: Size2i(width: 3, height: 3))
        Imgproc.dilate(src: imageMat, dst: imageMat, kernel: kernel, anchor: Point2i(x: -1, y: -1), iterations: 5)
        
        let hierarchy = Mat()
        var contours: [[Point]] = [[]]
        let contourImage = imageMat.clone()
        
        // FIND CONTOURS
        Imgproc.findContours(image: imageMat, contours: &contours, hierarchy: hierarchy, mode: RetrievalModes.RETR_EXTERNAL, method: ContourApproximationModes.CHAIN_APPROX_SIMPLE)
        
        for contour in contours {
            if
                let minX = contour.min(by: {$0.x < $1.x})?.x,
                let minY = contour.min(by: {$0.y < $1.y})?.y,
                let maxX = contour.max(by: {$0.x < $1.x})?.x,
                let maxY = contour.max(by: {$0.y < $1.y})?.y {
               
                // CALCULATE BOUDING RECT
                let width = maxX - minX
                let height = maxY - minY
                
                if width >= 230 && height >= 230 {
                    let boundRect = Rect2i(x: minX, y: minY, width: width, height: height)
                    // DRAW CONTOUR TO IMAGE
                    return Mat(mat: safeMat, rect: boundRect).toUIImage()
                }
            }
        }
        //UIImageWriteToSavedPhotosAlbum(imageMat.toUIImage(), nil, nil, nil)
        /*
        var circles = Mat()
        
        Imgproc.HoughCircles(image: imageMat, circles: circles, method: HoughModes.HOUGH_GRADIENT, dp: 2, minDist: 1, param1: 100, param2: 10, minRadius: 235, maxRadius: 250)
        //Imgproc.HoughCircles(image: imageMat, circles: circles, method: HoughModes.HOUGH_GRADIENT, dp: 1.2, minDist: 100)
        for i in 0..<circles.rows() {
            
            let data = circles.get(row: i, col: 0)
            var center = Point2i(x: Int32(data[1]), y: Int32(data[0]));
            var radius = Int32(data[2])
            print("FOUND CIRCLE WITH RADIUS \(radius) and center \(center)")
            
            
            let boundRect = Rect2i(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2)
            Imgproc.circle(img: imageMat, center: center, radius: radius, color: Scalar(255), thickness: 10)
            Imgproc.rectangle(img: imageMat, rec: boundRect, color: Scalar(255), thickness: 5)
            
            UIImageWriteToSavedPhotosAlbum(imageMat.toUIImage(), nil, nil, nil)
            return Mat(mat: safeMat, rect: boundRect).toUIImage()
            
        }*/
        
        
        return UIImage()
    }
    
    func generateClockImage() -> UIImage {
        var image = drawing.image(from: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: drawingRect.size.width, height: drawingRect.size.height)), scale: 1)
        return image
    }
    
    func generateFatClockImage() -> UIImage {
        return drawing.changeLineWidth(by: CGFloat(Config.changeLineWidthOfDrawingBy)).image(from: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: drawingRect.size.width, height: drawingRect.size.height)), scale: 1)
    }
}
