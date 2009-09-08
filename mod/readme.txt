Mod ReadMe
 - A custom mod used to extract additional data/statistics from the game.


Installation
 - Option 1: Manual
     - Copy the cod-stats folder into your CoD installation root folder.
 - Option 2: Apache Ant
     - Open a command prompt to this folder and type "ant".
     - By default it copies to "C:/Program Files/Call of Duty"
     - Override the path using -Dcod.dir=INSTALL_DIR when running ant.

Run
 - Make a copy of the shortcut file that comes with the game.
 - Right-click and choose "Properties".
 - Add the following to the very end of "Target": +set fs_game cod-stats
 - Start the game with this new shortcut and then create a game as normal.