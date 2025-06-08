-- Display a video (ogv Theora SUCKS)
local file = {priority=2}

function file:init()
  Video = Class("Video",Object)
  
  local function simulateDraw(o)
    if o.FitType == "stretch" then
      love.graphics.draw(o.Source,o.Position.x,o.Position.y,0,o.Size.w/o.Source:getWidth(),o.Size.h/o.Source:getHeight())
    elseif o.FitType == "fit" then
      local drawX = o.Position.x + (o.Size.w - o.Source:getWidth())/2
      local drawY = o.Position.y + (o.Size.h - o.Source:getHeight())/2
      
      local scale = math.min(o.Size.w/o.Source:getWidth(),o.Size.h/o.Source:getHeight())
      love.graphics.draw(o.Source,drawX,drawY,0,scale,scale)
    end
  end
  
  function Video:initialize(video)
    Object.initialize(self)
    
    self.Colour = {r=1,g=1,b=1,a=1}
    self.Source = love.graphics.newVideo(video)
    
    self.FitType = "stretch"
  end

  function Video:destroying()
    self.Source:release()
  end
  
  function Video:draw()
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