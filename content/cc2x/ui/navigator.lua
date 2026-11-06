-- SPDX-License-Identifier: GPL-3.0-or-later
-- Appends to the aviation-control map; never copies stock/Revolution screens.
do
    local previous_update,previous_input,previous_pointer=update,input_event,input_pointer
    local open,adding,consumed,announced,announce_ticks=false,false,false,false,0
    local px,py,hovered,width,height=0,0,false,256,256
    local buttons,capability_installed={},false
    local owner='carrier_navigator'
    local function bridge()return cc2x and cc2x.modules and cc2x.modules.read and cc2x.modules.send end
    local function read(topic,id,fallback)
        local value=bridge() and cc2x.modules.read(owner,topic,id)
        return type(value)=='number' and value or fallback
    end
    local function carrier()
        local v=update_get_screen_vehicle()
        return v and v:get() and v or nil
    end
    local function map_active()
        return (g_screen_index==nil or g_screen_index==0) and not (g_viewing_vehicle_id and g_viewing_vehicle_id>0) and
            not (g_selection and g_selection.is_selection and g_selection:is_selection())
    end
    local function can_route(v)
        return v and read('ready',0,0)==1 and read('authority',v:get_id(),0)==1 and
            (type(get_is_vehicle_waypoint_available)~='function' or get_is_vehicle_waypoint_available(v))
    end
    local function send(topic,value)
        local v=carrier()
        return v and bridge() and update_get_is_focus_local() and cc2x.modules.send(owner,topic,v:get_id(),value)
    end
    local function world(x,y)return get_world_from_screen(x,y,g_camera_pos_x,g_camera_pos_y,g_camera_size,width,height)end
    local function install_capability()
        if capability_installed or type(get_is_vehicle_type_waypoint_capable)~='function' then return end
        local previous=get_is_vehicle_type_waypoint_capable
        function get_is_vehicle_type_waypoint_capable(definition)
            if definition==e_game_object_type.chassis_carrier and can_route(carrier()) then return true end
            return previous(definition)
        end
        capability_installed=true
    end
    local background,foreground,accent=color8(3,15,20,245),color8(185,235,240,255),color8(0,165,200,255)
    local function text(x,y,message,w)update_ui_text(x,y,message,w,0,foreground,0)end
    local function button(x,y,w,label,action,enabled)
        local over=hovered and px>=x and px<x+w and py>=y and py<y+15
        update_ui_rectangle(x,y,w,15,enabled==false and color8(30,40,45,255) or over and accent or color8(15,65,75,255))
        text(x+3,y+3,label,w-6)
        buttons[#buttons+1]={x=x,y=y,w=w,action=action,enabled=enabled~=false}
    end
    local function keep_visible(v)
        -- Revolution can hide carrier waypoints. Draw our own route in that
        -- case without modifying its setting or any aircraft rendering.
        if g_is_carrier_waypoint~=false or type(get_screen_from_world)~='function' then return end
        local p=v:get_position_xz()
        local last_x,last_y=get_screen_from_world(p:x(),p:y(),g_camera_pos_x,g_camera_pos_y,g_camera_size,width,height)
        for i=0,math.min(v:get_waypoint_count()-1,19)do
            local wp=v:get_waypoint(i)
            if wp:get()then
                local pos=wp:get_position_xz()
                local x,y=get_screen_from_world(pos:x(),pos:y(),g_camera_pos_x,g_camera_pos_y,g_camera_size,width,height)
                update_ui_line(last_x,last_y,x,y,g_color_waypoint or accent)
                if atlas_icons and atlas_icons.map_icon_waypoint then update_ui_image(x-4,y-4,atlas_icons.map_icon_waypoint,g_color_waypoint or accent,0)
                else update_ui_rectangle(x-2,y-2,5,5,accent)end
                last_x,last_y=x,y
            end
        end
    end
    function update(w,h,ticks)
        width,height=w,h;install_capability();previous_update(w,h,ticks);buttons={}
        local v=carrier()
        if not v or not map_active()then adding=false;return end
        local id,ready=v:get_id(),can_route(v)
        announce_ticks=announce_ticks+(ticks or 1)
        if ready and (not announced or announce_ticks>=300)then
            for _,name in ipairs({'torpedo','torpedo_decoy','torpedo_noisemaker','torpedo_sonar_buoy'})do
                if e_game_object_type and type(e_game_object_type[name])=='number'then cc2x.modules.send(owner,'type.'..name,id,e_game_object_type[name])end
            end
            announced,announce_ticks=true,0
        elseif not ready then announced=false end
        if ready then keep_visible(v)end
        button(w-65,12,59,'NAV',function()open=not open;adding=false end)
        if not open then return end
        local x,y,panel=w-152,31,146
        update_ui_rectangle(x,y,panel,143,background)
        text(x+5,y+4,'CARRIER NAVIGATOR',panel-10)
        local state=read('state',id,0)
        text(x+5,y+17,not ready and 'UNAVAILABLE' or state==2 and 'FOLLOWING ROUTE' or 'PAUSED / MANUAL',panel-10)
        text(x+5,y+30,string.format('NATIVE POWER: %d%%',read('speed',id,100)),panel-10)
        text(x+5,y+42,string.format('ACTUAL: %.1f KN',read('actual',id,0)),panel-10)
        button(x+5,y+55,42,'-10%',function()send('speed',math.max(10,read('speed',id,100)-10))end,ready)
        button(x+51,y+55,42,'+10%',function()send('speed',math.min(100,read('speed',id,100)+10))end,ready)
        button(x+97,y+55,44,'FULL',function()send('speed',100)end,ready)
        button(x+5,y+73,65,adding and 'CANCEL' or '+ POINT',function()adding=not adding end,ready)
        button(x+74,y+73,67,'CLEAR',function()send('pause',0);v:clear_waypoints();adding=false end,ready)
        button(x+5,y+91,136,state==2 and 'PAUSE AUTOPILOT' or 'START AUTOPILOT',function()adding=false;send(state==2 and 'pause' or 'start',state==2 and 0 or 1)end,ready and v:get_waypoint_count()>0)
        local defence=read('defence',id,0)==1
        button(x+5,y+109,136,defence and 'DEFENCE: ON' or 'DEFENCE: OFF',function()send('defence',defence and 0 or 1)end,ready)
        text(x+5,y+127,adding and 'CLICK MAP ONCE' or 'DRAG CARRIER / POINT',panel-10)
    end
    function input_pointer(is_hovered,x,y)
        px,py,hovered=x,y,is_hovered
        if previous_pointer then return previous_pointer(is_hovered,x,y)end
    end
    local function clear_drag()
        if g_drag and g_drag.clear then g_drag:clear()end
        g_is_ignore_tap=true
    end
    local function move_point(v,id,x,z)
        local tail,found={},false
        for i=0,v:get_waypoint_count()-1 do
            local wp=v:get_waypoint(i)
            if wp:get_id()==id then found=true end
            if found then
                local p=wp:get_position_xz()
                tail[#tail+1]={x=p:x(),z=p:y(),repeat_index=type(wp.get_repeat_index)=='function' and wp:get_repeat_index() or -1}
            end
        end
        if not found then return false end
        for _,p in ipairs(tail)do if p.repeat_index>=0 and type(v.set_waypoint_repeat)~='function'then return false end end
        tail[1].x,tail[1].z=x,z
        v:clear_waypoints_from(id)
        local start=v:get_waypoint_count()
        for _,p in ipairs(tail)do v:add_waypoint(p.x,p.z)end
        for i,p in ipairs(tail)do
            if p.repeat_index>=0 then
                local wp,target=v:get_waypoint(start+i-1),v:get_waypoint(p.repeat_index)
                if wp:get() and target:get()then v:set_waypoint_repeat(wp:get_id(),target:get_id())end
            end
        end
        return true
    end
    function input_event(event,action)
        local v=carrier()
        if map_active() and event==e_input.pointer_1 then
            if action==e_input_action.press and update_get_is_focus_local()then
                for _,b in ipairs(buttons)do
                    if hovered and px>=b.x and px<b.x+b.w and py>=b.y and py<b.y+15 then consumed=true;if b.enabled then b.action()end;return end
                end
                if open and hovered and px>=width-152 and py>=31 and py<174 then consumed=true;return end
                if adding and hovered and can_route(v)then
                    if v:get_waypoint_count()<20 then local x,z=world(px,py);v:add_waypoint(x,z)end
                    adding,consumed=false,true;return
                end
            elseif action==e_input_action.release and consumed then consumed=false;return end
        end
        local release=action==e_input_action.release and (event==e_input.pointer_1 or event==e_input.action_a)
        if release and map_active() and update_get_is_focus_local() and can_route(v) and g_drag and g_drag.vehicle_id==v:get_id() and (g_drag_distance or 0)>3 then
            local x,z=world(g_cursor_pos_x or px,g_cursor_pos_y or py)
            if g_drag.waypoint_id and g_drag.waypoint_id>0 then move_point(v,g_drag.waypoint_id,x,z)
            else v:clear_waypoints();v:clear_attack_target();v:add_waypoint(x,z)end
            clear_drag()
        elseif event==e_input.back and action==e_input_action.press and open then open,adding=false,false;return end
        return previous_input(event,action)
    end
end
