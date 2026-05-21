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
                        Label("Share this list", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Sharing")
                } footer: {
                    if !AppConfig.useCloudKit {
                        Text("Syncing your lists across devices isn't available yet.")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
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
            .alert("Sharing isn't available yet", isPresented: $showingCloudKitAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Syncing your lists across devices will be available in a future update.")
            }
        }
    }
}

#Preview {
    SettingsView()
}
