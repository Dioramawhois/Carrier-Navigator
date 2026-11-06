-- SPDX-License-Identifier: GPL-3.0-or-later
local M = {}
local systems = {
    anti_air = {'carrier_weapons_active_0', 'carrier_weapons_active_1'},
    ciws = {'carrier_weapons_active_3', 'carrier_weapons_active_4', 'carrier_weapons_active_5', 'carrier_weapons_active_6'},
    torpedo_defence = {'carrier_countermeasure_active'},
    countermeasures = {'carrier_countermeasure_active'},
}
function M.new(cc2, Cruise, Defence)
    local states, generation, tick, enabled, catalog = {}, 0, 0, false, {}
    local speed = cc2.settings.get('cruise_percent', 100, 10, 100)
    local self = {}
    local function publish(topic, id, value) cc2.messages.publish(topic, id, value) end
    local function get_state(id)
        if not states[id] then states[id] = {running = false, was_active = false,
            cruise = Cruise.new(), defence = Defence.new({aircraft_range_m = 6000,
                surface_range_m = 5000, missile_range_m = 4000, torpedo_range_m = 5000}),
            pending = {}, buttons = {}, manual_locks = {}, threats = 0, history = {}} end
        return states[id]
    end
    function self:buttons(id)
        local s = states[id]; if not s then return end
        local motion = cc2.carrier.motion_state(id)
        if not motion or not motion.can_control then return end
        local buttons = cc2.world.buttons(id); if not buttons then return end
        local changes = {}
        for _, b in ipairs(buttons) do
            if s.buttons[b.name] == true and b.on == false then s.manual_locks[b.name] = true end
            if enabled and s.pending[b.name] and b.enabled and not b.on and not s.manual_locks[b.name] then changes[b.name] = true end
            s.buttons[b.name] = b.on
        end
        if next(changes) then
            local ok = cc2.world.set_buttons(id, changes)
            if ok then for name in pairs(changes) do s.buttons[name] = true end end
        end
    end
    function self:update()
        local current = cc2.session.generation()
        if current ~= generation then
            states, generation, tick, enabled, catalog = {}, current, 0, false, {}
        end
        if current == 0 then return end
        tick = tick+1
        publish('ready', 0, cc2.carrier.motion_available() and 1 or 0)
        local messages = cc2.messages.poll() or {}
        for _, m in ipairs(messages) do
            local motion = cc2.carrier.motion_state(m.subject)
            if motion and motion.can_control then
                local s = get_state(m.subject)
                if m.topic == 'start' and m.value == 1 and motion.waypoints > 0 then
                    s.running, s.was_active = true, false; s.cruise.reset()
                elseif m.topic == 'pause' then
                    s.running = false; cc2.carrier.set_motion(m.subject, false, 0)
                elseif m.topic == 'speed' and m.value >= 10 and m.value <= 100 and m.value % 1 == 0 then
                    speed = m.value; cc2.settings.set('cruise_percent', speed)
                    for _, state in pairs(states) do state.cruise.reset() end
                elseif m.topic == 'defence' and (m.value == 0 or m.value == 1) then
                    enabled = m.value == 1
                    for _, state in pairs(states) do state.manual_locks, state.pending = {}, {} end
                elseif m.topic:sub(1, 5) == 'type.' and m.value >= 0 and m.value <= 4096 and m.value % 1 == 0 then
                    catalog[m.topic:sub(6)] = m.value
                end
            end
        end
        for _, v in ipairs(cc2.world.vehicles() or {}) do
            if not v.is_air and not v.team_is_ai then
                local motion = cc2.carrier.motion_state(v.id)
                if motion then publish('authority', v.id, motion.can_control and 1 or 0) end
                if motion and motion.can_control then
                    local fresh = states[v.id] == nil
                    local s = get_state(v.id)
                    -- Native mode and native waypoints are part of the game save.
                    if fresh and motion.mode == 0 and motion.waypoints > 0 then s.running = true end
                    if motion.manual or s.was_active and not motion.active or motion.waypoints == 0 then s.running = false end
                    if s.running then
                        local power,forward = s.cruise.step(motion, speed, 1/30)
                        if not cc2.carrier.drive_motion(v.id, power, forward) then s.running = false end
                    elseif motion.active then cc2.carrier.set_motion(v.id, false, 0) end
                    s.was_active = s.running
                    s.pending, s.threats = {}, 0
                    local contacts = cc2.carrier.contacts(v.id)
                    local candidates, history = {}, {}
                    for _, c in ipairs(contacts or {}) do
                        if c.detected and c.team ~= v.team then
                            local d = math.sqrt((c.x-v.x)^2+(c.z-v.z)^2)
                            local kind
                            if c.kind == 1 then
                                local unit = cc2.world.vehicle(c.id)
                                if unit then kind = unit.is_air and 'aircraft' or 'surface' end
                            elseif c.definition == catalog.torpedo or c.definition == catalog.torpedo_decoy then kind = 'torpedo'
                            elseif c.definition ~= catalog.torpedo_noisemaker and c.definition ~= catalog.torpedo_sonar_buoy and catalog.torpedo then kind = 'missile' end
                            local previous = s.history[c.id]
                            local inbound = d < 1500 or previous and d < previous-.01
                            candidates[#candidates+1] = {id = c.id, kind = kind, hostile = true, current = true,
                                detected = true, range_m = d, inbound = inbound == true}
                            history[c.id] = d
                        end
                    end
                    s.history = history
                    local inventory = {}
                    for group, names in pairs(systems) do
                        local available, armed, locked = false, true, false
                        for _, name in ipairs(names) do
                            if s.buttons[name] ~= nil then available = true; armed = armed and s.buttons[name] end
                            locked = locked or s.manual_locks[name] == true
                        end
                        inventory[group] = {available = available, armed = armed, manual_lock = locked}
                    end
                    local result = s.defence:step({generation = current, id = v.id, team = v.team, can_control = true,
                        enabled = enabled, time_s = tick/30, contacts = candidates, systems = inventory})
                    s.threats = result.threats
                    for _, group in ipairs(result.arm) do for _, name in ipairs(systems[group]) do s.pending[name] = true end end
                    publish('state', v.id, s.running and 2 or motion.waypoints == 0 and 4 or 1)
                    publish('speed', v.id, speed); publish('actual', v.id, motion.speed_mps*3600/1852)
                    publish('defence', v.id, enabled and 1 or 0); publish('threats', v.id, s.threats)
                    publish('contacts', v.id, contacts and 1 or 0)
                end
            end
        end
    end
    function self:unload()
        for id in pairs(states) do cc2.carrier.set_motion(id, false, 0) end
    end
    return self
end
return M
