# Connected engine adapter

The independent Bridge module uses the optional CC2X 0.10 motion interface.
runtime.lua checks native authority for every screen request, adopts native
saved mode/points, renews an owner/session/carrier lease each tick and publishes
copied UI state. The backend admits only the owning team in a single-peer local
session. Errors, unload, empty routes, manual helm/throttle and missed renewals
release control. A lost lease requires an explicit new Start.

cruise.lua converts 10-100% into the forward-output cap. At 100% there is no
cruising-speed ceiling. Steering/pathfinding and acceleration remain native;
transform, velocity, hull thrust and drag are not overwritten. The former
synthetic steering/PID controller is removed from the shipped module.

The aviation helper wraps installed screen callbacks. Aircraft and short carrier
taps delegate to the original screen. Carrier point moves preserve the route tail
and repeat links. Attack/wait/altitude editing for carrier points is outside this
UI. Native waypoints are the only route store; settings store power preference.

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
are separate evidence. The initial native route ran with Revolution; alpha.2
aviation controls and ordinary-install/remote-game behavior are not yet certified.
