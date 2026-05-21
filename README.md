# ToDoApp

A SwiftUI iOS to-do app for family coordination. Tasks are dated, and
Today / Week / Weekend are three windows onto the same dated tasks.
On-device SwiftData persistence with a CloudKit-ready sync path. Built
as a class project from a real user interview.

## How the lists work

Every task belongs to a **day**. The three tabs are views, not separate
buckets:

- **Today** — tasks dated today, plus an "Earlier" section that carries
  forward anything overdue so nothing silently expires.
- **Week** — the current week as seven day-sections, each with its own
  inline add row. A task added for Thursday shows here and in Today.
- **Weekend** — the Saturday/Sunday day-sections.

## Pain points it solves

| Pain point | Solution |
|---|---|
| Poor flow between week and weekend lists | Tasks are dated, not bucketed — swipe a task to re-date it via a date picker; it appears in whichever views that day falls into |
| No accountability for when tasks were finished | `completedAt` timestamp; completed tasks show struck-through under their day with "Done Xm ago" |
| Not visible like a fridge calendar | Home Screen / Lock Screen / StandBy widget |
| Hard to decide weekend vs weekday | You pick a day; the task naturally surfaces in the right view |

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

Settings exposes a "Share with spouse" button that presents
`UICloudSharingController`. It's wired but not validated across two real
iCloud accounts — that requires the paid developer account plus two
devices with separate iCloud sign-ins and is out of scope for the class
deliverable.

## Project layout

```
ToDoApp/
  ToDoAppApp.swift              @main, injects ModelContainer
  Models/
    TaskScope.swift             the three tabs (Today/Week/Weekend)
    TodoItem.swift              SwiftData @Model — a dated task
    CalendarHelper.swift        week / weekend day math
  Persistence/
    ModelContainer+Shared.swift on-disk container, CloudKit toggle
  Views/
    RootTabView.swift           three-tab shell
    PlannerView.swift           dated planner; per-day sections + inline add
    TaskRow.swift               row with completion + editable title
    RescheduleSheet.swift       date picker for re-dating a task
    SettingsView.swift          settings sheet + share scaffold
ToDoAppWidget/                  Home Screen / Lock Screen / StandBy widget
```
