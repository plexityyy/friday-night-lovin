-- Handles tasks to do later

local file = {priority=3}

function file:init()
  Clock = Class("Clock")
  
  function Clock:initialize(maxReps,delay,callback)
    self.maxReps = maxReps
    self.delay = delay
    self.callback = callback

    self.reps = 0
    self.dt = 0
    self.paused = false
  end

  function Clock:update(dt)
    if self.paused then return end

    self.dt = self.dt + dt
    if self.dt >= self.delay then
      self.dt = 0
      self.reps = self.reps + 1
      self.callback(self)

      if self.reps >= self.maxReps and self.maxReps > 0 then
        Entity:destroy(self)
      end
    end
  end
end

return file