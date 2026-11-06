-- SPDX-License-Identifier: GPL-3.0-or-later
-- Pure route/controller policy. Only the engine adapter may supply telemetry,
-- native paths and authority; this module never writes bodies or calls the OS.
local M = {MPS_PER_KNOT = 1852 / 3600}
local pi = math.pi
local function finite(v) return type(v) == 'number' and v == v and math.abs(v) < math.huge end
local function integer(v, low) return finite(v) and v % 1 == 0 and v >= low and v <= 4294967295 end
local function clamp(v, lo, hi) return math.max(lo, math.min(v, hi)) end
local function distance(x, z, p) return math.sqrt((p.x-x)^2 + (p.z-z)^2) end
local function copy_route(route)
    if type(route) ~= 'table' or #route > 20 then return nil end
    local result, ids, entries = {}, {}, 0
    for k in pairs(route) do
        if not integer(k, 1) or k > #route then return nil end
        entries = entries + 1
    end
    if entries ~= #route then return nil end
    for _, p in ipairs(route) do
        if type(p) ~= 'table' or not integer(p.id, 1) or ids[p.id] or
            not finite(p.x) or not finite(p.z) or math.abs(p.x) > 1e7 or math.abs(p.z) > 1e7 then return nil end
        ids[p.id] = true
        result[#result+1] = {id = p.id, x = p.x, z = p.z}
    end
    return result
end
local function valid_frame(f)
    if type(f) ~= 'table' or not integer(f.generation, 1) or not integer(f.id, 1) or
        not integer(f.team, 0) or type(f.can_control) ~= 'boolean' or
        type(f.manual) ~= 'boolean' or type(f.engine_on) ~= 'boolean' then return false end
    for _, key in ipairs({'x', 'z', 'heading', 'speed_mps', 'yaw_rate', 'throttle'}) do
        if not finite(f[key]) then return false end
    end
    return f.speed_mps >= 0 and f.throttle >= 0 and f.throttle <= 1
end
local function command(kind, reason)
    local c = {kind = kind, reason = reason}
    if kind == 'stop' then c.throttle, c.steering = 0, 0 end
    return c
end

function M.new(options)
    options = options or {}
    assert(finite(options.max_speed_knots) and options.max_speed_knots > 0,
        'max_speed_knots must come from the reviewed carrier profile')
    local maximum = options.max_speed_knots
    local function positive(name, default)
        local value = options[name]
        if value == nil then value = default end
        assert(finite(value) and value > 0, 'invalid controller option: ' .. name)
        return value
    end
    -- Initial tuning for offline simulation only, not a measured ship model.
    local radius = positive('capture_radius_m', 100)
    local deceleration = positive('deceleration_mps2', .02)
    local throttle_up = positive('throttle_up_per_s', .08)
    local throttle_down = positive('throttle_down_per_s', .15)
    local self = {route = {}, revision = 0, index = 1, state = 'idle',
        reason = 'empty_route', speed = math.min(15, maximum),
        integral = 0, bound = nil, origin = nil, owns = false}

    local function stop(reason)
        self.state, self.reason, self.integral = 'paused', reason, 0
        return command('stop', reason)
    end
    local function release(reason, clear)
        self.owns, self.integral = false, 0
        self.state, self.reason = 'paused', reason
        if clear then
            self.route, self.revision, self.index, self.bound, self.origin = {}, 0, 1, nil, nil
            self.state = 'idle'
        end
        return command('release', reason)
    end
    function self:set_speed(knots)
        if not finite(knots) or knots <= 0 or knots > maximum then return false, 'invalid_speed' end
        self.speed, self.integral = knots, 0
        return true
    end
    function self:set_route(route, revision)
        local copied = copy_route(route)
        if not copied or not integer(revision, 1) then return false, 'invalid_route' end
        self.route, self.revision, self.index, self.integral = copied, revision, 1, 0
        self.origin = nil
        self.state = #copied > 0 and 'paused' or 'idle'
        self.reason = 'route_changed'
        return true
    end
    function self:start(f)
        if #self.route == 0 then return false, 'empty_route' end
        if not valid_frame(f) then return false, 'invalid_telemetry' end
        if self.bound then
            for _, k in ipairs({'generation', 'id', 'team'}) do
                if f[k] ~= self.bound[k] then release('context_changed', true); return false, 'context_changed' end
            end
        end
        if not f.can_control then return false, 'no_authority' end
        if f.manual then return false, 'manual_control' end
        if not f.engine_on then return false, 'engine_off' end
        if f.route_revision ~= self.revision then return false, 'route_changed' end
        if self.state == 'arrived' then return false, 'route_complete' end
        self.bound = {generation = f.generation, id = f.id, team = f.team}
        self.origin = self.origin or {x = f.x, z = f.z}
        self.state, self.reason, self.integral, self.owns = 'following', 'started', 0, true
        return true
    end
    function self:pause()
        if self.owns then stop('player_pause') end
    end
    function self:step(f, dt)
        if not self.owns then return command('none', self.reason) end
        if not valid_frame(f) then return release('invalid_telemetry', false) end
        for _, k in ipairs({'generation', 'id', 'team'}) do
            if not self.bound or f[k] ~= self.bound[k] then return release('context_changed', true) end
        end
        if f.manual then return release('manual_control', false) end
        if not f.can_control then return release('no_authority', false) end
        if not f.engine_on then return release('engine_off', false) end
        if not finite(dt) or dt <= 0 or dt > 1 then return stop('tick_gap') end
        if f.route_revision ~= self.revision then return stop('route_changed') end
        if self.state == 'paused' or self.state == 'idle' then return command('stop', self.reason) end
        if self.state == 'stopping' then
            if f.speed_mps <= .25 then
                if distance(f.x, f.z, self.route[#self.route]) <= radius then
                    self.state, self.reason = 'arrived', 'route_complete'
                else self.state, self.reason = 'paused', 'endpoint_overshoot' end
                self.owns = false
            end
            return command('stop', self.reason)
        end

        local waypoint = self.route[self.index]
        local remaining = distance(f.x, f.z, waypoint)
        local previous = self.route[self.index-1] or self.origin
        local passed = false
        if previous and self.index < #self.route then
            local dx, dz = waypoint.x-previous.x, waypoint.z-previous.z
            local length2 = dx*dx + dz*dz
            if length2 > 0 then
                local along = ((f.x-previous.x)*dx + (f.z-previous.z)*dz) / length2
                local cross = math.abs((f.x-previous.x)*dz - (f.z-previous.z)*dx) / math.sqrt(length2)
                passed = along >= 1 and cross <= radius
            end
        end
        if remaining <= radius or passed then
            if self.index == #self.route then
                self.state, self.reason = 'stopping', 'endpoint_reached'
                return command('stop', self.reason)
            end
            self.index = self.index + 1
            waypoint = self.route[self.index]
        end

        local path = f.path
        if type(path) ~= 'table' or path.ready ~= true or path.route_revision ~= self.revision or
            path.waypoint_id ~= waypoint.id or not finite(path.x) or not finite(path.z) or
            not finite(path.remaining_m) or path.remaining_m < distance(f.x, f.z, path) then
            self.state, self.reason, self.integral = 'waiting_path', 'path_unavailable', 0
            return command('stop', self.reason)
        end
        local dx, dz = path.x-f.x, path.z-f.z
        if dx*dx + dz*dz < 1 then
            self.state, self.reason = 'waiting_path', 'path_node_reached'
            return command('stop', self.reason)
        end
        local error = (math.atan(dx, dz)-f.heading+pi) % (2*pi) - pi
        local steering = clamp(error*.8 - f.yaw_rate*3, -1, 1)
        local target = self.speed * M.MPS_PER_KNOT
        -- Reduce speed for sharp turns. Only native path nodes determine heading.
        target = target * math.max(.2, math.cos(math.min(math.abs(error), pi/2)))
        if self.index == #self.route then
            target = math.min(target, math.sqrt(2*deceleration*math.max(0, path.remaining_m-radius)))
        end
        local speed_error = target-f.speed_mps
        local integral = clamp(self.integral + speed_error*dt*.008, 0, 1)
        local raw = speed_error*.12 + integral
        -- Conditional integration prevents windup at either throttle limit.
        if (raw >= 0 and raw <= 1) or (raw > 1 and speed_error < 0) or (raw < 0 and speed_error > 0) then
            self.integral = integral
        end
        local throttle = clamp(clamp(raw, 0, 1),
            math.max(0, f.throttle-throttle_down*dt), math.min(1, f.throttle+throttle_up*dt))
        self.state, self.reason = 'following', 'native_path'
        return {kind = 'drive', reason = self.reason, throttle = throttle, steering = steering,
            target_speed_mps = target, waypoint_id = waypoint.id}
    end
    function self:status()
        return {state = self.state, reason = self.reason, index = self.index,
            count = #self.route, route_revision = self.revision, speed_knots = self.speed}
    end
    function self:checkpoint()
        return {version = 1, route = copy_route(self.route), index = self.index, speed_knots = self.speed}
    end
    function self:restore(record, native_route, revision)
        if self.owns then return false, 'controls_engaged' end
        local route = copy_route(native_route)
        local saved = type(record) == 'table' and copy_route(record.route) or nil
        if not saved or not route or #route == 0 or #route ~= #saved or record.version ~= 1 or
            not integer(revision, 1) or not integer(record.index, 1) or record.index > #route or
            not finite(record.speed_knots) or record.speed_knots <= 0 or
            record.speed_knots > maximum then return false, 'invalid_checkpoint' end
        for i, p in ipairs(route) do
            local s = saved[i]
            if p.id ~= s.id or p.x ~= s.x or p.z ~= s.z then return false, 'route_mismatch' end
        end
        self.route, self.revision, self.index, self.speed = route, revision, record.index, record.speed_knots
        self.state, self.reason, self.integral, self.bound, self.origin = 'paused', 'restored', 0, nil, nil
        return true
    end
    return self
end
return M
