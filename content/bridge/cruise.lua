-- SPDX-License-Identifier: GPL-3.0-or-later
-- Native power demand with an opt-in precise-goal, speed-aware coastal approach.
local M = {}
local function finite(v)return type(v)=='number' and v==v and math.abs(v)<math.huge end
function M.new(mode)
    mode=mode or 'coastal'
    assert(mode=='native' or mode=='coastal','invalid navigation mode')
    local previous
    return {
        reset = function() previous=nil end,
        step = function(frame, percent, seconds)
            assert(finite(percent) and percent>=0 and percent<=100, 'invalid native power percentage')
            assert(finite(seconds) and seconds>0, 'invalid simulation step')
            local cap=percent/100
            local navigation=frame.navigation
            if not frame.guidance_ready or not finite(frame.heading_error) or
                not finite(frame.path_distance) or frame.path_distance<0 then
                previous=nil;return cap,0
            end
            local approach=math.min(1,frame.path_distance/100)
            if mode=='coastal' then
                if not finite(frame.speed_mps) or type(navigation)~='table' or
                    navigation.configured~=true or navigation.ready~=true or
                    navigation.blocked or navigation.faulted or navigation.arrived or
                    not finite(navigation.distance) or navigation.distance<0 or
                    not finite(navigation.arrival_radius) or navigation.arrival_radius<1 or navigation.arrival_radius>150 then
                    previous=nil;return cap,0
                end
                local remaining=math.max(0,navigation.distance-navigation.arrival_radius)
                local speed=math.abs(frame.speed_mps)
                -- Conservative demand heuristic, not a hull braking guarantee.
                local coast_distance=speed*speed/.2+speed*3
                if remaining<=coast_distance then previous=0;return cap,0 end
                approach=math.min(approach,remaining/math.max(100,speed*15))
            end
            -- Preserve normal full power and useful ahead thrust for open-water
            -- turns. Near the requested goal, approach demand takes precedence.
            local turn=.35+.65*(1+math.cos(frame.heading_error))*.5
            local target=cap*turn*approach
            if previous==nil then previous=finite(frame.lever) and math.max(0,math.min(cap,frame.lever)) or 0 end
            local dt=math.min(seconds,.25)
            local delta=target-previous
            previous=previous+math.max(-.45*dt,math.min(.35*dt,delta))
            previous=math.max(0,math.min(cap,previous))
            -- Reduce near-goal power immediately instead of forcing the far-route
            -- minimum forward setting through a sharp coastal turn.
            if approach<.25 then previous=math.min(previous,target) end
            return cap,previous
        end,
    }
end
return M
