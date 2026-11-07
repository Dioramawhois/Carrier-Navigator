# Carrier: Autopilot Waypoints 0.1.1-client-beta.1

Windows CC2 1.5.18-r2, local single-player. SDK 0.10 retains normal navigation;
the optional SDK 0.11 navigation API enables the coastal correction.
See
[coastal navigation notes](docs/COASTAL_NAVIGATION.md).

1. Open the **aviation-control map**. Drag the carrier icon to a destination;
   this replaces its previous route. A short click keeps the native carrier menu.
2. Open **NAV**, upper right, and press **START AUTOPILOT**.
3. **+ POINT** adds one point at your next map click, up to 20. Use **CANCEL**
   to leave placement mode. Drag existing points to move them without deleting
   the following route. **CLEAR** stops automation and removes the route.
   Drop a point onto another point on the same carrier route to create a loop.
   Drop the final point onto the first to repeat the entire route.
4. **FULL** selects 100% native forward power; **-10% / +10%** adjust it down to
   10%. Actual speed is displayed in knots. These are power settings, not knot
   targets: engine condition, waves, turns and Revolution physics still apply.
5. **PAUSE AUTOPILOT** neutralizes propulsion. Moving the physical helm/throttle
   also cancels autopilot; Start resumes it explicitly. Ship inertia still applies.
6. **DEFENCE: ON** enables automatic defensive arming for current radar or visual
   threats: AA, CIWS and native torpedo/countermeasure automation. Hidden/friendly
   targets do not trigger it. Offensive weapons remain under normal control.

The helm wheel and throttle lever now follow navigation commands. Ahead power
adjusts smoothly through turns instead of falling to turn-in-place idle, then
returns towards the selected setting as the ship straightens. With the optional
coastal API, this candidate keeps coastal destinations, admits shallow water and
slows demand near the exact goal with a 25 m arrival radius. Land or failed routes
show ROUTE BLOCKED and retain the order. Otherwise the published native routing
and power behavior remain available. The panel shows COASTAL: UPDATE SDK.
Normal engine output, fuel and hull collision still apply.

Native routes/navigation mode are saved by the game. An active saved route is
adopted after loading; exact coastal-point retention during the first loaded
frame remains unverified. Power is a preference. Defence starts disabled in each new
session. Disabling it does not disarm systems. Manual off switches are respected
until defence automation is enabled again.

Use original Revolution separately; Navigator preserves its command restrictions
and aircraft controls. No Island Airfields dependency. Native routing does not
guarantee collision avoidance. Live combat/countermeasure expenditure and broad
save/load coverage remain unverified; remote/dedicated sessions are unsupported.

**The SDK DLL is required.** A Workshop subscription alone does not install
**dinput8.dll beside carrier_command.exe**. Follow the manual DLL instructions
or use a **CC2 ModLoader release explicitly supporting the selected SDK build**.
We recommend ModLoader for reviewed installation and DLL upgrades with backups.
Updating this mod does not force an SDK update: SDK 0.11 is needed only for the
new coastal behavior. If a selected coastal backend fails during a route, the
autopilot stops and keeps the order rather than changing routing modes silently.
After a manually installed SDK DLL is updated, close the game and copy the new
matching DLL into the game folder again; Steam does not replace that copy.
See [installation and updates](docs/INSTALLATION.md).
