local VERSION = "5.2"
love.window.setTitle("Friday Night Lovin' - VERSION " .. VERSION)

local scripter = require("engine.scripter")
settings = require("settings")
push = require("libs.push")

local volumeTrayAssets = {}

local debugFont = love.graphics.newFont(24)
function love.load()
  Class = require("libs.middleclass")
  JSON = require("libs.json")
  flux = require("libs.flux")

  settings:init()
  settings:applyPlayerSettings()
  
  scripter:loadDir("engine/")
  scripter:init()

  debugFont = love.graphics.newFont(push:getHeight()*0.019)
  volumeTrayAssets = {
    images = {
        box = Image:new(love.graphics.newImage("assets/images/volumetray/volumebox.png"))
    },
    sounds = {
        volDown = Sound:new("assets/sounds/volumetray/Voldown.ogg",ENUM_SOUND_MEMORY),
        volUp = Sound:new("assets/sounds/volumetray/Volup.ogg",ENUM_SOUND_MEMORY),
        volMax = Sound:new("assets/sounds/volumetray/VolMAX.ogg",ENUM_SOUND_MEMORY),
    }
  }
  for i = 1,10 do volumeTrayAssets.images["bars" .. tostring(i)] = Image:new(love.graphics.newImage("assets/images/volumetray/bars_" .. tostring(i) .. ".png")) end
  for _,v in pairs(volumeTrayAssets.images) do v.Visible = false end
end

function love.exit()
  settings:saveSettings()
end

function love.resize(w,h)
  push:resize(w,h)
end

local function changeVolume(var)
    volumeTrayAssets.images.box.Size = {w=300,h=150}
    volumeTrayAssets.images.box.Position = {
        x = push:getWidth()/2-volumeTrayAssets.images.box.Size.w/2,
        y = 0
    }
    volumeTrayAssets.images.box.Visible = true

    Entity:destroy("VolumeTrayClock")
    Entity:destroy("VolumeTrayClock_Final")

    local currentSettings = settings:getSettings()
    if var == 'up' then
        currentSettings.masterVolume = currentSettings.masterVolume + 1
        if currentSettings.masterVolume > 10 then
            currentSettings.masterVolume = 10
            volumeTrayAssets.sounds.volMax:createSource():play()
        else
            volumeTrayAssets.sounds.volUp:createSource():play()
        end
    elseif var == 'down' then
        currentSettings.masterVolume = currentSettings.masterVolume - 1
        if currentSettings.masterVolume < 0 then
            currentSettings.masterVolume = 0
        else
            volumeTrayAssets.sounds.volDown:createSource():play()
        end
    end

    local chosenVolumeBox = nil
    for i = 1,10 do
        if i == currentSettings.masterVolume then
            chosenVolumeBox = volumeTrayAssets.images["bars" .. tostring(i)]
        else
            volumeTrayAssets.images["bars" .. tostring(i)].Visible = false
        end
    end

    if chosenVolumeBox then
        chosenVolumeBox.Size = {
            w = volumeTrayAssets.images.box.Size.w-25,
            h = 65
        }
        chosenVolumeBox.Position = {
            x = volumeTrayAssets.images.box.Position.x+(25/2),
            y = volumeTrayAssets.images.box.Position.y+15
        }

        chosenVolumeBox.Visible = true
    end

    Entity:create(Clock,"VolumeTrayClock",1,1,function()
        flux.to(volumeTrayAssets.images.box.Position,0.1,{y=-150}):ease("linear")
        if chosenVolumeBox then
            flux.to(chosenVolumeBox.Position,0.1,{y=-150}):ease("linear")
        end

        Entity:create(Clock,"VolumeTrayClock_Final",1,0.1,function()
            volumeTrayAssets.images.box.Visible = false
            if chosenVolumeBox then
                chosenVolumeBox.Visible = false
            end
        end)
    end)

    love.audio.setVolume(currentSettings.masterVolume/10)
    settings:changeSetting("masterVolume",currentSettings.masterVolume)
    settings:saveSettings()
end

local showDebugText = false
local keyToFunc = {
    ['f1'] = function()
        showDebugText = not showDebugText
    end,
    ['-'] = function()
        changeVolume("down")
    end,
    ['='] = function()
        changeVolume("up")
    end
}

function love.keypressed(key)
  if keyToFunc[key] then
    keyToFunc[key]()
    return
  end
  Input:runBinds("KeyPressed",key)
end

function love.keyreleased(key)
  Input:runBinds("KeyReleased",key)
end

function love.mousepressed(_,_,button)
  Input:runBinds("MousePressed",button)
end

function love.update(dt)
  flux.update(dt)
  scripter:update(dt)

  for _,v in pairs(volumeTrayAssets.sounds) do v:update() end
end

function love.draw()
  push:start()
  scripter:draw()

  do
    volumeTrayAssets.images.box:draw() -- draw the box first
    for i = 1,10 do -- ...before anything else
        volumeTrayAssets.images["bars" .. tostring(i)]:draw()
    end
  end

  if showDebugText then
    local major,minor = love.getVersion()
    local debugStr = [[Game/Love2D Version: %s/%s
FPS : %d
Memory Usage (Lua): %.2f MiB
Memory Usage (GPU): %.2f MiB]]
    debugStr = string.format(debugStr,
      VERSION,
      (major .. "." .. minor),
      1/love.timer.getDelta(),
      collectgarbage("count")/1024,
      love.graphics.getStats().texturememory/1024/1024
    )

    love.graphics.setColor(0,0,0,0.8)
    love.graphics.printf(debugStr,debugFont,6,6,love.graphics.getWidth(),"left")
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.printf(debugStr,debugFont,5,5,love.graphics.getWidth(),"left")
  end

  push:finish()
end