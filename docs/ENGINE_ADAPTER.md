# Engine adapter boundary

The Lua policies are pure decision code. They must not receive raw screen
messages as authoritative snapshots. The adapter is not implemented yet; the
following contract describes what must be verified before game activation.

## Navigation

`navigation.new({max_speed_knots = reviewed_limit})` exposes `set_route`,
`set_speed`, `start`, `pause`, `step`, `status`, `checkpoint` and `restore`.

A navigation frame contains generation, carrier ID, team, authority, explicit
manual-input state, engine state, position, heading, speed in m/s, yaw rate,
current throttle, route revision and an optional current native path target.
Horizontal axes are x/z; heading is radians from +z towards +x. All telemetry
must describe the same carrier and simulation tick.

Route entries are copied `{id, x, z}` records, at most 20. A route revision
represents an accepted route edit, not every replicated path refresh. A path
contains `ready`, `route_revision`, `waypoint_id`, `x`, `z`, `remaining_m`; the
adapter must obtain it from the native sea path follower for the active point.
Unknown paths produce a stop request, never a straight-line fallback across land.

`step(frame, simulation_seconds)` returns one of:

- `drive`: desired normalized steering/throttle and target speed. The adapter
  must verify native sign, limits and control mode before applying anything.
- `stop`: neutral steering/throttle; normal ship inertia still applies.
- `release`: relinquish control without overwriting the player's helm.
- `none`: no control request.

The engine's existing mode-0 waypoint branch is the preferred steering backend.
Do not replace the native path follower with the provisional controller merely
because it passes a synthetic fixture. Native cruising-speed regulation and
manual takeover still require a checked interface.

Control ownership must be carrier/session/owner scoped with a short expiry and
normal manual-input precedence. Revalidate at application, not just enqueue.
The old unscoped SDK throttle-step queue is unsuitable for this adapter.

`checkpoint` creates a copied version-1 record; `restore` validates it against
the native route and always restores paused. Neither method writes the game
save. The future save hook must associate the record with that save and carrier.
Global module settings may store user preferences, never cross-save routes.

## Defence

`defence.new` requires reviewed aircraft, missile and torpedo trigger ranges.
Test values are fixture data, not game defaults. Defence ticks are independent
of route ticks, allowing sensor processing while the map is closed.

A defence frame contains generation, carrier ID, team, authoritative `can_control`,
explicit `enabled`, simulation `time_s`, team-filtered `contacts` and `systems`.
Contacts must already establish current detection, hostile allegiance, distance
and known class. `radar == true or visual == true` is sufficient. Do not infer
identification or inbound direction by inspecting hidden enemy server state.

Systems are `anti_air`, `ciws`, `torpedo_defence`, `countermeasures`, each with
explicit boolean `available`, `armed`, `manual_lock`. Resolve them by reviewed
game definitions/control names, not an indiscriminate list of weapon slots.
Manual locks and actual armed-state acknowledgements come from the engine.

The policy returns arming requests only. Retries are limited to once per second
for unacknowledged arming; never bind a retry to a single-use fire control.
Consumable deployment needs a separate verified engine mechanism with threat
identity, cooldown, acknowledgement and save/load duplicate protection. It is
not implemented by this policy. No automatic disarm is requested on contact loss.

Remote screen requests must be authenticated through a verified engine order
context before they can change any state. A numeric module mailbox is not an
authority grant. Remote clients and dedicated servers remain unverified.
