local count = 0
local function test(name,fn)
    local ok,why=pcall(fn);assert(ok,name..': '..tostring(why));count=count+1;print('PASS '..name)
end
local function fixture(options)
    options=options or {}
    local f={generation=1,messages={},published={},calls={},contacts={},settings={},configurations={},events={},navigation_available=true,configure_ok=true,drive_ok=true}
    f.motion={id=42,team=0,can_control=true,manual=false,engine_on=true,active=false,mode=1,waypoints=2,speed_mps=0,
        guidance_ready=true,heading_error=0,path_distance=1000,lever=1}
    f.navigation={configured=false,active=false,ready=true,blocked=false,arrived=false,faulted=false,
        distance=1000,arrival_radius=25,minimum_depth=0,waypoint_id=11,target_x=1234,target_z=5678}
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
    cc2.carrier.navigation_available=function()return f.navigation_available end
    cc2.carrier.set_navigation=function(id,options)
        assert(id==42 and options.minimum_depth==0 and options.arrival_radius==25)
        f.configurations[#f.configurations+1]={id=id,options=options}
        f.events[#f.events+1]='configure'
        if not f.configure_ok then return false end
        f.navigation.configured=true
        return true
    end
    cc2.carrier.navigation_state=function(id)if id==42 then return f.navigation end end
    cc2.carrier.motion_state=function(id)if id==42 then return f.motion end end
    cc2.carrier.contacts=function()return f.contacts end
    cc2.carrier.set_motion=function(id,active,power)
        f.events[#f.events+1]=active and 'lease' or 'release'
        f.calls[#f.calls+1]={id=id,active=active,power=power}
        if not active then f.navigation.configured=false end
        f.motion.active=active;f.motion.mode=active and 0 or 1;return true
    end
    cc2.carrier.drive_motion=function(id,power,forward)
        f.events[#f.events+1]='drive'
        if not f.drive_ok then return false end
        assert(forward>=0 and forward<=power)
        cc2.carrier.set_motion(id,true,power)
        f.calls[#f.calls].forward=forward
        return true
    end
    if options.optional_missing then
        cc2.carrier.navigation_available=nil;cc2.carrier.set_navigation=nil;cc2.carrier.navigation_state=nil
    elseif options.optional_partial then cc2.carrier.navigation_state=nil end
    if options.unavailable then f.navigation_available=false end
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
    assert(f.calls[1].active and f.motion.waypoints==2 and #f.configurations==1)
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

test('precise routing is configured before any motion request and renewed idempotently',function()
    local r,f=fixture();r:update();f:send('start',1);r:update()
    assert(f.events[1]=='configure' and f.events[2]=='drive')
    r:update();assert(#f.configurations==2 and f.motion.waypoints==2)
end)

test('navigation configuration failure releases and requires explicit Start to retry',function()
    local r,f=fixture();f.configure_ok=false;r:update();f:send('start',1);r:update()
    assert(#f.calls==1 and not f.calls[1].active and f.published['navigation_status:42']==6)
    f.configure_ok=true;r:update();assert(#f.configurations==1 and #f.calls==1)
    f:send('start',1);r:update();assert(f.calls[#f.calls].active)
end)

test('losing an admitted coastal backend stops instead of switching the active route to native',function()
    local r,f=fixture();r:update();f:send('start',1);r:update()
    f.navigation_available=false;r:update()
    assert(f.published['ready:0']==0 and f.published['navigation_status:42']==5)
    assert(#f.calls==2 and not f.calls[2].active and #f.configurations==1)
    f.navigation_available=true;r:update();assert(#f.calls==2)
end)

test('old absent partial and unavailable optional APIs retain native autopilot',function()
    for _,options in ipairs({{optional_missing=true},{optional_partial=true},{unavailable=true}})do
        local r,f=fixture(options);r:update();f:send('start',1);r:update()
        assert(f.published['ready:0']==1 and f.published['navigation_mode:0']==0)
        assert(f.calls[#f.calls].active and f.calls[#f.calls].forward==1 and #f.configurations==0)
        assert(f.published['navigation_status:42']==8)
        f.navigation.blocked=true;f.navigation.distance=1;f.motion.speed_mps=60
        r:update();assert(f.calls[#f.calls].forward==1 and #f.configurations==0)
        f:send('pause',0);r:update();assert(not f.calls[#f.calls].active)
    end
end)

test('native compatibility preserves saved routes speed defence and manual takeover',function()
    local r,f=fixture({optional_missing=true});f.motion.mode=0;r:update()
    assert(f.calls[1].active and f.motion.waypoints==2)
    f:send('speed',50);r:update();assert(f.calls[#f.calls].power==.5 and f.settings.cruise_percent==50)
    r:buttons(42);f:send('defence',1)
    f.contacts={{id=70,team=1,kind=1,x=1000,y=100,z=0,detected=true}}
    r:update();r:buttons(42);assert(f.buttons[1].on)
    f.motion.manual=true;r:update();assert(not f.calls[#f.calls].active)
    local calls=#f.calls;f.motion.manual=false;r:update();assert(#f.calls==calls)
end)

test('backend selection is stable during a session and renegotiated in the next session',function()
    local r,f=fixture({unavailable=true});r:update();f:send('start',1);r:update()
    f.navigation_available=true;r:update()
    assert(f.published['navigation_mode:0']==0 and #f.configurations==0)
    f.generation=2;r:update()
    assert(f.published['navigation_mode:0']==1 and #f.configurations==1)
end)

test('initial configured route waits for native admission with a zero-power lease',function()
    local r,f=fixture();f.navigation.ready=false;r:update();f:send('start',1);r:update()
    assert(#f.calls==1 and f.calls[1].active and f.calls[1].power==0 and f.calls[1].forward==nil)
    assert(f.published['navigation_status:42']==1)
    f.navigation.ready=true;r:update()
    assert(f.calls[#f.calls].active and f.calls[#f.calls].forward==1)
end)

test('blocked route releases motion without forced thrust or automatic resume',function()
    local r,f=fixture();r:update();f:send('start',1);r:update()
    f.navigation.blocked=true;r:update()
    assert(not f.calls[#f.calls].active and f.published['navigation_status:42']==3)
    local calls=#f.calls;f.navigation.blocked=false;r:update()
    assert(#f.calls==calls and f.published['state:42']==1)
end)

test('arrived and faulted routes release without rewriting native route or repeat data',function()
    for _,case in ipairs({{'arrived',4},{'faulted',7}})do
        local r,f=fixture();r:update();f:send('start',1);r:update()
        if case[1]=='arrived'then f.motion.waypoints=0;f.navigation.distance=20 end
        f.navigation[case[1]]=true;r:update()
        assert(not f.calls[#f.calls].active and f.published['navigation_status:42']==case[2])
        assert(f.motion.waypoints==(case[1]=='arrived' and 0 or 2))
    end
end)

test('near-shore speed-aware coasting uses SDK exact target telemetry',function()
    local r,f=fixture();f.motion.speed_mps=12;f.navigation.distance=40
    r:update();f:send('start',1);r:update()
    assert(f.calls[#f.calls].active and f.calls[#f.calls].forward==0)
    assert(f.published['navigation_distance:42']==40)
    assert(f.published['navigation_target_x:42']==1234 and f.published['navigation_target_z:42']==5678)
    assert(f.published['navigation_waypoint:42']==11 and f.published['navigation_radius:42']==25)
end)

test('failed drive releases its configured motion instead of leaving a stale lease',function()
    local r,f=fixture();r:update();f:send('start',1);r:update()
    f.drive_ok=false;r:update()
    assert(not f.calls[#f.calls].active and f.published['navigation_status:42']==7)
    local calls=#f.calls;r:update();assert(#f.calls==calls)
end)

test('native intermediate and repeated legs advance without releasing motion',function()
    local r,f=fixture();r:update();f:send('start',1);r:update()
    f.navigation.distance=20;r:update()
    assert(f.calls[#f.calls].active and f.calls[#f.calls].forward==0)
    assert(f.published['navigation_status:42']==2 and f.motion.waypoints==2)
    f.navigation.waypoint_id=12;f.navigation.distance=5000;f.motion.path_distance=5;r:update()
    assert(f.calls[#f.calls].active and f.calls[#f.calls].forward>0)
    assert(f.published['navigation_waypoint:42']==12)
    for _,call in ipairs(f.calls)do assert(call.active)end
end)

test('an arrived snapshot cannot release a nonempty repeated route',function()
    local r,f=fixture();r:update();f:send('start',1);r:update()
    f.navigation.arrived=true;f.navigation.distance=20;r:update()
    assert(f.calls[#f.calls].active and f.calls[#f.calls].forward==0 and f.motion.waypoints==2)
    f.navigation.arrived=false;f.navigation.waypoint_id=12;f.navigation.distance=5000;r:update()
    assert(f.calls[#f.calls].active and f.calls[#f.calls].forward>0)
end)

test('missing or mismatched configured telemetry releases instead of using motion guidance',function()
    for _,field in ipairs({'configured','minimum_depth','arrival_radius'})do
        local r,f=fixture();r:update();f:send('start',1);r:update()
        if field=='configured'then f.configure_ok=false else f.navigation[field]=123 end
        r:update();assert(not f.calls[#f.calls].active and f.published['navigation_status:42']==6)
    end
end)
print('SCENARIOS '..count)
