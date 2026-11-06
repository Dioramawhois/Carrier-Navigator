local count = 0
local function test(name,fn)
    local ok,why=pcall(fn);assert(ok,name..': '..tostring(why));count=count+1;print('PASS '..name)
end
local function fixture()
    local f={generation=1,messages={},published={},calls={},contacts={},settings={}}
    f.motion={id=42,team=0,can_control=true,manual=false,engine_on=true,active=false,mode=1,waypoints=2,speed_mps=0,
        guidance_ready=true,heading_error=0,path_distance=1000,lever=1}
    f.buttons={}
    for i=0,8 do f.buttons[#f.buttons+1]={name='carrier_weapons_active_'..i,on=false,enabled=true} end
    f.buttons[#f.buttons+1]={name='carrier_countermeasure_active',on=false,enabled=true}
    local cc2={settings={},messages={},session={},world={},carrier={}}
    cc2.settings.get=function(_,fallback) return fallback end
    cc2.settings.set=function(name,value)f.settings[name]=value end
    cc2.session.generation=function()return f.generation end
    cc2.messages.publish=function(topic,id,value)f.published[topic..':'..id]=value end
    cc2.messages.poll=function()local q=f.messages;f.messages={};return q end
    cc2.world.vehicles=function()return {{id=42,team=0,x=0,z=0,is_air=false,team_is_ai=false}} end
    cc2.world.vehicle=function(id)return{id=id,is_air=true}end
    cc2.world.buttons=function()return f.buttons end
    cc2.world.set_buttons=function(id,values)
        assert(id==42)
        for _,b in ipairs(f.buttons)do if values[b.name]~=nil then b.on=values[b.name]end end
        return true
    end
    cc2.carrier.motion_available=function()return true end
    cc2.carrier.motion_state=function(id)if id==42 then return f.motion end end
    cc2.carrier.contacts=function()return f.contacts end
    cc2.carrier.set_motion=function(id,active,power)
        f.calls[#f.calls+1]={id=id,active=active,power=power}
        f.motion.active=active;f.motion.mode=active and 0 or 1;return true
    end
    cc2.carrier.drive_motion=function(id,power,forward)
        assert(forward>=0 and forward<=power)
        cc2.carrier.set_motion(id,true,power)
        f.calls[#f.calls].forward=forward
        return true
    end
    local runtime=POLICY.new(cc2)
    function f:send(topic,value,id)self.messages[#self.messages+1]={topic=topic,value=value,subject=id or 42}end
    return runtime,f
end
test('no automatic movement before Start',function()
    local r,f=fixture();r:update();assert(#f.calls==0 and f.published['state:42']==1)
end)
test('Start reaches the native motion API with nonzero bounded power',function()
    local r,f=fixture();r:update();f:send('start',1);r:update()
    assert(#f.calls==1 and f.calls[1].active and f.calls[1].power==1 and f.calls[1].forward==1)
end)

test('course changes reach native forward control without a stop command',function()
    local r,f=fixture();r:update();f:send('start',1);r:update()
    f.motion.heading_error=math.pi
    for _=1,90 do r:update() end
    assert(f.calls[#f.calls].active and f.calls[#f.calls].forward>=.35)
    for _,call in ipairs(f.calls)do assert(call.active and call.forward>0)end
end)
test('Pause reaches the native release API',function()
    local r,f=fixture();r:update();f:send('start',1);r:update();f:send('pause',0);r:update()
    assert(not f.calls[#f.calls].active and f.published['state:42']==1)
end)
test('speed selection persists only the preference',function()
    local r,f=fixture();r:update();f:send('speed',20);r:update()
    assert(f.settings.cruise_percent==20 and f.published['speed:42']==20)
    f:send('speed',101);r:update();assert(f.settings.cruise_percent==20)
end)
test('manual takeover does not automatically resume',function()
    local r,f=fixture();r:update();f:send('start',1);r:update()
    f.motion.manual,f.motion.active=true,true;r:update();f.motion.manual=false;r:update()
    assert(#f.calls==2 and not f.calls[2].active and f.published['state:42']==1)
end)
test('lost lease requires a new explicit Start',function()
    local r,f=fixture();r:update();f:send('start',1);r:update();f.motion.active=false;r:update()
    assert(#f.calls==1 and f.published['state:42']==1)
end)
test('native saved active route is adopted without replacing its points',function()
    local r,f=fixture();f.motion.mode=0;r:update()
    assert(f.calls[1].active and f.motion.waypoints==2)
end)
test('wrong carrier and absent authority refuse screen commands',function()
    local r,f=fixture();r:update();f:send('start',1,999);f.motion.can_control=false;f:send('start',1);r:update()
    assert(#f.calls==0 and f.published['authority:42']==0)
end)
test('aircraft threat arms AA and CIWS but no offensive weapons',function()
    local r,f=fixture();r:update();r:buttons(42)
    f.contacts={{id=70,team=1,kind=1,x=1000,y=100,z=0,detected=true}}
    f:send('defence',1);r:update();r:buttons(42)
    local armed={};for _,b in ipairs(f.buttons)do armed[b.name]=b.on end
    assert(armed.carrier_weapons_active_0 and armed.carrier_weapons_active_6)
    assert(not armed.carrier_weapons_active_2 and not armed.carrier_weapons_active_7 and not armed.carrier_weapons_active_8)
end)
test('known hostile torpedo enables native countermeasure automation',function()
    local r,f=fixture();r:update();r:buttons(42)
    f:send('type.torpedo',101);f:send('defence',1)
    f.contacts={{id=80,team=1,kind=2,definition=101,x=500,y=-10,z=0,detected=true}}
    r:update();r:buttons(42)
    assert(f.buttons[#f.buttons].on and f.published['threats:42']==1)
end)
test('friendly projectiles never activate automatic defence',function()
    local r,f=fixture();r:update();r:buttons(42);f:send('type.torpedo',101);f:send('defence',1)
    f.contacts={{id=80,team=0,kind=2,definition=101,x=500,y=-10,z=0,detected=true}}
    r:update();r:buttons(42);assert(not f.buttons[#f.buttons].on)
end)
test('unavailable sensors do not arm anything',function()
    local r,f=fixture();r:update();r:buttons(42);f:send('defence',1);f.contacts=nil;r:update();r:buttons(42)
    assert(f.published['contacts:42']==0)
    for _,b in ipairs(f.buttons)do assert(not b.on)end
end)
test('module unload releases the carrier',function()
    local r,f=fixture();r:update();f:send('start',1);r:update();r:unload();assert(not f.calls[#f.calls].active)
end)
print('SCENARIOS '..count)
