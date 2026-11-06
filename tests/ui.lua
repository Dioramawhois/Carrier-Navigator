local count=0
local function test(name,fn)local ok,why=pcall(fn);assert(ok,name..': '..tostring(why));count=count+1;print('PASS '..name)end
local function click(x,y)
    input_pointer(true,x,y);input_event(e_input.pointer_1,e_input_action.press);input_event(e_input.pointer_1,e_input_action.release)
end
test('carrier gains native drag capability; aircraft behavior stays native',function()
    update(256,256,1)
    assert(get_is_vehicle_type_waypoint_capable(0) and get_is_vehicle_type_waypoint_capable(5))
end)
test('aviation-map panel exposes full native power and actual game speed',function()
    click(210,18);update(256,256,1)
    local found=false;for _,s in ipairs(TEST.labels)do if s=='NATIVE POWER: 100%'then found=true end end
    assert(found)
    click(120,92);assert(TEST.messages[#TEST.messages].topic=='speed' and TEST.messages[#TEST.messages].value==90)
    click(220,92);assert(TEST.messages[#TEST.messages].value==100)
end)
test('append point uses aviation map camera transform',function()
    update(256,256,1);click(125,110);update(256,256,1);click(30,170)
    assert(#TEST.route==1 and TEST.route[1].x==1030 and TEST.route[1].z==2170)
end)
test('start and defence commands share the aviation map',function()
    update(256,256,1);click(180,130);assert(TEST.messages[#TEST.messages].topic=='start')
    click(180,150);assert(TEST.messages[#TEST.messages].topic=='defence')
    click(210,18);update(256,256,1)
end)
test('dragging carrier creates a normal native route',function()
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=42,0,20
    g_cursor_pos_x,g_cursor_pos_y=40,60
    input_event(e_input.pointer_1,e_input_action.release)
    assert(#TEST.route==1 and TEST.route[1].x==1040 and TEST.route[1].z==2060 and g_drag.vehicle_id==0)
end)
test('moving a middle point preserves the following route',function()
    TEST.vehicle:add_waypoint(2000,3000);TEST.vehicle:add_waypoint(4000,5000)
    local first=TEST.route[1].id
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=42,TEST.route[2].id,20
    g_cursor_pos_x,g_cursor_pos_y=75,85
    input_event(e_input.pointer_1,e_input_action.release)
    assert(#TEST.route==3 and TEST.route[1].id==first and TEST.route[2].x==1075 and TEST.route[2].z==2085)
    assert(TEST.route[3].x==4000 and TEST.route[3].z==5000)
end)
test('repeat links survive a moved carrier point',function()
    TEST.route[3].repeat_index=0
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=42,TEST.route[2].id,20
    input_event(e_input.pointer_1,e_input_action.release)
    assert(TEST.route[3].repeat_index==0)
end)
test('aircraft drag remains delegated to the original screen',function()
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=99,0,20
    input_event(e_input.pointer_1,e_input_action.release)
    assert(TEST.aircraft_drops==1 and #TEST.route==3)
end)
test('carrier tap still opens the native carrier interaction',function()
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=42,0,0
    input_event(e_input.pointer_1,e_input_action.release)
    assert(TEST.taps==1)
end)
test('Revolution command permission is respected',function()
    g_revolution_control_units=false
    assert(not get_is_vehicle_type_waypoint_capable(0))
    local x=TEST.route[1].x
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=42,TEST.route[1].id,20
    input_event(e_input.pointer_1,e_input_action.release)
    assert(TEST.route[1].x==x)
    g_revolution_control_units=true
end)
test('Revolution hidden carrier route is visible without changing its setting',function()
    g_is_carrier_waypoint=false
    local before=TEST.lines;update(256,256,1)
    assert(TEST.lines>before and g_is_carrier_waypoint==false)
end)
test('aircraft loadout and camera screens do not receive the map overlay',function()
    TEST.selected=true;TEST.labels={};update(256,256,1);assert(#TEST.labels==0)
    TEST.selected=false;g_viewing_vehicle_id=99;update(256,256,1);assert(#TEST.labels==0)
    g_viewing_vehicle_id=0
end)
print('SCENARIOS '..count)
