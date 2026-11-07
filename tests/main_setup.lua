TEST={navigation_available=true,created=0,updates=0,unloads=0,events={}}
local carrier={motion_available=function()return true end,drive_motion=function()end}
TEST.carrier=carrier
local cc2={carrier=carrier,events={}}
cc2.events.on=function(name,callback)TEST.events[name]=callback;return true end
cc2.events.off=function(name)TEST.events[name]=nil end
local runtime={update=function()TEST.updates=TEST.updates+1 end,
    buttons=function()end,unload=function()TEST.unloads=TEST.unloads+1 end}
function require(name)
    if name=='cc2'then return cc2 end
    if name=='bridge.runtime'then return {new=function()TEST.created=TEST.created+1;return runtime end}end
    if name=='bridge.cruise' or name=='bridge.defence'then return {}end
    error('Unexpected module '..tostring(name))
end
