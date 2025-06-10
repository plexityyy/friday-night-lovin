local settings = {}
settings.__index = settings

local currentSettings = {
    keybinds = {
        left = 'left',
        down = 'down',
        up = 'up',
        right = 'right'
    },
    downScroll = false,
    middleScroll = false,
    fullScreen = false,
    antiAliasing = true,
    vsync = true,
    hitVolume = 0.5,
    masterVolume = 10
}

function settings:init()
    if not love.filesystem.getInfo("settings.json") then
        love.filesystem.write("settings.json",JSON.encode(currentSettings))
    end
    currentSettings = JSON.decode(love.filesystem.read("settings.json"))

    for _,v in pairs({"customassets","stages","songs"}) do
        if not love.filesystem.getInfo(v) then
            love.filesystem.createDirectory(v)
        end
    end

    for _,v in pairs({"audio","fonts","images","videos","actors","shaders"}) do
        if not love.filesystem.getInfo("customassets/" .. v) then
            love.filesystem.createDirectory("customassets/" .. v)
        end
    end
end

function settings:applyPlayerSettings()
    local vsyncVal = 0
    if currentSettings.vsync then vsyncVal = 1 end
    local aliasingVal = 0
    if currentSettings.antiAliasing then aliasingVal = 2 end

    love.window.setMode(1366,728,{
        vsync = vsyncVal,
        msaa = aliasingVal
    })
    push:setupScreen(1920,1080,1366,728,{
        fullscreen = currentSettings.fullScreen,
        resizable = true
    })

    love.audio.setVolume(currentSettings.masterVolume/10)
end

function settings:getSettings()
    return currentSettings
end

function settings:changeSetting(name,value,save)
    currentSettings[name] = value
    if save then
        self:saveSettings()
    end
end

function settings:changeKeybind(direction,key)
    currentSettings.keybinds[direction] = key
end

function settings:saveSettings()
    love.filesystem.write("settings.json",JSON.encode(currentSettings))
end

return settings