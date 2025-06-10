-- generic superclass
local file = {priority=3}

function file:init()
  Object = Class("Object")
  
  function Object:initialize()
    self.Position = {x=0,y=0}
    self.Size = {w=0,h=0}
    
    self.Shader = nil
    self.Visible = true
  end
  
  function Object:setShader(shaderFile)
    self.Shader = love.graphics.newShader(love.filesystem.read(shaderFile))
  end
  
  function Object:clearShader()
    self.Shader = nil
  end
end

return file