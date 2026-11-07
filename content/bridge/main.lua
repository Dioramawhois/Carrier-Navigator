-- SPDX-License-Identifier: GPL-3.0-or-later
local cc2 = require('cc2')
local runtime
return {
    on_load = function()
        assert(cc2.carrier.motion_available and cc2.carrier.motion_available() and cc2.carrier.drive_motion,
            'Carrier: Autopilot Waypoints requires motion-enabled CC2X SDK support')
        runtime = require('bridge.runtime').new(cc2, require('bridge.cruise'), require('bridge.defence'))
        assert(cc2.events.on('vehicle_controls', function(id) runtime:buttons(id) end))
        print('Carrier: Autopilot Waypoints: native navigation, cruise control and team-contact defence ready')
    end,
    on_update = function() if runtime then runtime:update() end end,
    on_unload = function()
        if runtime then runtime:unload() end
        cc2.events.off('vehicle_controls')
    end,
}
