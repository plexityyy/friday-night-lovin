-- Handles states
local file = {priority=1}

local StatesSystem = Class("States")
function StatesSystem:initialize()
  self.AvailableStates = {
    ["menu"] = require("engine.states.menu"),
    ["game"] = require("engine.states.game")
  }
  self.currentState = "menu"
  self.AvailableStates[self.currentState]:enter()
end

function StatesSystem:switchState(nState,...)
  local newState = self.AvailableStates[nState]
  local oldState = self.AvailableStates[self.currentState]
  
  if oldState then
    oldState:exit(unpack({...}))
  end
  newState:enter(unpack({...}))
  self.currentState = nState

  collectgarbage("collect")
end

--

function file:init()
  States = StatesSystem:new()
end

function file:update(dt)
  States.AvailableStates[States.currentState]:update(dt)
end

function file:draw()
  States.AvailableStates[States.currentState]:draw()
end

return file