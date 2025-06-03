--[[

TODO:
   1. Make it so that the player can play the fucking game instead of watching the guys sing
      i. Player can hit long notes, giving them health (works????? i guess??????????)
   2. Make down- & middle-scroll options work
      i. For middle-scroll, don't display opponent notes
   3. Make it so that the player can die
      i. Allow the player to restart ("return" key) the song or return to menu ("escape" key) once in this "substate"
   4. Add a pause menu

]]

local state = {}
local stuff = {}
local songData = {}
local ui = {}

local function getObjectByTag(tag)
   for name,obj in pairs(stuff) do
      if obj.Tag and obj.Tag == tag then
         return obj
      end
   end
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
   end
}

function state:enter(song,difficulty)
   assert(love.filesystem.getDirectoryItems("songs/" .. song),string.format("An error occured with the game.lua scene! (Couldn't find \"%s\" song!)",song))

   print(string.format("Loading \"%s\" (%s)...",song,difficulty))

   local currentSettings = settings:getSettings()
   local metaData = JSON.decode(love.filesystem.read("songs/" .. song .. "/metadata.json"))
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
      maxPoints = 0
   }

   if love.filesystem.getInfo("songs/" .. song .. "/PlayerVocals.ogg") and love.filesystem.getInfo("songs/" .. song .. "/EnemyVocals.ogg") then
      songData.music.plyVocals = Entity:create(Sound,"plyVocalsMusic",love.filesystem.read("songs/" .. song .. "/PlayerVocals.ogg"),ENUM_SOUND_STREAM,true)
      songData.music.enemyVocals = Entity:create(Sound,"enemyVocalsMusic",love.filesystem.read("songs/" .. song .. "/EnemyVocals.ogg"),ENUM_SOUND_STREAM,true)
   elseif love.filesystem.getInfo("songs/" .. song .. "/Vocals.ogg") then
      songData.music.vocals = Entity:create(Sound,"vocalsMusic",love.filesystem.read("songs/" .. song .. "/Vocals.ogg"),ENUM_SOUND_STREAM,true)
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
   healthBar_Background.Position = {x=push:getWidth()/2-healthBar_Background.Size.w/2,y=push:getHeight()*0.09}
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

   local healthBar_infoText = Text:new("Score: 0",love.graphics.newFont("assets/fonts/vcr.ttf",push:getHeight()*0.03))
   healthBar_infoText.Position = {x=healthBar_Background.Position.x,y=healthBar_Background.Position.y+healthBar_Background.Size.h+healthBar_BackgroundBorders.LineThickness+30}
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
         if i == 1 then
            startingPos = 0
            xPosition = xPosition + (push:getWidth()/2)
         else
            noteActor:getAnimation("pressed").loopback = false
            noteActor:getAnimation("pressed_confirm").loopback = false
         end

         noteActor.Position = {
            x = xPosition,
            y = push:getHeight() - 15 - 158
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

         -- Calculate the offset so the camera stays centered when scaled
         local camOffsetX = (screenCenterX - Entity.camera.Position.x) * (zoomAmount-1)
         local camOffsetY = (screenCenterY - Entity.camera.Position.y) * (zoomAmount-1)

         -- Apply zoom and position offset
         Entity.camera.Scale = zoomAmount
         Entity.camera.OffsetPosition = {
            x = camOffsetX*1.75,
            y = -camOffsetY
         }

         -- Smoothly tween back to original scale and position
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
         dir = numberDirToStringDir[note.d].d,
         singer = numberDirToStringDir[note.d].s,
         length = note.l/1000,
         noteImg = {
            img = nil,
            bodyImg = nil,
            tailImg = nil,
            receptor = nil,
            index = i
         }
      }
      local noteImage = DumbImage:new(NOTES_image,noteQuads[n.dir .. "Note"])
      n.noteImg.receptor = ui[7][note.d+1]

      noteImage.Position = {
         x = n.noteImg.receptor.Position.x-77,
         y = -1500 -- :update(dt) will handle note positioning
      }

      n.noteImg.img = noteImage

      if n.length > 0 then
         local bodyImage = Image:new(NOTES_image,noteQuads[n.dir .. "NoteHoldBody"])
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
      local direction = nil

      for d,action in pairs(currentSettings.keybinds) do
         if action == key then
            direction = d
            break
         end
      end

      if not direction then return end

      local noteConfirmed = false
      local songPosition = songData.music.instrumental.PlayingSources[1]:tell()
      for i,note in pairs(songData.notes) do
         if note.singer == "player" and note.dir == direction then
            local difference = math.abs(songPosition-note.tick)
            if difference < 0.15 then
               noteConfirmed = true
               if songData.music.plyVocals then
                  songData.music.plyVocals.PlayingSources[1]:setVolume(1)
               else
                  songData.music.vocals.PlayingSources[1]:setVolume(1)
               end
               songData.health = math.min(100,songData.health + 5)
               songData.streak = songData.streak + 1

               local ranking = "shit" -- default rank
               if difference <= 0.02 then
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
                  if v == direction then
                     actor:playAnimation(v)
                     actor:stopAnimation(v .. "_miss")
                  else
                     actor:stopAnimation(v)
                     actor:stopAnimation(v .. "_miss")
                  end
               end

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
      if noteConfirmed then
         receptor:playAnimation("pressed_confirm")
      else
         receptor:playAnimation("pressed")
         local cln = songData.sounds["missNote" .. tostring(love.math.random(1,3))]:createSource()
         cln:setVolume(0.35)
         cln:play()

         songData.points = songData.points - 10
         songData.health = math.max(0,songData.health - 5)
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
            if difference > 0.06 then
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
               for _,dir in pairs({"left","down","up","right"}) do
                  actor:stopAnimation(dir)
                  actor:stopAnimation(dir .. "_miss")

                  if dir == note.dir then
                     actor:playAnimation(dir .. "_miss")
                  end
               end
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

   songData.music.instrumental:createSource():play()
   if songData.music.vocals then
      songData.music.vocals:createSource():play()
   else
      songData.music.plyVocals:createSource():play()
      songData.music.enemyVocals:createSource():play()
   end
end

function state:exit()
   for _,v in pairs(stuff) do
      Entity:destroy(v)
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

   stuff = {}
   ui = {}
   songData = {}

   collectgarbage("collect")
end

function state:update(dt)
   local songPosition = songData.music.instrumental.PlayingSources[1]:tell()

   for i,note in pairs(songData.notes) do
      note.noteImg.img.Position.y = (note.noteImg.receptor.Position.y-50) - (note.tick - songPosition) * songData.speed
      if note.noteImg.bodyImg and note.noteImg.tailImg then
         note.noteImg.tailImg.Position.y = (note.noteImg.receptor.Position.y - 50) - ((note.tick + note.length) - songPosition) * songData.speed
         note.noteImg.tailImg.Position.x = note.noteImg.img.Position.x + 40

         note.noteImg.bodyImg.Position.x = note.noteImg.tailImg.Position.x
         --[[if note.beingHit then -- TODO: Fix this bullshit
         else
            note.noteImg.bodyImg.Size.h = (note.noteImg.tailImg.Position.y + note.noteImg.tailImg.Image:getHeight()) - note.noteImg.img.Position.y
            note.noteImg.bodyImg.Position.y = ((note.noteImg.img.Position.y + note.noteImg.tailImg.Position.y - note.noteImg.tailImg.Image:getHeight())/2)*2
         end]]
      end

      if note.singer == "opponent" then
         if songPosition >= note.tick then
            local actor = getObjectByTag("opponent")

            local dirToNumb = {
               ["left"] = 5,
               ["down"] = 6,
               ["up"] = 7,
               ["right"] = 8
            }
            local receptorIndex = 0
            local chosenAnim = nil
            for _,dir in pairs({"left","down","up","right"}) do
               actor:stopAnimation(dir)
               if dir == note.dir then
                  receptorIndex = dirToNumb[dir]
                  chosenAnim = dir
                  actor:playAnimation(dir)
               end
            end
            
            ui[8]["note" .. tostring(note.noteImg.index)] = nil
            if note.length > 0 then
               note.beingHit = true

               local anim = ui[7][receptorIndex]:getAnimation("pressed_confirm")
               if not anim.playing then
                  ui[7][receptorIndex]:playAnimation("pressed_confirm")
               else
                  if anim.dt >= 3 then
                     if songData.music.vocals then
                        songData.music.vocals.PlayingSources[1]:setVolume(1)
                     end
                     anim.dt = 1
                  end
               end
               actor:getAnimation(chosenAnim).loopback = true

               if songPosition >= note.tick + note.length then
                  ui[8]["noteBody" .. tostring(note.noteImg.index)] = nil
                  ui[8]["noteTail" .. tostring(note.noteImg.index)] = nil
                  actor:getAnimation(chosenAnim).loopback = false
                  table.remove(songData.notes,i)
               end
            else
               if songData.music.vocals then
                  songData.music.vocals.PlayingSources[1]:setVolume(1)
               end

               ui[7][receptorIndex]:playAnimation("pressed_confirm")
               ui[7][receptorIndex]:getAnimation("pressed_confirm").loopback = false

               table.remove(songData.notes,i)
            end
         end
      else
         if songPosition >= note.tick+0.15 then
            if (note.length == 0) or (note.length > 0 and songPosition >= note.tick+note.length+0.15) then
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

                  if dir == note.dir then
                     chosenAnim = note.dir
                     actor:playAnimation(dir .. "_miss")
                  end
               end

               if note.length > 0 and note.beingHit then
                  local dirToNumb = {
                     ["left"] = 1,
                     ["down"] = 2,
                     ["up"] = 3,
                     ["right"] = 4
                  }
                  local receptorIndex = dirToNumb[chosenAnim]

                  local anim = ui[7][receptorIndex]:getAnimation("pressed_confirm")
                  if not anim.playing then
                     ui[7][receptorIndex]:playAnimation("pressed_confirm")
                  else
                     if anim.dt >= 3 then
                        if songData.music.vocals then
                           songData.music.vocals.PlayingSources[1]:setVolume(1)
                        end
                        anim.dt = 1
                     end
                  end
               end

               ui[8]["noteBody" .. tostring(note.noteImg.index)] = nil
               ui[8]["noteTail" .. tostring(note.noteImg.index)] = nil
               ui[8]["note" .. tostring(note.noteImg.index)] = nil
               table.remove(songData.notes,i)
            end
         end
      end
   end
   do
      local acc = "???"
      local rank = "?"
      if songData.maxPoints ~= 0 and songData.points ~= 0 then
         local percentage = (songData.points/songData.maxPoints)*100

         if percentage >= 99 then
            rank = "Marvelous!!!"
         elseif percentage >= 90 then
            rank = "Sick!!"
         elseif percentage >= 80 then
            rank = "Good!"
         elseif percentage >= 70 then
            rank = "Okay..."
         elseif percentage >= 60 then
            rank = "Bad"
         else
            rank = "Shit"
         end

         acc = string.format("%.1f",percentage)
      end

      ui[6].Text = "Score: " .. tostring(songData.points) .. " | Accuracy: " .. acc .. "% (" .. rank .. ")"
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