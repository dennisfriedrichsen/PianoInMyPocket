//
//  AboutSheet.swift
//  PianoInMyPocket
//
//  Created by Dennis Friedrichsen on 7/19/26.
//

import SwiftUI

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    var body: some View {
        NavigationStack {
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let appVersion {
                            Text("Version " + appVersion)
                        }
                        Text("© 2026 Dennis R. Friedrichsen")
                    }
                    .foregroundStyle(.secondary)

                    AboutLinkRow(title: "Website",
                                 destination: URL(string: "http://pianoinmypocket.friedrichsenweb.com/index.html")!)
                    AboutLinkRow(title: "Privacy Policy",
                                 destination: URL(string: "http://pianoinmypocket.friedrichsenweb.com/privacy.html")!)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                VStack(alignment: .leading, spacing: 18) {
                    AboutLinkRow(title: "Help",
                                 destination: URL(string: "http://pianoinmypocket.friedrichsenweb.com/help.html")!)
                    AboutLinkRow(title: "Issues Tracker (github.com)",
                                 destination: URL(string: "https://github.com/dennisfriedrichsen/PianoInMyPocket")!)
                    AboutLinkRow(title: "Buy me a coffee!",
                                 destination: URL(string: "https://www.buymeacoffee.com/drfriedrichsen")!)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
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

private struct AboutLinkRow: View {
    let title: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}


#Preview {
    AboutSheet()
}
