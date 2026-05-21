# ToDoApp

A SwiftUI iOS to-do app for family coordination, with three list types
(Today / Week / Weekend), on-device SwiftData persistence, and a CloudKit-
ready sync path. Built as a class project from a real user interview.

## Pain points it solves

| Pain point | Solution |
|---|---|
| Poor flow between week and weekend lists | One-tap "Move to scope" via row context menu and leading swipe |
| No accountability for when tasks were finished | `completedAt` timestamp; rows show "Done Xm ago"; "Recently completed" disclosure at the bottom of each list |
| Not visible like a fridge calendar | Home Screen / Lock Screen / StandBy widget (Checkpoint F) |
| Hard to decide weekend vs weekday | Three-tab navigation makes the choice the primary action; segmented scope picker on the add-task sheet |

## Requirements

- macOS with Xcode 17+ (built against Xcode 26.5 / iOS 26.5 SDK)
- [`xcodegen`](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- (Optional) Paid Apple Developer Program — required only to enable CloudKit sync

## Build and run

```
xcodegen generate
open ToDoApp.xcodeproj
```

Pick an iPhone simulator and run.

The Xcode project is **generated** from `project.yml`. Re-run `xcodegen
generate` after adding or moving source files outside Xcode.

## Enabling CloudKit sync (optional)

The repo ships with iCloud sync **off** because enabling it requires a
paid Apple Developer Program membership to create a CloudKit container
and provision the iCloud entitlement.

1. In Xcode, open the `ToDoApp` target → **Signing & Capabilities**.
2. Set **Team** to a paid developer account.
3. Tap **+ Capability** and add **iCloud**.
4. Under iCloud, check **CloudKit** and add a container
   (recommended ID: `iCloud.com.<your-org>.ToDoApp`).
5. Tap **+ Capability** and add **Background Modes** → check
   **Remote notifications**.
6. Tap **+ Capability** and add **Push Notifications**.
7. In `ToDoApp/Persistence/ModelContainer+Shared.swift`, change
   `useCloudKit` to `true`.
8. Build and run on a real device (or simulator) signed in to iCloud.

Without these steps the app uses on-disk SwiftData only — fully
functional, just not synced across devices.

## Sharing with a spouse (scaffold only)

The Settings tab exposes a "Share with spouse" button that presents
`UICloudSharingController` (Checkpoint G). It's wired but not validated
across two real iCloud accounts — that requires the paid developer
account plus two devices with separate iCloud sign-ins and is out of
scope for the class deliverable.

## Project layout

```
ToDoApp/
  ToDoAppApp.swift              @main, injects ModelContainer
  Models/
    TaskScope.swift             enum: daily / weekly / weekend
    TodoItem.swift              SwiftData @Model
  Persistence/
    ModelContainer+Shared.swift on-disk container, CloudKit toggle
  Views/
    RootTabView.swift           three-tab shell
    TaskListView.swift          reusable list keyed by TaskScope; inline add
    TaskRow.swift               row with completion + editable title
    SettingsView.swift          settings sheet + share scaffold
ToDoAppWidget/                  (Checkpoint F — Home Screen / Lock / StandBy)
```
