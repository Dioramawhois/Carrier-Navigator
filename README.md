# Carrier Navigator

Standalone Carrier Command 2 mod in development: carrier waypoints, selectable
cruising speed and threat-triggered defensive weapon activation.

This project is independent of Island Airfields. The current stage is an engine
capability audit; there is no installable or gameplay-tested build yet.

Confirmed requirements:

- Follow an ordered route of carrier waypoints.
- Let the player select the desired cruising speed.
- Activate defensive weapons when a threat is detected by radar **or visual
  contact**. Either source is sufficient. Hidden world entities do not count.

The intended primary interface is the holomap. Display speed in knots, matching
the stock propulsion monitor. Native waypoint storage, save/load behaviour,
steering, manual takeover and authoritative contact access must be verified
before connecting automation to the game.

See [the requirements](docs/CARRIER_WAYPOINTS_IDEA.ru.md) and
[the engine audit](docs/ENGINE_AUDIT.ru.md) for current evidence and gaps.
No game files, third-party screens, native binaries or private research are
included in this project.
