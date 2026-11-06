-- SPDX-License-Identifier: GPL-3.0-or-later
-- Decisions over an authoritative, team-filtered contact snapshot. No scans of
-- world vehicles, target assignment, weapon fire or guessed engine slot indices.
local M = {}
local function finite(v) return type(v) == 'number' and v == v and math.abs(v) < math.huge end
local function id(v, low) return finite(v) and v % 1 == 0 and v >= low and v <= 4294967295 end
local groups = {'anti_air', 'ciws', 'torpedo_defence', 'countermeasures'}
function M.new(options)
    options = options or {}
    local ranges = {aircraft = options.aircraft_range_m,
        surface = options.surface_range_m or options.aircraft_range_m,
        missile = options.missile_range_m, torpedo = options.torpedo_range_m}
    for _, kind in ipairs({'aircraft', 'missile', 'torpedo'}) do
        assert(finite(ranges[kind]) and ranges[kind] > 0, 'reviewed range required: ' .. kind)
    end
    local pending, context, last_time = {}, nil, nil
    local self = {}
    function self:step(f)
        local result = {arm = {}, threats = 0, reason = 'no_detected_threat'}
        if type(f) ~= 'table' or not id(f.generation, 1) or not id(f.id, 1) or
            not id(f.team, 0) or not finite(f.time_s) or f.time_s < 0 then
            pending, context, last_time = {}, nil, nil
            result.reason = 'invalid_context'; return result
        end
        local key = string.format('%.0f:%.0f:%.0f', f.generation, f.id, f.team)
        if key ~= context or (last_time and f.time_s < last_time) then pending = {} end
        context, last_time = key, f.time_s
        if f.can_control ~= true or f.enabled ~= true then
            pending = {}; result.reason = 'disabled_or_no_authority'; return result
        end
        if type(f.contacts) ~= 'table' or type(f.systems) ~= 'table' or #f.contacts > 4096 then
            result.reason = 'contacts_unavailable'; return result
        end
        local wanted = {}
        for _, c in ipairs(f.contacts) do
            if type(c) == 'table' and id(c.id, 1) and c.hostile == true and c.current == true and
                (c.detected == true or c.radar == true or c.visual == true) and finite(c.range_m) and c.range_m >= 0 and
                ranges[c.kind] and c.range_m <= ranges[c.kind] then
                if c.kind == 'aircraft' or c.kind == 'surface' or c.inbound == true then
                    result.threats = result.threats+1
                    if c.kind == 'torpedo' then
                        wanted.torpedo_defence, wanted.countermeasures = true, true
                    elseif c.kind == 'surface' then
                        wanted.ciws, wanted.torpedo_defence, wanted.countermeasures = true, true, true
                    else wanted.anti_air, wanted.ciws = true, true end
                end
            end
        end
        if result.threats > 0 then result.reason = 'detected_threat' end
        for _, name in ipairs(groups) do
            local s = f.systems[name]
            if wanted[name] and type(s) == 'table' and s.available == true and
                s.armed == false and s.manual_lock == false then
                -- Retry arming only; never turn this into repeated consumable fire.
                if not pending[name] or f.time_s-pending[name] >= 1 then
                    result.arm[#result.arm+1], pending[name] = name, f.time_s
                end
            else pending[name] = nil end
        end
        return result
    end
    return self
end
return M
