local component = require("component")
local event = require("event")
local term = require("term")

local percentages = {
  RCUTIN = 20,
  CUTIN = 25,
  CUTOFF = 30
}

local states = {
  ECHARGE = 0,  
  CHARGEMAX = 1,
  CHARGEMIN = 2,
  DISCHMIN = 3,
  DISCHMAX = 4
}

local rfPerTurbine = 28043
local interval = 5

local grid = {
  m_timerID = nil,
  m_rq = nil,
  m_charging = nil,
  m_rsOut = nil,
  m_lastRF = nil
}

function grid.doSomething()
  -- if no available tunnel or storage do nothing
  if not component.isAvailable("tunnel") or not component.isAvailable("draconic_rf_storage") then return end

  local storage = component.getPrimary("draconic_rf_storage")
  local tunnel = component.getPrimary("tunnel")

  -- only for the first time, update lastRF and don't do anything
  if grid.m_lastRF == nil then
    grid.m_lastRF = storage.getEnergyStored()
    return
  end

  -- set charging state
  local currRF = storage.getEnergyStored()
  local percent = currRF / (storage.getMaxEnergyStored() / 100)
  if percent > percentages.CUTOFF then
    -- discharge at max rate
    grid.m_charging = states.DISCHMAX
  elseif percent < percentages.CUTIN then
    if percent < percentages.RCUTIN then
      grid.m_charging = states.ECHARGE
    end
    -- if emergency was not already triggered request all turbines
    if grid.m_charging ~= states.ECHARGE then
      grid.m_charging = states.CHARGEMAX
    end
  else -- in between the cutin and cutoff points
    -- maintain current state but discharge at min rate
    if grid.m_charging == states.DISCHMAX then
      grid.m_charging = states.DISCHMIN
    elseif grid.m_charging == states.CHARGEMAX then
      grid.m_charging = states.CHARGEMIN
    end
  end
  
  -- set number of requested turbines
  -- by default rainbow gen is off
  local transfer = (currRF - grid.m_lastRF) / 20 / interval
  grid.m_lastRF = currRF
  grid.m_rsOut = false
  if grid.m_charging == states.DISCHMAX then
    grid.m_rq = 0
  elseif grid.m_charging == states.DISCHMIN then
    grid.m_rq = grid.m_rq - math.ceil(transfer / rfPerTurbine)
  elseif grid.m_charging == states.CHARGEMIN then
    grid.m_rq = grid.m_rq - math.floor(transfer / rfPerTurbine)
  elseif grid.m_charging == states.CHARGEMAX then
    grid.m_rq = grid.m_nTurb
  elseif grid.m_charging == states.ECHARGE then
    -- rainbow gen used in emergency mode
    grid.m_rsOut = true
    grid.m_rq = grid.m_nTurb
  else return
  end
  
  -- set rainbow gen
  grid.setRsOut(grid.m_rsOut)

  -- cannot request less than 0 or more than the max number of turbines
  if grid.m_rq < 0 then
    grid.m_rq = 0
  elseif grid.m_rq > grid.m_nTurb then
    grid.m_rq = grid.m_nTurb
  end
  
  x, y = term.getCursor()
  io.write("Requesting ", grid.m_rq, " of ", grid.m_nTurb, " turbines ")
  term.setCursor(x, y)
  tunnel.send("request", grid.m_rq)
end
  
function grid.svcRunning()
  return grid.m_timerID ~= nil
end

function grid.messageHandler(_, _, _, _, _, message, n)
  if message == "maxTurbines" then
    grid.m_nTurb = math.floor(n)
  end
end

function grid.setRsOut(active)
  if not component.isAvailable("redstone") then return end
  local redstone = component.getPrimary("redstone")
  local rsOut = 0
  if active then rsOut = 15 end
  for side = 0, 0 do
    redstone.setOutput(side, rsOut)
  end
end

function grid.startService()
  if grid.svcRunning() then return end
  grid.m_timerID = event.timer(interval, grid.doSomething, math.huge)
  grid.m_charging = states.CHARGEMIN
  grid.m_rq = 0
  grid.m_nTurb = 0
  grid.m_rsOut = false
  grid.m_lastRF = nil
  event.listen("modem_message", grid.messageHandler)
  term.setCursorBlink(false)
end

function grid.stopService()
  if not grid.svcRunning() then return end
  event.cancel(grid.m_timerID)
  grid.m_timerID = nil
  grid.m_charging = nil
  grid.m_rq = nil
  grid.m_rsOut = nil
  grid.m_lastRF = nil
  grid.setRsOut(grid.m_rsOut)
  event.ignore("modem_message", grid.messageHandler)
  grid.m_nTurb = nil
  term.setCursorBlink(true)
end

return grid