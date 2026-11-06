-- SPDX-License-Identifier: GPL-3.0-or-later
-- Uses the live game's native power range, with no invented knot limit.
local M = {}
function M.new()
    return {
        reset = function() end,
        step = function(_, percent)
            assert(type(percent)=='number' and percent==percent and percent>=0 and percent<=100, 'invalid native power percentage')
            return percent/100
        end,
    }
end
return M
