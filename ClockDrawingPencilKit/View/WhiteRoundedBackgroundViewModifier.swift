//
//  WhiteRoundedBackgroundViewModifier.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 13.11.21.
//

import SwiftUI

struct WhiteRoundedBackgroundViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color(.systemBackground).cornerRadius(10))
    }
}

extension View {
    func whiteRoundedBackground() -> some View {
        modifier(WhiteRoundedBackgroundViewModifier())
    }
}
