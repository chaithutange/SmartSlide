//
//  SettingsView.swift
//  NumberSeqGame
//
//  Created by Chaithanya Tangellapalli on 8/8/25.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("playerName") var playerName: String = ""
    @AppStorage("gridSize") var gridSize: Int = 3
    @AppStorage("timedMode") var timedMode: Bool = false
    @AppStorage("tileColor") var tileColorRaw: String = TileColorOption.blue.rawValue
    @AppStorage("soundOn") var soundOn: Bool = true
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Profile")) {
                    TextField("Player Name (optional)", text: $playerName)
                }
                
                Section(header: Text("Game Settings")) {
                    Picker("Grid Size", selection: $gridSize) {
                        Text("3 × 3").tag(3)
                        Text("4 × 4").tag(4)
                        Text("5 × 5").tag(5)
                    }
                    Toggle("Timed Mode", isOn: $timedMode)
                }
                
                Section(header: Text("Appearance")) {
                    Picker("Tile Color", selection: $tileColorRaw) {
                        ForEach(TileColorOption.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                }
                
                Section(header: Text("Sound")) {
                    Toggle("Sound Effects", isOn: $soundOn)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}
