--[[

TODO (after game.lua is done):
    1. Add settings menu
    2. Make it so that the player can actually choose a song

]]

local state = {}
local stuff = {}

local canTouchAnything = true

local function checkCollision(x,y,w,h)
    return x < Input.Mouse.x and Input.Mouse.x < x+w and y < Input.Mouse.y and Input.Mouse.y < y+h
end

function state:enter()
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

    local menuVHSFont = love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.05)
    local options = {
        {
            text = "SONGS",
            colour = {r=1,g=0,b=0,a=1},
            pri = 1,
            callback = function()
                States:switchState("game","blammed","hard")

                --[[local playlists = {}

                for _,folder in pairs(love.filesystem.getDirectoryItems("songs/")) do
                    local s,e = pcall(function()
                        error("will add later")
                    end)

                    if not s then
                        print(string.format("Error when trying to load \"%s\"!\n%s",folder,e))
                    else
                        table.insert(playlists,folder)
                    end
                end

                if #playlists == 0 then
                    local txt = [[You have no songs installed!!
Please put new playlists into %s/songs.]]
                    --[[local os = love.system.getOS()
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
                end

                for _,v in pairs({"buttonSONGS","buttonSETTINGS","buttonMERCH","buttonREPO","buttonQUIT","bumpingLogo","createdWithLOVEText"}) do
                    Entity:getObjectsByName(v)[1].Visible = false
                end

                local backButton = Entity:create(Text,"buttonBack","BACK",menuVHSFont)
                backButton.Colour = {r=1,g=0,b=0,a=1}
                backButton.Limit = push:getWidth()*0.15
                backButton.Position = {x=push:getWidth()/2-menuVHSFont:getWidth("BACK"),y=stuff.bar.Position.y + stuff.bar.Size.h/2 - (menuVHSFont:getHeight("BACK")/2)}

                function backButton.MousePressed()
                    pressedEvent(backButton)
                end

                function backButton.Event()
                    Entity:destroy("buttonBack")
                    stuff.backButton = nil

                    Entity:destroy("headsUp")
                    stuff.headsUp = nil

                    for _,v in pairs({"buttonSONGS","buttonSETTINGS","buttonMERCH","buttonREPO","buttonQUIT","bumpingLogo","createdWithLOVEText"}) do
                        Entity:getObjectsByName(v)[1].Visible = true
                    end
                end

                stuff.backButton = backButton]]
            end
        },
        {
            text = "SETTINGS",
            colour = {r=1,g=1,b=0,a=1},
            pri = 2,
            callback = function() -- to be finished later
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

                function backButton.MousePressed()
                    pressedEvent(backButton)
                end

                function backButton.Event()
                    Entity:destroy("buttonBack")
                    Entity:destroy("settingsBAR")
                    stuff.backButton = nil
                    stuff.settingsBAR = nil

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
            callback = function()
                love.system.openURL("https://needlejuicerecords.com/pages/friday-night-funkin")
            end
        },
        {
            text = "REPO",
            colour = {r=0,g=1,b=1,a=1},
            pri = 4,
            callback = function()
                love.system.openURL("https://gitea.com/plex/friday-night-lovin")
            end
        },
        {
            text = "QUIT",
            colour = {r=0,g=0,b=1,a=1},
            pri = 5,
            callback = function()
                love.event.quit()
            end
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
end

function state:exit()
    for _,v in pairs(stuff) do
        Entity:destroy(v)
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

                        v.ogText = v.Text
                        v.Text = "> " .. v.ogText .. " <"
                        flux.to(stuff.wallpaper.Colour,2,{r=math.max(128/255,v.Colour.r),g=math.max(128/255,v.Colour.g),b=math.max(128/255,v.Colour.b),a=v.Colour.a})

                        stuff.scrollSound:createSource():play()
                    end
                end
            else
                if v.alreadyIn then
                    v.Text = v.ogText
                    v.ogText = nil
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