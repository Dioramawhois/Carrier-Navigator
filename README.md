# Carrier: Autopilot Waypoints

This branch prepares an **unpublished 0.1.1-alpha.1 coastal-navigation candidate**
requiring optional CC2X SDK 0.11 navigation support. See the
[coastal correction](docs/COASTAL_NAVIGATION.md). The published beta and its
acceptance described below are unchanged; the candidate needs a new owner game test.

[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3834928522)
| [Client beta release](https://github.com/Dioramawhois/Carrier-Navigator/releases/tag/v0.1.0-client-beta.1)
| [Gameplay video](https://www.youtube.com/watch?v=HidFBf5PSQg)

Give your carrier a route, set its engine power and return to commanding aircraft.
Carrier: Autopilot Waypoints adds carrier navigation to the **same aviation-control map**
used for aircraft orders, with optional threat-triggered defensive arming.

**0.1.0-client-beta.1**, published on 2026-11-07, targets Windows CC2
1.5.18-r2, local single-player and
the matching **CC2X SDK 0.10.0-dev**. Stock and original Revolution can use the
addon independently of Island Airfields. The owner accepted the alpha.4 combined
ModLoader test and authorized beta publication with the steering observation
documented below. The supplied cover and video are used on the Workshop page.

## Plot and adjust a route

1. Open the carrier's aviation-control map and drag the carrier icon to a
   destination. This replaces its existing route with the new destination.
2. Click **NAV** at the upper right, then **START AUTOPILOT**.
3. To extend the route, click **+ POINT**, then click the map once. Repeat for
   additional points, up to 20. The button changes to **CANCEL** while placing.
4. Drag an existing point to reposition it. The following points and repeat
   links are preserved. A short carrier click keeps the original carrier menu.
   To loop the route, drop a point onto another point of this carrier's route.
   For example, drop C onto A to repeat A, B, C, A. This creates a native repeat
   link; it keeps the point positions and the route intact. Revolution's fallback
   carrier drawing also shows the closing segment.
5. **PAUSE AUTOPILOT** releases automatic control and neutralizes propulsion.
   **CLEAR** also removes the route. Stopping still uses normal ship inertia.

Orders use the engine's existing sea-path follower. This does not replace native
pathfinding or make the ship immune to shore collisions. Aircraft orders, cameras
and loadout windows continue through the installed screen.

## Native engine power

The panel offers **-10%**, **+10%** and **FULL**, from 10% to 100%, and separately
shows actual speed in knots. The default is 100%. **FULL permits the game's full
native forward output**: there is no fixed 25-knot or real-world maximum.

These are power settings, not guaranteed speeds. Hull physics, engine condition,
waves, turns and mods such as Revolution determine actual movement. Navigator
does not edit thrust definitions, drag, position or velocity to achieve a number.

In alpha.3, the physical helm wheel and throttle lever reflect native steering
and commanded forward power through normal replicated control factors. Turning
smoothly reduces ahead power according to course error, retaining 35% of the
selected setting for a reversal away from the native endpoint. Power rises
smoothly as the ship aligns again. Endpoint slowdown and engine/fuel gates still
apply. These changes are included in the owner-accepted alpha.4 experience.

Moving the physical helm or throttle cancels automatic navigation. Use Start
explicitly to resume. The module also releases control if it loses its lease,
the route becomes empty or the module stops.

## Optional automatic defence

Turn **DEFENCE: ON** in the same panel. Current radar **or** visual detection by
your team is sufficient; hidden enemies and friendly projectiles do not trigger
it. Relevant threats can arm AA, CIWS and the game's torpedo/countermeasure
automation. The game remains responsible for engagement and consumable use.

Offensive artillery, cruise missiles and offensive torpedo arming are left under
normal control. The mod does not send repeated countermeasure fire commands.
Manual off switches are respected until defence automation is explicitly enabled
again. Disabling automation does not disarm systems that are already enabled.

Defence operates independently of whether the route panel is open or the ship is
following a route. It begins disabled in each new session.

## Saves and Revolution

Waypoints and navigation mode are native game data. A saved active route is adopted
on loading; the power percentage is a user preference. This does not create one
global route shared between unrelated saves.

Enable the **original Revolution** alongside Navigator. Its command permissions
remain in force. If Revolution hides ordinary carrier route drawing, Navigator
draws its own route without changing that setting. No Revolution files, complete
game screens or gameplay DLL are included in this addon.

## Install and support

See the [installation guide](docs/INSTALLATION.md) and [quick controls](PLAYER_README.md).
The required native runtime is distributed separately in
[CC2X SDK](https://github.com/Dioramawhois/Carrier-Command-2-extender).
A Workshop subscription downloads files; it does not update a DLL beside the
game executable automatically.

The owner accepted alpha.4 in the ordinary Steam installation through ModLoader
with Revolution after the helm/turning and route-loop corrections. The exact
tested runtime is preserved. Only three public-title string literals differ in
the release's Lua files; the packager checks and reports those changes explicitly.
Neither general owner confirmation nor offline checks separately certify
live combat, countermeasure expenditure or every save/load scenario.
Remote multiplayer, dedicated servers and native macOS runtime are unsupported
by this candidate; the motion backend refuses multi-peer sessions.

## Source and developer checks

All owned gameplay/UI code, documentation, tests and packaging tools are in this
repository under GPL-3.0-or-later. Native changes are in the separate
[SDK navigation branch](https://github.com/Dioramawhois/Carrier-Command-2-extender/tree/codex/carrier-navigation).

```powershell
python tools/test.py --sdk ../cc2x-navigation --zig ../cc2x/.deps/zig-x86_64-windows-0.15.2/zig.exe
python -m unittest discover -s tests -p test_release.py
python tools/release.py --tested-candidate build/candidates/alpha2-02 --acceptance docs/verification/OWNER_ACCEPTANCE_2026-11-06.json --output build/release/NEW
```

Owned real-Lua fixtures are offline checks, separate from owner game acceptance.
The release tool verifies the accepted functional hashes and creates a **eight-file
Workshop payload**, a player ZIP, a complete committed source ZIP and separate
evidence. Tests, tools, private test observers and release reports never enter
the Steam payload. See [release procedure](docs/RELEASING.md).

Beta observation: a two-point route temporarily steered off course, then
realigned. The cause remains under investigation; the owner chose beta publication
with this limitation. No navigation behavior was changed for this release.
