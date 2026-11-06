local M, count = POLICY, 0
local function test(name, fn)
    local ok, why = pcall(fn); assert(ok, name .. ': ' .. tostring(why))
    count = count+1; print('PASS ' .. name)
end
local function new()
    return M.new({aircraft_range_m = 5000, missile_range_m = 3000, torpedo_range_m = 4000})
end
local function frame()
    return {generation = 1, id = 42, team = 0, can_control = true, enabled = true,
        time_s = 10, contacts = {{id = 70, hostile = true, current = true,
            radar = true, visual = false, kind = 'aircraft', range_m = 1000}},
        systems = {anti_air = {available = true, armed = false, manual_lock = false},
            ciws = {available = true, armed = false, manual_lock = false},
            torpedo_defence = {available = true, armed = false, manual_lock = false},
            countermeasures = {available = true, armed = false, manual_lock = false}}}
end
local function has(result, name)
    for _, v in ipairs(result.arm) do if v == name then return true end end
    return false
end
test('radar alone activates air defence', function()
    local r = new():step(frame()); assert(has(r, 'anti_air') and has(r, 'ciws'))
end)
test('visual contact alone activates air defence', function()
    local f = frame(); f.contacts[1].radar, f.contacts[1].visual = false, true
    assert(has(new():step(f), 'anti_air'))
end)
test('both detection sources cause no duplicate requests', function()
    local f = frame(); f.contacts[1].visual = true
    assert(#new():step(f).arm == 2)
end)
test('hidden hostile does not activate defence', function()
    local f = frame(); f.contacts[1].radar = false
    assert(#new():step(f).arm == 0)
end)
test('old observation is not a current contact', function()
    local f = frame(); f.contacts[1].current = false
    assert(#new():step(f).arm == 0)
end)
test('friendly or unclassified allegiance is not hostile', function()
    local f = frame(); f.contacts[1].hostile = false
    assert(#new():step(f).arm == 0)
    f.contacts[1].hostile = nil
    assert(#new():step(f).arm == 0)
end)
test('distant contact is not an immediate defence trigger', function()
    local f = frame(); f.contacts[1].range_m = 5001
    assert(#new():step(f).arm == 0)
end)
test('unknown class is not inferred from hidden world data', function()
    local f = frame(); f.contacts[1].kind = 'unknown'
    assert(#new():step(f).arm == 0)
end)
test('incoming missile arms anti air and ciws', function()
    local f = frame(); f.contacts[1].kind, f.contacts[1].inbound = 'missile', true
    local r = new():step(f)
    assert(has(r, 'ciws') and has(r, 'anti_air') and not has(r, 'countermeasures'))
end)
test('incoming torpedo arms torpedo defence and countermeasures', function()
    local f = frame(); f.contacts[1].kind, f.contacts[1].inbound = 'torpedo', true
    local r = new():step(f)
    assert(has(r, 'torpedo_defence') and has(r, 'countermeasures'))
    assert(not has(r, 'anti_air') and not has(r, 'ciws'))
end)
test('nonincoming or unknown-direction ammunition is ignored', function()
    local f = frame(); f.contacts[1].kind, f.contacts[1].inbound = 'torpedo', false
    assert(#new():step(f).arm == 0)
    f.contacts[1].inbound = nil
    assert(#new():step(f).arm == 0)
end)
test('manual system lock is respected', function()
    local f = frame(); f.systems.anti_air.manual_lock = true
    local r = new():step(f); assert(not has(r, 'anti_air') and has(r, 'ciws'))
end)
test('armed systems are not toggled again', function()
    local f = frame(); f.systems.anti_air.armed = true
    assert(not has(new():step(f), 'anti_air'))
end)
test('unavailable systems are not requested', function()
    local f = frame(); f.systems.anti_air.available = false; f.systems.ciws = nil
    assert(#new():step(f).arm == 0)
end)
test('same threat on successive ticks does not spam pending actions', function()
    local d, f = new(), frame()
    assert(#d:step(f).arm == 2)
    f.time_s = 10.1; assert(#d:step(f).arm == 0)
    f.time_s = 11.1; assert(#d:step(f).arm == 2)
end)
test('no threat never requests automatic disarm or firing', function()
    local d, f = new(), frame(); d:step(f); f.contacts = {}
    local r = d:step(f)
    assert(#r.arm == 0 and r.disarm == nil and r.fire == nil)
end)
test('disabled automation does not alter systems', function()
    local f = frame(); f.enabled = false
    assert(#new():step(f).arm == 0)
end)
test('no authority never arms defence', function()
    local f = frame(); f.can_control = false
    assert(#new():step(f).arm == 0)
end)
test('nonfinite or negative range cannot activate defence', function()
    for _, v in ipairs({math.huge, -1, 0/0}) do
        local f = frame(); f.contacts[1].range_m = v
        assert(#new():step(f).arm == 0)
    end
end)
test('session change does not carry pending commands to a new carrier', function()
    local d, f = new(), frame(); d:step(f)
    f.generation, f.id, f.contacts = 2, 43, {}
    assert(#d:step(f).arm == 0)
end)
test('clock rewind discards pending state', function()
    local d, f = new(), frame(); d:step(f)
    f.time_s = 1
    assert(#d:step(f).arm == 2)
end)
test('detection flags require actual booleans', function()
    local f = frame(); f.contacts[1].radar = 1
    assert(#new():step(f).arm == 0)
end)
print('SCENARIOS ' .. count)
