//
//  TileView.swift
//  NumberSeqGame
//
//  Created by Chaithanya Tangellapalli on 8/9/25.
//


import SwiftUI

struct TileView: View {
    let number: Int
    let fillColor: Color
    let strokeColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(number == 0 ? Color.clear : fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(strokeColor, lineWidth: number == 0 ? 1 : 0)
                )

            if number != 0 {
                Text("\(number)")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .shadow(radius: 1)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
    }
}
