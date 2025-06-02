-- Displays an image
local file = {priority=2}

function file:init()
  ENUM_SOUND_MEMORY = "static" -- loads to RAM
  ENUM_SOUND_STREAM = "stream" -- loads to hard drive

  Sound = Class("Sound")
  function Sound:initialize(dir,class,dirIsContents)
    if not dirIsContents then
      self.Source = love.audio.newSource(dir,class)
    else -- "dir" is really just the contents of the audio file
      local data = love.filesystem.newFileData(dir,"audioFile")
      self.Source = love.audio.newSource(data,class)
    end
    self.PlayingSources = {}
  end

  function Sound:createSource()
    local cln = self.Source:clone()
    table.insert(self.PlayingSources,cln)
    return cln
  end

  function Sound:destroying()
    for i,v in pairs(self.PlayingSources) do
      v:stop()
      v:release()
      table.remove(self.PlayingSources,i)
    end
  end

  function Sound:update()
    for i,v in pairs(self.PlayingSources) do
      if not v:isPlaying() and not v:isLooping() then
        v:release()
        table.remove(self.PlayingSources,i)
      end
    end
  end
end

return file