# Carrier Navigator

Standalone Carrier Command 2 mod in development: carrier waypoints, selectable
cruising speed and threat-triggered defensive weapon activation.

This project is independent of Island Airfields. The first route and defence
policies are implemented and tested with real Lua and synthetic telemetry.
The game adapter and interface are not connected yet; there is no installable
or gameplay-tested build.

Confirmed requirements:

- Follow an ordered route of carrier waypoints.
- Let the player select the desired cruising speed.
- Activate defensive weapons when a threat is detected by radar **or visual
  contact**. Either source is sufficient. Hidden world entities do not count.
- Include anti-air weapons, CIWS, torpedo defence and countermeasures.

## Implementation status

| Area | Current implementation | Remaining integration |
| --- | --- | --- |
| Route | Sequential points, native-path requirement, pause and manual takeover | Authoritative route/path reads and native mode transition |
| Speed | Knots, gradual throttle regulation, turn/endpoint slowdown | Guarded native control output and measured carrier tuning |
| Defence | Current team contact filtering, separate air/missile/torpedo decisions, manual locks and pending-action retries | Team sensor API, exact weapon mapping and consumable deployment |
| Save/load | Versioned checkpoint validation, restore paused | Per-save engine storage; no global route file |
| UI | Holomap selected as the intended surface | Map controls, speed selection and defence settings |

The provisional controller gains and detection ranges in the tests are synthetic
fixtures. They are not measured game parameters. Native waypoint steering is
preferred where the reviewed engine branch can be used safely. A pure controller
test is not evidence of collision avoidance, stopping distance or multiplayer.

## Developer validation

Use an external CC2X checkout with `dist/dinput8.build.json`, its restored Lua
sources and its verified Zig 0.15.2 compiler:

```powershell
python tools/test.py --sdk ../cc2x-equipment --zig ../cc2x/.deps/zig-x86_64-windows-0.15.2/zig.exe
```

This compiles an owned runner from SDK-hash-verified Lua sources, executes only
this project's policy fixtures and writes `build/TEST_RESULTS.json` with input,
compiler and interpreter hashes. No game process or DLL is loaded. Build outputs
are ignored by Git. Player installation instructions will accompany a playable
candidate; these commands are for development only.

The intended primary interface is the holomap. Display speed in knots, matching
the stock propulsion monitor. Native waypoint storage, save/load behaviour,
steering, manual takeover and authoritative contact access must be verified
before connecting automation to the game.

See [the requirements](docs/CARRIER_WAYPOINTS_IDEA.ru.md) and
[the engine audit](docs/ENGINE_AUDIT.ru.md) for current evidence and gaps.
The [adapter contract](docs/ENGINE_ADAPTER.md) records the remaining engine boundary.
No game files, third-party screens, native binaries or private research are
included in this project.
