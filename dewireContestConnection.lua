--[[
    dewireContestConnection.lua
    
    Connects to WiFi and the contest server.
--]]
local M = {}

-- Contest
local contestTopic = "hackathon/iot"
local contestName = "Dewires IoT contest"
local teamName = nil
local mainCB = nil
local connected = false
local wifiSignal = ""

--------------------------------- OLED SHIELD --------------------------------
local row1, row2, row3 = ""
function init_OLED() --Set up the u8glib lib
     SDA = 2 -- GPIO 4
     SCL = 1 --GPIO 5
     sla = 0x3C
     i2c.setup(0, SDA, SCL, i2c.SLOW)
     disp = u8g.ssd1306_64x48_i2c(sla)
     disp:setFont(u8g.font_6x10)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
     disp:setRot180()           -- Rotate Display if needed
end

function print_OLED(str1, str2, str3)
    row1 = str1
    row2 = str2
    row3 = str3 
   disp:firstPage()
   repeat
     disp:drawStr(3, 10, row1)
     disp:drawStr(3, 20, row2)
     disp:drawStr(3, 30, row3)
   until disp:nextPage() == false
end

local function printToLED(str1, str2)
    if connected then
        print_OLED(str1, str2, "Wifi:".. wifiSignal)
    end
end
M.printToLED = printToLED
-------------------------------------------------------------------------------

------------------------------------ WiFi -------------------------------------

function updateRSSI()
        signal = 2 * (wifi.sta.getrssi() + 100)
        if signal > 100 then signal = 100 end
        if signal < 0 then signal = 0 end
        wifiSignal = tostring(signal).."%"
end

function connectToWifi(ssid, pass)
    print("Connecting to " .. ssid)
    print_OLED("Connecting", " to wifi..", "")
    wifi.setmode(wifi.STATION)
    wifi.sta.config(ssid,pass,0)
    wifi.sta.connect()
end

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T) 
    print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
    T.netmask.."\n\tGateway IP: "..T.gateway)
    print_OLED("", " Got wifi!","")
    tmr.delay(2*1000*1000)
    print_OLED("Connecting", "  to the"," contest..")
    print("Connecting to "..contestName.."...")
    mqttConnect()
end)

wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T) 
    print("\n\tSTA - DISCONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
    T.BSSID.."\n\treason: "..T.reason)
    tmr.unregister(5);
    tmr.unregister(6);
    wifiSignal = "0%"
    print_OLED("   Wifi","  failed!", "")
    tmr.delay(2*1000*1000)
    print("Reconnecting to " .. T.SSID)
    print_OLED(" Reconnect", " to wifi..", "")
    wifi.sta.connect()
end)
-------------------------------------------------------------------------------

------------------------------------ MQTT -------------------------------------
-- MQTT client
local ID = teamName
local USER = ""
local PASS = ""
local keepAliveSec = 120
mqttc = mqtt.Client("test", keepAliveSec, "user", PASS)
local runMainCB = false

-- MQTT server
local SERVER_ADDR =  ""
local PORT = 11883
local MQTT_ADDR = "mqtt://"..SERVER_ADDR..":"..PORT

local function ping()
    if connected then
        updateRSSI()
        print_OLED(row1, row2,"Wifi:"..wifiSignal)
        if not pcall(mqttc.publish, mqttc, contestTopic,teamName.."§ping§.",0,0) then
            print_OLED("   Error", "  could", " not ping")
            mqttReconnect()
        end
    end
end

function mqttConnect()
    tmr.delay(1*1000*1000)
    mqttc:connect(SERVER_ADDR, PORT, 0, 1, 
        function(client) 
            print("Connected!!")
            connected = true
            mqttc:publish(contestTopic,teamName.."§register§.",0,0)
            print_OLED("", "Connected!","")
            tmr.delay(1*1000*1000)
            updateRSSI()
            print_OLED("", "","Wifi:"..wifiSignal)
            -- Start recurrent ping with 5 sec interval
            tmr.alarm(6, 5000, 1, ping)
            if not runMain then
                mainCB()
                runMainCB = true
            end
        end, 
        function(client, reason) print("Failed to connect to " ..contestName..": "..reason) print_OLED("  Contest", "connection", "  failed") tmr.delay(1*1000*1000) mqttReconnect()
    end)
end

function mqttReconnect()
    connected = false
    print("Lost connection to contest.")
    tmr.unregister(6);
    print_OLED("Reconnects", "    to"," contest..")
    print("Reconnecting to "..contestName.."...")
    mqttConnect()
end

-- On mqtt close
mqttc:on("offline", function(_, reasonCode) 
    connected = false
    print_OLED("  Lost", "connection","to contest")
    tmr.unregister(6);
    print("Connection closed", reasonCode) 
end) 

-- On mqtt receive message
mqttc:on("message", function(client, topic, data) 
    print("Received message: "..topic.." : "..data)
end)
-------------------------------------------------------------------------------

local function send(msg)
    if connected then
        if not pcall(mqttc.publish, mqttc, contestTopic,teamName.."§updatetext§"..msg,0,0) then
            print("Warning: Could not send.")
            print_OLED(" Warning", "  could", " not send")
            mqttReconnect()
        end
    end
end
M.send = send

-- Connect to wifi and contest
local function connect(name, ssid, psw, server, cb)
    print_OLED("", "", "")
    mqttc = mqtt.Client(name, keepAliveSec, USER, PASS)
    mainCB = cb
    teamName = name
    init_OLED()
    SERVER_ADDR = server
    -- After connecting to wifi it will try to contect to the contest server.
    connectToWifi(ssid, psw) 
end
M.connect = connect

-- Disconnect from wifi and contest
local function disconnect()
    print("Disconnecting from "..contestName.."!")
    tmr.unregister(6);
    connected = false
    mqttc:close()
end
M.disconnect = disconnect
 
return M
