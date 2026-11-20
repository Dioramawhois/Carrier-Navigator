local count=0
local function test(name,fn)local ok,why=pcall(fn);assert(ok,name..': '..tostring(why));count=count+1;print('PASS '..name)end
local function frame(error,distance,lever)
    return {guidance_ready=true,heading_error=error or 0,path_distance=distance or 1000,lever=lever or 1,speed_mps=0,
        navigation={configured=true,ready=true,blocked=false,arrived=false,faulted=false,
            distance=distance or 1000,arrival_radius=25,minimum_depth=0}}
end
local function settle(c,f,percent)
    local cap,forward
    for _=1,300 do cap,forward=c.step(f,percent or 100,1/30) end
    return cap,forward
end
test('straight full power has no fixed game-speed limit',function()
    for _,speed in ipairs({0,15,25,60,150})do
        local f=frame();f.speed_mps=speed;f.navigation.distance=1000000
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

test('precise raw goal controls approach instead of a distant native steering target',function()
    local f=frame(0,1000);f.navigation.distance=40;f.speed_mps=12
    local cap,forward=POLICY.new().step(f,100,1/30)
    assert(cap==1 and forward==0)
end)

test('a nearby intermediate corner retains native slowdown without marking goal arrival',function()
    local f=frame(0,5);f.navigation.distance=10000;f.speed_mps=5
    local cap,forward=POLICY.new().step(f,100,1/30)
    assert(cap==1 and forward>0 and forward<=.05)
end)

test('high speed starts coasting before a low speed approach at the same distance',function()
    local slow,fast=frame(),frame()
    slow.speed_mps,fast.speed_mps=2,20
    local _,slow_forward=POLICY.new().step(slow,100,1/30)
    local _,fast_forward=POLICY.new().step(fast,100,1/30)
    assert(slow_forward==1 and fast_forward==0)
end)

test('configured arrival radius stops forward demand at the actual requested point',function()
    for _,distance in ipairs({0,5,24,25})do
        local f=frame(0,1000);f.navigation.distance=distance
        local _,forward=POLICY.new().step(f,100,1/30)
        assert(forward==0)
    end
end)

test('a close reversal does not force the open-water minimum ahead setting',function()
    local f=frame(math.pi);f.navigation.distance=40
    local _,forward=POLICY.new().step(f,100,1/30)
    assert(forward>=0 and forward<.06)
end)

test('missing unconfigured blocked or faulted navigation never requests forward',function()
    for _,flag in ipairs({'missing','configured','ready','blocked','faulted','arrived','distance','radius','speed'})do
        local f=frame()
        if flag=='missing'then f.navigation=nil
        elseif flag=='distance'then f.navigation.distance=0/0
        elseif flag=='radius'then f.navigation.arrival_radius=-1
        elseif flag=='speed'then f.speed_mps=math.huge
        elseif flag=='configured' or flag=='ready'then f.navigation[flag]=false
        else f.navigation[flag]=true end
        local cap,forward=POLICY.new().step(f,100,1/30)
        assert(cap==1 and forward==0,flag)
    end
end)
test('native compatibility matches published cruise across course power endpoint and reset changes',function()
    local current,reference=POLICY.new('native'),POLICY.native_reference()
    for i=1,2000 do
        if i%173==0 then current.reset();reference.reset()end
        local f={guidance_ready=i%53~=0,heading_error=math.sin(i)*math.pi,
            path_distance=i%121,lever=(i%101)/100,speed_mps=i%200}
        if i%71==0 then f.path_distance=-1 end
        local percent=10+(i%10)*10
        local a,b=current.step(f,percent,1/30)
        local x,y=reference.step(f,percent,1/30)
        assert(a==x and b==y,'published native demand changed at step '..i)
    end
end)
print('SCENARIOS '..count)
