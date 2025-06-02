-- Displays images as a sequence of animations

local file = {priority=1.5}

function file:init()
  Actor = Class("Actor",Object)
  function Actor:initialize(spritesheet,framessheet,animationssheet)
    Object.initialize(self)
    
    self.Colour = {r=1,g=1,b=1,a=1}
    self.Scale = 1
    
    self.Animations = {}
    self.FallbackAnimation = nil
    
    self.Spritesheet = spritesheet

    local newFrmSheet = {}
    for i,v in pairs(framessheet) do
      newFrmSheet[tonumber(i)] = v
    end

    self.Framessheet = newFrmSheet
    self.Animationssheet = animationssheet

    -- autoload all animations
    for anim,contents in pairs(self.Animationssheet) do
      if contents.fallback and not self.FallbackAnimation then
        self.FallbackAnimation = anim
      end

      -- loading frames
      local quads = {}
      local x = 1
      for i = contents.startFrame,contents.endFrame do
        local frm = self.Framessheet[i]
        quads[x] = love.graphics.newQuad(frm.x,frm.y,frm.width,frm.height,self.Spritesheet:getWidth(),self.Spritesheet:getHeight())
        x = x + 1
      end

      self.Animations[anim] = {
        frames = quads,
        dt = 1,
        priority = contents.priority,
        speed = contents.speed,
        playing = false,
        looped = contents.looping,
        offsetX = contents.offsetX,
        offsetY = contents.offsetY
      }
    end
  end

  function Actor:playAnimation(name)
    self.Animations[name].playing = true
    self.Animations[name].dt = 1
  end

  function Actor:stopAnimation(name)
    self.Animations[name].playing = false
    self.Animations[name].dt = 1
  end

  function Actor:resumeAnimation(name)
    self.Animations[name].playing = true
  end

  function Actor:pauseAnimation(name)
    self.Animations[name].playing = false
  end

  function Actor:getAnimation(name)
    return self.Animations[name]
  end
  
  function Actor:update(dt)
    for _,anim in pairs(self.Animations) do
      if anim.playing then
        anim.dt = anim.dt + dt*anim.speed
        if anim.dt >= #anim.frames then
          if anim.looped then
            anim.dt = 1
          else
            anim.playing = false
          end
        end
      end
    end
  end
  
  function Actor:draw()
    if not self.Visible then return end
    love.graphics.setColor(self.Colour.r,self.Colour.g,self.Colour.b,self.Colour.a)
    
    local chosenAnim = nil
    local chosenPri = -1
    
    for name,anim in pairs(self.Animations) do
      if anim.playing and anim.priority > chosenPri then
        chosenPri = anim.priority
        chosenAnim = name
      end
    end
    
    if not chosenAnim then chosenAnim = self.FallbackAnimation end
    local currentAnim = self.Animations[chosenAnim]

    local width
    local height
    
    local currentFrame = self.Framessheet[ self.Animationssheet[chosenAnim].startFrame-1 + math.floor(currentAnim.dt) ]

    if currentFrame.offsetWidth == 0 then
      width = math.floor(currentFrame.width/2)
    else
      width = math.floor(currentFrame.offsetWidth/2) + currentFrame.offsetX
    end
    if currentFrame.offsetHeight == 0 then
      height = math.floor(currentFrame.height/2)
    else
      height = math.floor(currentFrame.offsetHeight/2) + currentFrame.offsetY
    end

    local scaleX = self.Scale
    if self.Flipped then
      scaleX = -scaleX
    end

    love.graphics.draw(
      self.Spritesheet,
      currentAnim.frames[math.floor(currentAnim.dt)],
      self.Position.x,
      self.Position.y,
      0,
      scaleX,
      self.Scale,
      width + currentAnim.offsetX,
      height + currentAnim.offsetY
    )
  end
end

return file