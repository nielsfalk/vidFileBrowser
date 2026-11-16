# VidFileBrowser

VidFileBrowser is a macOS application that combines a file browser with a video and image player. It is built for quickly reviewing, trimming, labeling and sorting large collections of media files, mostly from the keyboard.

## Platform

- macOS 14 (Sonoma) or later
- Distributed through the Mac App Store (sandboxed)
- Because of the sandbox, the user must grant access to folders (via an open dialog or by dropping a folder onto the app). Granted folders are remembered across launches.

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
