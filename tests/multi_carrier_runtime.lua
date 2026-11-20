local count=0
local function test(name,fn)local ok,why=pcall(fn);assert(ok,name..': '..tostring(why));count=count+1;print('PASS '..name)end
local function fixture(settings)
    local f={generation=1,messages={},published={},settings=settings or {},calls={},motions={},buttons={}}
    for _,id in ipairs({42,43,44})do
        f.motions[id]={id=id,team=0,can_control=true,manual=false,engine_on=true,active=false,mode=1,
            waypoints=2,speed_mps=0,guidance_ready=true,heading_error=0,path_distance=1000,lever=1}
        f.buttons[id]={{name='carrier_weapons_active_0',on=false,enabled=true}}
    end
    local c={settings={},messages={},session={},world={},carrier={}}
    c.settings.get=function(key,fallback)return f.settings[key] or fallback end
    c.settings.set=function(key,value)f.settings[key]=value;return true end
    c.session.generation=function()return f.generation end
    c.messages.publish=function(topic,id,value)f.published[topic..':'..id]=value;return true end
    c.messages.poll=function()local q=f.messages;f.messages={};return q end
    c.world.vehicles=function()return {{id=42,team=0,x=0,z=0,is_air=false,team_is_ai=false},
        {id=43,team=0,x=100,z=0,is_air=false,team_is_ai=false},{id=44,team=0,x=200,z=0,is_air=false,team_is_ai=false}}end
    c.world.buttons=function(id)return f.buttons[id] end
    c.world.set_buttons=function()return true end
    c.carrier.motion_available=function()return true end
    c.carrier.motion_state=function(id)return f.motions[id]end
    c.carrier.contacts=function()return {} end
    c.carrier.set_motion=function(id,active,power)
        assert(f.motions[id]);f.calls[#f.calls+1]={id=id,active=active,power=power}
        f.motions[id].active=active;f.motions[id].mode=active and 0 or 1;return true
    end
    c.carrier.drive_motion=function(id,power,forward)
        c.carrier.set_motion(id,true,power);f.calls[#f.calls].forward=forward;return true
    end
    function f.send(id,topic,value)f.messages[#f.messages+1]={subject=id,topic=topic,value=value}end
    function f.last(id)for i=#f.calls,1,-1 do if f.calls[i].id==id then return f.calls[i]end end end
    return POLICY.new(c),f
end
test('power changes belong to one of three simultaneously running carriers',function()
    local r,f=fixture();r:update()
    for _,id in ipairs({42,43,44})do f.send(id,'start',1)end;r:update()
    f.send(43,'speed',20);r:update()
    assert(f.published['speed:42']==100 and f.published['speed:43']==20 and f.published['speed:44']==100)
    assert(f.last(42).power==1 and f.last(43).power==.2 and f.last(44).power==1)
end)
test('automatic defence belongs to the requested carrier only',function()
    local r,f=fixture();r:update();f.send(43,'defence',1);r:update()
    assert(f.published['defence:42']==0 and f.published['defence:43']==1 and f.published['defence:44']==0)
    f.send(42,'defence',1);f.send(43,'defence',0);r:update()
    assert(f.published['defence:42']==1 and f.published['defence:43']==0 and f.published['defence:44']==0)
end)
test('pause and manual takeover cannot stop another carrier',function()
    local r,f=fixture();r:update();for _,id in ipairs({42,43,44})do f.send(id,'start',1)end;r:update()
    f.send(43,'pause',0);r:update();assert(f.published['state:42']==2 and f.published['state:43']==1 and f.published['state:44']==2)
    f.motions[42].manual=true;r:update();assert(f.published['state:42']==1 and f.published['state:44']==2)
end)
test('per-carrier power preference survives module recreation without replacing native routes',function()
    local r,f=fixture();r:update();f.send(43,'speed',30);r:update()
    assert(f.settings.cruise_0_43==30 and f.settings.cruise_percent==nil)
    local r2,g=fixture(f.settings);r2:update()
    assert(g.published['speed:42']==100 and g.published['speed:43']==30 and g.published['speed:44']==100)
    assert(g.motions[42].waypoints==2 and g.motions[43].waypoints==2 and g.motions[44].waypoints==2)
end)
test('session identity is published and authority is revoked on unreadable carriers',function()
    local r,f=fixture();r:update();assert(f.published['session:0']==1)
    f.motions[43]=nil;r:update();assert(f.published['authority:43']==0)
    f.generation=2;r:update();assert(f.published['session:0']==2)
end)
test('unknown carriers and denied native authority do not accept commands',function()
    local r,f=fixture();r:update();f.motions[43].can_control=false
    f.send(99,'speed',10);f.send(43,'defence',1);r:update()
    assert(f.published['authority:43']==0 and f.published['defence:42']==0 and #f.calls==0)
end)
print('SCENARIOS '..count)
