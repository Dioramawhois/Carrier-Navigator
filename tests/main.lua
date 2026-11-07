local count=0
local function test(name,fn)local ok,why=pcall(fn);assert(ok,name..': '..tostring(why));count=count+1;print('PASS '..name)end

test('an old motion-only SDK loads the Navigator and keeps its lifecycle',function()
    POLICY.on_load();assert(TEST.created==1 and TEST.events.vehicle_controls)
    POLICY.on_update();assert(TEST.updates==1)
    POLICY.on_unload();assert(TEST.unloads==1 and TEST.events.vehicle_controls==nil)
end)

test('an unavailable optional backend does not prevent module loading',function()
    TEST.carrier.navigation_available=function()return false end
    TEST.carrier.navigation_state=function()return {}end
    TEST.carrier.set_navigation=function()return true end
    POLICY.on_load();assert(TEST.created==2 and TEST.events.vehicle_controls)
    POLICY.on_unload()
end)

test('complete optional navigation support preserves module update and unload lifecycle',function()
    TEST.carrier.navigation_available=function()return true end
    POLICY.on_load();assert(TEST.created==3 and TEST.events.vehicle_controls)
    POLICY.on_update();assert(TEST.updates==2)
    POLICY.on_unload();assert(TEST.unloads==3 and TEST.events.vehicle_controls==nil)
end)
test('missing mandatory motion support is still refused',function()
    TEST.carrier.motion_available=function()return false end
    assert(not pcall(POLICY.on_load) and TEST.created==3)
end)
print('SCENARIOS '..count)
