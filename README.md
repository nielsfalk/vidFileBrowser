# VidFileBrowser

VidFileBrowser is a macOS application that combines a file browser with a video and image player. It is built for quickly reviewing, trimming, labeling and sorting large collections of media files, mostly from the keyboard.

## Platform

- macOS 14 (Sonoma) or later
- Distributed through the Mac App Store (sandboxed)
- Because of the sandbox, the user must grant access to folders (via an open dialog or by dropping a folder onto the app). Granted folders are remembered across launches.

## Tech stack

**Recommended: Swift + SwiftUI, with AppKit where needed, and AVFoundation.**

- **SwiftUI** for the window layout, controls and settings.
- **AppKit** for the parts SwiftUI handles poorly on macOS: the file list (`NSTableView`), context menus (`NSMenu`) that can be opened and navigated from the keyboard, drag and drop, and the responder chain in fullscreen.
- **AVFoundation / AVKit** for playback, seeking and lossless, keyframe-snapped trimming (`AVAssetExportSession` with passthrough). Hardware-accelerated and native.
- **Finder integration** through system APIs: tags and label colors via `URLResourceValues` (`tagNames`, `labelNumber`), drag and drop, copy/cut/paste via `NSPasteboard` and `NSItemProvider`.
- **Sandboxed App Store build**: folder access through security-scoped bookmarks so granted folders survive relaunches.

Fallbacks, if needed later:

- **MKV, WebM, AVI support:** keep AVPlayer for MP4/MOV and add **libmpv or VLCKit** as a fallback player, with bundled **ffmpeg** for trimming those formats. This increases app size and licensing/compliance work.
- **Maximum control** over menus, table dragging and fullscreen: use **pure AppKit** instead of SwiftUI.

Not recommended: **Electron, Tauri, Flutter and Compose Desktop**. Each requires native bridging for Finder tags, drag and drop, sandbox bookmarks and drawing the progress bar over video, while giving a less native feel and (except Tauri) a much larger footprint.

## Window layout

```
+-------------------------------------------------------------+
| Breadcrumb path                                             |
+----------------------+--------------------------------------+
| Sort: [Name v] [^/v] |                                      |
|----------------------|                                      |
| Name   | Sort  | Tags|            Player                    |
| ...    | ...   | ... |                                      |
|        |       |     |                                      |
|        |       |     |  [=========o--------------------]    |
+----------------------+--------------------------------------+
```

- The divider between the file browser and the player can be resized.
- On launch, the app reopens the last folder and restores the window size, position and divider position.

## Breadcrumb path

The breadcrumb path sits at the top of the window and shows the current folder path. Each part of the path can be clicked to jump to that folder.

## File browser

The file browser sits on the left side of the window and lists all files and folders in the current folder.

### Columns

1. **Name**: the file or folder name
2. **Sort value**: the value of the current sort property (date, size, ...). Hidden when sorting by name.
3. **Tags**: the colors of the macOS Finder tags on the file

### Sorting

- A dropdown above the list selects the sort property: **Name**, **Date**, **Label**, **Size**.
- A toggle next to it switches between ascending and descending order.
- Folders are always listed before files.
- The sort setting applies to all folders and is remembered across launches.

### Navigation

- Up/Down moves the selection.
- Enter or double-click opens a folder.
- Selecting a playable file shows it in the player.
- Non-media files are listed but cannot be played.

### Drag and drop

Files can be dropped into the file browser (see [Drag and drop, copy and paste](#drag-and-drop-copy-and-paste)).

## Player

The player sits on the right side of the window and shows the file selected in the file browser.

### Videos

- A newly selected video starts playing automatically.
- When a video ends, playback stops on the last frame.
- A clickable progress bar at the bottom of the player shows the current position. Clicking it jumps to that position.
- The progress bar hides after a short period of mouse inactivity and reappears when the mouse moves.

### Images

- Images are displayed fitted to the player area.
- The user can zoom (pinch, scroll wheel with modifier) and pan (drag) images.

## Trimming

Trimming removes part of the current video, relative to the current playback position:

- **Trim left** (`n`) removes everything **before** the current position.
- **Trim right** (`m`) removes everything **after** the current position.

Behavior:

- Trimming is lossless (no re-encoding), so it is fast and keeps the original quality. The cut point snaps to the nearest keyframe, so it can be slightly off from the exact playback position.
- The trimmed video replaces the original file under the same name.
- The original file is moved to the Trash, so it can be restored from there. There is no in-app undo.
- Finder tags and the file's creation date are kept on the trimmed file.

## Favorite folders

In the settings the user can add, remove and reorder favorite folders. Files can be moved into a favorite folder through the **Move to** submenu of the context menu.

## Context menu

Right-clicking a file in the file browser or in the player opens a context menu with these actions:

- **Move to** ▸ list of favorite folders
- **Tags** ▸ set or remove macOS Finder tags (toggle each tag color; "Remove all tags")
- **Trim left** / **Trim right** (videos only)
- **Rename**
- **Reveal in Finder**
- **Copy path**
- **Move to Trash**

After the current file is moved or trashed, the **next** file in the list is selected and starts playing automatically.

## Fullscreen

- Enter or leave fullscreen with `f` or by double-clicking the player.
- `Esc` leaves fullscreen.
- In fullscreen the player fills the whole screen. All shortcuts and the context menu keep working, including navigating to the next or previous file with Up/Down.

## Drag and drop, copy and paste

- Files can be dragged and dropped between VidFileBrowser and Finder windows in both directions.
- Copy (`Cmd+C`), cut (`Cmd+X`) and paste (`Cmd+V`) work between VidFileBrowser and Finder.
- If a file with the same name already exists at the target, a modal conflict dialog is shown with these options:
  - **Replace**: overwrite the existing file
  - **Keep both**: copy or move with a numbered suffix (e.g. `video 2.mp4`)
  - **Skip**: leave this file out
  - **Cancel**: stop the whole operation
  - An **Apply to all** checkbox applies the choice to all remaining conflicts in the same operation.

## Keyboard shortcuts

| Key | Action |
|---|---|
| Up / Down | Select the previous / next file (also in fullscreen) |
| Enter | Open the selected folder |
| Space | Play / pause |
| Left / Right | Skip back / forward 10 seconds |
| `,` / `.` | Skip back / forward 30 seconds |
| `n` | Trim left (remove everything before the current position) |
| `m` | Trim right (remove everything after the current position) |
| `f` | Toggle fullscreen |
| `Esc` | Leave fullscreen / close the open menu |
| `y` | Open the context menu for the current file |
| `x` | Open the **Move to** menu for the current file |
| `Cmd+C` / `Cmd+X` / `Cmd+V` | Copy / cut / paste files |

While a menu opened with `y` or `x` is visible, Up/Down moves through the menu entries, Enter runs the selected entry and `Esc` closes the menu.

## Tasks

Every commit references one of these task numbers (see `agents.md`). A checked task is done; it can be unchecked again if its scope changes.

### Project setup

- [x] T01 Write the feature specification in this README
- [x] T02 Choose the tech stack
- [ ] T03 Create the Xcode project: SwiftUI app, macOS 14 deployment target, App Sandbox enabled
- [ ] T04 Add git hooks (`commit-msg`, `pre-push`) that enforce the commit rules, plus an `installHooks` task
- [ ] T05 Add a unit test target and a command-line build and test command (`xcodebuild test`)

### Window and folder access

- [ ] T06 Main window layout: breadcrumb on top, resizable split view with file browser left and player right
- [ ] T07 Folder access: open dialog to grant a folder, store it as a security-scoped bookmark, restore access on launch
- [ ] T08 Remember the last folder, window frame and divider position across launches

### Breadcrumb path

- [ ] T09 Show the current folder path as breadcrumb segments
- [ ] T10 Clicking a breadcrumb segment opens that folder

### File browser

- [ ] T11 Directory model: load files and folders of the current folder with name, date, size and tags
- [ ] T12 File list view (`NSTableView`) with Name, Sort value and Tags columns
- [ ] T13 Show Finder tag colors as dots in the Tags column
- [ ] T14 Sorting by name, date, label and size, folders always first
- [ ] T15 Sort dropdown and ascending/descending toggle, stored as a global setting
- [ ] T16 Keyboard navigation: Up/Down moves the selection, Enter or double-click opens a folder
- [ ] T17 Detect playable files (video, image); non-media files are listed but not played
- [ ] T18 Refresh the list automatically when the folder content changes on disk

### Player

- [ ] T19 Play the selected video with AVPlayer, starting automatically on selection
- [ ] T20 Stop on the last frame when a video ends
- [ ] T21 Clickable progress bar at the bottom that shows the position and seeks on click
- [ ] T22 Hide the progress bar after mouse inactivity, show it again on mouse movement
- [ ] T23 Show the selected image fitted to the player area
- [ ] T24 Zoom (pinch, scroll wheel with modifier) and pan (drag) for images
- [ ] T25 Playback shortcuts: Space play/pause, Left/Right skip 10 s, `,`/`.` skip 30 s

### Trimming

- [ ] T26 Trim service: lossless, keyframe-snapped export of a time range (`AVAssetExportSession` passthrough)
- [ ] T27 Replace the original: write to a temp file, move the original to the Trash, move the trimmed file into place
- [ ] T28 Keep Finder tags and creation date on the trimmed file
- [ ] T29 Trim left (`n`) and trim right (`m`) at the current position, then reload the player
- [ ] T30 Show progress during a trim and report errors

### Finder tags

- [ ] T31 Tag service: read and write Finder tags and label colors
- [ ] T32 Tags submenu: toggle each tag color, "Remove all tags"

### Favorite folders

- [ ] T33 Settings window: add, remove and reorder favorite folders (stored as security-scoped bookmarks)
- [ ] T34 Move a file into a favorite folder

### Context menu

- [ ] T35 Context menu on right-click in the file browser and the player
- [ ] T36 Move to submenu with the favorite folders
- [ ] T37 Rename action
- [ ] T38 Reveal in Finder and Copy path actions
- [ ] T39 Move to Trash action
- [ ] T40 After a move or trash, select the next file and start playing it
- [ ] T41 `y` opens the context menu and `x` opens the Move to menu for the current file, navigable with Up/Down/Enter/Esc

### Fullscreen

- [ ] T42 Toggle fullscreen with `f` or double-click on the player, leave with `Esc`
- [ ] T43 All shortcuts and menus work in fullscreen, including Up/Down file navigation

### Drag and drop, copy and paste

- [ ] T44 File operation service: copy and move files with conflict detection
- [ ] T45 Conflict dialog: Replace, Keep both, Skip, Cancel and Apply to all
- [ ] T46 Drag files from the file browser to Finder
- [ ] T47 Drop files from Finder into the file browser
- [ ] T48 Copy, cut and paste files with `Cmd+C`, `Cmd+X` and `Cmd+V`, also with Finder

### Release

- [ ] T49 App icon and app metadata
- [ ] T50 Signing, App Store build and submission
