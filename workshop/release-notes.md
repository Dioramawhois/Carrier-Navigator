# Carrier: Autopilot Waypoints 0.1.0-client-beta.1

Plan a carrier route from the aviation-control map, set native power and return
to commanding aircraft. Drag the carrier to create a route, drag individual points
to adjust it, then use **NAV > START AUTOPILOT**. **+ POINT** extends the route;
moving an existing point preserves the points that follow it.

The same NAV panel contains power, pause/clear and defensive automation controls.
**FULL means 100% native forward output**, with no fixed 25-knot ceiling. Actual
speed is shown in knots and remains governed by the game's physics and Revolution.

The physical helm wheel and throttle lever follow navigation commands. Ahead
power adjusts smoothly through course changes, preserving headway instead of
dropping to turn-in-place idle, then recovers as the ship aligns. Endpoint,
engine and fuel gates remain active. The new alpha.3 revision awaits the owner's
test independently of the earlier alpha.2 acceptance.

Optional defence can arm AA, CIWS and native torpedo/countermeasure systems when
your team currently detects a threat by radar **or** visual contact. Offensive
arming remains manual. The game handles engagement and consumable expenditure.

Physical helm/throttle input cancels autopilot. Native routes/navigation mode
use game save data; active saved routes are adopted after loading. Defence begins
disabled per session. Original Revolution's command permissions and normal
aircraft interactions remain in place. No Revolution files are bundled.

Requires **CC2X SDK 0.10.0-dev** separately. Install its exact DLL beside the game
executable while the game is closed; a Workshop download alone does not update
that file. [Installation](https://github.com/Dioramawhois/Carrier-Navigator/blob/main/docs/INSTALLATION.md).

The owner accepted the revised navigation experience with Revolution. This client
beta is local single-player only. Live combat/countermeasure expenditure and
broader save/load cases are not separately certified; remote/dedicated/native
macOS operation is unsupported. Full source and developer material are on GitHub;
the Steam payload contains only eight functional/license files.
