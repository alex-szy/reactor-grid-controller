local turbine = {}

local rpms = {
  CUTOFF = 1790,
  CUTIN = 1782
}

function turbine:new(component, active)
  --address validity is not checked
  --print("Constructing new turbine")
  local newTurbine = {
    m_component = component,
    m_active = active
  }
  setmetatable(newTurbine, {__index = turbine})
  return newTurbine
end

function turbine:doSomething()
  local comp = self.m_component
  if not comp.getConnected() then return end
  if self:getRunState() == true then
    -- if i'm supposed to be running
    local rpm = comp.getRotorSpeed()
    if rpm > rpms.CUTOFF then
      -- above cutoff rpm
      comp.setInductorEngaged(true)
      comp.setActive(false)
    elseif rpm < rpms.CUTIN then
      -- below cutin rpm
      comp.setInductorEngaged(false)
      comp.setActive(true)
    else--if rpm >= rpms.STEADY then
      -- at steady rpm
      comp.setInductorEngaged(true)
      comp.setActive(true)
    end
  else
    comp.setInductorEngaged(false)
    comp.setActive(false)
  end
end

function turbine:setRunState(active)
  self.m_active = active
end

function turbine:getRunState()
  return self.m_active
end

return turbine