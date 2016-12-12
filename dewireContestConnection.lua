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
local runMainCB = true

--------------------------------- OLED SHIELD --------------------------------
local row1, row2, row3 = ""
function initOLED() --Set up the u8glib lib
     SDA = 2 -- GPIO 4
     SCL = 1 --GPIO 5
     sla = 0x3C
     i2c.setup(0, SDA, SCL, i2c.SLOW)
     disp = u8g.ssd1306_64x48_i2c(sla)
     disp:setFont(u8g.font_6x10)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
     disp:firstPage()
     disp:setRot180()           -- Rotate Display if needed
end

function printLogo()
    initOLED()
    function fromhex(str)
        return (str:gsub('..', function (cc)
            return string.char(tonumber(cc, 16))
        end))
    end
    bin_data1 = fromhex("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3fc080bc270103fe7f8eb9193333e6fe7f9ed919")
    bin_data2 = fromhex("333366ff7f9ec149328307ff7f9ed943380367ff7f9ef9e33833e6ff7f8eb9e73c73e6fe3fe080e73c6102feffffffffffffffffffffffffffffffff")
    bin_data3 = fromhex("ffffffffffffffffffffff7ffdffffffffffff3ff8ffffffffffff1f60fdffffffffff0700feffffffffff0300f8ffffffffff0000fcffffffffff00")
    bin_data4 = fromhex("00fcffffffff3f0000fcffffffff7f0000f8ffffffff7f0000f8ffffffff1f0000f8ffffffff3f0000f8ffffffff3f0000f8ffffffff3f0000f0ffff")
    bin_data5 = fromhex("ffff7f0000f0ffffffff7f0000e0ffffffff7f0000e0ffffffffff0000e0ffffffffff0100f0ffffffffff0100f0ffffffffff0300f0ffffffffff07")
    bin_data6 = fromhex("00f8ffffffffff0f00f8ffffffffff0f00f8ffffffffff0f00fcffffffffff07e0ffffffffffff07e0ffffffffffff07f0ffffffffffff03f0ffffff")
    bin_data7 = fromhex("ffffff01e0ffffffffffff01c0ffffffffffff00c0ffffff")
    bin_data = bin_data1..bin_data2..bin_data3..bin_data4..bin_data5..bin_data6..bin_data7
    
    --init_OLED()
    disp:firstPage()  
    repeat  
        disp:drawXBM( 0, 0, 64, 48, bin_data);
    until disp:nextPage() == false  
end
M.printLogo = printLogo

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
    if runMainCB then
        print_OLED(str1, str2, "")
    elseif not runMainCB and connected then
        print_OLED(str1, str2, "Wifi:".. wifiSignal)
    end
end
M.printToLED = printToLED
-------------------------------------------------------------------------------

------------------------------------ MQTT -------------------------------------
-- MQTT client
local ID = teamName
local USER = ""
local PASS = ""
local keepAliveSec = 120

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
            mqttc:subscribe("test",0, function(conn) print("Subscribed!") end) 
            print("Connected!!")
            connected = true
            mqttc:publish(contestTopic,teamName.."§register§.",0,0)
            print_OLED("", "Connected!","")
            tmr.delay(1*1000*1000)
            updateRSSI()
            print_OLED("", "","Wifi:"..wifiSignal)
            -- Start recurrent ping with 5 sec interval
            tmr.alarm(6, 5000, 1, ping)
            if runMainCB then
                mainCB()
                runMainCB = false
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
    print_OLED("", "", "") -- Clear screen
    mqttc = mqtt.Client(name, keepAliveSec, USER, PASS)
    
    -- MQTT on-callbacks
    mqttc:on("offline", function(_, reasonCode) 
        connected = false
        print_OLED("  Lost", "connection","to contest")
        tmr.unregister(6);
        print("Connection closed", reasonCode)
    end) 

    mainCB = cb
    teamName = name
    initOLED()
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
