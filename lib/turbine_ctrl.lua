local component = require("component")
local event = require("event")
local turbine = require("turbine")

local turbines = {
  m_turbines = nil,
  m_timerID = nil,
  m_nTurb = nil
}

function turbines.discover()
  for address, _ in component.list("br_turbine", true) do
    turbines.add(address)
  end
end

function turbines.doSomething()
  for _, t in pairs(turbines.m_turbines) do
    t:doSomething()
  end
end

function turbines.requestTurbines(n)
  for _, t in pairs(turbines.m_turbines) do
    if n > 0 then
      t:setRunState(true)
    else
      t:setRunState(false)
    end
    n = n - 1
  end
end

function turbines.svcRunning()
  return turbines.m_timerID ~= nil
end

function turbines.add(address)
  turbines.m_turbines[address] = turbine:new(component.proxy(address), false)
  turbines.m_nTurb = turbines.m_nTurb + 1
end

function turbines.remove(address)
  if turbines.m_turbines[address] ~= nil then
    turbines.m_turbines[address] = nil
    turbines.m_nTurb = turbines.m_nTurb - 1
  end
end

function turbines.hotPlug(event, address, ctype)
  if ctype == "br_turbine" then
    if event == "component_removed" then
      turbines.remove(address)
    elseif event == "component_added" then
      turbines.add(address)
    end
  end
end

function turbines.getMaxTurbines()
  if turbines.m_nTurb == nil then
    return 0
  else
    return turbines.m_nTurb
  end
end

function turbines.list()
  print("List of turbines:")
  for address, _ in pairs(turbines.m_turbines) do
    print(address)
  end
  print("End of list")
end

function turbines.startService()
  if not turbines.svcRunning() then
    turbines.m_nTurb = 0
    turbines.m_turbines = {}
    turbines.discover()
    event.listen("component_removed", turbines.hotPlug)
    event.listen("component_added", turbines.hotPlug)
    turbines.m_timerID = event.timer(1, turbines.doSomething, math.huge)
    return true
  end
  return false
end

function turbines.stopService()
  if turbines.svcRunning() then
    event.ignore("component_removed", turbines.hotPlug)
    event.ignore("component_added", turbines.hotPlug)
    event.cancel(turbines.m_timerID)
    turbines.m_nTurb = nil
    turbines.m_timerID = nil
    turbines.m_turbines = nil
    return true
  end
  return false
end

return turbines