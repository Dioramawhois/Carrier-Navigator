-- SPDX-License-Identifier: GPL-3.0-or-later
-- Native power selection with continuous ahead propulsion through course changes.
local M = {}
local function finite(v)return type(v)=='number' and v==v and math.abs(v)<math.huge end
function M.new()
    local previous
    return {
        reset = function() previous=nil end,
        step = function(frame, percent, seconds)
            assert(finite(percent) and percent>=0 and percent<=100, 'invalid native power percentage')
            assert(finite(seconds) and seconds>0, 'invalid simulation step')
            local cap=percent/100
            if not frame.guidance_ready or not finite(frame.heading_error) or
                not finite(frame.path_distance) or frame.path_distance<0 then
                previous=nil;return cap,0
            end
            -- Full ahead on a straight course; retain 35% of selected power
            -- for a complete reversal instead of native turn-in-place idle.
            local turn=.35+.65*(1+math.cos(frame.heading_error))*.5
            local approach=math.min(1,frame.path_distance/100)
            local target=cap*turn*approach
            if previous==nil then previous=finite(frame.lever) and math.max(0,math.min(cap,frame.lever)) or 0 end
            local dt=math.min(seconds,.25)
            local delta=target-previous
            previous=previous+math.max(-.45*dt,math.min(.35*dt,delta))
            previous=math.max(0,math.min(cap,previous))
            -- Keep stopping near the native path endpoint responsive.
            if approach<.25 then previous=math.min(previous,target) end
            return cap,previous
        end,
    }
end
return M
