//
//  TileColorOption.swift
//  NumberSeqGame
//
//  Created by Chaithanya Tangellapalli on 8/8/25.
//


import SwiftUI

enum TileColorOption: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"

    var fillColor: Color {
        switch self {
        case .blue:   return Color.blue.opacity(0.8)
        case .purple: return Color.purple.opacity(0.8)
        case .pink:   return Color.pink.opacity(0.8)
        }
    }
    
    var strokeColor: Color {
        switch self {
        case .blue:   return Color.blue
        case .purple: return Color.purple
        case .pink:   return Color.pink
        }
    }
}
