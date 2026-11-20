local count=0
local function test(name,fn)local ok,why=pcall(fn);assert(ok,name..': '..tostring(why));count=count+1;print('PASS '..name)end
TEST.frame();TEST.click('NAV')
test('teleport cancels pending point placement without copying the old carrier route',function()
    TEST.click('+ POINT');local a,b=#TEST.vehicles[42].route,#TEST.vehicles[43].route
    TEST.screen=43;TEST.frame()
    assert(TEST.label('+ POINT')and not TEST.label('CANCEL'))
    input_pointer(true,10,240);input_event(e_input.pointer_1,e_input_action.press);input_event(e_input.pointer_1,e_input_action.release)
    assert(#TEST.vehicles[42].route==a and #TEST.vehicles[43].route==b)
end)
test('a stale CLEAR closure cannot pause the new carrier while deleting the previous route',function()
    local button=assert(TEST.label('CLEAR'));local n=#TEST.messages
    TEST.screen=44
    input_pointer(true,button.x+1,button.y+1);input_event(e_input.pointer_1,e_input_action.press);input_event(e_input.pointer_1,e_input_action.release)
    assert(#TEST.messages==n and #TEST.vehicles[43].route==1 and #TEST.vehicles[44].route==1)
    TEST.frame()
end)
test('NAV offers control selection for all three friendly carriers',function()
    TEST.click('NEXT');TEST.click('NEXT');TEST.click('NEXT')
    local seen={}
    for _=1,8 do
        for _,row in ipairs(TEST.labels)do local id=row.text:match('CARRIER #(%d+)');if id then seen[tonumber(id)]=true end end
        TEST.click('NEXT')
    end
    assert(seen[42]and seen[43]and seen[44]and not seen[45]and not seen[49])
end)
test('remote-target commands identify the selected carrier rather than the physical screen carrier',function()
    local target
    for _=1,8 do
        for _,row in ipairs(TEST.labels)do if row.text:find('CARRIER #42',1,true)then target=42 end end
        if target then break end;TEST.click('NEXT')
    end
    assert(target==42 and TEST.screen==44)
    local n=#TEST.messages;TEST.click('FULL');assert(#TEST.messages==n+1 and TEST.messages[#TEST.messages].id==42)
end)
test('native drag edits its own carrier even when waypoint IDs overlap',function()
    local before=TEST.vehicles[42].route[1].x
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=43,7,20
    g_cursor_pos_x,g_cursor_pos_y=20,21
    local x,z=get_world_from_screen(20,21,g_camera_pos_x,g_camera_pos_y)
    input_event(e_input.pointer_1,e_input_action.release)
    assert(TEST.vehicles[43].route[1].x==x and TEST.vehicles[43].route[1].z==z)
    assert(TEST.vehicles[42].route[1].x==before)
end)
test('same carrier ID in another session cannot inherit pending edits',function()
    TEST.frame();TEST.click('+ POINT');TEST.session=2;TEST.frame()
    assert(TEST.label('+ POINT')and not TEST.label('CANCEL'))
end)
test('enemy and aircraft drag releases remain outside Navigator control',function()
    local n=#TEST.messages;local x=TEST.vehicles[45].route[1].x
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=45,7,20
    input_event(e_input.pointer_1,e_input_action.release)
    assert(TEST.vehicles[45].route[1].x==x and #TEST.messages==n)
end)
test('loss of local focus cancels point placement',function()
    TEST.frame();TEST.click('+ POINT');TEST.focus=false;TEST.frame();TEST.focus=true;TEST.frame()
    assert(TEST.label('+ POINT')and not TEST.label('CANCEL'))
end)
test('a denied friendly-carrier drag cannot fall through to native route editing',function()
    local n=TEST.base_events;local x=TEST.vehicles[46].route[1].x
    g_drag.vehicle_id,g_drag.waypoint_id,g_drag_distance=46,7,20
    input_event(e_input.pointer_1,e_input_action.release)
    assert(TEST.base_events==n and TEST.vehicles[46].route[1].x==x and g_drag.vehicle_id==0)
end)
test('teleport also clears native waypoint selection from another carrier',function()
    TEST.selected=true;g_selection.vehicle_id,g_selection.waypoint_id=42,7
    TEST.screen=43;TEST.frame()
    assert(not TEST.selected and g_selection.vehicle_id==0 and TEST.label('NAV'))
end)
print('SCENARIOS '..count)
