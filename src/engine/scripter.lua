-- Manages scripts

local file = {ignore=true}
local scripts = {}

function file:loadDir(dir)
  local prefix = dir
  if string.sub(dir,#dir,#dir) ~= "/" then prefix = prefix .. "/" end
  for _,v in pairs(love.filesystem.getDirectoryItems(dir)) do
    if string.sub(v,#v-3,#v) == ".lua" then
      local path = prefix .. v
      path = string.gsub(path,"/",".")
      path = string.gsub(path,".lua","")
      local file = require(path)
      if not file.ignore then
        table.insert(scripts,file)
      end
    end
  end
end

function file:init()
  table.sort(scripts,function(a,b)
    local aPr = a.priority or 0
    local bPr = b.priority or 0
    return aPr > bPr
  end)

  for _,v in pairs(scripts) do
    if v.init then
      v:init()
    end
  end
end

function file:update(dt)
  for _,v in pairs(scripts) do
    if v.update then
      v:update(dt)
    end
  end
end

function file:draw()
  for _,v in pairs(scripts) do
    if v.draw then
      v:draw()
    end
  end
end

return file