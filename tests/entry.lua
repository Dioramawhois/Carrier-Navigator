local count=0
local function test(name,fn)local ok,why=pcall(fn);assert(ok,name..': '..tostring(why));count=count+1;print('PASS '..name)end
local function setup()
    update=function()end;input_event=function()end;input_pointer=function()end
    begin_load=function()return 'native',nil,9 end
    color8=function()return{}end
    g_drag=nil;get_is_vehicle_waypoint_available=nil
end
test('unrelated screens keep their callbacks and native library return values',function()
    setup();local before=update;POLICY();assert(update==before)
    local a,b,c=begin_load();assert(a=='native' and b==nil and c==9 and update==before)
end)
test('library loaded before screen installs after native begin_load',function()
    setup();local before=update;POLICY()
    g_drag={};get_is_vehicle_waypoint_available=function()return true end
    begin_load();assert(update~=before)
    local installed=update;begin_load();assert(update==installed)
end)
test('library loaded during screen begin installs immediately once',function()
    setup();g_drag={};get_is_vehicle_waypoint_available=function()return true end
    local before=update;POLICY();assert(update~=before)
    local installed=update;begin_load();assert(update==installed)
end)
print('SCENARIOS '..count)
