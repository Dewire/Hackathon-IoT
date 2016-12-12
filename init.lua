--[[
    init.lua

    Waits 5 seconds after boot befor starting main.lua. 
    This time can be used for sending/removing files to the node.
--]]
dcc = require("dewireContestConnection")
dcc.printLogo()
print("Your node has booted!")
local warned = false

function startup()
    if not pcall(dofile, "main.lua") then
        if not warned then print("Warning: Could not run main.lua.") warned = true end
        dcc.printToLED(" Missing", " main.lua")
        tmr.alarm(1, 5000, tmr.ALARM_SINGLE, startup)
    end
end 

tmr.alarm(1, 5000, tmr.ALARM_SINGLE, startup)

    



