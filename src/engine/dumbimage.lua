-- Displays an image (simpler form of image.lua, doesn't involve any FitTypes)
local file = {priority=2}

function file:init()
  DumbImage = Class("DumbImage",Object)
  
  function DumbImage:initialize(img,quad)
    Object.initialize(self)
    self.Size = nil
    self.ScaleX = 1
    self.ScaleY = 1
    self.OffsetX = 0
    self.OffsetY = 0
    
    self.Colour = {r=1,g=1,b=1,a=1}
    self.Image = img
    self.Quad = quad or nil
    self.Visible = true
  end

  function DumbImage:destroying()
    self.Image:release()
    self.Quad:release()
  end
  
  function DumbImage:draw()
    if not self.Visible then return end

    love.graphics.setColor(self.Colour.r,self.Colour.g,self.Colour.b,self.Colour.a)
    if self.Shader then
      love.graphics.setShader(self.Shader)
      if self.Quad then
        love.graphics.draw(self.Image,self.Quad,self.Position.x,self.Position.y,0,self.ScaleX,self.ScaleY,self.OffsetX,self.OffsetY)
      else
        love.graphics.draw(self.Image,self.Position.x,self.Position.y,0,self.ScaleX,self.ScaleY,self.OffsetX,self.OffsetY)
      end
      love.graphics.setShader()
      return
    end
    
    if self.Quad then
      love.graphics.draw(self.Image,self.Quad,self.Position.x,self.Position.y,0,self.ScaleX,self.ScaleY,self.OffsetX,self.OffsetY)
    else
      love.graphics.draw(self.Image,self.Position.x,self.Position.y,0,self.ScaleX,self.ScaleY,self.OffsetX,self.OffsetY)
    end
  end
end

return file