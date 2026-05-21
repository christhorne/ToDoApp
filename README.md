# ToDoApp

A SwiftUI iOS app for planning a family's day, week, and weekend — built
around **dated tasks** shown through three simple views: **Today**,
**Week**, and **Weekend**.

Built as a class project, designed from a real user interview.

## The idea

The interview described a family juggling several separate Google Keep
lists — a daily list, a weekly plan, and a weekend list — with tasks
constantly needing to be shuffled between them. ToDoApp replaces that
with **one set of tasks, each assigned to a day**. The three tabs aren't
separate lists; they're three windows onto those same tasks, so nothing
ever has to be copied or moved between lists by hand.

## How it works

Every task belongs to a **day**. The three tabs are lenses on the same
dated tasks:

- **Today** — tasks due today. Anything left unfinished from earlier is
  carried forward into an "Earlier" section, so nothing silently slips
  away.
- **Week** — the current week, Monday through Sunday, as one section per
  day. Empty past days are hidden, days collapse to stay tidy, and today
  is highlighted.
- **Weekend** — Saturday and Sunday, always shown together.

A task added under Thursday automatically appears in the Week view and,
when Thursday arrives, in Today — no duplication.

### What you can do

| Action | How |
|---|---|
| Add a task | Tap the "Add a task" row under any day and type. Press Return to add it and immediately start the next one. |
| Edit a task | Tap its title and type. |
| Complete a task | Tap the checkbox. Finished tasks collect in a "Completed" section you can expand. |
| Move a task to another day | Swipe the task → **Move** → choose **Tomorrow**, **This Weekend**, or pick any date. |
| Reorder tasks within a day | Tap **Edit**, then drag. |
| Delete a task | Swipe it away. |
| Start fresh | Settings → **Clear All Tasks** (asks to confirm first). |

Each tab has its own accent color — Today orange, Week blue, Weekend
green — so it's always clear which view you're in.

## What it solves

Each feature traces back to something the interview surfaced:

| From the interview | How ToDoApp addresses it |
|---|---|
| Tasks were awkward to shuffle between separate week/weekend lists | Tasks aren't in separate lists — each has a day; re-dating one moves it between views automatically |
| No sense of when something actually got done | Completing a task timestamps it; finished tasks gather in a dated "Completed" section |
| The plan wasn't visible at a glance like a fridge calendar | A widget puts the day's tasks on the Home Screen, Lock Screen, and StandBy |
| Hard to decide if something was a weekday or weekend task | You just give it a day; it surfaces in whichever view that day belongs to |

## Tech overview

- **SwiftUI** for the interface, **SwiftData** for storage, **WidgetKit**
  for the widget.
- Tasks persist on-device automatically. The data layer is
  **CloudKit-ready** — cross-device sync can be switched on with a paid
  Apple Developer account (see below).
- Targets iOS 17+, built with Xcode 26.

## Requirements

- macOS with Xcode 17 or newer
- [`xcodegen`](https://github.com/yonaskolb/XcodeGen) — install with
  `brew install xcodegen`
- (Optional) A paid Apple Developer Program membership — only needed to
  turn on CloudKit sync

## Building and running

The Xcode project is **generated** from `project.yml` rather than
hand-edited. To build:

```sh
xcodegen generate
open ToDoApp.xcodeproj
```

Then pick an iPhone simulator in Xcode and press Run.

Re-run `xcodegen generate` any time source files are added, moved, or
deleted outside of Xcode.

## How this app was built

This project was developed iteratively with
[Claude Code](https://www.anthropic.com/claude-code), Anthropic's
command-line AI coding agent, working through the
[XcodeBuildMCP](https://xcodebuildmcp.com) server.

XcodeBuildMCP connects an AI agent directly to Xcode and the iOS
simulator. It was used heavily throughout this project to:

- generate and inspect the Xcode project,
- build the app and surface compile errors,
- install and launch it on the simulator,
- capture screenshots to visually review each change.

That build → run → screenshot loop is how nearly every feature here was
checked before moving on. To reproduce the workflow, install
XcodeBuildMCP and run Claude Code in this repository. None of it is
required just to build the app — the `xcodegen` + Xcode steps above are
enough on their own.

## Enabling CloudKit sync (optional)

The app ships with cross-device sync **off**, because turning it on
requires a paid Apple Developer Program membership to create a CloudKit
container.

1. In Xcode, open the **ToDoApp** target → **Signing & Capabilities**.
2. Set **Team** to a paid developer account.
3. Add the **iCloud** capability, check **CloudKit**, and add a container
   (e.g. `iCloud.com.<your-name>.ToDoApp`).
4. Add the **Background Modes** capability and check
   **Remote notifications**.
5. Add the **Push Notifications** capability.
6. In `ToDoApp/Persistence/AppConfig.swift`, change `useCloudKit` to
   `true`.
7. Build and run on a device or simulator signed in to iCloud.

Without these steps the app still works fully — it just keeps data on
one device.

## Sharing (not yet active)

Settings includes a "Share this list" button. The sharing flow is
scaffolded — it presents Apple's `UICloudSharingController` — but is not
active: verifying it across two real iCloud accounts needs the paid
developer account and two devices, which is out of scope for this class
deliverable. Settings shows a plain-language note explaining this.

## Project layout

```
ToDoApp/
  ToDoAppApp.swift              App entry point; sets up storage
  Models/
    TodoItem.swift              A task — title, day, completion (SwiftData model)
    TaskScope.swift             The three tabs: Today / Week / Weekend
    CalendarHelper.swift        Week and weekend date math (Monday-start)
  Persistence/
    AppConfig.swift             The CloudKit on/off switch
    ModelContainer+Shared.swift The on-device data store
    SharedAppGroup.swift        Shared storage location for the widget
  Views/
    RootTabView.swift           The three-tab shell
    PlannerView.swift           The main planner — day sections, inline add
    TaskRow.swift               A single task row
    RescheduleSheet.swift       The "Move" sheet (Tomorrow / Weekend / date)
    SettingsView.swift          Settings — sharing, clear data, version
    ShareSheetView.swift        CloudKit share sheet wrapper (scaffold)
ToDoAppWidget/                  The Home Screen / Lock Screen / StandBy widget
project.yml                     xcodegen project definition
```
