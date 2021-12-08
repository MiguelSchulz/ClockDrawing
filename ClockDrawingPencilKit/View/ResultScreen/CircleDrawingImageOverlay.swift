//
//  CircleDrawingImageOverlay.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 14.11.21.
//

import SwiftUI

struct CircleDrawingImageOverlay: View {
    
    var image: UIImage
    
    var body: some View {
        ZStack {
            Circle().fill(Color.white).shadow(radius: 4)
            Circle().stroke(Color.black, lineWidth: 3)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }.padding(10)
    }
}

