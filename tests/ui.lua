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

local function loop_route()
    TEST.vehicle:clear_waypoints()
    TEST.vehicle:add_waypoint(1040,2060);TEST.vehicle:add_waypoint(1090,2100);TEST.vehicle:add_waypoint(1130,2060)
    g_highlighted.vehicle_id,g_highlighted.waypoint_id=0,0
end
local function route_positions()
    local parts={}
    for _,p in ipairs(TEST.route)do parts[#parts+1]=p.id..':'..p.x..':'..p.z end
    return table.concat(parts,';')
end
local function loop_drop(event,target)
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=42,TEST.route[3].id,20
    g_highlighted.vehicle_id,g_highlighted.waypoint_id=42,target
    g_cursor_pos_x,g_cursor_pos_y=40,60
    input_event(event,e_input_action.release)
    g_highlighted.vehicle_id,g_highlighted.waypoint_id=0,0
end

test('dropping the final point onto the first creates a native loop without moving points',function()
    loop_route();local positions=route_positions();local calls=#TEST.repeat_calls
    local source,target=TEST.route[3].id,TEST.route[1].id
    loop_drop(e_input.pointer_1,target)
    assert(route_positions()==positions and TEST.route[3].repeat_index==0)
    assert(#TEST.repeat_calls==calls+1 and TEST.repeat_calls[#TEST.repeat_calls].id==source and TEST.repeat_calls[#TEST.repeat_calls].target==target)
end)

test('controller drop can repeat from the final point to a middle point',function()
    loop_route();local positions=route_positions()
    loop_drop(e_input.action_a,TEST.route[2].id)
    assert(route_positions()==positions and TEST.route[3].repeat_index==1)
end)

test('a stale highlighted repeat target does not rewrite the route',function()
    loop_route();local positions=route_positions();local calls=#TEST.repeat_calls
    loop_drop(e_input.pointer_1,999999)
    assert(route_positions()==positions and #TEST.repeat_calls==calls)
end)

test('Revolution permission and local focus gate loop commands',function()
    loop_route();local positions=route_positions();local calls=#TEST.repeat_calls
    g_revolution_control_units=false;loop_drop(e_input.pointer_1,TEST.route[1].id)
    g_revolution_control_units=true;TEST.focus=false;loop_drop(e_input.pointer_1,TEST.route[1].id);TEST.focus=true
    assert(route_positions()==positions and #TEST.repeat_calls==calls)
end)

test('a waypoint on another vehicle is not linked into the carrier loop',function()
    loop_route();local calls=#TEST.repeat_calls
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=42,TEST.route[3].id,20
    g_highlighted.vehicle_id,g_highlighted.waypoint_id=99,TEST.route[1].id
    input_event(e_input.pointer_1,e_input_action.release)
    assert(#TEST.repeat_calls==calls)
    g_highlighted.vehicle_id,g_highlighted.waypoint_id=0,0
end)

test('Revolution fallback route drawing includes the closing repeat segment',function()
    loop_route();TEST.route[3].repeat_index=0;g_is_carrier_waypoint=false
    local before=#TEST.dashed;update(256,256,1)
    assert(#TEST.dashed==before+1)
    local line=TEST.dashed[#TEST.dashed]
    assert(line.x==130 and line.y==60 and line.tx==40 and line.ty==60)
    g_is_carrier_waypoint=nil
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
local function show_navigation_panel()
    TEST.labels={};update(256,256,1)
    local open=false
    for _,label in ipairs(TEST.labels)do open=open or label=='AUTOPILOT WAYPOINTS' end
    if not open then click(210,18);TEST.labels={};update(256,256,1)end
end
test('blocked coastal route is visible instead of claiming to follow',function()
    local previous=cc2x.modules.read
    cc2x.modules.read=function(owner,topic,id)
        if topic=='navigation_status'then return 3 end
        if topic=='state'then return 1 end
        return previous(owner,topic,id)
    end
    show_navigation_panel()
    local blocked,following=false,false
    for _,label in ipairs(TEST.labels)do
        blocked=blocked or label=='ROUTE BLOCKED'
        following=following or label=='FOLLOWING ROUTE'
    end
    assert(blocked and not following)
    cc2x.modules.read=previous
end)
test('pending coastal guidance stays pausable without changing the route',function()
    local previous=cc2x.modules.read
    cc2x.modules.read=function(owner,topic,id)
        if topic=='navigation_status'then return 1 end
        if topic=='state'then return 2 end
        return previous(owner,topic,id)
    end
    show_navigation_panel()
    local waiting,pausable=false,false
    for _,label in ipairs(TEST.labels)do
        waiting=waiting or label=='PLOTTING ROUTE'
        pausable=pausable or label=='PAUSE AUTOPILOT'
    end
    assert(waiting and pausable)
    local positions=route_positions()
    click(145,130)
    assert(TEST.messages[#TEST.messages].topic=='pause' and route_positions()==positions)
    cc2x.modules.read=previous
end)
test('old SDK keeps Start enabled and clearly marks the optional coastal upgrade',function()
    local previous=cc2x.modules.read
    cc2x.modules.read=function(owner,topic,id)
        if topic=='navigation_mode'then return 0 end
        if topic=='navigation_status'then return 8 end
        return previous(owner,topic,id)
    end
    show_navigation_panel()
    local native,upgrade=false,false
    for _,label in ipairs(TEST.labels)do
        native=native or label=='FOLLOWING NATIVE ROUTE'
        upgrade=upgrade or label=='COASTAL: UPDATE SDK'
    end
    assert(native and upgrade)
    click(145,130);assert(TEST.messages[#TEST.messages].topic=='start')
    cc2x.modules.read=previous
end)
print('SCENARIOS '..count)
