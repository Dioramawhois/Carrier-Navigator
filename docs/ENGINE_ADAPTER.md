# Connected engine adapter

The independent Bridge module uses the optional CC2X 0.10 motion interface.
runtime.lua checks native authority for every screen request, adopts native
saved mode/points, renews an owner/session/carrier lease each tick and publishes
copied UI state. The backend admits only the owning team in a single-peer local
session. Errors, unload, empty routes, manual helm/throttle and missed renewals
release control. A lost lease requires an explicit new Start.

cruise.lua converts 10-100% into a forward-output cap and selects a smooth
forward command through cc2.carrier.drive_motion. Course error progressively
reduces power to 35% of the setting at a reversal; endpoint distance reduces it
near the native path target. Lever changes are bounded, resume uses live lever
state and straightening restores selected power. At 100% there is no knot
ceiling. Steering/pathfinding and physical acceleration remain native;
transform, velocity, hull thrust and drag are not overwritten. The former
synthetic steering/PID controller is removed from the shipped module.

The owned library_custom_0.lua entry wraps installed aviation callbacks.
It installs only when the aviation-screen contract exists and defers through
normal begin_load when libraries execute first. This avoids a duplicate
screen-extension target with Island Airfields in current ModLoader. Aircraft and short carrier
taps delegate to the original screen. Carrier point moves preserve the route tail
and repeat links. Attack/wait/altitude editing for carrier points is outside this
UI. Native waypoints are the only route store; settings store power preference.

Drop onto another live waypoint of the same carrier now invokes the native
set_waypoint_repeat(source ID, target ID) before the ordinary move handler.
It leaves IDs, positions and the route tail unchanged. Stale targets are refused;
mouse/controller, local focus and Revolution command permissions share the same
gate. The hidden-carrier-route fallback draws a native repeat's closing segment.

Defence reads native current-visible records for the owning team. It uses the
combined detected flag without fabricating radar/visual provenance. Metadata is
read only after visibility admission. Policy trigger radii are 6 km air,
5 km surface/torpedo and 4 km missile; these are not measured weapon ranges.
Projectile closing distance uses successive known contacts or a close-range
fallback. Sensor failure requests no arming.

Reviewed stock controls: AA carrier_weapons_active_0/1; CIWS _3/4/5/6;
torpedo defence/countermeasure automation carrier_countermeasure_active.
Offensive _2/7/8, carrier_torpedos_active and countermeasure fire are untouched.
Arming uses the normal vehicle-controls event, acknowledgements, bounded retries
and manual-off locks. Live engagement and consumable expenditure need acceptance.

Revolution is not bundled. Its waypoint-availability function gates orders;
other chassis capability calls delegate unchanged. Its carrier-route visibility
option is not modified; owned fallback drawing makes Navigator points visible.
Third-party script syntax checks do not execute those scripts outside the game.

Real-Lua synthetic fixtures, native synthetic ABI fixtures and private game runs
are separate evidence. The owner accepted alpha.2 aviation navigation with
Revolution and requested release preparation. The exact accepted functional files
and runtime are preserved. Ordinary-install/remote-game and separate live-combat
acceptance remain outside that confirmation.
