-- Displays text w/ a given font
local file = {priority=2}

function file:init()
  Text = Class("Text",Object)
  
  function Text:initialize(text,font)
    Object.initialize(self)
    self.Size = nil

    self.Text = text or "Hello World!"
    self.Font = font or love.graphics.newFont(push:getHeight()*0.25)
    self.Limit = push:getWidth()/2
    self.Align = "center"
    self.Scale = 1

    self.Colour = {r=1,g=1,b=1,a=1}
    self.Visible = true
  end
  
  function Text:draw()
    if not self.Visible then return end

    love.graphics.setColor(self.Colour.r,self.Colour.g,self.Colour.b,self.Colour.a)
    if self.Shader then
      love.graphics.setShader(self.Shader)
      love.graphics.printf(self.Text,self.Font,self.Position.x,self.Position.y,self.Limit/self.Scale,self.Align,0,self.Scale,self.Scale)
      love.graphics.setShader()
      return
    end
    
    love.graphics.printf(self.Text,self.Font,self.Position.x,self.Position.y,self.Limit/self.Scale,self.Align,0,self.Scale,self.Scale)
  end
end

return file