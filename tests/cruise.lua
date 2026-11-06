local count=0
local function test(name,fn)local ok,why=pcall(fn);assert(ok,name..': '..tostring(why));count=count+1;print('PASS '..name)end
local function frame(error,distance,lever)
    return {guidance_ready=true,heading_error=error or 0,path_distance=distance or 1000,lever=lever or 1}
end
local function settle(c,f,percent)
    local cap,forward
    for _=1,300 do cap,forward=c.step(f,percent or 100,1/30) end
    return cap,forward
end
test('straight full power has no fixed game-speed limit',function()
    for _,speed in ipairs({0,15,25,60,150})do
        local f=frame();f.speed_mps=speed
        local cap,forward=POLICY.new().step(f,100,1/30)
        assert(cap==1 and forward==1)
    end
end)
test('right-angle turn keeps meaningful ahead thrust',function()
    local cap,forward=settle(POLICY.new(),frame(math.pi/2))
    assert(cap==1 and math.abs(forward-.675)<1e-8)
end)
test('full reversal never becomes turn-in-place idle',function()
    local cap,forward=settle(POLICY.new(),frame(math.pi))
    assert(cap==1 and math.abs(forward-.35)<1e-8)
end)
test('port and starboard course changes use equal power',function()
    local _,a=settle(POLICY.new(),frame(math.pi/2))
    local _,b=settle(POLICY.new(),frame(-math.pi/2))
    assert(a==b)
end)
test('course change smoothly adjusts power without dropping to zero',function()
    local c=POLICY.new();c.step(frame(),100,1/30)
    local _,forward=c.step(frame(math.pi),100,1/30)
    assert(forward>.98 and forward<1)
end)
test('straightening course recovers full selected power smoothly',function()
    local c=POLICY.new();settle(c,frame(math.pi))
    local _,first=c.step(frame(),100,1/30);assert(first>.35 and first<.37)
    local _,full=settle(c,frame());assert(full==1)
end)
test('selected cap applies immediately without exceeding native range',function()
    local c=POLICY.new();c.step(frame(),100,1/30)
    local cap,forward=c.step(frame(),50,1/30);assert(cap==.5 and forward==.5)
    local low,ahead=settle(c,frame(math.pi),10)
    assert(low==.1 and math.abs(ahead-.035)<1e-8)
end)
test('near native endpoint reduces power and stops at the target',function()
    local c=POLICY.new();c.step(frame(),100,1/30)
    local _,near=c.step(frame(0,5),100,1/30);assert(near<=.05)
    local _,at=c.step(frame(0,0),100,1/30);assert(at==0)
end)
test('missing or invalid native guidance requests no ahead thrust',function()
    for _,f in ipairs({{}, {guidance_ready=true,heading_error=0/0,path_distance=100},
        {guidance_ready=true,heading_error=0,path_distance=-1}})do
        local cap,forward=POLICY.new().step(f,100,1/30);assert(cap==1 and forward==0)
    end
end)
test('invalid percentages and simulation times are refused',function()
    for _,percent in ipairs({-1,101,math.huge,0/0})do
        assert(not pcall(function()POLICY.new().step(frame(),percent,1/30)end))
    end
    assert(not pcall(function()POLICY.new().step(frame(),100,0)end))
end)
test('large simulation delta cannot make the lever jump',function()
    local _,forward=POLICY.new().step(frame(math.pi),100,10)
    assert(forward>.88 and forward<.9)
end)
test('reset adopts current live lever instead of previous route state',function()
    local c=POLICY.new();settle(c,frame(math.pi));c.reset()
    local _,forward=c.step(frame(0,1000,.8),100,1/30)
    assert(forward>.8 and forward<.82)
end)
print('SCENARIOS '..count)
