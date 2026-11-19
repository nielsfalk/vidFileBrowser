# VidFileBrowser

VidFileBrowser is a macOS application that combines a file browser with a video and image player. It is built for quickly reviewing, trimming, tagging and sorting large collections of media files, mostly from the keyboard.

> **Disclaimer**
>
> No one has ever read this code. It is completely vibecoded: written by AI agents, accepted when the tests passed, and only ever checked by clicking around in the app. Use it at your own risk. It comes with **no warranty** of any kind, express or implied, including but not limited to correctness, fitness for a particular purpose, or suitability for any purpose. Keep backups of your files; trimming, moving and renaming modify and delete media files.

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
- **Finder integration** through system APIs: Finder tags via `URLResourceValues` (`tagNames`) and the `com.apple.metadata:_kMDItemUserTags` attribute, drag and drop, copy/cut/paste via `NSPasteboard` and `NSItemProvider`.
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
- The last viewed file is remembered. If it was in another folder, that folder is opened and the file is selected again.

### Window title

The window title is `VidFileBrowser`. When exactly one file is selected, it shows the app name and the file name separated by a dash, for example `VidFileBrowser - clip 3.mov`.

## Breadcrumb path

The breadcrumb path sits at the top of the window and shows the current folder path. Each part of the path can be clicked to jump to that folder.

## File browser

The file browser sits on the left side of the window and lists all files and folders in the current folder.

### Columns

1. **Name**: the file or folder name
2. **Sort value**: the value of the current sort property (date, size, ...). Hidden when sorting by name.
3. **Tags**: the colors of the macOS Finder tags on the file

### Sorting

- A dropdown above the list selects the sort property: **Name**, **Date**, **Tags**, **Size**.
- A toggle next to it switches between ascending and descending order.
- Folders are always listed before files.
- Sorting by **Tags** compares the whole combination of tags on a file, not only its first tag. Files with the same tags keep the name order.
- The sort setting applies to all folders and is remembered across launches.

### Navigation

- Option+Up/Option+Down moves the selection.
- Enter or double-click opens a folder.
- Selecting a playable file shows it in the player.
- Non-media files are listed but cannot be played.

### Multiple selection

- **Shift+click** selects a range of files.
- **Cmd+click** adds a file to the selection or removes it again.
- **Shift+Option+Up/Down** extends the selection with the keyboard.
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

## Automatic tags

In the settings the user can turn on automatic tagging of played files and choose which Finder tag color is added. The option is off by default.

- A file is tagged once it has been played or shown in the player for at least 2 seconds.
- Turning the option off stops adding the tag. Tags that were already added stay on the files.
- Changing the tag color only affects tags that are added afterwards.

## Trimming

Trimming removes part of the current video, relative to the current playback position:

- **Trim left** (`n`) removes everything **before** the current position.
- **Trim right** (`m`) removes everything **after** the current position.

Behavior:

- Trimming is lossless (no re-encoding, done with ffmpeg), so it is fast and keeps the original quality and container format. It works for every format ffmpeg can read. The cut point snaps to the nearest keyframe, so it can be slightly off from the exact playback position.
- The trimmed video replaces the original file. `_t` is added to the base name before the first dot, e.g. `clip.mov` becomes `clip_t.mov` (unless the suffix is already there).
- The original file is moved to the Trash, so it can be restored from there. There is no in-app undo.
- Finder tags and the file's dates (creation and modification date) are preserved on the trimmed file.
- The trimmed file keeps its position in the file list, even though the `_t` suffix changes its name.

## Favorite folders

In the settings the user can add, remove and reorder favorite folders. Files can be moved into a favorite folder through the **Move to** submenu of the context menu.

Next to the **Open Folder…** button in the breadcrumb bar there is a favorites menu that jumps directly to a favorite folder.

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
- In fullscreen the player fills the whole screen. All shortcuts and the context menu keep working, including navigating to the next or previous file with Option+Up/Option+Down.
- Leaving fullscreen scrolls the file list to the selected file.

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
| Option+Up / Option+Down | Select the previous / next file (also in fullscreen) |
| Shift+Option+Up / Shift+Option+Down | Extend the selection |
| Enter | Open the selected folder |
| Space | Play / pause |
| Up / Down | Skip back / forward 40 seconds |
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

make release    # archive a Release build
make sign       # re-sign with DEVELOPER_ID="Developer ID Application: ..."
make notarize   # submit and staple with NOTARY_PROFILE=<notarytool profile>
make dmg        # create dist/VidFileBrowser.dmg
make dist       # release, sign, notarize and dmg
```

## Tasks

Every commit references one of these task numbers (see `agents.md`). A checked task is done; it can be unchecked again if its scope changes.

### Project setup

- [x] T01 Write the feature specification in this README
- [x] T02 Choose the tech stack
- [x] T03 Create the Xcode project: SwiftUI app, macOS 14 deployment target, hardened runtime, no App Sandbox
- [x] T04 Add git hooks (`commit-msg`, `pre-push`) that enforce the commit rules, plus an `installHooks` task
- [x] T05 Add a unit test target and a command-line build and test command (`xcodebuild test`)
- [x] T59 Add a README disclaimer and an MIT license
- [x] T51 Dependency check on launch: find `libmpv` and `ffmpeg` in `/opt/homebrew` and `/usr/local`, show the install command if missing

### Window and folder access

- [x] T06 Main window layout: breadcrumb on top, resizable split view with file browser left and player right
- [x] T07 Open a folder via an open dialog or by dropping a folder onto the app
- [x] T08 Remember the last folder, window frame and divider position across launches
- [x] T56 Quit the app when the last window is closed
- [x] T60 Show the selected file in the window title as `VidFileBrowser - <file>` when exactly one file is selected
- [ ] T68 Remember the last viewed file, open its folder on launch and select the file again

### Breadcrumb path

- [x] T09 Show the current folder path as breadcrumb segments
- [x] T10 Clicking a breadcrumb segment opens that folder

### File browser

- [x] T11 Directory model: load files and folders of the current folder with name, date, size and tags
- [x] T12 File list view (`NSTableView`) with Name, Sort value and Tags columns
- [x] T13 Show Finder tag colors as dots in the Tags column
- [x] T14 Sorting by name, date, tags and size, folders always first
- [x] T15 Sort dropdown and ascending/descending toggle, stored as a global setting
- [x] T16 Keyboard navigation: move the selection, Enter renames, double-click opens a folder
- [x] T17 Detect playable files (video, image); non-media files are listed but not played
- [x] T18 Refresh the list automatically when the folder content changes on disk
- [x] T54 Multiple selection in the file list: keyboard extension, Shift+click and Cmd+click
- [x] T55 Apply tags, Move to, Move to Trash and drag and drop to all selected files
- [x] T62 Sort by tags using the whole combination of tags on a file instead of only its first tag
- [x] T63 Call tags tags and never label, in the UI, the README and the code
- [x] T70 Option+Up/Option+Down moves the file selection, also in fullscreen; Shift+Option+Up/Down extends it

### Player

- [x] T52 `Player` protocol: load, play, pause, seek, position, duration and end-of-file event
- [x] T53 libmpv integration: link `libmpv` from Homebrew and embed mpv's video view in the player area
- [x] T19 Play the selected video with the mpv player, starting automatically on selection
- [x] T20 Stop on the last frame when a video ends
- [x] T21 Clickable progress bar overlaid on the mpv view that shows the position and seeks on click
- [x] T22 Hide the progress bar after mouse inactivity, show it again on mouse movement
- [x] T23 Show the selected image (ImageIO / NSImage) fitted to the player area
- [x] T24 Zoom (pinch, scroll wheel with modifier) and pan (drag) for images
- [x] T25 Playback shortcuts: Space play/pause, Left/Right skip 10 s, `,`/`.` skip 30 s
- [x] T69 Up/Down skips the playhead back and forward 40 seconds

### Trimming

- [x] T26 Trim service: lossless, keyframe-snapped cut with ffmpeg (`-c copy`), keyframe lookup with `ffprobe`
- [x] T27 Replace the original: write to a temp file, move the original to the Trash, move the trimmed file into place
- [x] T28 Keep Finder tags and creation date on the trimmed file
- [x] T29 Trim left (`n`) and trim right (`m`) at the current position, then reload the player
- [x] T30 Show progress during a trim and report errors
- [x] T57 Add `_t` to the trimmed file name before the first dot
- [x] T58 Ask to add a keyframe at the beginning by re-encoding when none exists before the trim point
- [x] T64 Keep the trimmed file in the same position in the file list when the `_t` suffix changes its name

### Finder tags

- [x] T31 Tag service: read and write Finder tags and their colors
- [x] T32 Tags submenu: toggle each tag color, "Remove all tags"

### Automatic tags

- [x] T65 Settings option to tag played files: choose the tag color, off by default
- [x] T66 Add the chosen tag to a file after it was viewed in the player for 2 seconds

### Favorite folders

- [x] T33 Settings window: add, remove and reorder favorite folders (stored as bookmarks so they survive renames and moves)
- [x] T34 Move a file into a favorite folder
- [ ] T67 Quick favorites menu next to **Open Folder…** to jump to a favorite folder

### Context menu

- [x] T35 Context menu on right-click in the file browser and the player
- [x] T36 Move to submenu with the favorite folders
- [x] T37 Rename action
- [x] T38 Reveal in Finder and Copy path actions
- [x] T39 Move to Trash action
- [x] T40 After a move or trash, select the next file and start playing it
- [x] T41 `y` opens the context menu and `x` opens the Move to menu for the current file, navigable with Up/Down/Enter/Esc

### Fullscreen

- [x] T42 Toggle fullscreen with `f` or double-click on the player, leave with `Esc`; fullscreen shows only the player
- [x] T43 All shortcuts and menus work in fullscreen, including file navigation
- [x] T61 Scroll the file list to the selected file when leaving fullscreen

### Drag and drop, copy and paste

- [x] T44 File operation service: copy and move files with conflict detection
- [x] T45 Conflict dialog: Replace, Keep both, Skip, Cancel and Apply to all
- [x] T46 Drag files from the file browser to Finder
- [x] T47 Drop files from Finder into the file browser
- [x] T48 Copy, cut and paste files with `Cmd+C`, `Cmd+X` and `Cmd+V`, also with Finder

### Release

- [x] T49 App icon and app metadata
- [x] T50 Signing (hardened runtime, `disable-library-validation`), notarization and DMG build

## License

MIT, see [LICENSE](LICENSE). The software is provided "as is", without warranty of any kind. Note that mpv and ffmpeg are separate programs installed by the user and are licensed by their respective projects.
