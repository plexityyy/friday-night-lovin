-- Displays an image
local file = {priority=2}

function file:init()
  ENUM_IMAGE_FITTYPE_STRETCH = "stretch"
  ENUM_IMAGE_FITTYPE_FIT = "fit"

  Image = Class("Image",Object)
  
  local function simulateDraw(o)
    if o.FitType == ENUM_IMAGE_FITTYPE_STRETCH then
      if o.Quad then
        love.graphics.draw(o.Image,o.Quad,o.Position.x,o.Position.y,0,o.Size.w/o.Image:getWidth(),o.Size.h/o.Image:getHeight())
      else
        love.graphics.draw(o.Image,o.Position.x,o.Position.y,0,o.Size.w/o.Image:getWidth(),o.Size.h/o.Image:getHeight())
      end
    elseif o.FitType == ENUM_IMAGE_FITTYPE_FIT then
      local drawX = o.Position.x + (o.Size.w - o.Image:getWidth())/2
      local drawY = o.Position.y + (o.Size.h - o.Image:getHeight())/2
      
      local scale = math.min(o.Size.w/o.Image:getWidth(),o.Size.h/o.Image:getHeight())
      if o.Quad then
        love.graphics.draw(o.Image,o.Quad,drawX,drawY,0,scale,scale)
      else
        love.graphics.draw(o.Image,drawX,drawY,0,scale,scale)
      end
    end
  end
  
  function Image:initialize(img,quad)
    Object.initialize(self)
    
    self.Colour = {r=1,g=1,b=1,a=1}
    self.Image = img
    self.Quad = quad or nil
    
    self.FitType = ENUM_IMAGE_FITTYPE_STRETCH
    self.Visible = true
  end

  function Image:destroying()
    self.Image:release()
    if self.Quad then
      self.Quad:release()
    end
  end
  
  function Image:draw()
    if not self.Visible then return end

    love.graphics.setColor(self.Colour.r,self.Colour.g,self.Colour.b,self.Colour.a)
    if self.Shader then
      love.graphics.setShader(self.Shader)
      simulateDraw(self)
      love.graphics.setShader()
      return
    end
    
    simulateDraw(self)
  end
end

return file