# ADR-0001: carrier-scoped navigation controls

Accepted 2026-11-20 for the reported stale markers after teleporting between
three carriers and the request to control all friendly carriers from NAV.

Keep native waypoints as the only route store. Separate the physical screen
carrier from the selected command target. Use the live session, screen ID, team
and selected carrier ID to invalidate actions captured by an older frame.
Cancel pending editing when that context changes; do not copy a route to another
ship. Recheck live authority at command time and consume denied carrier drags
instead of allowing the original screen to bypass the Navigator gate.

Give every carrier its own cruise preference, defence flag and existing policy
instances. Keep the established module owner, normal SDK capability negotiation
and native permission checks. Do not extend local mailbox requests into remote
network authority without a separately reviewed transport.

Merge source and regression evidence now. Prepare the player update and obtain
fresh game acceptance later; historical single-player evidence does not certify
the new multi-carrier or remote-client behavior.
