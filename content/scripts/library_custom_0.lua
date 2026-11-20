-- SPDX-License-Identifier: GPL-3.0-or-later
-- Owned aviation-map UI through the game's standard custom-library slot.
-- Handles both library-before-screen and begin_load-time execution without
-- replacing a screen or competing for a merged SDK screen descriptor.
do
    if g_carrier_navigator_library then return end
    g_carrier_navigator_library=true
    local installed=false
    local function install()
        if installed or type(update)~='function' or type(g_drag)~='table' or
            type(get_is_vehicle_waypoint_available)~='function' then return end
        installed=true
    local previous_update,previous_input,previous_pointer=update,input_event,input_pointer
    local open,adding,consumed,announced,announce_ticks=false,false,false,false,0
    local px,py,hovered,width,height=0,0,false,256,256
    local buttons,capability_installed={},false
    local selected_id,screen_id,screen_team,session_id,previous_focus
    local context_known=false
    local owner='carrier_navigator'
    local function bridge()return cc2x and cc2x.modules and cc2x.modules.read and cc2x.modules.send end
    local function read(topic,id,fallback)
        local value=bridge() and cc2x.modules.read(owner,topic,id)
        return type(value)=='number' and value or fallback
    end
    local function physical_carrier()
        local v=update_get_screen_vehicle()
        return v and v:get() and v or nil
    end
    local function team()
        if type(update_get_screen_team_id)=='function'then return update_get_screen_team_id()end
        local v=physical_carrier();return v and v:get_team() or -1
    end
    local function friendly_carrier(v)
        return v and v:get() and v:get_definition_index()==e_game_object_type.chassis_carrier and v:get_team()==team()
    end
    local function by_id(id)
        local own=physical_carrier()
        if own and own:get_id()==id then return own end
        if type(update_get_map_vehicle_by_id)=='function'then return update_get_map_vehicle_by_id(id)end
    end
    local function carriers()
        local result,seen={},{}
        local function add(v)
            if friendly_carrier(v)and not seen[v:get_id()]then seen[v:get_id()]=true;result[#result+1]=v end
        end
        add(physical_carrier())
        if type(update_get_map_vehicle_count)=='function'and type(update_get_map_vehicle_by_index)=='function'then
            for i=0,update_get_map_vehicle_count()-1 do add(update_get_map_vehicle_by_index(i))end
        end
        table.sort(result,function(a,b)return a:get_id()<b:get_id()end)
        return result
    end
    local function carrier()
        local v=by_id(selected_id)
        return friendly_carrier(v)and v or nil
    end
    local function clear_field(field)
        if field then
            if type(field.clear)=='function'then field:clear()
            else field.vehicle_id,field.waypoint_id=0,0 end
        end
    end
    local function cancel_edit()
        adding,consumed,announced,announce_ticks=false,false,false,0;buttons={}
        local dragged=g_drag and by_id(g_drag.vehicle_id)
        if g_drag and (g_drag.vehicle_id==screen_id or g_drag.vehicle_id==selected_id or friendly_carrier(dragged))then clear_field(g_drag)end
        if g_highlighted and (g_highlighted.vehicle_id==screen_id or g_highlighted.vehicle_id==selected_id)then clear_field(g_highlighted)end
        if g_selection and (g_selection.vehicle_id==screen_id or g_selection.vehicle_id==selected_id)and
            (g_selection.waypoint_id or 0)>0 then clear_field(g_selection)end
    end
    local function synchronize()
        local own=physical_carrier();local id=own and own:get_id()or 0
        local current_team,current_session=team(),read('session',0,0)
        local focus=update_get_is_focus_local()
        local changed=context_known and (id~=screen_id or current_team~=screen_team or current_session~=session_id)
        if not context_known or changed then
            cancel_edit();selected_id=id
            if changed then g_is_camera_pos_initialised=false end
        elseif previous_focus and not focus then cancel_edit()end
        screen_id,screen_team,session_id,previous_focus=id,current_team,current_session,focus
        context_known=true
        if not carrier()then cancel_edit();selected_id=id end
        return changed
    end
    local function focus_carrier(v)
        if not friendly_carrier(v)then return end
        local p=v:get_position_xz()
        g_camera_pos_x,g_camera_pos_y=p:x(),p:y()
        g_next_pos_x,g_next_pos_y,g_prev_pos_x,g_prev_pos_y=p:x(),p:y(),p:x(),p:y()
        g_is_camera_pos_initialised=true
    end
    local function cycle_carrier(direction)
        local list=carriers();if #list==0 then return end
        local index=1
        for i,v in ipairs(list)do if v:get_id()==selected_id then index=i;break end end
        local v=list[(index-1+direction)%#list+1]
        cancel_edit();selected_id=v:get_id();focus_carrier(v)
    end
    local function map_active()
        return (g_screen_index==nil or g_screen_index==0) and not (g_viewing_vehicle_id and g_viewing_vehicle_id>0) and
            not (g_selection and g_selection.is_selection and g_selection:is_selection())
    end
    local function can_route(v)
        return friendly_carrier(v) and read('ready',0,0)==1 and read('authority',v:get_id(),0)==1 and
            (type(get_is_vehicle_waypoint_available)~='function' or get_is_vehicle_waypoint_available(v))
    end
    local function send(topic,value,expected_id)
        local v=carrier()
        return v and (not expected_id or v:get_id()==expected_id) and can_route(v) and bridge() and
            update_get_is_focus_local() and cc2x.modules.send(owner,topic,v:get_id(),value)
    end
    local function world(x,y)return get_world_from_screen(x,y,g_camera_pos_x,g_camera_pos_y,g_camera_size,width,height)end
    local function install_capability()
        if capability_installed or type(get_is_vehicle_type_waypoint_capable)~='function' then return end
        local previous=get_is_vehicle_type_waypoint_capable
        function get_is_vehicle_type_waypoint_capable(definition)
            if definition==e_game_object_type.chassis_carrier then
                for _,v in ipairs(carriers())do if can_route(v)then return true end end
            end
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
        buttons[#buttons+1]={x=x,y=y,w=w,action=action,enabled=enabled~=false,
            screen_id=screen_id,selected_id=selected_id,session_id=session_id}
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
                local repeat_index=type(wp.get_repeat_index)=='function' and wp:get_repeat_index() or -1
                if repeat_index>=0 and repeat_index<v:get_waypoint_count() and repeat_index~=i then
                    local target=v:get_waypoint(repeat_index)
                    if target:get()then
                        local target_pos=target:get_position_xz()
                        local tx,ty=get_screen_from_world(target_pos:x(),target_pos:y(),g_camera_pos_x,g_camera_pos_y,g_camera_size,width,height)
                        if type(render_dashed_line)=='function'then render_dashed_line(x,y,tx,ty,g_color_waypoint or accent)
                        else update_ui_line(x,y,tx,ty,g_color_waypoint or accent)end
                    end
                end
                last_x,last_y=x,y
            end
        end
    end
    function update(w,h,ticks)
        synchronize()
        width,height=w,h;install_capability();previous_update(w,h,ticks);buttons={}
        local v=carrier()
        if not v or not map_active()then adding=false;return end
        local id,ready=v:get_id(),can_route(v)
        if not ready then adding=false end
        announce_ticks=announce_ticks+(ticks or 1)
        if ready and (not announced or announce_ticks>=300)then
            for _,name in ipairs({'torpedo','torpedo_decoy','torpedo_noisemaker','torpedo_sonar_buoy'})do
                if e_game_object_type and type(e_game_object_type[name])=='number'then cc2x.modules.send(owner,'type.'..name,id,e_game_object_type[name])end
            end
            announced,announce_ticks=true,0
        elseif not ready then announced=false end
        keep_visible(v)
        button(w-65,12,59,'NAV',function()open=not open;adding=false end)
        if not open then return end
        local x,y,panel=w-152,31,146
        local list=carriers();local extra=#list>1 and 43 or 0
        update_ui_rectangle(x,y,panel,155+extra,background)
        text(x+5,y+4,'AUTOPILOT WAYPOINTS',panel-10)
        if #list>1 then
            local index=1;for i,c in ipairs(list)do if c:get_id()==id then index=i;break end end
            text(x+5,y+17,string.format('CARRIER #%d  %d/%d',id,index,#list),panel-10)
            button(x+5,y+29,42,'PREV',function()cycle_carrier(-1)end)
            button(x+51,y+29,42,'NEXT',function()cycle_carrier(1)end)
            button(x+97,y+29,44,'FOCUS',function()focus_carrier(carrier())end)
        end
        y=y+extra
        local state=read('state',id,0)
        local navigation_labels={[1]='PLOTTING ROUTE',[2]='FOLLOWING ROUTE',[3]='ROUTE BLOCKED',
            [4]='ARRIVED AT POINT',[5]='UPDATE SDK REQUIRED',[6]='ROUTE SETUP FAILED',[7]='NAVIGATION STOPPED',
            [8]='FOLLOWING NATIVE ROUTE'}
        local status=not ready and 'UNAVAILABLE' or navigation_labels[read('navigation_status',id,0)] or
            (state==2 and 'FOLLOWING ROUTE' or 'PAUSED / MANUAL')
        text(x+5,y+17,status,panel-10)
        text(x+5,y+30,string.format('NATIVE POWER: %d%%',read('speed',id,100)),panel-10)
        text(x+5,y+42,string.format('ACTUAL: %.1f KN',read('actual',id,0)),panel-10)
        button(x+5,y+55,42,'-10%',function()send('speed',math.max(10,read('speed',id,100)-10),id)end,ready)
        button(x+51,y+55,42,'+10%',function()send('speed',math.min(100,read('speed',id,100)+10),id)end,ready)
        button(x+97,y+55,44,'FULL',function()send('speed',100,id)end,ready)
        button(x+5,y+73,65,adding and 'CANCEL' or '+ POINT',function()adding=not adding end,ready)
        button(x+74,y+73,67,'CLEAR',function()if send('pause',0,id)then v:clear_waypoints()end;adding=false end,ready)
        button(x+5,y+91,136,state==2 and 'PAUSE AUTOPILOT' or 'START AUTOPILOT',function()adding=false;send(state==2 and 'pause' or 'start',state==2 and 0 or 1,id)end,ready and v:get_waypoint_count()>0)
        local defence=read('defence',id,0)==1
        button(x+5,y+109,136,defence and 'DEFENCE: ON' or 'DEFENCE: OFF',function()send('defence',defence and 0 or 1,id)end,ready)
        text(x+5,y+127,adding and 'CLICK MAP ONCE' or 'DRAG CARRIER / POINT',panel-10)
        local mode=read('navigation_mode',0,-1)
        if mode>=0 then text(x+5,y+139,mode==1 and 'COASTAL: ENABLED' or 'COASTAL: UPDATE SDK',panel-10)end
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
    local function repeat_point(v,id,target)
        if id==target or type(v.set_waypoint_repeat)~='function'then return false end
        local source_found,target_found=false,false
        for i=0,v:get_waypoint_count()-1 do
            local wp=v:get_waypoint(i)
            if wp:get()then
                source_found=source_found or wp:get_id()==id
                target_found=target_found or wp:get_id()==target
            end
        end
        if not source_found or not target_found then return false end
        v:set_waypoint_repeat(id,target)
        return true
    end
    function input_event(event,action)
        local changed=synchronize()
        if changed and action==e_input_action.release and (event==e_input.pointer_1 or event==e_input.action_a)then return end
        local v=carrier()
        if map_active() and event==e_input.pointer_1 then
            if action==e_input_action.press and update_get_is_focus_local()then
                for _,b in ipairs(buttons)do
                    if hovered and px>=b.x and px<b.x+b.w and py>=b.y and py<b.y+15 then
                        if b.enabled and b.screen_id==screen_id and b.selected_id==selected_id and b.session_id==session_id then b.action()end
                        consumed=true;return
                    end
                end
                local panel_end=31+155+(#carriers()>1 and 43 or 0)
                if open and hovered and px>=width-152 and py>=31 and py<panel_end then consumed=true;return end
                if adding and hovered and can_route(v)then
                    if v:get_waypoint_count()<20 then local x,z=world(px,py);v:add_waypoint(x,z)end
                    adding,consumed=false,true;return
                end
            elseif action==e_input_action.release and consumed then consumed=false;return end
        end
        local release=action==e_input_action.release and (event==e_input.pointer_1 or event==e_input.action_a)
        local dragged=g_drag and by_id(g_drag.vehicle_id)
        if release and map_active()and update_get_is_focus_local()and friendly_carrier(dragged)and
            not can_route(dragged)and (g_drag_distance or 0)>3 then clear_drag();return end
        if release and map_active() and update_get_is_focus_local() and can_route(dragged) and (g_drag_distance or 0)>3 then
            v=dragged;selected_id=v:get_id();adding=false;buttons={}
            local x,z=world(g_cursor_pos_x or px,g_cursor_pos_y or py)
            if g_drag.waypoint_id and g_drag.waypoint_id>0 then
                if g_highlighted and g_highlighted.vehicle_id==v:get_id() and
                    (g_highlighted.waypoint_id or 0)>0 and g_highlighted.waypoint_id~=g_drag.waypoint_id then
                    repeat_point(v,g_drag.waypoint_id,g_highlighted.waypoint_id)
                else move_point(v,g_drag.waypoint_id,x,z)end
            else v:clear_waypoints();v:clear_attack_target();v:add_waypoint(x,z)end
            clear_drag()
        elseif event==e_input.back and action==e_input_action.press and open then open,adding=false,false;return end
        return previous_input(event,action)
    end
        if cc2x and type(cc2x.log)=='function' then cc2x.log('CARRIER_NAVIGATOR_UI_READY entry=library_custom_0') end
    end
    local previous_load=begin_load
    if type(previous_load)=='function' then
        function begin_load(...)
            local results=table.pack(previous_load(...))
            install()
            return table.unpack(results,1,results.n)
        end
    end
    install()
end
