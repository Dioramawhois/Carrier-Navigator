local function point(x,z)return{x=function()return x end,y=function()return z end}end
TEST={messages={},route={},base_events=0,base_updates=0,labels={},next_id=10,taps=0,aircraft_drops=0,lines=0,permission=true}
e_input={pointer_1=1,back=2,action_a=3};e_input_action={press=1,release=0}
e_game_object_type={chassis_carrier=0,torpedo=101,torpedo_decoy=102,torpedo_noisemaker=103,torpedo_sonar_buoy=104}
g_selection={is_selection=function()return TEST.selected==true end}
g_drag={vehicle_id=0,waypoint_id=0,clear=function(self)self.vehicle_id=0;self.waypoint_id=0 end}
g_drag_distance,g_cursor_pos_x,g_cursor_pos_y=0,0,0
g_camera_pos_x,g_camera_pos_y,g_camera_size=1000,2000,16000
function color8(...)return{...}end
function update_get_is_focus_local()return true end
local vehicle={get=function()return true end,get_id=function()return 42 end,get_position_xz=function()return point(0,0)end}
function vehicle:get_waypoint_count()return #TEST.route end
function vehicle:get_waypoint(i)
    local p=TEST.route[i+1]
    return{get=function()return p~=nil end,get_id=function()return p.id end,get_position_xz=function()return point(p.x,p.z)end,get_repeat_index=function()return p.repeat_index or -1 end}
end
function vehicle:add_waypoint(x,z)
    TEST.next_id=TEST.next_id+1;TEST.route[#TEST.route+1]={id=TEST.next_id,x=x,z=z}
    return TEST.next_id
end
function vehicle:clear_waypoints()TEST.route={}end
function vehicle:clear_attack_target()TEST.attack_cleared=true end
function vehicle:clear_waypoints_from(id)
    for i,p in ipairs(TEST.route)do if p.id==id then while #TEST.route>=i do table.remove(TEST.route)end;return end end
end
function vehicle:set_waypoint_repeat(id,target)
    for _,p in ipairs(TEST.route)do if p.id==id then for i,t in ipairs(TEST.route)do if t.id==target then p.repeat_index=i-1 end end end end
end
TEST.vehicle=vehicle
function update_get_screen_vehicle()return vehicle end
function get_is_vehicle_waypoint_available()return TEST.permission and g_revolution_control_units~=false end
function get_is_vehicle_type_waypoint_capable(definition)return definition~=0 end
function update_ui_rectangle()end
function update_ui_image()end
function update_ui_line()TEST.lines=TEST.lines+1 end
function update_ui_text(_,_,message)TEST.labels[#TEST.labels+1]=message end
function get_screen_from_world(x,z,cx,cz)return x-cx,z-cz end
function get_world_from_screen(x,y,cx,cz)return x+cx,y+cz end
function update()TEST.base_updates=TEST.base_updates+1 end
function input_event(event,action)
    TEST.base_events=TEST.base_events+1
    if action==e_input_action.release then
        if g_is_ignore_tap then g_is_ignore_tap=false
        elseif g_drag.vehicle_id==42 and g_drag_distance<3 then TEST.taps=TEST.taps+1
        elseif g_drag.vehicle_id==99 then TEST.aircraft_drops=TEST.aircraft_drops+1 end
        g_drag:clear()
    end
end
function input_pointer()end
cc2x={modules={}}
function cc2x.modules.read(_,topic)
    return ({ready=1,authority=1,state=1,speed=100,actual=55,defence=0,threats=0,contacts=1})[topic]
end
function cc2x.modules.send(_,topic,id,value)TEST.messages[#TEST.messages+1]={topic=topic,id=id,value=value};return true end
