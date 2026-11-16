# VidFileBrowser

VidFileBrowser is a macOS application that combines a file browser with a video and image player. It is built for quickly reviewing, trimming, labeling and sorting large collections of media files, mostly from the keyboard.

## Platform

- macOS 14 (Sonoma) or later, Apple Silicon and Intel
- Distributed directly as a notarized DMG (hardened runtime, no App Sandbox). It is **not** distributed through the Mac App Store, because it depends on separately installed tools.
- Requires [Homebrew](https://brew.sh) packages for playback and trimming:
  ```
  brew install mpv ffmpeg
  ```
- On launch, the app looks for `libmpv` and `ffmpeg` in `/opt/homebrew` (Apple Silicon) and `/usr/local` (Intel). If they are missing, it shows a message with the install command.
- Without the sandbox, any folder can be opened directly. macOS still asks for permission once when the app first opens protected locations (Desktop, Documents, Downloads, external and network volumes).

## Tech stack

**Swift + SwiftUI/AppKit for the UI, libmpv for playback, ffmpeg for trimming.**

This is the same approach as the [IINA](https://iina.io) player. The app can play every format mpv and ffmpeg support, which is about the same as VLC (MP4, MOV, MKV, WebM, AVI, FLV, WMV, H.264, HEVC, VP9, AV1, DTS, …).

- **SwiftUI** for the window layout, controls and settings.
- **AppKit** for the parts SwiftUI handles poorly on macOS: the file list (`NSTableView`), context menus (`NSMenu`) that can be opened and navigated from the keyboard, drag and drop, and the responder chain in fullscreen.
- **libmpv** (from Homebrew `mpv`) for video playback and seeking.
  - All playback goes through a small `Player` protocol (`load`, `play`, `pause`, `seek`, `position`, `duration`, end-of-file event), so the UI does not depend on mpv. Another player (AVPlayer, VLCKit) can be added later behind the same protocol.
  - mpv draws into its own embedded view (`wid`) instead of the OpenGL render API. mpv can then render with OpenGL or with Vulkan through MoltenVK (Metal), which protects the app against Apple eventually removing the deprecated OpenGL.
  - The progress bar is a separate overlay view on top of the mpv view.
- **ffmpeg** (from Homebrew) for lossless trimming of any format: `ffmpeg -ss <start> -to <end> -i in -map 0 -c copy -avoid_negative_ts make_zero out`. `ffprobe` finds the keyframe the cut snaps to.
- **ImageIO / NSImage** for images (JPEG, PNG, HEIC, …) with zoom and pan.
- **Finder integration** through system APIs: tags and label colors via `URLResourceValues` (`tagNames`, `labelNumber`), drag and drop, copy/cut/paste via `NSPasteboard` and `NSItemProvider`.
- **Signing:** hardened runtime with the `com.apple.security.cs.disable-library-validation` entitlement, so the app can load `libmpv` from Homebrew. The app is notarized for distribution.

Licensing: the Homebrew `mpv` build is GPL. If the app is distributed, it should either be open source under the GPL or use an LGPL build of mpv.

Alternatives, if requirements change:

- **Back to the Mac App Store:** replace libmpv with **VLCKit** (it includes its own decoders) and bundle an **LGPL ffmpeg** build, sandboxed.
- **Better HDR / lower power use for common files:** add **AVPlayer** for MP4/MOV behind the `Player` protocol and keep mpv for everything else.

Not recommended: **Electron, Tauri, Flutter and Compose Desktop**. Each requires native bridging for Finder tags, drag and drop and drawing the progress bar over video, and none can play all formats without the same mpv/VLC integration work.

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

### Multiple selection

- **Shift+click** selects a range of files.
- **Cmd+click** adds a file to the selection or removes it again.
- **Shift+Up/Down** extends the selection with the keyboard.
- With several files selected, tags can be set or removed, files can be moved to a favorite folder or to the Trash, and the whole selection can be dragged to another folder or into Finder.
- Trim, Rename, Reveal in Finder and Copy path always act on the current file only.

### Drag and drop

Files can be dropped into the file browser (see [Drag and drop, copy and paste](#drag-and-drop-copy-and-paste)). Dragging a file that is part of a multiple selection drags the whole selection.

## Player

The player sits on the right side of the window and shows the file selected in the file browser.

### Videos

- Every video format supported by mpv/ffmpeg can be played.
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

- Trimming is lossless (no re-encoding, done with ffmpeg), so it is fast and keeps the original quality and container format. It works for every format ffmpeg can read. The cut point snaps to the nearest keyframe, so it can be slightly off from the exact playback position.
- The trimmed video replaces the original file under the same name.
- The original file is moved to the Trash, so it can be restored from there. There is no in-app undo.
- Finder tags and the file's dates (creation and modification date) are preserved on the trimmed file.

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

When multiple files are selected, **Move to**, **Tags** and **Move to Trash** apply to every selected file. The other actions apply to the current file only.

After the selected files are moved or trashed, the **next** file after the selection is selected and starts playing automatically.

## Fullscreen

- Enter or leave fullscreen with `f` or by double-clicking the player.
- `Esc` leaves fullscreen.
- In fullscreen the player fills the whole screen. All shortcuts and the context menu keep working, including navigating to the next or previous file with Up/Down.

## Drag and drop, copy and paste

- Files can be dragged and dropped between VidFileBrowser and Finder windows in both directions.
- Dragging one file of a multiple selection drags all selected files.
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
| Shift+Up / Shift+Down | Extend the selection |
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

## Development

Requirements:

- Xcode 27 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- The runtime dependencies from [Platform](#platform): `brew install mpv ffmpeg`

The Xcode project is generated from `project.yml` and is not checked in. On a fresh checkout run `make generate` once.

```
make generate   # create VidFileBrowser.xcodeproj
make build      # generate and build (Debug)
make test       # generate and run the unit tests
make run        # build and open the app
make clean      # remove the build output and the generated project
make installHooks  # install the git hooks from scripts/git-hooks
```

## Tasks

Every commit references one of these task numbers (see `agents.md`). A checked task is done; it can be unchecked again if its scope changes.

### Project setup

- [x] T01 Write the feature specification in this README
- [x] T02 Choose the tech stack
- [x] T03 Create the Xcode project: SwiftUI app, macOS 14 deployment target, hardened runtime, no App Sandbox
- [x] T04 Add git hooks (`commit-msg`, `pre-push`) that enforce the commit rules, plus an `installHooks` task
- [x] T05 Add a unit test target and a command-line build and test command (`xcodebuild test`)
- [x] T51 Dependency check on launch: find `libmpv` and `ffmpeg` in `/opt/homebrew` and `/usr/local`, show the install command if missing

### Window and folder access

- [x] T06 Main window layout: breadcrumb on top, resizable split view with file browser left and player right
- [x] T07 Open a folder via an open dialog or by dropping a folder onto the app
- [x] T08 Remember the last folder, window frame and divider position across launches

### Breadcrumb path

- [x] T09 Show the current folder path as breadcrumb segments
- [x] T10 Clicking a breadcrumb segment opens that folder

### File browser

- [x] T11 Directory model: load files and folders of the current folder with name, date, size and tags
- [x] T12 File list view (`NSTableView`) with Name, Sort value and Tags columns
- [x] T13 Show Finder tag colors as dots in the Tags column
- [x] T14 Sorting by name, date, label and size, folders always first
- [x] T15 Sort dropdown and ascending/descending toggle, stored as a global setting
- [x] T16 Keyboard navigation: Up/Down moves the selection, Enter or double-click opens a folder
- [x] T17 Detect playable files (video, image); non-media files are listed but not played
- [x] T18 Refresh the list automatically when the folder content changes on disk
- [ ] T54 Multiple selection in the file list: Shift+Up/Down, Shift+click and Cmd+click
- [ ] T55 Apply tags, Move to, Move to Trash and drag and drop to all selected files

### Player

- [x] T52 `Player` protocol: load, play, pause, seek, position, duration and end-of-file event
- [ ] T53 libmpv integration: link `libmpv` from Homebrew and embed mpv's video view in the player area
- [ ] T19 Play the selected video with the mpv player, starting automatically on selection
- [ ] T20 Stop on the last frame when a video ends
- [ ] T21 Clickable progress bar overlaid on the mpv view that shows the position and seeks on click
- [ ] T22 Hide the progress bar after mouse inactivity, show it again on mouse movement
- [ ] T23 Show the selected image (ImageIO / NSImage) fitted to the player area
- [ ] T24 Zoom (pinch, scroll wheel with modifier) and pan (drag) for images
- [ ] T25 Playback shortcuts: Space play/pause, Left/Right skip 10 s, `,`/`.` skip 30 s

### Trimming

- [ ] T26 Trim service: lossless, keyframe-snapped cut with ffmpeg (`-c copy`), keyframe lookup with `ffprobe`
- [ ] T27 Replace the original: write to a temp file, move the original to the Trash, move the trimmed file into place
- [ ] T28 Keep Finder tags and creation date on the trimmed file
- [ ] T29 Trim left (`n`) and trim right (`m`) at the current position, then reload the player
- [ ] T30 Show progress during a trim and report errors

### Finder tags

- [ ] T31 Tag service: read and write Finder tags and label colors
- [ ] T32 Tags submenu: toggle each tag color, "Remove all tags"

### Favorite folders

- [ ] T33 Settings window: add, remove and reorder favorite folders (stored as bookmarks so they survive renames and moves)
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
- [ ] T50 Signing (hardened runtime, `disable-library-validation`), notarization and DMG build
