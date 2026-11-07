-- SPDX-License-Identifier: GPL-3.0-or-later
-- The real SDK facade and current complete mod run against owned native doubles.
local count=0
for _,available in ipairs({false,true})do
    local motion={id=42,team=0,can_control=true,manual=false,active=false,mode=1,
        waypoints=2,speed_mps=0,guidance_ready=true,heading_error=0,path_distance=1000,lever=1}
    local published,messages,drives,configured={}, {},0,0
    local precise=available and type(POLICY.sdk.carrier.navigation_available)=='function'
    cc2_bridge_motion_available=function()return true end
    cc2_bridge_motion_state=function(id)assert(id==42);return motion end
    cc2_bridge_motion_set=function(_,active)motion.active=active;return true end
    cc2_bridge_motion_drive=function(_,power,forward)
        assert(power==1 and forward==1);drives=drives+1;motion.active=true;return true
    end
    cc2_bridge_motion_contacts=function()return {}end
    cc2_bridge_session_generation=function()return 1 end
    cc2_bridge_messages_publish=function(topic,id,value)published[topic..':'..id]=value;return true end
    cc2_bridge_messages_poll=function()local result=messages;messages={};return result end
    cc2_bridge_event_capabilities={vehicle_controls=true}
    cc2_bridge_event_subscription=function()return true end
    cc2_bridge_navigation_available=function()return available end
    cc2_bridge_navigation_set=function(_,options)
        assert(precise and options.minimum_depth==0 and options.arrival_radius==25)
        configured=configured+1;return true
    end
    cc2_bridge_navigation_state=function()
        assert(precise)
        return {configured=true,ready=true,distance=10000,arrival_radius=25,minimum_depth=0}
    end
    POLICY.sdk.world.vehicles=function()return {{id=42,team=0,x=0,z=0,is_air=false,team_is_ai=false}}end
    local entry=POLICY.entry();entry.on_load();entry.on_update()
    messages={{topic='start',value=1,subject=42}};entry.on_update()
    assert(drives==1 and motion.active and motion.waypoints==2)
    assert(published['ready:0']==1 and published['navigation_mode:0']==(precise and 1 or 0))
    assert(configured==(precise and 1 or 0))
    messages={{topic='pause',value=0,subject=42}};entry.on_update()
    assert(not motion.active);entry.on_unload()
    count=count+1;print('PASS real SDK facade preserves module load Start Pause and capability selection')
end
print('SCENARIOS '..count)
