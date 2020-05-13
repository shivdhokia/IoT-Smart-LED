wifi.sta.sethostname("uopNodeMCU")
wifi.setmode(wifi.STATION)
station_cfg = {}
station_cfg.ssid = "TP-Link_7BDB"
station_cfg.pwd = "71771489"
station_cfg.save = true
wifi.sta.config(station_cfg)
wifi.sta.connect()

-- mytimer = tmr.create()
-- mytimer:register(20000, 1, function() 
if wifi.sta.getip() == nil then
    print("Connecting to AP...\n")
else
    ip, nm, gw = wifi.sta.getip()
    mac = wifi.sta.getmac()
    rssi = wifi.sta.getrssi()
    print("IP Info: \nIP Address: ", ip)
    print("Netmask: ", nm)
    print("Gateway Addr: ", gw)
    print("MAC: ", mac)
    print("RSSI: ", rssi, "\n")
    --    mytimer:stop()
end
-- end)
-- mytimer:start()

photoPin = 0
LED_pin = 3

gpio.mode(LED_pin, gpio.OUTPUT)
gpio.write(LED_pin, gpio.LOW)

HOST = "io.adafruit.com" -- adafruit host
PORT = 1883 -- 1883 or 8883(1883 for default TCP, 8883 for encrypted SSL or other ways)
ADAFRUIT_IO_USERNAME = "ShivD97" -- put your own username here
ADAFRUIT_IO_KEY = "aio_GxtH272mDCxHv2u568MlVrl03wzn" -- put your own io_key here
PUBLISH_TOPIC = "ShivD97/feeds/stream"
SUBSCRIBE_TOPIC = "ShivD97/feeds/brightnessled" -- put your topic of subscribe shown on the IoT platform/broker site
-- init mqtt client with logins, keepalive timer 300 seconds
m = mqtt.Client("Client1", 300, ADAFRUIT_IO_USERNAME, ADAFRUIT_IO_KEY)
-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 1, retain = 0, data = "offline"
-- to topic "/lwt" if client does not send keepalive packet
m:lwt("/lwt", "Now offline", 1, 0)
-- on different event "connect","offline","message",...
m:on("connect", function(client)
    print("Client connected")
    print("MQTT client connected to " .. HOST)
    client:subscribe(SUBSCRIBE_TOPIC, 1,
                     function(client) print("Subscribe successfully") end)

    pubADC(client)
end)

m:on("offline", function(client) print("Client offline") end)

dc = 1023
pinDim = 3
pinADC = 0

mytimer = tmr.create()
print("Timer Created")
mytimer:register(5000, 1, function()
    digitV = adc.read(pinADC)
    print("Light")
    print(digitV)
    if (digitV < 10) then
        dc = digitV * 100
    else
        dc = 1023
    end
    pwm.setduty(pinDim, dc)
end)

m:on("message", function(client, topic, data)
    print(topic .. ":")
    print("data")
    print(data)

    pwm.setup(pinDim, 1000, dc)
    pwm.start(pinDim)

    if data == 'ON' then

        print(data)

        gpio.write(pinDim, gpio.HIGH)

        mytimer:start()


    elseif data == 'OFF' then
        print(mytimer:state())
        running, mode = mytimer:state()
        if (running == "true" or mode == 1) then

            mytimer:stop()
        end

        gpio.write(pinDim, gpio.LOW)
        pwm.setduty(pinDim,0)
        print("Turned Off")
        

    else
        print(mytimer:state())
        running, mode = mytimer:state()

        if (running == "true" or mode == 1) then
            mytimer:stop()
        end
        gpio.write(pinDim, gpio.HIGH)

        dc = data * 10
        pwm.setduty(pinDim, dc)

    end
end)

function pubADC(client)
    mytimerPublish = tmr.create()
    mytimerPublish:register(5000,1,function()

    strV = tostring(dc/100)
    client:publish(PUBLISH_TOPIC,strV,1,0,function(client)
    print("Light level reading sent: " , strV) 
        end)
    end)
    mytimerPublish:start()
end

m:connect(HOST, PORT, false, false, function(conn) end, function(conn, reason)
    print("Fail! Failed reason is: " .. reason)
end)
