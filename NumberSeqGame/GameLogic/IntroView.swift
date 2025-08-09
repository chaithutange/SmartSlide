//
//  IntroView.swift
//  NumberSeqGame
//
//  Created by Chaithanya Tangellapalli on 8/8/25.
//


import SwiftUI

struct IntroView: View {
    @Binding var isPresented: Bool
    var onOpenSettings: () -> Void

    @AppStorage("gridSize") private var gridSize: Int = 3
    @AppStorage("tileColor") private var tileColorRaw: String = TileColorOption.blue.rawValue
    @AppStorage("soundOn") private var soundOn: Bool = true
    @AppStorage("timedMode") private var timedMode: Bool = false

    var body: some View {
        NavigationView {
            TabView {
                // Page 1
                VStack(spacing: 16) {
                    Text("Welcome to SmartSlide").font(.title.bold())
                    Text("Slide tiles to arrange them in order.\nLeave the blank tile at the end.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Image(systemName: "square.grid.3x3.fill").font(.system(size: 64))
                }.padding()

                // Page 2
                VStack(spacing: 16) {
                    Text("How to Play").font(.title.bold())
                    Text("Tap a tile next to the blank space to move it.\nKeep sliding until tiles read 1 → \(gridSize*gridSize - 1).")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Image(systemName: "hand.tap.fill").font(.system(size: 64))
                }.padding()

                // Page 3 — Tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tips & Settings")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                        Text("Change the **grid size** and **tile color** any time: tap the gear → Settings.")
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                        Text("Need a refresher? Tap the **?** icon to reopen this guide.")
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.3x3.fill")
                        Text("New to sliding puzzles? Start with **3×3**. The classic is **4×4**.")
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Toggle **Sound Effects** and **Timed Mode** in Settings.")
                    }

                    Button {
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onOpenSettings()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Open Settings", systemImage: "slider.horizontal.3")
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(10)
                    }
                    .padding(.top, 8)

                    Spacer()
                }
                .padding()

                // Page 4 — Quick settings
                Form {
                    Section(header: Text("Quick Settings")) {
                        Picker("Grid Size", selection: $gridSize) {
                            Text("3 × 3").tag(3)
                            Text("4 × 4").tag(4)
                            Text("5 × 5").tag(5)
                        }
                        Picker("Tile Color", selection: $tileColorRaw) {
                            ForEach(TileColorOption.allCases) { option in
                                Text(option.rawValue).tag(option.rawValue)
                            }
                        }
                        Toggle("Sound Effects", isOn: $soundOn)
                        Toggle("Timed Mode", isOn: $timedMode)
                    }
                    Section {
                        Button {
                            isPresented = false
                        } label: {
                            HStack { Spacer(); Text("Start Playing").bold(); Spacer() }
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .navigationTitle("Getting Started")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { isPresented = false }
                }
            }
        }
    }
}
