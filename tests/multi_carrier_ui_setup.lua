local function vec(x,z)return{x=function()return x end,y=function()return z end}end
TEST={screen=42,session=1,focus=true,vehicles={},order={42,43,44,45,46,47,49},messages={},labels={},base_events=0,
    permissions={},authority={},next_id=100,lines={},selected=false}
e_input={pointer_1=1,back=2,action_a=3};e_input_action={press=1,release=0}
e_game_object_type={chassis_carrier=0,torpedo=101,torpedo_decoy=102,torpedo_noisemaker=103,torpedo_sonar_buoy=104}
g_selection={vehicle_id=0,waypoint_id=0,is_selection=function()return TEST.selected end,
    clear=function(self)self.vehicle_id=0;self.waypoint_id=0;TEST.selected=false end}
g_drag={vehicle_id=0,waypoint_id=0,clear=function(self)self.vehicle_id=0;self.waypoint_id=0 end}
g_highlighted={vehicle_id=0,waypoint_id=0,clear=function(self)self.vehicle_id=0;self.waypoint_id=0 end}
g_drag_distance,g_cursor_pos_x,g_cursor_pos_y=0,20,20
g_camera_pos_x,g_camera_pos_y,g_camera_size=0,0,16000
g_screen_index=0;g_is_carrier_waypoint=false;g_is_camera_pos_initialised=true
for _,id in ipairs(TEST.order)do
    local v={id=id,team=id==45 and 1 or 0,definition=id==49 and 2 or 0,
        route={{id=7,x=id*10,z=id*10,repeat_index=-1}},valid=true}
    function v:get()return self.valid end
    function v:get_id()return self.id end
    function v:get_team()return self.team end
    function v:get_definition_index()return self.definition end
    function v:get_position_xz()return vec(self.id*10,self.id*10)end
    function v:get_waypoint_count()return #self.route end
    function v:get_waypoint(i)
        local row=self.route[i+1]
        return {get=function()return row~=nil end,get_id=function()return row.id end,
            get_position_xz=function()return vec(row.x,row.z)end,get_repeat_index=function()return row.repeat_index end}
    end
    function v:add_waypoint(x,z)TEST.next_id=TEST.next_id+1;self.route[#self.route+1]={id=TEST.next_id,x=x,z=z,repeat_index=-1};return TEST.next_id end
    function v:clear_waypoints()self.route={}end
    function v:clear_attack_target()end
    function v:clear_waypoints_from(id)for i,p in ipairs(self.route)do if p.id==id then while #self.route>=i do table.remove(self.route)end;return end end end
    function v:set_waypoint_repeat(id,target)self.repeated={id=id,target=target}end
    TEST.vehicles[id]=v;TEST.authority[id]=id~=46 and 1 or 0;TEST.permissions[id]=id~=47
end
function update_get_screen_vehicle()return TEST.vehicles[TEST.screen]end
function update_get_screen_team_id()local v=TEST.vehicles[TEST.screen];return v and v.team or -1 end
function update_get_map_vehicle_count()return #TEST.order end
function update_get_map_vehicle_by_index(i)return TEST.vehicles[TEST.order[i+1]]end
function update_get_map_vehicle_by_id(id)return TEST.vehicles[id]or{get=function()return false end}end
function update_get_is_focus_local()return TEST.focus end
function get_is_vehicle_waypoint_available(v)return TEST.permissions[v:get_id()]end
function get_is_vehicle_type_waypoint_capable(definition)return definition~=0 end
function color8(...)return {...}end
function update_ui_rectangle()end
function update_ui_image()end
function update_ui_line(x,z,tx,tz)TEST.lines[#TEST.lines+1]={x=x,z=z,tx=tx,tz=tz}end
function render_dashed_line()end
function update_ui_text(x,y,text)TEST.labels[#TEST.labels+1]={x=x,y=y,text=text}end
function get_screen_from_world(x,z,cx,cz)return x-cx,z-cz end
function get_world_from_screen(x,y,cx,cz)return x+cx,y+cz end
function update()end
function input_event()TEST.base_events=TEST.base_events+1 end
function input_pointer()end
cc2x={modules={}}
function cc2x.modules.read(_,topic,id)
    if topic=='session'then return TEST.session elseif topic=='authority'then return TEST.authority[id]or 0 end
    return ({ready=1,state=1,speed=100,actual=5,defence=0,navigation_mode=0,navigation_status=8})[topic]
end
function cc2x.modules.send(_,topic,id,value)TEST.messages[#TEST.messages+1]={topic=topic,id=id,value=value};return true end
function TEST.frame()TEST.labels={};TEST.lines={};update(256,256,1)end
function TEST.label(label)for _,row in ipairs(TEST.labels)do if row.text==label then return row end end end
function TEST.click(label)
    local row=assert(TEST.label(label),'Missing control '..label)
    input_pointer(true,row.x+1,row.y+1);input_event(e_input.pointer_1,e_input_action.press);input_event(e_input.pointer_1,e_input_action.release);TEST.frame()
end
