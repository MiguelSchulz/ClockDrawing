//
//  SavedClockCellView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 29.12.21.
//

import SwiftUI
import RealmSwift

struct SavedClockCellView: View {
    
    @ObservedRealmObject var clock: SavedClock
    
    var body: some View {
        VStack {
            CircleDrawingImageOverlay(image: clock.thumbnail)
            Text("\(clock.rightScore)")
        }.padding().background(Color(.systemGroupedBackground).cornerRadius(10))
    }
}

struct SavedClockCellView_Previews: PreviewProvider {
    static var previews: some View {
        SavedClockCellView(clock: SavedClock())
    }
}
