# VidFileBrowser

VidFileBrowser is a Application for MacOs that is a mixture of a File Browser and a Video Player.

# Breadcurmpath

The Breadcurmpath lives on the top of the Window and shows the current path. Every part is clickable. With a click the user can navigate to the parent directory.

# FileBrowser

The FileBrowser lives on the left side of the window and allows the user to navigate through the file system. It is a list of files in the current directory in 3 columns name, current sort property and colors of the file labels from MacOs. It is also possible to drag and drop files into the FileBrowser. A dropdown on top lets the user change the sort property ( name, date, lable, size ).

# Video Player

The Video Player lives on the right side of the window and shows the current video or image shown marked in the FileBrowser. A newly selected file starts playing automatically. A clickable progressbar on the button of the player shows the current position of the video. It hides automatically with mouse inactivity. I

# Favorite folders

In the settings the user can add favorite folders. There are actions to move a file into them via the context menu.

# Context menu

By clicking with the right button on a file in the FileBrowser or on the videoPlayer. It shows a menu which allows available actions with the file including a sub menu for moveto and to set and reset lables.

# Fullscreen

In fullscreen mode the Video Player takes the whole screen. All actions are still possible.

# Drag and drop

Drag and drop and copy, cut, paste into and from a finder window is also possible. A modal dialog for conflict handling with apply to all changes is shown when a conflict occurs.

# Shortcuts

- up/down navigates through the files even if a video is in fullscreen.
- space pause/play
- left/right skip 10 seconds
- ,/. skip 30 seconds
- n trimleft on the current video
- m trimright on the current video
- y shows the context menu wich then can be navigated with up/down/enter
- x shows the moveto context menu
