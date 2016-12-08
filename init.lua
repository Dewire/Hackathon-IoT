--[[
    init.lua

    Waits 5 seconds after boot befor starting main.lua. 
    This time can be used for sending/removing files to the node.
--]]

--------------------------------- OLED SHIELD --------------------------------
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
     disp:firstPage()
     disp:setRot180()           -- Rotate Display if needed
end
-------------------------------------------------------------------------------

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

init_OLED()
disp:firstPage()  
repeat  
    disp:drawXBM( 0, 0, 64, 48, bin_data);
until disp:nextPage() == false  
tmr.wdclr()

print("Your node has booted!")
local warned = false

function startup()
    if not pcall(dofile, "main.lua") then
        if not warned then print("Warning: Could not run main.lua.") warned = true end
        disp:firstPage()
        repeat
            disp:drawStr(3, 10, " Missing")
            disp:drawStr(3, 20, " main.lua")
        until disp:nextPage() == false
        tmr.alarm(1, 5000, tmr.ALARM_SINGLE, startup)
    end
end 

tmr.alarm(1, 5000, tmr.ALARM_SINGLE, startup)

    



