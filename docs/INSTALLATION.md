# Installation

Carrier Navigator requires **CC2X SDK 0.10.0-dev**, Windows CC2 1.5.18-r2 and a
local single-player session. The older SDK 0.9/0.8 runtimes do not provide the
motion interface. The SDK and Navigator are separate packages.

## Steam Workshop

1. Subscribe to Carrier Navigator and
   [CC2X SDK](https://steamcommunity.com/sharedfiles/filedetails/?id=3833014670).
   Wait for Steam to finish downloading. The Navigator Workshop page will be
   published after the owner supplies its artwork.
2. Close the game. Download the exact DLL from the
   [SDK 0.10.0-dev release](https://github.com/Dioramawhois/Carrier-Command-2-extender/releases/tag/0.10.0-dev)
   when that release is published. Identify and back up any existing loader.
3. In Steam, open Carrier Command 2 > Manage > Browse local files. Put
   **dinput8.dll beside carrier_command.exe**. A Workshop subscription does not
   install or replace this manually installed DLL automatically.
4. Enable Carrier Navigator and restart the game. For Revolution, also enable
   [original Revolution](https://steamcommunity.com/sharedfiles/filedetails/?id=3460002110).
   Island Airfields is optional. No Revolution files are bundled.
5. Open an aviation-control map, drag the carrier to a destination, then choose
   **NAV > START AUTOPILOT**.

Automatic runtime installation through CC2 ModLoader requires a build explicitly
supporting this exact SDK binary. Do not assume an older ModLoader recognizes it;
use the manual runtime route above until a matching release is available.

## GitHub player ZIP

Extract the **Carrier Navigator** folder from the player ZIP into the game's
local mods folder under **%APPDATA%/Carrier Command 2/mods/**, then enable it.
Install the SDK DLL as described above. The source ZIP is for development, not
the player installation. No Python, Git, Lua compiler or developer tools are
needed to play.

## Updating or removing

Close the game before updating the runtime or active mod files. Remove the local
Navigator folder or disable the Workshop mod to remove the addon. The SDK is
shared with other mods; only remove its loader after checking those dependencies.
Restore an identified previous loader from your backup when appropriate.

For reports include game/SDK/mod versions, enabled mods, exact steps and cc2x.log
from beside the game executable. Local single-player only; multiplayer and
dedicated-server operation are not supported by this navigation candidate.
