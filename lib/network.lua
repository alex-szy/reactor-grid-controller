local tCon = require("turbine_ctrl")
local event = require("event")
local component = require("component")

local network = {}

function network.startService()
  if network.m_timerID ~= nil then
    print("Turbine controller already running.")
    return
  end
  print("Starting turbine controller")
  tCon.startService()
  event.listen("modem_message", network.messageHandler)
  network.m_timerID = event.timer(1, network.sendInfo, math.huge)
  print("Turbine controller started")
end

function network.stopService()
  if network.m_timerID == nil then return end
  event.ignore("modem_message", network.messageHandler)
  event.cancel(network.m_timerID)
  network.m_timerID = nil
  tCon.stopService()
end

function network.sendInfo()
  if not component.isAvailable("tunnel") then return end
  local tunnel = component.getPrimary("tunnel")
  tunnel.send("maxTurbines", tCon.getMaxTurbines())
end

function network.messageHandler(_, _, _, _, _, message, n)
  if message == "request" then
    tCon.requestTurbines(tonumber(n))
  end
end

return network