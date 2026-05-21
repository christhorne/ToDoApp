import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var showingCloudKitAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        if AppConfig.useCloudKit {
                            showingShareSheet = true
                        } else {
                            showingCloudKitAlert = true
                        }
                    } label: {
                        Label("Share with spouse", systemImage: "person.2.fill")
                    }
                } header: {
                    Text("Family sharing")
                } footer: {
                    if !AppConfig.useCloudKit {
                        Text("Sharing is scaffolded but not active until CloudKit is configured. See README → Enabling CloudKit sync.")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Built for", value: "Sabrina")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheetView()
                    .ignoresSafeArea()
            }
            .alert("CloudKit not configured", isPresented: $showingCloudKitAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("To enable share-with-spouse, configure the iCloud capability in Xcode and flip `AppConfig.useCloudKit` to true. See README.")
            }
        }
    }
}

#Preview {
    SettingsView()
}
