-- Handles user inputs (duh)

local file = {priority=3}

local BindClass = Class("Bind")
function BindClass:initialize(actions,callback)
  self.actions = actions
  self.callback = callback
end

function BindClass:execute(...)
  self.callback(unpack({...}))
end

--

local currentBinds = {}
local InputSystem = Class("Input")

function InputSystem:initialize()
  self.Mouse = {x = 0,y = 0}
end

function InputSystem:bind(name,actions,callback)
  assert(not currentBinds[name],string.format("Error when trying to bind action \"%s\" (there is another bind w/ the same name)",name))
  currentBinds[name] = BindClass:new(actions,callback)
end

function InputSystem:unbind(name)
  assert(currentBinds[name],string.format("Error when trying to unbind action \"%s\" (bind does not exist)",name))
  currentBinds[name] = nil
end

function InputSystem:getBind(name)
  return currentBinds[name]
end

function InputSystem:runBinds(action,...)
  for _,bind in pairs(currentBinds) do
    for _,ac in pairs(bind.actions) do
      if ac == action then
        bind:execute(...)
        break
      end
    end
  end
end

--

function file:init()
  Input = InputSystem:new()
end

function file:update()
  local mX,mY = push:toGame(love.mouse.getX(),love.mouse.getY())
  if not mX or not mY then return end

  Input.Mouse.x = mX
  Input.Mouse.y = mY
end

return file