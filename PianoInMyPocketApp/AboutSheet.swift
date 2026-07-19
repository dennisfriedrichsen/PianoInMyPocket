//
//  AboutSheet.swift
//  PianoInMyPocket
//
//  Created by Dennis Friedrichsen on 7/19/26.
//

import SwiftUI

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                        Text("Version " + appVersion)
                    }
                    Text("© 2026 Dennis R. Friedrichsen")
                    Link("Website",
                          destination: URL(string: "http://pianoinmypocket.friedrichsenweb.com/index.html")!)
                    Link("Privacy Policy",
                          destination: URL(string: "http://pianoinmypocket.friedrichsenweb.com/privacy.html")!)
                    Link("Help",
                          destination: URL(string: "http://pianoinmypocket.friedrichsenweb.com/help.html")!)
                    Link("Issues Tracker (github.com)",
                          destination: URL(string: "https://github.com/dennisfriedrichsen/PianoInMyPocket")!)
                    Link("Buy me a coffee!",
                         destination: URL(string: "https://www.buymeacoffee.com/drfriedrichsen")!)
                }
            }
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}


#Preview {
    AboutSheet()
}
