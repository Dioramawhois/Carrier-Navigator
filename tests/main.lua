local count=0
local function test(name,fn)local ok,why=pcall(fn);assert(ok,name..': '..tostring(why));count=count+1;print('PASS '..name)end

test('an old motion-only SDK is refused before creating the Navigator runtime',function()
    local ok,why=pcall(POLICY.on_load)
    assert(not ok and tostring(why):find('precise navigation support',1,true))
    assert(TEST.created==0 and next(TEST.events)==nil)
end)

test('a present but unavailable precise navigation backend is refused',function()
    TEST.carrier.navigation_available=function()return false end
    TEST.carrier.navigation_state=function()return {}end
    TEST.carrier.set_navigation=function()return true end
    assert(not pcall(POLICY.on_load) and TEST.created==0)
end)

test('complete optional navigation support preserves module update and unload lifecycle',function()
    TEST.carrier.navigation_available=function()return true end
    POLICY.on_load();assert(TEST.created==1 and TEST.events.vehicle_controls)
    POLICY.on_update();assert(TEST.updates==1)
    POLICY.on_unload();assert(TEST.unloads==1 and TEST.events.vehicle_controls==nil)
end)
print('SCENARIOS '..count)
