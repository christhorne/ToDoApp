import Foundation

enum AppConfig {
    // Flip to `true` after wiring the iCloud + CloudKit capability and a
    // real development team in Xcode → Target → Signing & Capabilities.
    // See README → Enabling CloudKit sync.
    static let useCloudKit = false
}
