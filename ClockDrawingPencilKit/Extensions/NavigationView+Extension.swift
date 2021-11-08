//
//  NavigationView+Extension.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 07.11.21.
//

import SwiftUI
struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
