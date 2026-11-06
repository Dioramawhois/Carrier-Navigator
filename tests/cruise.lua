local c=POLICY.new()
for _,game_speed in ipairs({0,15,25,60,150})do assert(c.step(game_speed,100,1/30)==1)end
assert(c.step(0,50,1/30)==.5)
assert(c.step(100,10,1/30)==.1)
assert(not pcall(function()c.step(0,101,1/30)end))
c.reset();assert(c.step(0,100,1/30)==1)
print('SCENARIOS 5')
