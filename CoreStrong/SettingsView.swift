//
//  SettingsView.swift
//  CoreStrong
//
//  Created by John Pickett on 3/9/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultRestDuration") private var defaultRestDuration: Int = 90
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Rest Timer") {
                    Stepper(
                        value: $defaultRestDuration,
                        in: 15...600,
                        step: 15
                    ) {
                        HStack {
                            Text("Default Duration")
                            Spacer()
                            Text(formattedDuration(defaultRestDuration))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Used for exercises that have no custom rest duration set.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }
}
