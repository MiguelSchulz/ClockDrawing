//
//  SimpleCanvasView.swift
//  PlanInk
//
//  Created by Miguel Schulz on 08.12.20.
//

import SwiftUI
import PencilKit


struct DrawingView: UIViewRepresentable {
    
    var ignoreDarkmode = false
    @Binding var drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        if(ignoreDarkmode) {
            canvas.overrideUserInterfaceStyle = .light
        }
        
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            canvas.tool = PKInkingTool(.pen, color: .black, width: 12)
        }
        
        canvas.becomeFirstResponder()

        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        //PKToolPicker.shared.addObserver(uiView)
        if(uiView.drawing.dataRepresentation().count != self.drawing.dataRepresentation().count) {
            uiView.drawing = self.drawing
        }
        
        //PKToolPicker.shared.setVisible(PKToolPicker.visible, forFirstResponder: uiView)
        DispatchQueue.main.async {
            //uiView.becomeFirstResponder()
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
  // MARK: - Coordinator

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingView
        
        init(parent: DrawingView) {
            
            self.parent = parent
            super.init()
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            //shouldUpdate = true
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
           // if(!parent.programChange.programChange) {
               // parent.drawing = canvasView.drawing
            DispatchQueue.main.async {
                self.parent.drawing = canvasView.drawing
            }
            //}
        }
        
       
    }
}
