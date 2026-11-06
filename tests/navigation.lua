local M = POLICY
local count = 0
local function test(name, fn)
    local ok, why = pcall(fn)
    assert(ok, name .. ': ' .. tostring(why))
    count = count + 1
    print('PASS ' .. name)
end
local function new()
    return M.new({max_speed_knots = 25})
end
local route = {{id = 10, x = 0, z = 2000}, {id = 11, x = 1000, z = 2000}}
local function frame()
    return {generation = 1, id = 42, team = 0, can_control = true,
        manual = false, engine_on = true, x = 0, z = 0, heading = 0,
        speed_mps = 0, yaw_rate = 0, throttle = 0, route_revision = 7,
        path = {ready = true, route_revision = 7, waypoint_id = 10,
            x = 0, z = 2000, remaining_m = 2000}}
end
local function running()
    local n, f = new(), frame()
    assert(n:set_route(route, 7))
    assert(n:start(f))
    return n, f
end

test('empty route cannot start', function()
    local n = new()
    local ok, why = n:start(frame())
    assert(not ok and why == 'empty_route')
end)
test('invalid replacement preserves the previous route', function()
    local n = running()
    assert(not n:set_route({{id = 2, x = 0/0, z = 2}}, 8))
    assert(n:status().route_revision == 7 and n:status().count == 2)
end)
test('duplicate waypoint ids are refused', function()
    assert(not new():set_route({{id = 2, x = 0, z = 0}, {id = 2, x = 1, z = 1}}, 1))
end)
test('route input is copied', function()
    local n, r = new(), {{id = 1, x = 0, z = 1000}}
    assert(n:set_route(r, 1)); r[1].z = 0
    assert(n:checkpoint().route[1].z == 1000)
end)
test('speed selection validates without changing accepted speed', function()
    local n = new()
    assert(n:set_speed(20))
    for _, v in ipairs({-1, 0, 26, math.huge, '20'}) do assert(not n:set_speed(v)) end
    assert(not n:set_speed(0/0))
    assert(n:status().speed_knots == 20)
end)
test('following uses gradual forward throttle', function()
    local n, f = running()
    local c = n:step(f, .1)
    assert(c.kind == 'drive' and c.throttle > 0 and c.throttle < .1)
    assert(c.steering == 0 and c.waypoint_id == 10)
end)
test('speed decrease reduces throttle', function()
    local n, f = running()
    f.throttle, f.speed_mps = .8, 10
    assert(n:set_speed(5))
    assert(n:step(f, .1).throttle < .8)
end)
test('native detour is followed instead of a direct island crossing', function()
    local n, f = running()
    f.path.x, f.path.z, f.path.remaining_m = 600, 0, 2600
    local c = n:step(f, .1)
    assert(c.kind == 'drive' and c.steering > 0)
end)
test('missing path stops instead of driving directly', function()
    local n, f = running(); f.path = nil
    local c = n:step(f, .1)
    assert(c.kind == 'stop' and c.reason == 'path_unavailable')
    assert(n:status().state == 'waiting_path')
    f.path = frame().path
    assert(n:step(f, .1).kind == 'drive')
end)
test('stale path is refused', function()
    local n, f = running(); f.path.route_revision = 6
    assert(n:step(f, .1).kind == 'stop')
end)
test('path for another waypoint is refused', function()
    local n, f = running(); f.path.waypoint_id = 11
    assert(n:step(f, .1).kind == 'stop')
end)
test('waypoint transition waits for the corresponding native path', function()
    local n, f = running(); f.z = 1950
    local c = n:step(f, .1)
    assert(c.kind == 'stop' and n:status().index == 2)
    f.path = {ready = true, route_revision = 7, waypoint_id = 11,
        x = 1000, z = 2000, remaining_m = 1010}
    assert(n:step(f, .1).waypoint_id == 11)
end)
test('passed intermediate point is captured inside corridor', function()
    local n, f = running(); f.z = 2200
    n:step(f, .1)
    assert(n:status().index == 2)
end)
test('passing a distant parallel line does not skip a waypoint', function()
    local n, f = running(); f.x, f.z = 900, 2200
    n:step(f, .1)
    assert(n:status().index == 1)
end)
test('last waypoint enters stopping before arrival', function()
    local n, f = new(), frame()
    assert(n:set_route({route[1]}, 7)); assert(n:start(f))
    f.z, f.speed_mps = 1950, 3
    assert(n:step(f, .1).kind == 'stop')
    assert(n:status().state == 'stopping')
    f.speed_mps = .1
    assert(n:step(f, .1).kind == 'stop')
    assert(n:status().state == 'arrived')
    assert(n:step(f, .1).kind == 'none')
end)
test('approaching endpoint lowers target speed', function()
    local n, f = new(), frame()
    assert(n:set_route({route[1]}, 7)); assert(n:start(f))
    f.z, f.path.remaining_m = 1800, 200
    local c = n:step(f, .1)
    assert(c.target_speed_mps < 15 * M.MPS_PER_KNOT)
end)
test('coasting beyond the endpoint is not reported as successful arrival', function()
    local n, f = new(), frame()
    assert(n:set_route({route[1]}, 7)); assert(n:start(f))
    f.z, f.speed_mps = 1950, 3; n:step(f, .1)
    f.z, f.speed_mps = 2500, .1; n:step(f, .1)
    assert(n:status().state == 'paused' and n:status().reason == 'endpoint_overshoot')
end)
test('heading wraps across north by the short turn', function()
    local n, f = running(); f.heading = math.pi * 2 - .01
    local c = n:step(f, .1)
    assert(c.steering > 0 and c.steering < .1)
end)
test('manual takeover releases controls without neutralizing the helm', function()
    local n, f = running(); f.manual = true
    local c = n:step(f, .1)
    assert(c.kind == 'release' and c.throttle == nil)
    f.manual = false
    assert(n:step(f, .1).kind == 'none')
    assert(n:start(f))
    assert(n:step(f, .1).kind == 'drive')
end)
test('lost authority releases and does not automatically resume', function()
    local n, f = running(); f.can_control = false
    assert(n:step(f, .1).kind == 'release')
    f.can_control = true
    assert(n:step(f, .1).kind == 'none')
end)
test('carrier or session change clears the route', function()
    for _, key in ipairs({'id', 'generation', 'team'}) do
        local n, f = running(); f[key] = f[key] + 1
        assert(n:step(f, .1).kind == 'release')
        assert(n:status().count == 0)
    end
end)
test('engine off requires explicit restart', function()
    local n, f = running(); f.engine_on = false
    assert(n:step(f, .1).kind == 'release')
    f.engine_on = true
    assert(n:step(f, .1).kind == 'none')
end)
test('route revision mismatch stops and requires explicit restart', function()
    local n, f = running(); f.route_revision = 8
    assert(n:step(f, .1).kind == 'stop')
    f.route_revision = 7
    assert(n:step(f, .1).kind == 'stop')
end)
test('invalid timestep cannot generate throttle', function()
    for _, dt in ipairs({0, -1, 2, math.huge}) do
        local n, f = running()
        assert(n:step(f, dt).kind == 'stop')
    end
end)
test('nonfinite telemetry releases controls', function()
    local n, f = running(); f.heading = 0/0
    assert(n:step(f, .1).kind == 'release')
end)
test('checkpoint is a copy and restore never starts movement', function()
    local n, f = running()
    assert(n:set_speed(12))
    local record = n:checkpoint()
    local restored = new()
    assert(restored:restore(record, route, 7))
    assert(restored:status().speed_knots == 12)
    assert(restored:step(f, .1).kind == 'none')
    record.route[1].z = 123
    assert(restored:checkpoint().route[1].z == 2000)
end)
test('restore rejects a different native route transactionally', function()
    local n = new(); assert(n:set_route(route, 7))
    local save = n:checkpoint(); save.route[1].z = 123
    local ok, reason = n:restore(save, route, 7)
    assert(not ok and reason == 'route_mismatch')
    assert(n:status().route_revision == 7)
end)
test('restart cannot bind an old route to another session', function()
    local n, f = running(); n:pause(); f.generation = 2
    local ok, reason = n:start(f)
    assert(not ok and reason == 'context_changed' and n:status().count == 0)
end)
test('closed loop speed settles and follows a changed setpoint', function()
    local n, f = running()
    local function simulate(seconds)
        for _ = 1, seconds*10 do
            local c = n:step(f, .1)
            assert(c.kind == 'drive' and c.throttle >= 0 and c.throttle <= 1)
            f.throttle = c.throttle
            -- Synthetic motor/drag model, not Carrier Command 2 physics.
            f.speed_mps = math.max(0, f.speed_mps + (.1*f.throttle-.008*f.speed_mps)*.1)
        end
    end
    simulate(600)
    assert(math.abs(f.speed_mps-15*M.MPS_PER_KNOT) < .3)
    assert(n:set_speed(5)); simulate(600)
    assert(math.abs(f.speed_mps-5*M.MPS_PER_KNOT) < .3)
end)
print('SCENARIOS ' .. count)
