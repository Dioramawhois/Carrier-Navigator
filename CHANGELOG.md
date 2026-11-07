# Changelog

## 0.1.1-client-beta.1 - 2026-11-07

- Keep normal autopilot, speed, defence and route controls available on SDK 0.10.
  Select the optional coastal API by capability at each session boundary.
- Show COASTAL: UPDATE SDK without blocking native controls. Stop on failure of
  an already selected coastal backend instead of changing its routing policy.
- Verify native cruise against the published policy over 2,000 changing frames,
  and exercise current/older real SDK Lua facades with synthetic native callbacks.

## Unreleased - 0.1.1-alpha.1 coastal navigation candidate

- Require the optional SDK 0.11 surface-navigation interface and configure only
  the controlled carrier for wet-mesh routing and a 25 m arrival radius.
- Preserve the raw coastal goal, wait for admitted guidance without forward
  thrust, and expose blocked/setup/fault/arrival status on the aviation panel.
- Combine exact-goal, speed-aware coasting with native corner slowdown; retain
  full native open-water power, saved routes, repeat links and manual control.
- Keep blocked points and require explicit restart instead of falling back to
  deep-water routing. Live coastal/physics acceptance remains pending.

## 0.1.0-client-beta.1 - published 2026-11-07

- Preserve owner-accepted alpha.4 navigation and the exact motion-enabled SDK
  from the ordinary combined ModLoader test. Record general acceptance separately
  from unverified combat, exhaustive save/load and multiplayer cases.
- Explain functions, mandatory DLL, manual and ModLoader installation, and why
  a manually copied DLL must be replaced after an SDK runtime update.
- Recommend compatible CC2 ModLoader for reviewed DLL installation and upgrades.
- Freeze an eight-file Steam payload. Keep complete owned source, tests and
  packaging tools on GitHub. Publish with the owner's cover and gameplay video.
- Record the owner's temporary off-course turn on a two-point route, followed
  by realignment. Beta publication was explicitly authorized with this observation;
  no navigation fix is claimed.

- Fix the public mod name as **Carrier: Autopilot Waypoints** in metadata,
  player documentation and Workshop materials. Use Autopilot Waypoints on the
  compact in-game panel and Carrier Autopilot Waypoints for the Windows player
  folder. Release archive names use Carrier-Autopilot-Waypoints.
- Preserve existing repository URLs, module/settings identity and frozen test
  receipts. The package verifier allows only the three exact title string changes
  from the accepted candidate and records their before/after hashes.

## 0.1.0-alpha.4 - route repeat fix

- Restore native route repetition when a carrier waypoint is dropped onto another
  waypoint of the same carrier, with mouse and controller input.
- Keep waypoint positions/IDs and the rest of the route intact when linking.
  Reject stale highlighted targets and preserve Revolution/local-focus gates.
- Show the closing repeat segment in Navigator's Revolution fallback drawing.
- Add six real-Lua UI regressions, including the owner's failing gesture.

## 0.1.0-alpha.3 - owner test pending

- Feed native helm/throttle animation with current steering and forward command.
- Replace turn-in-place throttle loss with smooth course-dependent forward power,
  retaining 35% of the selected setting for a reversal away from the endpoint.
- Recover selected power as the course aligns; retain endpoint slowdown and
  normal engine, fuel, disabled-state and manual-control gates.
- Use the revised matching motion-enabled SDK; alpha.2 acceptance remains historical.

## 0.1.0-alpha.2 - unpublished

- Move route management to the aviation-control map: drag carrier/points, keep
  later points and repeat links, preserve aircraft and short carrier taps.
- Replace fixed knot targets with 10-100% native power, default 100%. FULL
  permits the game's full native output, including Revolution physics.
- Preserve Revolution permissions and files; draw owned routes when its standard
  carrier-waypoint display is hidden.
- Connect native steering, saved routes, manual takeover, expiring leases and
  team-contact defensive arming through the optional CC2X motion interface.
- Add source-hashed real-Lua runtime/UI fixtures and negative controls.
- Local single-player candidate; revised UI and live combat need acceptance.
