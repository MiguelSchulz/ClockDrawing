//
//  CriteriaListItemView.swift
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 13.11.21.
//

import SwiftUI

enum CriteriaRating: String {
    case right = "checkmark.circle"
    case unsure = "questionmark.circle"
    case wrong = "xmark.circle"
    
    var symbol: some View {
        return Image(systemName: self.rawValue).foregroundColor(color).font(.title2)
    }
    
    private var color: Color {
        switch self {
        case .right:
            return Color(.systemGreen)
        case .unsure:
            return Color(.systemYellow)
        case .wrong:
            return Color(.systemRed)
        }
    }
}

struct CriteriaListItemView: View {

    var criteriaRating = CriteriaRating.right
    var explanation = "You passed because of blablabla  blablabla  blablabla  blablabla  blablabla  blablabla  blablabla  blablabla  blablabla  blablabla "
    
    var body: some View {
        HStack {
            criteriaRating.symbol
            Text(explanation).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct CriteriaListItemView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            CriteriaListItemView(criteriaRating: .right)
            CriteriaListItemView(criteriaRating: .unsure)
            CriteriaListItemView(criteriaRating: .wrong)
        }
    }
}
