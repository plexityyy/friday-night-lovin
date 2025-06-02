-- Entity manager

local EntitySystem = Class("Entity")
function EntitySystem:initialize()
  self.camera = Camera:new()
  self.instances = {}
end

function EntitySystem:create(class,name,...)
  local o = class:new(unpack({...}))
  o.Name = name or "Object"
  table.insert(self.instances,o)
  return o
end

function EntitySystem:insert(obj,name)
  obj.Name = name or "Object"
  table.insert(self.instances,obj)
end

function EntitySystem:flush() -- oml i gotta shit
  for i,v in pairs(self.instances) do
    if v.destroying then
      v:destroying()
    end
    table.remove(self.instances,i)
  end
end

function EntitySystem:destroy(obj)
  if type(obj) == "string" then
    for i,v in pairs(self.instances) do
      if v.Name == obj then
        if v.destroying then
          v:destroying()
        end
        table.remove(self.instances,i)
        return
      end
    end
  end
  
  for i,v in pairs(self.instances) do
    if v == obj then
      if v.destroying then
        v:destroying()
      end
      table.remove(self.instances,i)
      return
    end
  end
end

function EntitySystem:getObjectsByName(name)
  local objs = {}
  
  for _,v in pairs(self.instances) do
    if v.Name == name then
      table.insert(objs,v)
    end
  end
  
  return objs
end

--

local file = {priority=4}

function file:init()
  Entity = EntitySystem:new()
end

function file:update(dt)
  for _,v in pairs(Entity.instances) do
    if v.update then
      v:update(dt)
    end
  end
end

function file:draw()
  Entity.camera:attach()
  for _,v in pairs(Entity.instances) do
    if v.draw then
      v:draw()
    end
  end
  Entity.camera:detach()
end

return file