# Installation and updates

Carrier: Autopilot Waypoints requires **CC2X SDK 0.10.0-dev**, Windows Carrier
Command 2 **1.5.18-r2** and a local single-player session. The native
**dinput8.dll is mandatory**: it provides carrier motion and control APIs absent
from ordinary game Lua. SDK 0.9/0.8 cannot run this navigation interface.
The SDK and this addon are separate downloads.

## Recommended: CC2 ModLoader

1. Subscribe to Carrier: Autopilot Waypoints and
   [CC2X SDK](https://steamcommunity.com/sharedfiles/filedetails/?id=3833014670).
   Wait for Steam to finish downloading both.
2. Close the game. Download the ready Windows GUI from
   [CC2 ModLoader releases](https://github.com/Dioramawhois/CC2-ModLoader/releases).
   Use **beta 12 or later** for independent official SDK updates.
3. Place **CC2ModLoader.exe** beside **carrier_command.exe** and open it. Select
   the verified game if asked.
4. Select the SDK library and Carrier: Autopilot Waypoints together with your
   other mods. With Revolution, select
   [original Revolution](https://steamcommunity.com/sharedfiles/filedetails/?id=3460002110)
   too. ModLoader applies the selection automatically, builds the combined mod
   and installs the reviewed DLL through its reversible transaction.
5. Wait for the applied selection to be ready, then click **Launch**.

No terminal, Python, Git, compiler or technical configuration editing is needed.
ModLoader checks the supported game and exact runtime, backs up a recognized
previous DLL and preserves an unknown installed loader. Resolve an identified
incompatible-loader conflict before using this addon.

## Alternative: manual DLL installation

1. Subscribe to this addon and CC2X SDK and wait for their downloads. Close the
   game.
2. Download **dinput8.dll** from the
   [matching SDK 0.10.0-dev release](https://github.com/Dioramawhois/Carrier-Command-2-extender/releases/tag/0.10.0-dev).
   Use the DLL asset or extract it from the Windows runtime ZIP. The source ZIP
   is for developers.
3. In Steam, right-click Carrier Command 2 > **Manage > Browse local files**.
   Find **carrier_command.exe**.
4. Identify and back up any existing CC2X **dinput8.dll** in that folder before
   replacing it. Preserve an unrelated loader: two different DLLs cannot share
   the same filename in the game directory.
5. Copy the matching **dinput8.dll directly beside carrier_command.exe**. Leaving
   it inside a ZIP or putting it only in a mods folder does not install it.
6. Enable Carrier: Autopilot Waypoints in the game's mod list. Enable original
   Revolution too when using it, and restart the game. Island Airfields is
   optional; no Revolution files are bundled.

## First route

Open the **aviation-control map**, drag the carrier icon to a destination, then
choose **NAV > START AUTOPILOT**. **+ POINT** extends the route; drag a point onto
another point on that carrier route to create a repeat link. Choose native
power with **-10% / +10% / FULL**. See the [player guide](../PLAYER_README.md).

## DLL updates: installation must be repeated

**A Steam Workshop SDK update does not replace a DLL copied manually into the
game folder.** After an SDK runtime update, close the game and repeat the manual
copy with the new matching DLL. Updating only the Lua addon does not always
require a new DLL; check the SDK requirement for that addon version.

**We recommend CC2 ModLoader beta 12 or later for installation and DLL updates.**
Official compatible SDK updates apply from the downloaded library without replacing
the ModLoader EXE. Wait for Steam downloads, close the game and let ModLoader apply
the selected set. Publisher verification, runtime backup and Undo remain active.

## GitHub player ZIP

Extract **Carrier Autopilot Waypoints** from the player ZIP into
**%APPDATA%/Carrier Command 2/mods/**, then select it through ModLoader or enable
it in the game for manual installation. Install the SDK DLL by one method above.
The source ZIP is for development.

## Removing or reporting problems

Close the game before changing active mod files. Disable the addon through your
chosen mod manager or remove its local player folder. The SDK is shared with
other mods; check their dependencies before removing it. Use ModLoader's
available Undo for an owned activation, or restore an identified previous loader
from your manual backup when appropriate.

For a report include game, SDK and mod versions, enabled mods, reproduction steps
and **cc2x.log** from beside the game executable. Remote multiplayer, dedicated
servers and native macOS runtime are unsupported by this client beta.
