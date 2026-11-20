# Multiple carrier controls (unreleased source changes)

When more than one friendly carrier is available, NAV shows the selected carrier
ID and PREV, NEXT and FOCUS controls. Selection changes the target of the existing
power, Start/Pause, Clear, point-placement and defence controls. FOCUS centers the
aviation map on that carrier. Enemy ships and non-carrier vehicles are excluded.
Unavailable friendly carriers remain visible with editing controls disabled.

Teleporting to a different carrier selects that screen's carrier and cancels
unfinished point placement, stale buttons and carrier drag/waypoint selection.
The map can initialize its camera for the new screen. A new session, change of
team or loss of local screen focus also invalidates pending editing. Losing a
selected carrier returns selection to the current screen carrier.

Routes are always read from and written to the chosen native carrier. There is
no shared route buffer. Waypoint IDs are resolved within their owning carrier;
the same waypoint ID on another ship cannot redirect an edit. Dragging any
authorized friendly carrier or its point targets that carrier and selects it
for the panel. Aircraft and short carrier taps retain their original handlers.

Power and automatic defence are independent per carrier. Power preferences use
`cruise_<team>_<carrier>` settings keys, falling back to the previous
`cruise_percent` preference for a carrier with no saved preference. These are
user settings, not campaign state: reusing a carrier ID/team in another campaign
may reuse a power preference, but never a route or running-state record.
Defence starts off independently in each new session. Native route, pause,
manual takeover, owner/session leases and coastal capability gates are retained.

The mailbox retains its established module ID and command topics. It additionally
publishes `session` on subject 0, and explicitly revokes `authority` when a known
carrier is no longer readable. Every incoming command still requires a fresh
native `motion.can_control` result. This change does not add a network RPC or
remove the SDK's multiplayer restrictions. A multi-carrier UI fixture is not a
second-client multiplayer acceptance test.

## Verification and delivery boundary

`tools/test_multi_carrier.py` uses the existing hash-identified restricted Lua
runner to execute explicit project-owned policies against synthetic telemetry.
Build that runner with the normal `tools/test.py --sdk ... --zig ...` developer
check first; the normal command also includes both multi-carrier suites. The
focused check is `python tools/test_multi_carrier.py --regressions-only --output
<new-directory>` and accepts either the pinned bootstrap runner or a runner
matching the successful local build receipt and tracked runner source.
The new tests reproduce the previous cross-carrier power/defence changes and
pending-point placement after teleport, then exercise the corrected behavior.
The existing cruise, defence, runtime, aviation UI and lifecycle suites remain.

The source is staged for a later update. No Workshop upload, release tag,
installed-game modification or native SDK installation is part of this change.
Fresh rendering, movement, save/load and remote-client acceptance remain pending,
including acceptance on the current game/SDK profile rather than historical
1.5.18-r2 evidence.
