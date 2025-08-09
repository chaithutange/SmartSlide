//
//  ShareSheet.swift
//  NumberSeqGame
//
//  Created by Chaithanya Tangellapalli on 8/9/25.
//


import SwiftUI
import UIKit

// MARK: - View Snapshot Extension
extension UIView {
    /// Capture the view hierarchy as a UIImage
    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in
            layer.render(in: ctx.cgContext)
        }
    }
}

// MARK: - Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
