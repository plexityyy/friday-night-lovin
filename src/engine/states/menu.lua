--[[

TODO:
    1. Add settings menu

]]

local state = {}
local stuff = {}

local canTouchAnything = true
local settingsMessageShown = false

local function checkCollision(x,y,w,h)
    return x < Input.Mouse.x and Input.Mouse.x < x+w and y < Input.Mouse.y and Input.Mouse.y < y+h
end

function state:enter(skipIntro)
    Entity.camera.Position.x, Entity.camera.Position.y = 0,0

    stuff.MainMenuSound = Entity:create(Sound,"menuSong","assets/music/freakyMenu.ogg",ENUM_SOUND_STREAM)
    stuff.MainMenuSound.Source:setLooping(true)

    stuff.wallpaper = Entity:create(Image,"wallpaperMainMenu",love.graphics.newImage("assets/images/mainmenu/menuDesat.png"))
    stuff.wallpaper.Size.w = push:getWidth()*1.05
    stuff.wallpaper.Size.h = push:getHeight()*1.05
    stuff.wallpaper.Position = {
        x = push:getWidth()/2 - stuff.wallpaper.Size.w/2,
        y = push:getHeight()/2 - stuff.wallpaper.Size.h/2
    }
    stuff.wallpaper.FitType = ENUM_IMAGE_FITTYPE_STRETCH
    stuff.wallpaper.Visible = false

    stuff.bar = Entity:create(Box,"menuPanel")
    stuff.bar.Colour = {r=0,g=0,b=0,a=0.5}
    stuff.bar.Size = {w=push:getWidth(),h=push:getHeight()*0.15}
    stuff.bar.Position = {x=0,y=push:getHeight()-stuff.bar.Size.h}

    stuff.menuSoundConfirm = Entity:create(Sound,"menuSoundConfirm","assets/sounds/confirmMenu.ogg",ENUM_SOUND_MEMORY)
    stuff.scrollSound = Entity:create(Sound,"scrollSound","assets/sounds/scrollMenu.ogg",ENUM_SOUND_MEMORY)

    local function pressedEvent(button)
        if not canTouchAnything then return end
        canTouchAnything = false
        stuff.menuSoundConfirm:createSource():play()

        Entity:create(Clock,"buttonFlash",20,1/24,function(clock)
            if clock.reps%2 == 0 then
                button.Visible = true
            else
                button.Visible = false
            end

            if clock.reps == 20 then
                canTouchAnything = true
                button.Event()
            end
        end)
    end

    local playlists = {}
    local playListsPage = 1
    local playListsMaxPages = 1

    local items = 0
    for i,folder in pairs(love.filesystem.getDirectoryItems("songs/")) do
        local s,e = pcall(function()
            local metadata = JSON.decode(love.filesystem.read("songs/" .. folder .. "/metadata.json"))
            playlists[i] = {
                meanName = folder,
                name = metadata.songName,
                artist = metadata.artist or "Unknown",
                charter = metadata.charter or "Unknown",
                version = metadata.version or "1",
                difficulties = {
                    easy = false,
                    normal = false,
                    hard = false
                }
            }

            local chartingData = JSON.decode(love.filesystem.read("songs/" .. folder .. "/chart.json"))
            playlists[i].difficulties.easy = (chartingData.notes.easy ~= nil)
            playlists[i].difficulties.normal = (chartingData.notes.normal ~= nil)
            playlists[i].difficulties.hard = (chartingData.notes.hard ~= nil)
        end)

        if not s then
            print(string.format("Error when trying to load \"%s\"!\n%s",folder,e))
            playlists[i] = nil
        else
            items = items + 1
            if items > 5 then
                items = 0
                playListsMaxPages = playListsMaxPages + 1
            end
        end
    end

    local menuVHSFont = love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.05)
    local options = {
        {
            text = "SONGS",
            colour = {r=1,g=0,b=0,a=1},
            pri = 1,
            callback = function()
                if #playlists == 0 then
                    local txt = [[You have no songs installed!!
Please put new playlists into %s/songs.]]
                    local os = love.system.getOS()
                    if os == "Windows" then
                        txt = string.format(txt,"%AppData%/LOVE/friday-night-lovin")
                    elseif os == "Linux" then
                        txt = string.format(txt,"~/.local/share/love/friday-night-lovin")
                    elseif os == "OS X" then
                        txt = string.format(txt,"your user directory/Library/Application Support/LOVE/friday-night-lovin")
                    end

                    local font = love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.04)
                    stuff.headsUp = Entity:create(Text,"headsUp",txt,font)
                    stuff.headsUp.Limit = push:getWidth()
                    stuff.headsUp.Position = {x=0,y=push:getHeight()/2 - font:getHeight(txt)/2}
                else
                    local function rebuildButtons()
                        for name,v in pairs(stuff) do
                            if string.find(name,"songButton") then
                                v.Visible = false
                                Entity:destroy(v)
                            end
                        end

                        local index = 1
                        for i = (playListsPage - 1) * 5 + 1,math.min(playListsPage * 5, #playlists) do
                            if playlists[i] then
                                local songButton = Entity:create(Text,"songButton" .. tostring(index),playlists[i].name,love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.1))
                                songButton.ChangeColour = false
                                songButton.Position.y = push:getHeight()*0.25 + (songButton.Font:getHeight() * (index-1))
                                songButton.Limit = push:getWidth()

                                function songButton.MousePressed()
                                    if not canTouchAnything then return end
                                    stuff.menuSoundConfirm:createSource():play()
                                    for name,_ in pairs(stuff) do
                                        if string.find(name,"songSelected") then
                                            Entity:destroy(name)
                                        end
                                    end

                                    local box = Entity:create(Box,"songSelectedBox")
                                    box.Size = {w=push:getWidth()*0.65,h=push:getHeight()*0.22}
                                    box.Position = {x=push:getWidth()/2-box.Size.w/2,y=0}
                                    box.Colour = {r=0,g=0,b=0,a=0.5}

                                    local songName = Entity:create(Text,"songSelectedSongName","\"" .. string.upper(playlists[i].name) .. "\"",love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.1))
                                    songName.Position = {x=box.Position.x,y=5}
                                    songName.Limit = box.Size.w

                                    local creditsText = Entity:create(Text,"songSelectedCreditsText","Artist(s): " .. playlists[i].artist .. ", Charter(s): " .. playlists[i].charter,love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.03))
                                    creditsText.Position = {x=box.Position.x,y=box.Size.h/2}
                                    creditsText.Limit = box.Size.w
                                    
                                    for _,v in pairs({"easy","normal","hard"}) do
                                        if playlists[i].difficulties[v] then
                                            local diffButton = Entity:create(Text,"songSelectedDifficulty" .. v,string.upper(v),menuVHSFont)
                                            diffButton.Position.y = box.Size.h - diffButton.Font:getHeight()

                                            diffButton.Limit = box.Size.w*0.3
                                            if v == "easy" then
                                                diffButton.Colour = {r=0,g=1,b=0,a=1}
                                                diffButton.Position.x = box.Position.x
                                            elseif v == "normal" then
                                                diffButton.Colour = {r=1,g=1,b=0,a=1}
                                                diffButton.Position.x = box.Position.x + (box.Size.w/2) - (diffButton.Font:getWidth(diffButton.Text)/2)*2
                                                
                                            elseif v == "hard" then
                                                diffButton.Colour = {r=1,g=0,b=0,a=1}
                                                diffButton.Position.x = box.Position.x + box.Size.w - diffButton.Font:getWidth(diffButton.Text)*3
                                            end

                                            function diffButton.MousePressed()
                                                pressedEvent(diffButton)
                                            end
                                            function diffButton.Event()
                                                States:switchState("game", playlists[i].meanName,v)
                                            end

                                            stuff["songSelectedDifficulty" .. v] = diffButton
                                        end
                                    end

                                    stuff.songSelectedCreditsText = creditsText
                                    stuff.songSelectedSongName = songName
                                    stuff.songSelectedBox = box
                                end

                                stuff["songButton" .. tostring(index)] = songButton
                                index = index + 1
                            end
                        end
                    end

                    local pagesText = Entity:create(Text,"pagesText","Page: " .. tostring(playListsPage),menuVHSFont)
                    pagesText.Limit = push:getWidth()*0.15
                    pagesText.Position = {x=push:getWidth()/2-menuVHSFont:getWidth("BACK"),y=stuff.bar.Position.y + stuff.bar.Size.h/4 - (menuVHSFont:getHeight("BACK")/2)}

                    local previousButton = Entity:create(Text,"previousButton","PREVIOUS", menuVHSFont)
                    previousButton.Limit = push:getWidth()*0.25
                    previousButton.Position = {x=push:getWidth()*0.02,y=stuff.bar.Position.y + stuff.bar.Size.h/2 - (menuVHSFont:getHeight(previousButton.Text)/2)}
                    previousButton.Visible = false
                    previousButton.ChangeColour = false

                    local nextButton = Entity:create(Text,"nextButton","NEXT", menuVHSFont)
                    nextButton.Limit = push:getWidth()*0.25
                    nextButton.Position = {x=push:getWidth()*0.75,y=stuff.bar.Position.y + stuff.bar.Size.h/2 - (menuVHSFont:getHeight(nextButton.Text)/2)}
                    nextButton.ChangeColour = false

                    if playListsMaxPages == 1 then
                        nextButton.Visible = false
                    end

                    function previousButton.MousePressed()
                        pressedEvent(previousButton)
                    end
                    function previousButton.Event()
                        playListsPage = playListsPage - 1
                        if playListsPage < 1 then playListsPage = 1 end
                        pagesText.Text = "Page: " .. tostring(playListsPage)
                        if playListsPage == 1 then
                            previousButton.Visible = false
                        end
                        nextButton.Visible = true

                        rebuildButtons()
                    end

                    function nextButton.MousePressed()
                        pressedEvent(nextButton)
                    end
                    function nextButton.Event()
                        playListsPage = playListsPage + 1
                        if playListsPage > #playlists then playListsPage = #playlists end
                        pagesText.Text = "Page: " .. tostring(playListsPage)
                        if playListsPage == #playlists then
                            nextButton.Visible = false
                        end
                        previousButton.Visible = true

                        rebuildButtons()
                    end

                    stuff.pagesText = pagesText
                    stuff.nextButton = nextButton
                    stuff.previousButton = previousButton

                    rebuildButtons()
                end

                for _,v in pairs({"buttonSONGS","buttonSETTINGS","buttonMERCH","buttonREPO","buttonQUIT","bumpingLogo","createdWithLOVEText"}) do
                    Entity:getObjectsByName(v)[1].Visible = false
                end

                local backButton = Entity:create(Text,"buttonBack","BACK",menuVHSFont)
                backButton.Colour = {r=1,g=0,b=0,a=1}
                backButton.Limit = push:getWidth()*0.15
                backButton.Position = {x=push:getWidth()/2-menuVHSFont:getWidth("BACK"),y=stuff.bar.Position.y + stuff.bar.Size.h/1.2 - (menuVHSFont:getHeight("BACK")/2)}

                function backButton.MousePressed()
                    pressedEvent(backButton)
                end

                function backButton.Event()
                    for _,v in pairs({"buttonBack","headsUp","pagesText","previousButton","nextButton","songSelectedCreditsText","songSelectedSongName","songSelectedBox","songSelectedDifficultyeasy","songSelectedDifficultynormal","songSelectedDifficultyhard"}) do
                        Entity:destroy(v)
                        stuff[v] = nil
                    end
                    for i = 1,6 do
                        Entity:destroy("songButton" .. tostring(i))
                        stuff["songButton" .. tostring(i)] = nil
                    end
                    
                    for _,v in pairs({"buttonSONGS","buttonSETTINGS","buttonMERCH","buttonREPO","buttonQUIT","bumpingLogo","createdWithLOVEText"}) do
                        Entity:getObjectsByName(v)[1].Visible = true
                    end
                end

                stuff.backButton = backButton
            end
        },
        {
            text = "SETTINGS",
            colour = {r=1,g=1,b=0,a=1},
            pri = 2,
            callback = function() -- to be finished later
                if not settingsMessageShown then
                    love.window.showMessageBox("Not finished!","This menu isn't finished yet, but you can interact with most options.\nSorry! :P", "info", true)
                    settingsMessageShown = true
                end
                for _,v in pairs({"buttonSONGS","buttonSETTINGS","buttonMERCH","buttonREPO","buttonQUIT","bumpingLogo","createdWithLOVEText"}) do
                    Entity:getObjectsByName(v)[1].Visible = false
                end

                stuff.settingsBAR = Entity:create(Box,"settingsBAR")
                stuff.settingsBAR.Colour = {r=0,g=0,b=0,a=0.5}
                stuff.settingsBAR.Size = {w=push:getWidth()*0.8,h=push:getHeight()*0.6}
                stuff.settingsBAR.Position = {x=push:getWidth()/2-stuff.settingsBAR.Size.w/2,y=push:getHeight()*0.25-stuff.settingsBAR.Size.h*0.25}

                local backButton = Entity:create(Text,"buttonBack","BACK",menuVHSFont)
                backButton.Colour = {r=1,g=0,b=0,a=1}
                backButton.Limit = push:getWidth()*0.15
                backButton.Position = {x=push:getWidth()/2-menuVHSFont:getWidth("BACK"),y=stuff.bar.Position.y + stuff.bar.Size.h/2 - (menuVHSFont:getHeight("BACK")/2)}

                local currentSettings = settings:getSettings()
                local settingsVHSFont = love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.05)

                -- DOWNSCROLL
                local downScrollButton = Entity:create(Text,"downScrollButton", "Downscroll?: YES", settingsVHSFont)
                downScrollButton.ChangeColour = false
                downScrollButton.Limit = stuff.settingsBAR.Size.w/2
                downScrollButton.Position = {
                    x = stuff.settingsBAR.Position.x,
                    y = stuff.settingsBAR.Position.y+75
                }
                if not currentSettings.downScroll then
                    downScrollButton.Text = "Downscroll?: NO"
                end
                function downScrollButton.MousePressed()
                    pressedEvent(downScrollButton)
                end
                function downScrollButton.Event()
                    currentSettings.downScroll = not currentSettings.downScroll
                    settings:changeSetting("downScroll",currentSettings.downScroll,true)

                    if currentSettings.downScroll then
                        downScrollButton.Text = "Downscroll?: YES"
                    else
                        downScrollButton.Text = "Downscroll?: NO"
                    end
                end
                -- MIDDLESCROLL
                local middleScrollButton = Entity:create(Text,"middleScrollButton", "Middlescroll?: YES", settingsVHSFont)
                middleScrollButton.ChangeColour = false
                middleScrollButton.Limit = stuff.settingsBAR.Size.w/2
                middleScrollButton.Position = {
                    x = stuff.settingsBAR.Position.x,
                    y = stuff.settingsBAR.Position.y+75+settingsVHSFont:getHeight()
                }
                if not currentSettings.middleScroll then
                    middleScrollButton.Text = "Middlescroll?: NO"
                end
                function middleScrollButton.MousePressed()
                    pressedEvent(middleScrollButton)
                end
                function middleScrollButton.Event()
                    currentSettings.middleScroll = not currentSettings.middleScroll
                    settings:changeSetting("middleScroll",currentSettings.middleScroll,true)

                    if currentSettings.middleScroll then
                        middleScrollButton.Text = "Middlescroll?: YES"
                    else
                        middleScrollButton.Text = "Middlescroll?: NO"
                    end
                end

                -- VSYNC
                local vsyncButton = Entity:create(Text,"vsyncButton", "V-Sync?: YES", settingsVHSFont)
                vsyncButton.ChangeColour = false
                vsyncButton.Limit = stuff.settingsBAR.Size.w/2
                vsyncButton.Position = {
                    x = stuff.settingsBAR.Position.x,
                    y = stuff.settingsBAR.Position.y+75+(settingsVHSFont:getHeight()*2)
                }
                if not currentSettings.vsync then
                    vsyncButton.Text = "V-Sync?: NO"
                end
                function vsyncButton.MousePressed()
                    pressedEvent(vsyncButton)
                end
                function vsyncButton.Event()
                    currentSettings.vsync = not currentSettings.vsync
                    settings:changeSetting("vsync",currentSettings.vsync,true)
                    settings:applyPlayerSettings()

                    if currentSettings.vsync then
                        vsyncButton.Text = "V-Sync?: YES"
                    else
                        vsyncButton.Text = "V-Sync?: NO"
                    end
                end
                
                -- ANTI-ALIASING
                local msaaButton = Entity:create(Text,"msaaButton", "Anti-Aliasing?: YES", settingsVHSFont)
                msaaButton.ChangeColour = false
                msaaButton.Limit = stuff.settingsBAR.Size.w/2
                msaaButton.Position = {
                    x = stuff.settingsBAR.Position.x,
                    y = stuff.settingsBAR.Position.y+75+(settingsVHSFont:getHeight()*3)
                }
                if not currentSettings.antiAliasing then
                    msaaButton.Text = "Anti-Aliasing?: NO"
                end
                function msaaButton.MousePressed()
                    pressedEvent(msaaButton)
                end
                function msaaButton.Event()
                    currentSettings.antiAliasing = not currentSettings.antiAliasing
                    settings:changeSetting("antiAliasing",currentSettings.antiAliasing,true)
                    settings:applyPlayerSettings()

                    if currentSettings.antiAliasing then
                        msaaButton.Text = "Anti-Aliasing?: YES"
                    else
                        msaaButton.Text = "Anti-Aliasing?: NO"
                    end
                end

                -- FULLSCREEN
                local fullscreenButton = Entity:create(Text,"fullscreenButton", "Fullscreen?: YES", settingsVHSFont)
                fullscreenButton.ChangeColour = false
                fullscreenButton.Limit = stuff.settingsBAR.Size.w/2
                fullscreenButton.Position = {
                    x = stuff.settingsBAR.Position.x,
                    y = stuff.settingsBAR.Position.y+75+(settingsVHSFont:getHeight()*4)
                }
                if not currentSettings.fullScreen then
                    fullscreenButton.Text = "Fullscreen?: NO"
                end
                function fullscreenButton.MousePressed()
                    pressedEvent(fullscreenButton)
                end
                function fullscreenButton.Event()
                    currentSettings.fullScreen = not currentSettings.fullScreen
                    settings:changeSetting("fullScreen",currentSettings.fullScreen,true)
                    settings:applyPlayerSettings()

                    if currentSettings.fullScreen then
                        fullscreenButton.Text = "Fullscreen?: YES"
                    else
                        fullscreenButton.Text = "Fullscreen?: NO"
                    end
                end

                -- HIT VOLUME
                local hitVolumeButton = Entity:create(Text,"hitVolumeButton", "Hit Volume?: " .. tostring(math.floor(currentSettings.hitVolume*100)) .. "%", settingsVHSFont)
                local hitVolumeButtonUp = Entity:create(Text,"hitVolumeButtonUp", "^", settingsVHSFont)
                hitVolumeButtonUp.ChangeColour = false
                local hitVolumeButtonDown = Entity:create(Text,"hitVolumeButtonDown", "v", settingsVHSFont)
                hitVolumeButtonDown.ChangeColour = false

                hitVolumeButton.Limit = (stuff.settingsBAR.Size.w/2) - settingsVHSFont:getWidth(hitVolumeButtonUp.Text) - settingsVHSFont:getWidth(hitVolumeButtonDown.Text)
                hitVolumeButtonUp.Limit = settingsVHSFont:getWidth(hitVolumeButtonUp.Text)
                hitVolumeButtonDown.Limit = settingsVHSFont:getWidth(hitVolumeButtonDown.Text)
                hitVolumeButtonDown.Align = "left"
                hitVolumeButtonUp.Align = "right"

                hitVolumeButtonDown.DontDisplayBorders = true
                hitVolumeButtonUp.DontDisplayBorders = true

                hitVolumeButtonDown.Position = {
                    x = stuff.settingsBAR.Position.x,
                    y = stuff.settingsBAR.Position.y+75+(settingsVHSFont:getHeight()*5)
                }
                hitVolumeButton.Position = {
                    x = hitVolumeButtonDown.Position.x + hitVolumeButtonDown.Limit + 15,
                    y = hitVolumeButtonDown.Position.y
                }
                hitVolumeButtonUp.Position = {
                    x = hitVolumeButton.Position.x + hitVolumeButton.Limit + hitVolumeButtonUp.Limit/2,
                    y = hitVolumeButton.Position.y
                }

                local hitSoundEffect = Entity:create(Sound,"hitSoundEffect","assets/sounds/hit.ogg",ENUM_SOUND_MEMORY)

                function hitVolumeButtonDown.MousePressed()
                    if not canTouchAnything then return end

                    currentSettings.hitVolume = currentSettings.hitVolume - 0.1
                    if currentSettings.hitVolume < 0 then currentSettings.hitVolume = 0 end
                    settings:changeSetting("hitVolume",currentSettings.hitVolume,true)

                    hitSoundEffect.Source:setVolume(currentSettings.hitVolume)
                    hitSoundEffect:createSource():play()

                    hitVolumeButton.Text = "Hit Volume?: " .. tostring(math.floor(currentSettings.hitVolume*100)) .. "%"
                end

                function hitVolumeButtonUp.MousePressed()
                    if not canTouchAnything then return end

                    currentSettings.hitVolume = currentSettings.hitVolume + 0.1
                    if currentSettings.hitVolume > 1 then currentSettings.hitVolume = 1 end
                    settings:changeSetting("hitVolume",currentSettings.hitVolume,true)

                    hitSoundEffect.Source:setVolume(currentSettings.hitVolume)
                    hitSoundEffect:createSource():play()

                    hitVolumeButton.Text = "Hit Volume?: " .. tostring(math.floor(currentSettings.hitVolume*100)) .. "%"
                end

                -- KEY BINDS
                for i,v in pairs({"Left","Down","Up","Right"}) do
                    local keyBindingButton = Entity:create(Text,"keyBindingButton" .. v, v .. "?: " .. currentSettings.keybinds[v:lower()]:upper(), settingsVHSFont)
                    keyBindingButton.ChangeColour = false
                    keyBindingButton.Limit = stuff.settingsBAR.Size.w/2
                    keyBindingButton.Position = {
                        x = stuff.settingsBAR.Position.x+stuff.settingsBAR.Size.w/2,
                        y = stuff.settingsBAR.Position.y+75+(settingsVHSFont:getHeight()*(i-1))
                    }

                    function keyBindingButton.MousePressed()
                        pressedEvent(keyBindingButton)
                    end
                    function keyBindingButton.Event()
                        love.window.showMessageBox("Sorry!","This option doesn't do anything yet.","info",true)
                    end

                    stuff["keyBindingButton" .. v] = keyBindingButton
                end

                stuff.hitSoundEffect = hitSoundEffect
                stuff.hitVolumeButton = hitVolumeButton
                stuff.hitVolumeButtonUp = hitVolumeButtonUp
                stuff.hitVolumeButtonDown = hitVolumeButtonDown
                stuff.fullscreenButton = fullscreenButton
                stuff.msaaButton = msaaButton
                stuff.vsyncButton = vsyncButton
                stuff.downScrollButton = downScrollButton
                stuff.middleScrollButton = middleScrollButton

                function backButton.MousePressed()
                    pressedEvent(backButton)
                end

                function backButton.Event()
                    for _,v in pairs({"backButton","settingsBAR","downScrollButton","middleScrollButton","vsyncButton","msaaButton","fullscreenButton","hitVolumeButton","hitVolumeButtonUp","hitVolumeButtonDown","hitSoundEffect","keyBindingButtonLeft","keyBindingButtonDown","keyBindingButtonUp","keyBindingButtonRight"}) do
                        Entity:destroy(stuff[v])
                        stuff[v] = nil
                    end

                    for _,v in pairs({"buttonSONGS","buttonSETTINGS","buttonMERCH","buttonREPO","buttonQUIT","bumpingLogo","createdWithLOVEText"}) do
                        Entity:getObjectsByName(v)[1].Visible = true
                    end
                end

                stuff.backButton = backButton
            end
        },
        {
            text = "MERCH",
            colour = {r=0,g=1,b=0,a=1},
            pri = 3,
            callback = function() love.system.openURL("https://needlejuicerecords.com/pages/friday-night-funkin") end
        },
        {
            text = "REPO",
            colour = {r=0,g=1,b=1,a=1},
            pri = 4,
            callback = function() love.system.openURL("https://github.com/plexityyy/friday-night-lovin") end
        },
        {
            text = "QUIT",
            colour = {r=0,g=0,b=1,a=1},
            pri = 5,
            callback = function() love.event.quit() end
        }
    }

    local count = 0
    for _,info in pairs(options) do
        local button = Entity:create(Text,"button" .. info.text,info.text,menuVHSFont)
        button.Colour = info.colour
        button.Visible = false
        button.Limit = push:getWidth()*0.22
        button.Position = {
            x = ((push:getWidth()*0.2)*count) + push:getWidth()/90,
            y = stuff.bar.Position.y + stuff.bar.Size.h/2 - (menuVHSFont:getHeight(info.text)/2)
        }
        count = count + 1

        function button.MousePressed()
            pressedEvent(button)
        end

        function button.Event()
            info.callback()
        end

        stuff["button" .. info.text] = button
    end

    stuff.bumpinLogo = Entity:create(Actor,"bumpingLogo",love.graphics.newImage("assets/images/mainmenu/logoBumpin.png"),require("assets.images.mainmenu.logoBumpin"),require("assets.animations.mainmenu.logoBumpin"))
    stuff.bumpinLogo:playAnimation("idle")
    stuff.bumpinLogo.Scale = 1.25
    stuff.bumpinLogo.Position = {
        x = push:getWidth()/2,
        y = push:getHeight()/2
    }

    stuff.bumpinLogo.Visible = false

    stuff.MainMenuSoundInstance = stuff.MainMenuSound:createSource()
    state.mainmenuVolume = 0
    stuff.MainMenuSoundInstance:play()
    flux.to(state,8,{mainmenuVolume=1})

    stuff.IntroText = Entity:create(TextImage,"introText","PLEX")
    stuff.IntroText.Style = ENUM_TEXTIMAGE_STYLE_BOLD
    stuff.IntroText.Limit = push:getWidth()
    stuff.IntroText.Position = {x=0,y=push:getHeight()/2-36/2}

    local possibleQuotes = {
        {p="HOW DOES THE",q="FNF FONT SYSTEM WORK"},
        {p="CYBERZONE",q="COMING SOON"},
        {p="DANCIN",q="FOREVER"},
        {p="DOPE ASS GAME",q="PLAYSTATION MAGAZINE"},
        {p="FUNKIN",q="FOREVER"},
        {p="GAME OF THE YEAR",q="FOREVER"},
        {p="IN LOVING MEMORY OF",q="HENRYEYES"},
        {p="RISE AND GRIND",q="LOVE TO LUIS"},
        {p="LOVE TO THRIFTMAN",q="SWAG"},
        {p="LUDUM DARE",q="EXTRAORDINAIRE"},
        {p="RATE FIVE",q="PLS NO BLAM"},
        {p="LIKE PARAPPA",q="BUT COOLER"},
        {p="LIKE LAMMY",q="BUT COOLER"}, -- it's um jammer lammy you fucking idiots
        {p="SHOUT OUT TO",q="PESCI"},
        {p="RHYTHM GAMING",q="ULTIMATE"},
        {p="RITZ DX",q="REST IN PEACE LOL"},
        {p="SHOUTOUTS TO TOM FULP",q="LOL"},
        {p="ULTIMATE RHYTHM GAMING",q="PROBABLY"},
        {p="YOU ALREADY KNOW",q="WE REALLY OUT HERE"},
        {p="PARENTAL ADVISORY",q="EXPLICIT CONTENT"},
        {p="PICO SAYS",q="TRANS RIGHTS"}, -- 🏳️‍⚧️
    }
    local chosenQuote = love.math.random(1,#possibleQuotes)

    Input:bind("SkipIntro",{"KeyPressed"},function(key)
        if key ~= "return" then return end

        stuff.introClock.reps = 12
        stuff.introClock.dt = 9999
    end)

    stuff.introClock = Entity:create(Clock,"introClock",12,9.35/12,function(clock)
        -- 1 : "...PRESENTS"
        -- 2 : EMPTY
        -- 3 : "IN ASSOCIATION WITH..."
        -- 4 : "...NOBODY IN PARTICULAR"
        -- 5 : EMPTY
        -- 6 : QUOTE_PART1...
        -- 7 : ...QUOTE_PART2
        -- 8 : EMPTY
        -- 9 : "FRIDAY..."
        -- 10 : "...NIGHT..."
        -- 11 : "...LOVIN"
        -- 12 : show the main menu god damn it

        local timesToFunc = {
            [1] = function()
                stuff.IntroText2 = Entity:create(TextImage,"introText","PRESENTS")
                stuff.IntroText2.Style = ENUM_TEXTIMAGE_STYLE_BOLD
                stuff.IntroText2.Limit = push:getWidth()
                stuff.IntroText2.Position = {x=0,y=stuff.IntroText.Position.y+68}
            end,
            [2] = function()
                Entity:destroy(stuff.IntroText)
                Entity:destroy(stuff.IntroText2)
                stuff.IntroText = nil
                stuff.IntroText2 = nil
            end,
            [3] = function()
                stuff.associationText1 = Entity:create(TextImage,"associationText","IN ASSOCIATION WITH")
                stuff.associationText1.Style = ENUM_TEXTIMAGE_STYLE_BOLD
                stuff.associationText1.Limit = push:getWidth()
                stuff.associationText1.Position = {x=0,y=push:getHeight()/2-36/2}
            end,
            [4] = function()
                stuff.associationText2 = Entity:create(TextImage,"introText","NOBODY IN PARTICULAR")
                stuff.associationText2.Style = ENUM_TEXTIMAGE_STYLE_BOLD
                stuff.associationText2.Limit = push:getWidth()
                stuff.associationText2.Position = {x=0,y=stuff.associationText1.Position.y+68}
            end,
            [5] = function()
                Entity:destroy(stuff.associationText1)
                Entity:destroy(stuff.associationText2)
                stuff.associationText1 = nil
                stuff.associationText2 = nil
            end,
            [6] = function()
                stuff.quoteText1 = Entity:create(TextImage,"quoteText",possibleQuotes[chosenQuote].p)
                stuff.quoteText1.Style = ENUM_TEXTIMAGE_STYLE_BOLD
                stuff.quoteText1.Limit = push:getWidth()
                stuff.quoteText1.Position = {x=0,y=push:getHeight()/2-36/2}
            end,
            [7] = function()
                stuff.quoteText2 = Entity:create(TextImage,"quoteText",possibleQuotes[chosenQuote].q)
                stuff.quoteText2.Style = ENUM_TEXTIMAGE_STYLE_BOLD
                stuff.quoteText2.Limit = push:getWidth()
                stuff.quoteText2.Position = {x=0,y=stuff.quoteText1.Position.y+68}
            end,
            [8] = function()
                Entity:destroy(stuff.quoteText1)
                Entity:destroy(stuff.quoteText2)
                stuff.quoteText1 = nil
                stuff.quoteText2 = nil
            end,
            [9] = function()
                stuff.fridayText = Entity:create(TextImage,"lastWords","FRIDAY")
                stuff.fridayText.Style = ENUM_TEXTIMAGE_STYLE_BOLD
                stuff.fridayText.Limit = push:getWidth()
                stuff.fridayText.Position = {x=0,y=push:getHeight()/2-36/2}
            end,
            [10] = function()
                stuff.nightText = Entity:create(TextImage,"lastWords","NIGHT")
                stuff.nightText.Style = ENUM_TEXTIMAGE_STYLE_BOLD
                stuff.nightText.Limit = push:getWidth()
                stuff.nightText.Position = {x=0,y=stuff.fridayText.Position.y+68}
            end,
            [11] = function()
                stuff.lovinText = Entity:create(TextImage,"lastWords","LOVIN")
                stuff.lovinText.Style = ENUM_TEXTIMAGE_STYLE_BOLD
                stuff.lovinText.Limit = push:getWidth()
                stuff.lovinText.Position = {x=0,y=stuff.fridayText.Position.y+136}
            end
        }

        if not timesToFunc[clock.reps] then

            for _,v in pairs({"IntroText","IntroText2","associationText1","associationText2","quoteText1","quoteText2","fridayText","nightText","lovinText"}) do
                Entity:destroy(stuff[v])
                stuff[v] = nil
            end

            Input:unbind("SkipIntro")

            stuff.wallpaper.Visible = true
            stuff.bumpinLogo.Visible = true

            stuff.createdWithLOVEText = Entity:create(TextImage,"createdWithLOVEText","Created with LOVE")
            stuff.createdWithLOVEText.Style = ENUM_TEXTIMAGE_STYLE_REGULAR
            stuff.createdWithLOVEText.Position.y = stuff.bumpinLogo.Position.y + (45*6.5)

            for _,info in pairs(options) do
                stuff["button" .. info.text].Visible = true
            end

            stuff.flash = Entity:create(Box,"whiteFlash")
            stuff.flash.Size.w, stuff.flash.Size.h = push:getWidth(), push:getHeight()
            flux.to(stuff.flash.Colour,1,{a=0})
        
            Input:bind("Menu_MousePressed",{"MousePressed"},function(button)
                if button ~= 1 then return end
        
                for _,v in pairs(stuff) do
                    if v.MousePressed and v.Visible and v.__index == Text.__index then
                        if v.mouseEntered then
                            v.MousePressed()
                            break
                        end
                    end
                end
            end)

            Entity:create(Clock,"destroyFlash",1,1,function()
                Entity:destroy(stuff.flash)
                stuff.flash = nil
            end)

            return
        end

        timesToFunc[clock.reps]()
    end)

    if skipIntro then
        stuff.introClock.reps = 12
        stuff.introClock.dt = 9999
    end
end

function state:exit()
    for _,v in pairs(stuff) do
        Entity:destroy(v)
    end

    if Input:getBind("Menu_MousePressed") then
        Input:unbind("Menu_MousePressed")
    end

    stuff = {}
end

local somethingSelected = false
function state:update(dt)
    stuff.MainMenuSoundInstance:setVolume(state.mainmenuVolume)
    stuff.wallpaper.Position = {
        x = (push:getWidth()/2 - stuff.wallpaper.Size.w/2) * (Input.Mouse.x/push:getWidth())*0.3,
        y = (push:getHeight()/2 - stuff.wallpaper.Size.h/2) * (Input.Mouse.y/push:getHeight())*0.3
    }

    for _,v in pairs(stuff) do
        if v.MousePressed and v.Visible and v.__index == Text.__index then
            v.mouseEntered = checkCollision(v.Position.x,v.Position.y,v.Limit,v.Font:getHeight())
            if v.mouseEntered then
                if not somethingSelected then
                    if not v.alreadyIn and canTouchAnything then
                        v.alreadyIn = true
                        somethingSelected = true

                        if not v.DontDisplayBorders then
                            v.Text = "> " .. v.Text .. " <"
                        end

                        if v.ChangeColour or v.ChangeColour == nil then
                            flux.to(stuff.wallpaper.Colour,2,{r=math.max(128/255,v.Colour.r),g=math.max(128/255,v.Colour.g),b=math.max(128/255,v.Colour.b),a=v.Colour.a})
                        end

                        stuff.scrollSound:createSource():play()
                    end
                end
            else
                if v.alreadyIn then
                    v.Text = v.Text:gsub("> ",""):gsub(" <","")
                    v.alreadyIn = false
                    somethingSelected = false
                end
            end
        end
    end
end

function state:draw()
  
end

return state