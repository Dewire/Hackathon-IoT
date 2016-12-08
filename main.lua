--[[ 
     ____                _            ___    _____  _                _         _   _                 
    |  _ \  _____      _(_)_ __ ___  |_ _|__|_   _|| |__   __ _  ___| | ____ _| |_| |__   ___  _ __  
    | | | |/ _ \ \ /\ / / | '__/ _ \  | |/ _ \| |  | '_ \ / _` |/ __| |/ / _` | __| '_ \ / _ \| '_ \ 
    | |_| |  __/\ V  V /| | | |  __/  | | (_) | |  | | | | (_| | (__|   < (_| | |_| | | | (_) | | | |
    |____/ \___| \_/\_/ |_|_|  \___| |___\___/|_|  |_| |_|\__,_|\___|_|\_\__,_|\__|_| |_|\___/|_| |_|

    -----------------------------------  API description --------------------------------------------
    * dcc.send(string) :: Send a string to the contest server.                                      *
    * dcc.printToLED(string, string) :: Write two strings to the LED screen.                        *
    -------------------------------------------------------------------------------------------------
    
--]]

local dcc = require("dewireContestConnection")

-- Change the values below to the ones given by the instructors.
local contestServer = "xxxx.dewire.com"
local SSID = "wifi SSID"
local PASS = "wifi password"

local teamName = "noname" -- Change this to your team name.
local alphabet = {" ","a","b","c"}
local scentence = "your sentence.."
local currentChar = "a"
local debugStr = "debug str"

local function main()
    print("Your code is running!")
    
    -- Tip: use tmr.alarm to schedule events without locking the system.
    -- Example code:
    tmr.alarm(1, 1000, 1, function()
        currentChar = alphabet[math.random(1,4)]
        dcc.printToLED("char:"..currentChar, debugStr)
        dcc.send(scentence..currentChar)
    end)
end

-- Connects to wifi, register to the contest and then triggers the main function.
dcc.connect(teamName, SSID, PASS, contestServer, main)
