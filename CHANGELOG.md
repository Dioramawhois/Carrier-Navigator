# Changelog

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

## 0.1.0-client-beta.1 - release preparation

- Preserve owner-accepted alpha.2 gameplay bytes and the exact motion-enabled SDK.
- Add detailed controls, power/defence behavior, installation and Revolution notes.
- Stage a nine-file Steam payload; keep all source, tests and tools on GitHub.
- Record owner acceptance separately from offline checks and unverified combat.
- Await owner artwork before publishing the release.

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
