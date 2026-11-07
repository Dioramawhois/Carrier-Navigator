# Coastal navigation correction

Unpublished candidate: Carrier: Autopilot Waypoints 0.1.1-alpha.1 with optional
CC2X SDK 0.11.0-dev navigation API 1. Existing client-beta publication and its
owner acceptance remain historical evidence for the unchanged public release.

## Problem

The owner reports the carrier turning away from a nearby coastal destination.
Static inspection of the supported engine confirms that its carrier uses the
same deep-water mesh admission as barges: a -100 elevation classification, a
150 m proximity getter, waypoint projection and completion after a failed path.
This is a concrete mechanism that can redirect/consume a coastal point. The
exact reported game episode has not been captured with live target telemetry.

The map wrapper passes raw coordinates correctly; source, Workshop and the
active merged wrapper matched during the audit. A throttle-only change cannot
remove native projection or make a shallow-water point navigable.

## Candidate behavior

- Explicitly opt this owned carrier into the separate SDK surface policy with
  strictly wet triangles and a 25 m arrival radius. Other ships retain their
  native policy; native land-path rejection and steering remain in use.
- Keep the requested point instead of silently projecting it offshore. Stop and
  display `ROUTE BLOCKED` if the SDK cannot admit/reach that point. Require Start
  after a blocked/configuration/fault refusal; do not silently revert to deep-water
  routing or discard the point.
- Wait for admitted guidance using a zero-power lease. Show `PLOTTING ROUTE` and
  keep Pause available during that wait.
- Use copied exact-goal distance alongside native intermediate-corner distance.
  Reduce forward demand near arrival according to actual speed. Full power in
  open water retains the game's maximum output and has no fixed knot ceiling.
- Preserve native route storage, repeat links, manual takeover, Revolution
  permissions, aircraft controls and independent defensive arming.

The coast gate is a conservative demand heuristic (0.1 m/s² plus three seconds
of travel), not a measured hull braking guarantee. No position, velocity, hull
drag or engine output is written. Game hull collision/grounding remains physical.
Wet mesh admission does not promise that every shoreline coordinate has hull or
under-keel clearance; mixed shoreline triangles can still be rejected.

## Acceptance

Owned real-Lua regressions, native geometry/ABI/fault fixtures and static profile
guards are separate from live navigation. Before publishing, the owner must test
the paired candidate in the ordinary combined ModLoader setup: shallow coastal
goal, land rejection, an offshore multi-point route, loop and save/load, manual
takeover and close stopping with Revolution physics. No new public release or
installed-game change is implied by the source candidate.

First-frame reload is a specific unresolved risk: the SDK dispatches module
updates after the original engine tick. A saved carrier in native auto mode
could therefore encounter stock projection before the module adopts its route.
Whether that occurs on the first loaded frame has not been verified. The
candidate does not reorder global ticks or intercept unowned ships to hide this
uncertainty. Exact coastal-point retention after reload is a publication gate.
