# Carrier Navigator

Separate Carrier Command 2 addon: native carrier waypoints, selectable engine
power and threat-triggered defensive arming. Current candidate: **0.1.0-alpha.2**,
requiring the matching experimental **CC2X 0.10.0-dev** runtime.

## Controls

Use the **aviation-control map**. Drag your carrier to create a route; drag an
existing point to reposition it while keeping the following points. A short
carrier click keeps the normal carrier interaction. Open **NAV** in the upper
right for **+ POINT**, **CLEAR**, **START / PAUSE**, power and defence controls.
Aircraft orders, cameras and loadout windows continue through the original screen.

**FULL / 100%** permits the game's full native forward power. There is no fixed
25-knot or real-world maximum. Engine, hull, waves, turns and enabled mods
determine actual speed, displayed in knots. Lower percentages limit forward jet
output; they are power settings, not promised cruising speeds.

Navigation uses the engine's existing sea path follower. Routes and navigation
mode use native game saves; a saved active route is adopted on loading. Power is
a user preference. Moving the physical helm/throttle cancels autopilot; use Start
explicitly to resume. Pausing neutralizes propulsion, with normal ship inertia.

Defence starts disabled each session. Current team radar **or** visual detection
can arm AA, CIWS and native torpedo/countermeasure automation. Offensive weapons
and countermeasure fire pulses remain untouched. Manual off switches are respected
until automation is explicitly enabled again. Disabling automation does not disarm
systems already enabled by the game.

## Revolution and validation

This package appends owned helper code to the installed aviation screen through
CC2X. It includes no Revolution files, complete game screens or gameplay DLL.
Revolution's command permissions remain in force; its hidden-carrier-route option
is preserved while Navigator draws its own route. Use the original Revolution
subscription alongside this independent addon.

The initial native route ran in a private legitimate game copy with the owner's
copied Revolution-containing mod set. The revised aviation-map UI requires its own
runtime acceptance. Offline fixtures and load logs are not gameplay acceptance.
Local single-player only: the backend refuses remote multiplayer sessions.
Live combat and countermeasure expenditure remain unverified. This is unpublished.

## Developer checks

```powershell
python tools/test.py --sdk ../cc2x-navigation --zig ../cc2x/.deps/zig-x86_64-windows-0.15.2/zig.exe
python tools/package.py --sdk ../cc2x-navigation --output build/candidates/NEW
```

The runner verifies external Lua/compiler hashes and executes owned fixtures only.
Packaging freezes a Lua-only addon and a separate matching tested SDK; it never
installs or publishes. See [engine boundary](docs/ENGINE_ADAPTER.md) and
[player controls](PLAYER_README.md).
