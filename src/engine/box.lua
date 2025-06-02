-- Displays an image
local file = {priority=2}

function file:init()
  ENUM_BOX_FILLMODE_FILL = "fill"
  ENUM_BOX_FILLMODE_LINE = "line"

  Box = Class("Box",Object)
  
  function Box:initialize()
    Object.initialize(self)
    self.Colour = {r=1,g=1,b=1,a=1}

    self.FillMode = ENUM_BOX_FILLMODE_FILL
    self.LineThickness = 1
  end
  
  function Box:draw()
    love.graphics.setColor(self.Colour.r,self.Colour.g,self.Colour.b,self.Colour.a)
    love.graphics.setLineWidth(self.LineThickness)
    if self.Shader then
      love.graphics.setShader(self.Shader)
      love.graphics.rectangle(self.FillMode,self.Position.x,self.Position.y,self.Size.w,self.Size.h)
      love.graphics.setShader()
      return
    end
    
    love.graphics.rectangle(self.FillMode,self.Position.x,self.Position.y,self.Size.w,self.Size.h)
  end
end

return file