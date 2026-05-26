# ToDoApp

A SwiftUI iOS app for planning a family's day, week, and weekend — built
around **dated tasks** shown through four simple views: **Home**,
**Today**, **Week**, and **Weekend**.

Built collaboratively as a class project by Chris Thorne and Sabrina
Schubert, designed from a real user interview.

## The idea

The interview described a family juggling several separate Google Keep
lists — a daily list, a weekly plan, and a weekend list — with tasks
constantly needing to be shuffled between them. ToDoApp replaces that
with **one set of tasks, each assigned to a day**. The planner tabs
aren't separate lists; they're three windows onto those same tasks, so
nothing ever has to be copied or moved between lists by hand.

## How it works

Every task belongs to a **day**. Four tabs let you see your tasks through
different lenses:

- **Home** — a family dashboard: how many tasks the family has knocked
  out this week, a per-person split, an activity feed of recent
  completions, and a celebration when everything for today is done.
- **Today** — tasks due today. Anything left unfinished from earlier is
  carried forward into an "Earlier" section, so nothing silently slips
  away.
- **Week** — the current week, Monday through Sunday, as one section per
  day. Empty past days are hidden, days collapse to stay tidy, and today
  is highlighted.
- **Weekend** — Saturday and Sunday, always shown together.

A task added under Thursday automatically appears in the Week view and,
when Thursday arrives, in Today — no duplication.

### Working with tasks

| Action | How |
|---|---|
| Add a task | Tap the "Add a task" row under any day and type. Press Return to add it and immediately start the next one. |
| Add a time | Type it inline — "3pm pick up Alex", "Saturday groceries at 9:30am". The time is pulled into a chip on the row; the title is cleaned up automatically. |
| Edit a task | Tap its title and type. |
| Complete a task | Tap the checkbox. Finished tasks collect in a "Completed" section you can expand. |
| Move a task to another day | Swipe the task → **Move** → choose **Tomorrow**, **This Weekend**, or pick any date. |
| Reorder tasks within a day | Tap **Edit**, then drag. |
| Delete a task | Swipe it away, or use Edit mode. |
| Filter by person | Tap the **people icon** in the toolbar — All / Alex / Sam. |
| Start fresh | Settings → **Clear All Tasks** (asks to confirm first). |

Each tab has its own accent color — Home indigo, Today orange, Week
blue, Weekend green — so it's always clear which view you're in.

## Hold a task to add extras

Long-press (touch and hold) any task to reveal a small popover with four
options for adding richer detail to it:

- **Time** — set or change the task's time of day. Timed tasks float to
  the top of their day.
- **Repeat** — make the task recur **Daily**, **Weekly**, or **Every 3
  days**. Completing a recurring task spawns the next instance
  automatically.
- **Assign** — assign to one of two mock users for the demo, **Alex**
  (blue) or **Sam** (purple). A small colored chip appears on the row
  showing who owns it. (In a real release these would be real iCloud
  family members.)
- **Attach** — attach a **Map** (an address that opens in Apple Maps on
  tap) or a **List** (an inline checklist that expands below the task
  with a top-to-bottom item reveal animation).

Nothing is shown on a task until you add it — the row stays clean by
default and surfaces a chip / pin / chevron only once you've actually
attached something.

## Home tab

The Home tab is the shared overview a partner sees first:

- **"This Week" card** — total tasks completed this week, plus the
  split between Alex and Sam.
- **Celebration banner** — when everything dated today is checked off
  and there was at least one task to start with, a banner appears with
  a brief confetti animation (shown once per day).
- **Recent Activity** — the last few completed tasks with who completed
  them and a relative timestamp. **Tap any activity row** to bring up a
  small emoji reaction picker (🙏 ❤️ 🎉 👏 🔥); reactions show inline
  on the task.

## Week's Focus / Weekend's Focus

The text field at the top of the Week and Weekend tabs is a free-form
"what do you want to focus on this week / weekend?" prompt. The two
prompts are stored separately, so the Week and Weekend tabs can carry
different intentions, and the storage rolls over with the ISO week.

## What it solves

Each feature traces back to something the interview surfaced:

| From the interview | How ToDoApp addresses it |
|---|---|
| Tasks were awkward to shuffle between separate week/weekend lists | Tasks aren't in separate lists — each has a day; re-dating one moves it between views automatically |
| No sense of when something actually got done | Completing a task timestamps it; finished tasks gather in a dated "Completed" section, and the Home tab surfaces the activity |
| The plan wasn't visible at a glance like a fridge calendar | A widget puts the day's tasks on the Home Screen, Lock Screen, and StandBy |
| Hard to decide if something was a weekday or weekend task | You just give it a day; it surfaces in whichever view that day belongs to |
| Hard to coordinate who is doing what | Tasks can be assigned to a person; the planner filter and the Home dashboard summarize ownership |
| Hard to remember context (where? what items?) | Map and list attachments live on the task itself |

## Tech overview

- **SwiftUI** for the interface, **SwiftData** for storage, **WidgetKit**
  for the widget.
- A single `TodoItem` SwiftData model carries the title, day, completion
  timestamp, plus optional time, assignee id, recurrence link, reactions,
  and an attachment payload. The planner views are lenses over a single
  `@Query` of those items.
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

Several of the later features — assignees, the Home tab, recurring
tasks, time-of-day, task attachments — were built in **parallel by
multiple Claude Code sub-agents** working in isolated git worktrees,
then merged back into the main branch. That build → run → screenshot
loop is how nearly every feature here was checked before moving on. To
reproduce the workflow, install XcodeBuildMCP and run Claude Code in
this repository. None of it is required just to build the app — the
`xcodegen` + Xcode steps above are enough on their own.

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
    TodoItem.swift              A task — title, day, completion, time,
                                assignee, recurrence, reactions, attachment
                                (SwiftData @Model)
    TaskScope.swift             The planner tabs: Today / Week / Weekend
    Assignee.swift              Mock users (Alex, Sam) for the demo
    RecurrenceRule.swift        Daily / Weekly / Every-N-days (SwiftData @Model)
    TaskAttachment.swift        Map or List attachment + codable accessor
    CalendarHelper.swift        Week and weekend date math (Monday-start)
    WeekFocus.swift             Per-week (and per-weekend) focus storage
  Persistence/
    AppConfig.swift             The CloudKit on/off switch
    ModelContainer+Shared.swift The on-device data store
    SharedAppGroup.swift        Shared storage location for the widget
    DemoSeeder.swift            Seeds the two demo tasks on first launch
  Views/
    RootTabView.swift           The four-tab shell
    HomeView.swift              Home dashboard — stats, activity, reactions, confetti
    PlannerView.swift           The main planner — day sections, inline add
    TaskRow.swift               A task row + the long-press action popover
                                (also defines ChecklistRow for inline lists)
    WeekFocusBanner.swift       The Week's / Weekend's Focus text field
    RescheduleSheet.swift       The "Move" sheet (Tomorrow / Weekend / date)
    SettingsView.swift          Settings — sharing, clear data, version
    ShareSheetView.swift        CloudKit share sheet wrapper (scaffold)
ToDoAppWidget/                  The Home Screen / Lock Screen / StandBy widget
project.yml                     xcodegen project definition
```
