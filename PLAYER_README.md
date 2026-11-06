# Carrier Navigator 0.1.0-alpha.2 - local test

Requires the matching CC2X 0.10 test runtime. Local single-player only.

1. Open the **aviation-control map**, where you already issue aircraft orders.
2. Drag the carrier icon to a destination. Drag a route point to move it while
   keeping later points. A short click keeps normal carrier interaction.
3. Open **NAV** in the upper right. **+ POINT** adds one point at your next map
   click (up to 20). **CLEAR** removes the route.
4. **FULL** selects 100% native power; **-10% / +10%** adjust it. Actual game
   speed is shown in knots. There is no fixed knot maximum: Revolution's physics,
   engine condition, waves and turns determine the result.
5. Press **START AUTOPILOT**. **PAUSE AUTOPILOT** releases control and neutralizes
   thrust. Moving the physical helm/throttle also cancels autopilot; use Start
   explicitly to resume. Stopping still uses normal inertia.
6. **DEFENCE: ON** enables threat-triggered AA, CIWS and native torpedo
   countermeasure arming. Radar or visual detection is enough. Hidden/friendly
   targets do not trigger it; offensive weapons remain under manual control.

The game saves native routes and navigation mode. An active saved route is adopted
after loading; power is a preference. Defence starts disabled in each new session.
Disabling it does not disarm already enabled systems. Manual off switches are
respected until automation is enabled again.

Revolution stays separate; its command restrictions and normal aircraft controls
are preserved. This candidate is unpublished. Revised UI, live combat and
countermeasure expenditure need runtime acceptance. Native routing does not
guarantee collision avoidance.
