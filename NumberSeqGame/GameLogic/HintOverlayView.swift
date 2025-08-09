import SwiftUI

struct HintOverlayView: View {
    /// Called when the overlay is dismissed.
    /// - Parameter dontShowAgain: true if user tapped "Don’t show again".
    var onDismiss: (_ dontShowAgain: Bool) -> Void

    @State private var slide: Bool = false
    @State private var tapPulse: Bool = false

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 16) {
                Text("How to Move")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("Tap a tile **next to** the blank space to slide it.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))

                // Mini demo: tile -> blank + tapping hand
                ZStack {
                    demoBoard
                    handTap
                }
                .frame(width: 220, height: 120)

                HStack(spacing: 12) {
                    Button(role: .cancel) {
                        onDismiss(false)
                    } label: {
                        Text("Got it")
                            .font(.headline)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }

                    Button {
                        onDismiss(true)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.slash")
                            Text("Don’t show again")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 6)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                slide = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2).repeatForever(autoreverses: true)) {
                tapPulse = true
            }
        }
    }

    // MARK: - Pieces

    private var demoBoard: some View {
        // Two squares: left = tile, right = blank
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.85))
                .overlay(Text("12").font(.headline).foregroundColor(.white))
                .frame(width: 70, height: 70)
                .offset(x: slide ? 42 : 0) // slide right

            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.gray.opacity(0.7), lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.clear))
                .frame(width: 70, height: 70)
                .offset(x: slide ? -42 : 0) // blank shifts opposite for effect
        }
    }

    private var handTap: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: tapPulse ? 52 : 36, height: tapPulse ? 52 : 36)
                        .opacity(tapPulse ? 0.2 : 0.5)
                    Image(systemName: "hand.tap")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
                .offset(x: -40, y: -16) // position near the moving tile
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
