-- 1,000+ LINES HOLLY MOLLY!!
-- hold notes still look like shit might i add (especially the longer ones)

local state = {}
local stuff = {}
local songData = {}
local ui = {}

local function getObjectByTag(tag)
   for _,obj in pairs(stuff) do
      if obj.Tag and obj.Tag == tag then
         return obj
      end
   end
end

local function playerMiss(dir)
   local cln = songData.sounds["missNote" .. tostring(love.math.random(1,3))]:createSource()
   cln:setVolume(0.35)
   cln:play()

   if songData.music.plyVocals then
      songData.music.plyVocals.PlayingSources[1]:setVolume(0)
   else
      songData.music.vocals.PlayingSources[1]:setVolume(0)
   end
   songData.health = songData.health - 5
   songData.points = songData.points - 10
   songData.maxPoints = songData.maxPoints + 450

   if songData.streak >= 10 then
      getObjectByTag("gf"):playAnimation("sad")
   end
   songData.streak = 0

   local actor = getObjectByTag("player")
   local chosenAnim = nil
   for _,dir in pairs({"left","down","up","right"}) do
      actor:stopAnimation(dir)
      actor:stopAnimation(dir .. "_miss")
   end
   actor:playAnimation(dir .. "_miss")
   return chosenAnim
end

local function calculateAccuracy()
   local acc = "???"
   local rank = "?"
   if songData.maxPoints ~= 0 then
      local percentage = (songData.points/songData.maxPoints)*100

      if percentage == 100 then
         rank = "S+"
      elseif percentage >= 99 then
         rank = "S"
      elseif percentage >= 90 then
         rank = "A"
      elseif percentage >= 80 then
         rank = "B"
      elseif percentage >= 70 then
         rank = "C"
      elseif percentage >= 60 then
         rank = "D"
      else
         rank = "F"
      end

      acc = string.format("%.1f",percentage)
   end

   ui[6].Text = "Score: " .. tostring(songData.points) .. " | Accuracy: " .. acc .. "% (" .. rank .. ")"
end

local eventToFunction = {
   ["FocusCamera"] = function(data)
      local newCamPosX, newCamPosY
      if data.singer == "player" then
         newCamPosX = songData.cameraInfo.playerFocusPos.x
         newCamPosY = songData.cameraInfo.playerFocusPos.y
      elseif data.singer == "opponent" then
         newCamPosX = songData.cameraInfo.opponentFocusPos.x
         newCamPosY = songData.cameraInfo.opponentFocusPos.y
      elseif data.singer == "both" then
         newCamPosX = songData.cameraInfo.defaultPos.x
         newCamPosY = songData.cameraInfo.defaultPos.y
      end

      flux.to(Entity.camera.Position,1,{x = newCamPosX, y = newCamPosY}):ease("quadout")
   end,
   ["ChangeBPM"] = function(data)
      stuff.bumpinClock.delay = 60/data.bpm
      stuff.bumpinIcons.delay = 120/data.bpm
      stuff.bumpinClock.dt,stuff.bumpinIcons.dt = 0,0
   end
}

local safeKeeping = {}
local paused = false
local currentSettings
function state:enter(song,difficulty)
   assert(love.filesystem.getDirectoryItems("songs/" .. song),string.format("An error occured with the game.lua scene! (Couldn't find \"%s\" song!)",song))

   print(string.format("Loading \"%s\" (%s)...",song,difficulty))

   currentSettings = settings:getSettings()
   local metaData = JSON.decode(love.filesystem.read("songs/" .. song .. "/metadata.json"))

   safeKeeping = {
      name = song,
      diff = difficulty
   }
   songData = {
      music = {
         instrumental = Entity:create(Sound,"instrumentalMusic",love.filesystem.read("songs/" .. song .. "/Inst.ogg"),ENUM_SOUND_STREAM,true)
      },
      sounds = {
         missNote1 = Entity:create(Sound,"missNote1","assets/sounds/missnote1.ogg",ENUM_SOUND_MEMORY),
         missNote2 = Entity:create(Sound,"missNote1","assets/sounds/missnote2.ogg",ENUM_SOUND_MEMORY),
         missNote3 = Entity:create(Sound,"missNote1","assets/sounds/missnote3.ogg",ENUM_SOUND_MEMORY),
      },
      notes = {},
      scripts = {},
      events = {},
      icons = {
         player = {
            iconSheet = nil,
            fineQuad = nil,
            alertQuad = nil,
            colour = {r=0,g=1,b=0}
         },
         opponent = {
            iconSheet = nil,
            fineQuad = nil,
            alertQuad = nil,
            colour = {r=1,g=0,b=0}
         }
      },
      cameraInfo = {
         playerFocusPos = {
            x = 0,
            y = 0
         },
         opponentFocusPos = {
            x = 0,
            y = 0
         },
         defaultPos = {
            x = 0,
            y = 0
         }
      },
      speed = 0,
      health = 50,
      points = 0,
      streak = 0,
      maxPoints = 0,
      songTimer = 0,
      started = false,
      hitSound = Entity:create(Sound,"noteHisSound","assets/sounds/hit.ogg",ENUM_SOUND_MEMORY)
   }
   songData.hitSound.Source:setVolume(currentSettings.hitVolume)
   songData.music.instrumental.Source:setLooping(true)

   if love.filesystem.getInfo("songs/" .. song .. "/PlayerVocals.ogg") and love.filesystem.getInfo("songs/" .. song .. "/EnemyVocals.ogg") then
      songData.music.plyVocals = Entity:create(Sound,"plyVocalsMusic",love.filesystem.read("songs/" .. song .. "/PlayerVocals.ogg"),ENUM_SOUND_STREAM,true)
      songData.music.plyVocals.Source:setLooping(true)
      songData.music.enemyVocals = Entity:create(Sound,"enemyVocalsMusic",love.filesystem.read("songs/" .. song .. "/EnemyVocals.ogg"),ENUM_SOUND_STREAM,true)
      songData.music.enemyVocals.Source:setLooping(true)
   elseif love.filesystem.getInfo("songs/" .. song .. "/Vocals.ogg") then
      songData.music.vocals = Entity:create(Sound,"vocalsMusic",love.filesystem.read("songs/" .. song .. "/Vocals.ogg"),ENUM_SOUND_STREAM,true)
      songData.music.vocals.Source:setLooping(true)
   else
      error(string.format("Error when trying to load \"%s\"! (Song has no vocal files, or at least not one that's valid.)",song))
   end

   local stageData = {}

   do -- priority variable doesn't seem to work w/o this
      local dataTemp = JSON.decode(love.filesystem.read("stages/" .. metaData.stage .. ".json"))
      for name,data in pairs(dataTemp) do
         data.name = name
         table.insert(stageData,data)
      end
   end

   table.sort(stageData,function(a,b)
      local pr1 = a.priority or 0
      local pr2 = b.priority or 0
      return pr1 < pr2
   end)

   -- setting up stage
   for _,data in pairs(stageData) do
      if data.class == "actor" then
         local actorFolder = "customassets/actors/" .. data.agent .. "/"

         local animationsSheet = JSON.decode(love.filesystem.read(actorFolder .. "animations.json"))
         local framesSheet = JSON.decode(love.filesystem.read(actorFolder .. "frames.json"))
         local spritesSheet = love.graphics.newImage(
            love.filesystem.newFileData(
               love.filesystem.read(actorFolder .. "sprites.png"),
               "actorSheetsFile"
            )
         )

         stuff[data.name] = Entity:create(Actor,data.name,spritesSheet,framesSheet,animationsSheet)
         if data.flipped then
            stuff[data.name].Flipped = true
         end
         if data.tag then
            stuff[data.name].Tag = data.tag

            if data.tag == "player" or data.tag == "opponent" then
               local target = songData.icons[data.tag]
               local iconData = JSON.decode(love.filesystem.read(actorFolder .. "metadata.json"))

               local iconSheet = love.graphics.newImage(
                  love.filesystem.newFileData(
                     love.filesystem.read("customassets/images/" .. iconData.icon),
                     "healthIcon"
                  )
               )

               target.iconSheet = iconSheet
               target.fineQuad = love.graphics.newQuad(0,0,iconSheet:getWidth()/2,iconSheet:getHeight(),iconSheet:getWidth(),iconSheet:getHeight())
               target.alertQuad = love.graphics.newQuad(iconSheet:getWidth()/2,0,iconSheet:getWidth()/2,iconSheet:getHeight(),iconSheet:getWidth(),iconSheet:getHeight())
               target.colour = {
                  r = iconData.colour.r/255,
                  g = iconData.colour.g/255,
                  b = iconData.colour.b/255
               }
            elseif data.tag == "gf" then
               local calcSpeed = 14.4 / (60/metaData.bpm)
               stuff[data.name]:getAnimation("idle").speed = calcSpeed
               stuff[data.name]:getAnimation("hairblowing").speed = calcSpeed
               stuff[data.name]:playAnimation("idle")
            end
         end
         if data.scale then
            stuff[data.name].Scale = data.scale
         end

         stuff[data.name].Position.x = data.x
         stuff[data.name].Position.y = data.y
      elseif data.class == "image" then
         local textureImage = love.graphics.newImage(
            love.filesystem.newFileData(
               love.filesystem.read("customassets/images/" .. data.texture),
               "imageTextureFile"
            )
         )

         stuff[data.name] = Entity:create(Image,data.name,textureImage)
         stuff[data.name].Position.x = data.x
         stuff[data.name].Position.y = data.y
         if data.fitType == "fit" then
            stuff[data.name].FitType = ENUM_IMAGE_FITTYPE_FIT
         else
            stuff[data.name].FitType = ENUM_IMAGE_FITTYPE_STRETCH
         end

         stuff[data.name].Size.w = data.w
         stuff[data.name].Size.h = data.h
      elseif data.class == "camera" then
         songData.cameraInfo.playerFocusPos.x = data.playerPosition.x
         songData.cameraInfo.playerFocusPos.y = data.playerPosition.y

         songData.cameraInfo.opponentFocusPos.x = data.opponentPosition.x
         songData.cameraInfo.opponentFocusPos.y = data.opponentPosition.y

         songData.cameraInfo.defaultPos.x = data.defaultPosition.x
         songData.cameraInfo.defaultPos.y = data.defaultPosition.y
         Entity.camera.Position.x = data.defaultPosition.x
         Entity.camera.Position.y = data.defaultPosition.y
      end
   end

   -- run song script, if there is one.
   local problems = 0
   if love.filesystem.getInfo("songs/" .. song .. "/script.lua") then
      print("Running song script (" .. song .. ".lua)...")
      local s,e = pcall(function ()
         songData.scripts.songScript = love.filesystem.load("songs/" .. song .. "/script.lua")()
      end)

      if s then
         print("Ran song script with no errors.")
      else
         print("A problem occured while running the song script!\n\t" .. e)
         problems = problems + 1
      end
   end

   -- run stage script, if there is one.
   if love.filesystem.getInfo("stages/" .. metaData.stage .. ".lua") then
      print("Running stage script (" .. metaData.stage .. ".lua)...")
      local s,e = pcall(function ()
         songData.scripts.songScript = love.filesystem.load("stages/" .. metaData.stage .. ".lua")()
      end)

      if s then
         print("Ran stage script with no errors.")
      else
         print("A problem occured while running the stage script!\n\t" .. e)
         problems = problems + 1
      end
   end

   for _,script in pairs(songData.scripts) do
      local s,e = pcall(function()
         if script and script.load then
            script:load(metaData)
         end
      end)

      if not s then
         print("An error occured while trying to run a script's :load() method.\n\t" .. e)
         problems = problems + 1
      end
   end

   if problems == 0 then
      print("Loaded song with no errors.")
   else
      print("Loaded song with " .. tostring(problems) .. " errors. Please check and fix them as soon as you can.")
   end

   -- loading up UI
   local healthBar_Background = Box:new()
   healthBar_Background.Size = {w=push:getWidth()*0.75,h=push:getHeight()*0.02}
   healthBar_Background.Position.x = push:getWidth()/2-healthBar_Background.Size.w/2
   if not currentSettings.downScroll then
      healthBar_Background.Position.y = push:getHeight() - (push:getHeight()*0.09)
   else
      healthBar_Background.Position.y = push:getHeight()*0.09
   end
   healthBar_Background.Colour = {
      r = songData.icons.opponent.colour.r,
      g = songData.icons.opponent.colour.g,
      b = songData.icons.opponent.colour.b,
      a = 1
   }

   local healthBar_HealthBar = Box:new()
   healthBar_HealthBar.Size = {
      w = healthBar_Background.Size.w * (songData.health/100),
      h = healthBar_Background.Size.h
   }
   healthBar_HealthBar.Position = {
      x = healthBar_Background.Position.x + healthBar_Background.Size.w - (healthBar_Background.Size.w * (songData.health/100)),
      y = healthBar_Background.Position.y
   }
   healthBar_HealthBar.Colour = {
      r = songData.icons.player.colour.r,
      g = songData.icons.player.colour.g,
      b = songData.icons.player.colour.b,
      a = 1
   }

   local healthBar_playerIcon = DumbImage:new(songData.icons.player.iconSheet,songData.icons.player.fineQuad)
   healthBar_playerIcon.ScaleX = -1.3
   healthBar_playerIcon.ScaleY = 1.3
   healthBar_playerIcon.Position = {
      x=healthBar_HealthBar.Position.x+(healthBar_playerIcon.Image:getWidth()*0.6),
      y=healthBar_HealthBar.Position.y-(healthBar_playerIcon.Image:getHeight()/2)
   }

   local healthBar_opponentIcon = DumbImage:new(songData.icons.opponent.iconSheet,songData.icons.opponent.fineQuad)
   healthBar_opponentIcon.ScaleX = 1.3
   healthBar_opponentIcon.ScaleY = 1.3
   healthBar_opponentIcon.Position = {
      x=healthBar_HealthBar.Position.x-(healthBar_playerIcon.Image:getWidth()*0.6),
      y=healthBar_HealthBar.Position.y-(healthBar_opponentIcon.Image:getHeight()/2)
   }

   local healthBar_BackgroundBorders = Box:new()
   healthBar_BackgroundBorders.Size = {w=healthBar_Background.Size.w,h=healthBar_Background.Size.h}
   healthBar_BackgroundBorders.Position = {x=healthBar_Background.Position.x,y=healthBar_Background.Position.y}
   healthBar_BackgroundBorders.Colour = {r=0,g=0,b=0,a=1}
   healthBar_BackgroundBorders.FillMode = ENUM_BOX_FILLMODE_LINE
   healthBar_BackgroundBorders.LineThickness = 12

   local healthBar_infoText = Text:new("Score: 0 | Accuracy: ???% (?)",love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.03))
   healthBar_infoText.Position.x = healthBar_Background.Position.x

   if not currentSettings.downScroll then
      healthBar_infoText.Position.y = healthBar_Background.Position.y-healthBar_Background.Size.h-healthBar_BackgroundBorders.LineThickness-15
   else
      healthBar_infoText.Position.y = healthBar_Background.Position.y+healthBar_Background.Size.h+healthBar_BackgroundBorders.LineThickness+3
   end

   healthBar_infoText.Limit = healthBar_Background.Size.w
   healthBar_infoText.Align = "right"

   ui[1] = healthBar_BackgroundBorders
   ui[2] = healthBar_Background
   ui[3] = healthBar_HealthBar
   ui[4] = healthBar_playerIcon
   ui[5] = healthBar_opponentIcon
   ui[6] = healthBar_infoText
   ui[7] = {} -- note receptors
   ui[8] = {} -- actual notes

   -- setting up note receptors
   local NOTES_image = love.graphics.newImage("assets/images/NOTE_assets.png")
   local NOTES_frames = require("assets.animations.NOTE_assets_frames")
   for i = 1,2 do
      for k,v in pairs({"left","down","up","right"}) do
         local noteActor = Actor:new(NOTES_image,NOTES_frames,require("assets.animations.notes." .. v .. "Receptor"))

         local xPosition = 225 + (150*(k-1))
         local startingPos = 4

         if currentSettings.middleScroll then
            if i == 1 then
               startingPos = 0
               xPosition = xPosition + (push:getWidth()/3.9)
            else
               xPosition = xPosition + push:getWidth()*500 -- put it off-screen or whatever
            end
         else
            if i == 1 then
               startingPos = 0
               xPosition = xPosition + (push:getWidth()/2)
            else
               noteActor:getAnimation("pressed").loopback = false
               noteActor:getAnimation("pressed_confirm").loopback = false
            end
         end

         local yPos = push:getHeight() - 15 - 158
         if not currentSettings.downScroll then
            yPos = 15 + 158
         end

         noteActor.Position = {
            x = xPosition,
            y = yPos
         }

         noteActor:playAnimation("idle")
         ui[7][k+startingPos] = noteActor
      end
   end

   stuff.bumpinClock = Entity:create(Clock,"bumpin",-1,60/metaData.bpm,function(clock)
      for _,v in pairs({"player","opponent"}) do
         local actor = getObjectByTag(v)

         if not actor:getAnimation("idle").playing then
            actor:playAnimation("idle")
         end
      end

      if (clock.reps % 2 == 0) then
         local zoomAmount = 1.015
         local screenCenterX = push:getWidth() / 2
         local screenCenterY = push:getHeight() / 2

         local ogScale = Entity.camera.Scale
         local ogPos = {
            x = Entity.camera.Position.x,
            y = Entity.camera.Position.y
         }

         local camOffsetX = (screenCenterX - Entity.camera.Position.x) * (zoomAmount-1)
         local camOffsetY = (screenCenterY - Entity.camera.Position.y) * (zoomAmount-1)

         Entity.camera.Scale = zoomAmount
         Entity.camera.OffsetPosition = {
            x = camOffsetX*1.75,
            y = -camOffsetY
         }

         flux.to(Entity.camera, clock.delay, { Scale = ogScale }):ease("quadout")
         flux.to(Entity.camera.OffsetPosition, clock.delay, {
            x = 0,
            y = 0
         }):ease("quadout")
      end
   end)

   stuff.bumpinIcons = Entity:create(Clock,"bumpinIcons",-1,120/metaData.bpm,function()
      healthBar_playerIcon.ScaleX = -1.4
      healthBar_playerIcon.ScaleY = 1.4
      flux.to(healthBar_playerIcon,60/metaData.bpm,{ScaleX = -1.3,ScaleY=1.3})

      healthBar_opponentIcon.ScaleX = 1.4
      healthBar_opponentIcon.ScaleY = 1.4
      flux.to(healthBar_opponentIcon,60/metaData.bpm,{ScaleX = 1.3,ScaleY=1.3})
   end)

   -- load events
   local chartData = JSON.decode(love.filesystem.read("songs/" .. song .. "/chart.json"))
   songData.speed = chartData.scrollSpeed[difficulty]*1000

   for _,event in pairs(chartData.events) do
      table.insert(songData.events,{
         class = event.class,
         tick = event.tick,
         params = event.params
      })
   end

   local numberDirToStringDir = {
      [0] = {
         s = "player",
         d = "left"
      },
      [1] = {
         s = "player",
         d = "down"
      },
      [2] = {
         s = "player",
         d = "up"
      },
      [3] = {
         s = "player",
         d = "right"
      },
      [4] = {
         s = "opponent",
         d = "left"
      },
      [5] = {
         s = "opponent",
         d = "down"
      },
      [6] = {
         s = "opponent",
         d = "up"
      },
      [7] = {
         s = "opponent",
         d = "right"
      }
   }

   -- loading up note assets
   local notesFile = require("assets.animations.notes.notes")
   local noteQuads = {}

   for i,v in pairs(notesFile) do
      noteQuads[i] = love.graphics.newQuad(
         v.x,
         v.y,
         v.w,
         v.h,
         NOTES_image:getWidth(),
         NOTES_image:getHeight()
      )
   end

   -- loading up the chart
   for i,note in pairs(chartData.notes[difficulty]) do
      local n = {
         tick = note.t/1000,
         dir = numberDirToStringDir[tonumber(note.d)].d,
         singer = numberDirToStringDir[tonumber(note.d)].s,
         length = 0,
         noteImg = {
            img = nil,
            bodyImg = nil,
            tailImg = nil,
            receptor = nil,
            index = i
         }
      }
      if note.l then
         n.length = note.l/1000
      end

      local noteImage = DumbImage:new(NOTES_image,noteQuads[n.dir .. "Note"])
      noteImage.Visible = false
      n.noteImg.receptor = ui[7][note.d+1]

      noteImage.Position = {
         x = n.noteImg.receptor.Position.x-77,
         y = -1500 -- :update(dt) will handle note positioning
      }

      n.noteImg.img = noteImage

      if n.length > 0 then
         local bodyImage = Image:new(NOTES_image,noteQuads[n.dir .. "NoteHoldBody"])
         bodyImage.Size.w = 51
         local tailImage = DumbImage:new(NOTES_image,noteQuads[n.dir .. "NoteHoldTail"])
         bodyImage.Size = {
            w = bodyImage.Image:getWidth(),
            h = bodyImage.Image:getHeight()
         }

         bodyImage.Position,tailImage.Position = {
            x = noteImage.Position.x,
            y = -1500
         },{
            x = noteImage.Position.x,
            y = -1500
         }
         bodyImage.Visible, tailImage.Visible = false, false

         if not currentSettings.downScroll then
            tailImage.ScaleY = -1
         end

         n.noteImg.bodyImg = bodyImage
         n.noteImg.tailImg = tailImage
         ui[8]["noteBody" .. tostring(i)] = n.noteImg.bodyImg
         ui[8]["noteTail" .. tostring(i)] = n.noteImg.tailImg
      end
      ui[8]["note" .. tostring(i)] = n.noteImg.img -- actual note goes above hold assets

      table.insert(songData.notes,n)
   end

   -- streak assets
   local streakAssets = {
      ranks = {
         shit = love.graphics.newImage("assets/images/popup/shit.png"),
         bad = love.graphics.newImage("assets/images/popup/bad.png"),
         good = love.graphics.newImage("assets/images/popup/good.png"),
         sick = love.graphics.newImage("assets/images/popup/sick.png"),
      },
      numbers = {},
      instances = 0
   }
   for i = 1,10 do
      streakAssets.numbers[i-1] = love.graphics.newImage("assets/images/popup/num" .. tostring(i-1) .. ".png")
   end

   -- bind key actions
   Input:bind("GameInputPressed",{"KeyPressed"},function(key)
      if key == 'escape' or key == 'return' then
         paused = not paused

         if paused then
            local music = Entity:create(Sound,"pauseMenuMusic","assets/music/breakfast.ogg",ENUM_SOUND_STREAM)
            music.Source:setLooping(true)
            music:createSource():play()

            local backgroundBox = Box:new()
            backgroundBox.Size = {w = push:getWidth(), h = push:getHeight()}
            backgroundBox.Colour = {r=0,g=0,b=0,a=0.5}

            local summaryText = Text:new(string.upper(metaData.songName) .. " (" .. string.upper(difficulty) .. ")", love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.1))
            summaryText.Position.x = 150
            summaryText.Limit = push:getWidth()
            summaryText.Align = "right"
            flux.to(summaryText.Position,2,{x=0}):ease("quadout")

            local controlsText = Text:new("Escape/Return -> Resume song\nR -> Restart song\nQ -> Return to main menu", love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.05))
            controlsText.Limit = push:getWidth()
            controlsText.Position.y = push:getHeight()/2 - controlsText.Font:getHeight(controlsText.Text)/2

            ui[9] = backgroundBox
            ui[10] = summaryText
            ui[11] = controlsText

            Input:bind("PauseMenuPressed",{"KeyPressed"},function(key)
               if key == "r" then
                  Entity:destroy("pauseMenuMusic")
                  States:switchState("game",song,difficulty)
               elseif key == "q" then
                  Entity:destroy("pauseMenuMusic")
                  States:switchState("menu",true)
               end
            end)

            for _,v in pairs(Entity.instances) do
               if v.Paused ~= nil then
                  v.Paused = true
               end
            end

            if #songData.music.instrumental.PlayingSources > 0 then
               songData.music.instrumental.PlayingSources[1]:pause()
               if songData.music.vocals then
                  songData.music.vocals.PlayingSources[1]:pause()
               else
                  songData.music.plyVocals.PlayingSources[1]:pause()
                  songData.music.enemyVocals.PlayingSources[1]:pause()
               end
            end
         else
            Entity:destroy("pauseMenuMusic")
            Input:unbind("PauseMenuPressed")

            for i = 9,11 do
               ui[i] = nil
            end

            for _,v in pairs(Entity.instances) do
               if v.Paused ~= nil then
                  v.Paused = false
               end
            end

            if #songData.music.instrumental.PlayingSources > 0 then
               songData.music.instrumental.PlayingSources[1]:play()
               if songData.music.vocals then
                  songData.music.vocals.PlayingSources[1]:play()
               else
                  songData.music.plyVocals.PlayingSources[1]:play()
                  songData.music.enemyVocals.PlayingSources[1]:play()
               end
            end
         end

         return
      elseif key == 'r' then
         songData.health = 0
         return
      end
      if paused then return end

      local direction = nil

      for d,action in pairs(currentSettings.keybinds) do
         if action == key then
            direction = d
            break
         end
      end

      if not direction then return end

      local noteConfirmed = nil
      local songPosition = 0
      if songData.music.instrumental.PlayingSources[1] then
         songPosition = songData.music.instrumental.PlayingSources[1]:tell()
      end
      for i,note in pairs(songData.notes) do
         if note.singer == "player" and note.dir == direction then
            local difference = math.abs(songPosition-note.tick)
            if difference < 0.15 then
               noteConfirmed = note
               songData.hitSound:createSource():play()
               if songData.music.plyVocals then
                  songData.music.plyVocals.PlayingSources[1]:setVolume(1)
               else
                  songData.music.vocals.PlayingSources[1]:setVolume(1)
               end
               songData.health = math.min(100,songData.health + 5)
               songData.streak = songData.streak + 1

               local ranking = "shit" -- default rank
               if difference <= 0.03 then
                  ranking = "sick"
                  songData.points = songData.points + 450
               elseif difference <= 0.06 then
                  ranking = "good"
                  songData.points = songData.points + 200
               elseif difference <= 0.1 then
                  ranking = "bad"
                  songData.points = songData.points + 100
               else
                  songData.points = songData.points + 50
               end
               songData.maxPoints = songData.maxPoints + 450
               calculateAccuracy()

               -- spawn rank & streak view
               local gf = getObjectByTag("gf")
               streakAssets.instances = streakAssets.instances + 1
               local rankImagePopup = Entity:create(DumbImage,"streakPopup_Rank",streakAssets.ranks[ranking])
               rankImagePopup.Position = {
                  x = gf.Position.x + rankImagePopup.Image:getWidth()/2 - 350,
                  y = gf.Position.y + 45
               }
               rankImagePopup.ScaleX,rankImagePopup.ScaleY = 1.08,1.08

               flux.to(rankImagePopup.Position,1.2,{
                  x = rankImagePopup.Position.x + 30,
                  y = rankImagePopup.Position.y - (45*2)
               }):ease("backout")
               flux.to(rankImagePopup.Colour,0.5,{
                  a = 0
               }):delay(0.7)

               local rankNumberPopups = {}
               local streakStr = tostring(songData.streak)
               local c = 0
               for i = #streakStr,1,-1 do
                  local num = tonumber(string.sub(streakStr,i,i))
                  local rankNumberPopup = Entity:create(Image,"streakPopup_Number",streakAssets.numbers[num])
                  rankNumberPopup.Size = {
                     w=streakAssets.numbers[num]:getWidth(),
                     h=streakAssets.numbers[num]:getHeight()
                  }
                  rankNumberPopup.Position = {
                     x = rankImagePopup.Position.x + rankImagePopup.Image:getWidth()/2 - (rankNumberPopup.Size.w*c/1.2),
                     y = rankImagePopup.Position.y + rankImagePopup.Image:getHeight()
                  }

                  flux.to(rankNumberPopup.Position,1.2,{
                     x = rankNumberPopup.Position.x + 30 + love.math.random(5,15),
                     y = rankNumberPopup.Position.y - 60
                  }):ease("backout")
                  flux.to(rankNumberPopup.Colour,0.5,{
                     a = 0
                  }):delay(0.7)
                  c = c + 1
               end

               stuff["streakPopup_Rank" .. tostring(streakAssets.instances)] = rankImagePopup
               stuff["streakPopup_Clock" .. tostring(streakAssets.instances)] = Entity:create(Clock,"streakPopup_Clock",1,2.5,function()
                  Entity:destroy(rankImagePopup)
                  for _,v in pairs(rankNumberPopups) do Entity:destroy(v) end

                  stuff["streakPopup_Rank" .. tostring(streakAssets.instances)] = nil
                  stuff["streakPopup_Clock" .. tostring(streakAssets.instances)] = nil
               end)

               -- player animation
               local actor = getObjectByTag("player")
               for _,v in pairs({"left","down","up","right"}) do
                  actor:stopAnimation(v)
                  actor:stopAnimation(v .. "_miss")
               end
               actor:playAnimation(direction)

               -- destroy note
               ui[8]["note" .. tostring(note.noteImg.index)] = nil

               if note.length > 0 then
                  note.beingHit = true
               else
                  table.remove(songData.notes,i)
               end
               break
            end
         end
      end

      local dirToReceptorNumber = {
         ["left"] = 1,
         ["down"] = 2,
         ["up"] = 3,
         ["right"] = 4
      }
      local receptor = ui[7][dirToReceptorNumber[direction]]

      receptor:getAnimation("pressed_confirm").loopback = (noteConfirmed and noteConfirmed.length > 0)
      if noteConfirmed then
         receptor:playAnimation("pressed_confirm")
      else
         receptor:playAnimation("pressed")
         local cln = songData.sounds["missNote" .. tostring(love.math.random(1,3))]:createSource()
         cln:setVolume(0.35)
         cln:play()

         songData.points = songData.points - 10
         songData.health = math.max(0,songData.health - 5)
         calculateAccuracy()
         local actor = getObjectByTag("player")
         for _,v in pairs({"left","down","up","right"}) do
            if v == direction then
               actor:playAnimation(v .. "_miss")
            else
               actor:stopAnimation(v)
               actor:stopAnimation(v .. "_miss")
            end
         end
      end
   end)
   Input:bind("GameInputReleased",{"KeyReleased"},function(key)
      if paused then return end
      local direction = nil

      for d,action in pairs(currentSettings.keybinds) do
         if action == key then
            direction = d
            break
         end
      end

      if not direction then return end

      for i,note in pairs(songData.notes) do
         if note.singer == "player" and note.length > 0 and note.beingHit and note.dir == direction then
            local difference = math.abs(songData.music.instrumental.PlayingSources[1]:tell()-note.tick-note.length)
            if difference > 0.15 then
               playerMiss(note.dir)
               calculateAccuracy()
            end

            ui[8]["noteBody" .. tostring(note.noteImg.index)] = nil
            ui[8]["noteTail" .. tostring(note.noteImg.index)] = nil
            table.remove(songData.notes,i)
         end
      end

      local dirToReceptorNumber = {
         ["left"] = 1,
         ["down"] = 2,
         ["up"] = 3,
         ["right"] = 4
      }
      local receptor = ui[7][dirToReceptorNumber[direction]]
      receptor:stopAnimation("pressed")
      receptor:stopAnimation("pressed_confirm")
   end)

   local countDownSounds = {
      [1] = love.audio.newSource("assets/sounds/countdown/introTHREE.ogg","static"),
      [2] = love.audio.newSource("assets/sounds/countdown/introTWO.ogg","static"),
      [3] = love.audio.newSource("assets/sounds/countdown/introONE.ogg","static"),
      [4] = love.audio.newSource("assets/sounds/countdown/introGO.ogg","static"),
   }
   local countDownImages = {
      [2] = love.graphics.newImage("assets/images/countdown/ready.png"),
      [3] = love.graphics.newImage("assets/images/countdown/set.png"),
      [4] = love.graphics.newImage("assets/images/countdown/go.png"),
   }
   stuff.Countdown = Entity:create(Clock,"Countdown",5,60/metaData.bpm,function(clock)
      if countDownSounds[clock.reps] then
         countDownSounds[clock.reps]:play()
      end
      if countDownImages[clock.reps] then
         local img = Image:new(countDownImages[clock.reps])
         img.FitType = ENUM_IMAGE_FITTYPE_FIT
         img.Size = {w=push:getWidth()*0.75,h=push:getHeight()*0.75}
         img.Position = {x=0,y=0}

         flux.to(img.Colour,clock.delay,{a=0})

         Entity:create(Clock,"destroyCountdownImage",1,clock.delay,function()
            ui[12] = nil
         end)

         ui[12] = img
      end

      if clock.reps == 5 then
         songData.music.instrumental:createSource():play()
         if songData.music.vocals then
            songData.music.vocals:createSource():play()
         else
            songData.music.plyVocals:createSource():play()
            songData.music.enemyVocals:createSource():play()
         end

         songData.started = true
         stuff.Countdown = nil
      end
   end)

   songData.health = 50 -- need this when the player restarts the song (the player dies instantly if this is not included)
end

local alreadyDead = false
function state:exit()
   for _,v in pairs(stuff) do
      Entity:destroy(v)
   end
   for _,v in pairs(ui) do
      Entity:destroy(v)
   end

   if songData.music then
      Entity:destroy(songData.music.instrumental)
      if songData.music.plyVocals then
         Entity:destroy(songData.music.plyVocals)
         Entity:destroy(songData.music.enemyVocals)
      else
         Entity:destroy(songData.music.vocals)
      end
   end

   if Input:getBind("GameInputPressed") then
      Input:unbind("GameInputPressed")
   end
   if Input:getBind("GameInputReleased") then
      Input:unbind("GameInputReleased")
   end
   if Input:getBind("PauseMenuPressed") then
      Input:unbind("PauseMenuPressed")
   end

   for _,script in pairs(songData.scripts) do
      if script.exit then
         script:exit()
      end
   end

   paused = false
   alreadyDead = false

   stuff = {}
   ui = {}
   songData = {}
   safeKeeping = {}

   Entity:flush()
end

function state:update(dt)
   if songData.health and songData.health <= 0 then
      if not alreadyDead then
         -- destroy everything, but keep bf around
         do
            for i,v in pairs(stuff) do
               if not v.Tag or v.Tag ~= "player" then
                  Entity:destroy(v)
                  stuff[i] = nil
               end
            end

            Entity:destroy(songData.music.instrumental)
            if songData.music.plyVocals then
               Entity:destroy(songData.music.plyVocals)
               Entity:destroy(songData.music.enemyVocals)
            else
               Entity:destroy(songData.music.vocals)
            end

            Input:unbind("GameInputPressed")
            Input:unbind("GameInputReleased")

            ui = {}
         end
         stuff.AAUGHHIMDEAD = Entity:create(Sound,"AAUGHHIMDEAD","assets/sounds/death.ogg",ENUM_SOUND_MEMORY)
         stuff.AAUGHHIMDEAD:createSource():play()

         local bf = getObjectByTag("player")
         flux.to(Entity.camera.Position,1,{x = bf.Position.x - push:getWidth()/2, y = bf.Position.y - push:getWidth()/3.5}):ease("quadout")

         for name,_ in pairs(bf.Animations) do
            bf:stopAnimation(name)
         end

         bf:playAnimation("dead_enter")

         Entity:create(Clock,"deadDelay",-1,0,function()
            if not bf:getAnimation("dead_enter").playing then
               bf:playAnimation("dead_idle")

               stuff.DeadMusic = Entity:create(Sound,"gameOver","assets/music/gameOver.ogg",ENUM_SOUND_STREAM)
               stuff.DeadMusicEnd = Entity:create(Sound,"gameOverEnd","assets/music/gameOverEnd.ogg",ENUM_SOUND_STREAM)

               stuff.DeadMusic.Source:setLooping(true)
               stuff.DeadMusic:createSource():play()

               Input:bind("GameOverRestart",{"KeyPressed"},function(key)
                  if key == "return" then
                     Entity:destroy(stuff.DeadMusic)
                     stuff.DeadMusic = nil
                     stuff.DeadMusicEnd:createSource():play()

                     bf:stopAnimation("dead_enter")
                     bf:playAnimation("dead_confirm")

                     flux.to(bf.Colour,4,{a=0}):delay(0.5)
                     stuff.restartClock = Entity:create(Clock,"restartClock",1,4,function()
                        States:switchState("game",safeKeeping.name,safeKeeping.diff)
                     end)

                     Input:unbind("GameOverRestart")
                  elseif key == "escape" or key == "backspace" then
                     Input:unbind("GameOverRestart")
                     States:switchState("menu",true)
                  end
               end)

               Entity:destroy("deadDelay")
            end
         end)

         alreadyDead = true
      end

      return
   end
   if not songData.started then return end

   if songData.songTimer >= songData.music.instrumental.PlayingSources[1]:getDuration() then -- assume the song ended
      States:switchState("menu",true)
      return
   end

   if alreadyDead or paused then return end
   songData.songTimer = songData.songTimer + dt

   local songPosition = songData.music.instrumental.PlayingSources[1]:tell()
   for i,note in pairs(songData.notes) do
      if currentSettings.downScroll then
         note.noteImg.img.Position.y = (note.noteImg.receptor.Position.y-50) - (note.tick - songPosition) * songData.speed
         if note.noteImg.bodyImg and note.noteImg.tailImg then
            note.noteImg.tailImg.Position.y = (note.noteImg.receptor.Position.y-50) - ((note.tick + note.length) - songPosition) * songData.speed
            note.noteImg.tailImg.Position.x = note.noteImg.img.Position.x + 40

            note.noteImg.bodyImg.Position.x = note.noteImg.tailImg.Position.x
            note.noteImg.bodyImg.Position.y = note.noteImg.tailImg.Position.y + 64 -- 64 for the height of the tailImg quad
            if note.beingHit then
               note.noteImg.bodyImg.Size.h = -((note.noteImg.tailImg.Position.y + 64) - (note.noteImg.receptor.Position.y + (158/3)))*25
            else
               note.noteImg.bodyImg.Size.h = math.abs((note.noteImg.tailImg.Position.y + 64) - note.noteImg.img.Position.y)*25
            end
         end
      else
         note.noteImg.img.Position.y = (note.noteImg.receptor.Position.y-50) + (note.tick - songPosition) * songData.speed
         if note.noteImg.bodyImg and note.noteImg.tailImg then
            note.noteImg.tailImg.Position.y = ((note.noteImg.receptor.Position.y-50) + ((note.tick + note.length) - songPosition) * songData.speed)
            note.noteImg.tailImg.Position.x = note.noteImg.img.Position.x + 40

            note.noteImg.bodyImg.Position.x = note.noteImg.tailImg.Position.x
            note.noteImg.bodyImg.Position.y = note.noteImg.img.Position.y
            if note.beingHit then
               note.noteImg.bodyImg.Size.h = ((note.noteImg.tailImg.Position.y - 64) - (note.noteImg.receptor.Position.y + (158/3)))*25
            else
               note.noteImg.bodyImg.Size.h = ((note.noteImg.tailImg.Position.y - 64) - note.noteImg.img.Position.y)*25
            end

            note.noteImg.bodyImg.Position.y = note.noteImg.bodyImg.Position.y + (157/2)
            note.noteImg.tailImg.Position.y = note.noteImg.tailImg.Position.y + (157/2)
         end
      end

      if note.noteImg.img.Position.y + note.noteImg.img.Image:getHeight() >= 0 then
         note.noteImg.img.Visible = true
         if note.length > 0 then
            note.noteImg.bodyImg.Visible = true
            note.noteImg.tailImg.Visible = true
         end
      end

      if note.singer == "opponent" then
         if songPosition >= note.tick then
            local actor = getObjectByTag("opponent")
            for _,dir in pairs({"left","down","up","right"}) do
               actor:stopAnimation(dir)
               if dir == note.dir then
                  actor:playAnimation(dir)
               end
            end
            
            ui[8]["note" .. tostring(note.noteImg.index)] = nil
            if note.length > 0 then
               note.beingHit = true

               local anim = note.noteImg.receptor:getAnimation("pressed_confirm")
               if not anim.playing then
                  note.noteImg.receptor:playAnimation("pressed_confirm")
               else
                  if anim.dt >= 3 then
                     if songData.music.vocals then
                        songData.music.vocals.PlayingSources[1]:setVolume(1)
                     else
                        songData.music.enemyVocals.PlayingSources[1]:setVolume(1)
                     end

                     getObjectByTag("opponent"):getAnimation(note.dir).dt = 1
                     anim.dt = 1
                  end
               end

               if songPosition >= note.tick + note.length then
                  ui[8]["noteBody" .. tostring(note.noteImg.index)] = nil
                  ui[8]["noteTail" .. tostring(note.noteImg.index)] = nil
                  table.remove(songData.notes,i)
               end
            else
               if songData.music.vocals then
                  songData.music.vocals.PlayingSources[1]:setVolume(1)
               else
                  songData.music.enemyVocals.PlayingSources[1]:setVolume(1)
               end

               note.noteImg.receptor:playAnimation("pressed_confirm")
               table.remove(songData.notes,i)
            end
         end
      else
         local remove = false
         if songPosition >= note.tick+0.15 then
            if note.length == 0 then
               remove = true
            else
               if note.beingHit then
                  local anim = note.noteImg.receptor:getAnimation("pressed_confirm")
                  if not anim.playing then
                     note.noteImg.receptor:playAnimation("pressed_confirm")
                  else
                     if anim.dt >= 3 then
                        if songData.music.vocals then
                           songData.music.vocals.PlayingSources[1]:setVolume(1)
                        else
                           songData.music.plyVocals.PlayingSources[1]:setVolume(1)
                        end

                        getObjectByTag("player"):getAnimation(note.dir).dt = 1
                        anim.dt = 1
                     end
                  end
               end

               remove = songPosition >= note.tick+note.length+0.15
            end
         end

         if remove then
            playerMiss(note.dir)
            calculateAccuracy()
            ui[8]["noteBody" .. tostring(note.noteImg.index)] = nil
            ui[8]["noteTail" .. tostring(note.noteImg.index)] = nil
            ui[8]["note" .. tostring(note.noteImg.index)] = nil
            table.remove(songData.notes,i)
         end
      end
   end

   local healthBar_Background = ui[2]
   local healthBar_HealthBar = ui[3]
   local healthBar_playerIcon = ui[4]
   local healthBar_opponentIcon = ui[5]

   healthBar_HealthBar.Size = {
      w = healthBar_Background.Size.w * (songData.health/100),
      h = healthBar_Background.Size.h
   }
   healthBar_HealthBar.Position = {
      x = healthBar_Background.Position.x + healthBar_Background.Size.w - (healthBar_Background.Size.w * (songData.health/100)),
      y = healthBar_Background.Position.y
   }

   healthBar_playerIcon.Position = {
      x=healthBar_HealthBar.Position.x+(healthBar_playerIcon.Image:getWidth()*0.6),
      y=healthBar_HealthBar.Position.y-(healthBar_playerIcon.Image:getHeight()/1.65)
   }

   healthBar_opponentIcon.Position = {
      x=healthBar_HealthBar.Position.x-(healthBar_playerIcon.Image:getWidth()*0.6),
      y=healthBar_HealthBar.Position.y-(healthBar_opponentIcon.Image:getHeight()/1.65)
   }

   if (songData.health <= 25) then
      healthBar_playerIcon.Quad = songData.icons.player.alertQuad
   elseif (songData.health >= 75) then
      healthBar_opponentIcon.Quad = songData.icons.opponent.alertQuad
   else
      healthBar_playerIcon.Quad = songData.icons.player.fineQuad
      healthBar_opponentIcon.Quad = songData.icons.opponent.fineQuad
   end

   for i,event in pairs(songData.events) do
      if (songPosition >= event.tick) then
         if eventToFunction[event.class] then
            eventToFunction[event.class](event.params)
         end

         table.remove(songData.events,i)
      end
   end

   for _,v in pairs(ui[7]) do
      v:update(dt)
   end

   for name,script in pairs(songData.scripts) do
      if script then
         local s,e = pcall(function()
            if script.update then
               script:update(dt)
            end
         end)

         if not s then
            print("An error occured while trying to run a script's :update() method. It will be unloaded to prevent console spam.\n\t" .. e)
            songData.scripts[name] = nil
         end
      end
   end
end

function state:draw()
   if songData.scripts then
      for name,script in pairs(songData.scripts) do
         if script then
            local s,e = pcall(function()
               if script.draw then
                  script:draw()
               end
            end)

            if not s then
               print("An error occured while trying to run a script's :draw() method. It will be unloaded to prevent console spam.\n\t" .. e)
               songData.scripts[name] = nil
            end
         end
      end
   end

   for _,v in pairs(ui) do
      if not v.draw and type(v) == "table" then
         for _,k in pairs(v) do
            if k then
               k:draw()
            end
         end
      else
         if v then
            v:draw()
         end
      end
   end
end

return state