-- $1,000,000 camera
local file = {priority=5}

function file:init()
  Camera = Class("Camera")
  function Camera:initialize()
    self.Position = {x=0,y=0}
    self.OffsetPosition = {x=0,y=0}
    self.Scale = 1
  end

  function Camera:worldToCam(pos)
    return {
      x = (pos.x - (self.Position.x + self.OffsetPosition.x)) * self.Scale,
      y = (pos.y - (self.Position.y + self.OffsetPosition.y)) * self.Scale
    }
  end

  function Camera:camToWorld(pos)
    return {
      x = pos.x / self.Scale + (self.Position.x + self.OffsetPosition.x),
      y = pos.y / self.Scale + (self.Position.y + self.OffsetPosition.y)
    }
  end

  function Camera:attach()
    love.graphics.push()
    love.graphics.scale(self.Scale)
    love.graphics.translate(-(self.Position.x + self.OffsetPosition.x),-(self.Position.y + self.OffsetPosition.x))
  end

  function Camera:detach()
    love.graphics.pop()
  end
end

return file