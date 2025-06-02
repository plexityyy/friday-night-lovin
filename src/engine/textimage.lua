-- Similar to text.lua. Uses assets/fonts/alphabet.png.
-- Is more limiting in capabilities compared to text.lua.

-- NOTE: linebreak features are broken.
local file = {priority=2}

local alphabetImage = love.graphics.newImage("assets/fonts/alphabet.png")
local alphabetFrames = require("assets.fonts.alphabet")
local alphabetAnimations = require("assets.animations.fonts.alphabet")

local characterSaves = {}

for name,v in pairs(alphabetAnimations) do
    local frames = {}
    
    local x = 1
    for i = v.startFrame,v.endFrame do
        local frm = alphabetFrames[i]
        frames[x] = love.graphics.newQuad(frm.x,frm.y,frm.width,frm.height,alphabetImage:getWidth(),alphabetImage:getHeight())

        x = x + 1
    end

    characterSaves[name] = frames
end

function file:init()
    ENUM_TEXTIMAGE_STYLE_REGULAR = "regular"
    ENUM_TEXTIMAGE_STYLE_BOLD = "bold"

    TextImage = Class("TextImage")
    function TextImage:initialize(text)
        self.Text = text or "Hello World!"

        self.Colour = {r=1,g=1,b=1,a=1}

        self.Position = {x=0,y=0}
        self.Scale = 1
        self.Alignment = "centre"
        self.Limit = push:getWidth()
        self.Visible = true

        self.dt = 1
        self.Style = "regular"
    end

    function TextImage:update(dt)
        self.dt = self.dt + dt * 27
        if self.dt >= 4 then self.dt = 1 end
    end

    function TextImage:draw()
        if not self.Visible then return end
        love.graphics.setColor(self.Colour.r,self.Colour.g,self.Colour.b,self.Colour.a)

        love.graphics.push()
            love.graphics.scale(self.Scale)
            love.graphics.translate(self.Position.x,self.Position.y)

            local actualText = self.Text
            if self.Style == ENUM_TEXTIMAGE_STYLE_BOLD then
                actualText = string.upper(actualText)
            end

            local letterPadding = self.LetterPadding
            local visibleChars = {}
            local totalWidth = 0
            local maxHeight = 0

            for i = 1, #actualText do
                local chr = actualText:sub(i, i)
                if chr ~= " " and chr ~= "\n" then
                    local key = (self.Style == ENUM_TEXTIMAGE_STYLE_BOLD and characterSaves[chr .. "bold"]) and (chr .. "bold") or chr
                    local anim = alphabetAnimations[key]
                    if anim then
                        local frame = alphabetFrames[anim.startFrame]
                        local width = frame.width
                        local height = frame.height
                        table.insert(visibleChars,{char=chr,key=key,width=width})
                        totalWidth = totalWidth + width
                        if height > maxHeight then
                            maxHeight = height
                        end
                    end
                end
            end

            local offsetX = 0
            if self.Alignment == "centre" then
                offsetX = (self.Limit - totalWidth)/2
            elseif self.Alignment == "right" then
                offsetX = (self.Limit - totalWidth)
            end

            local xPos = offsetX
            local lineBreaks = 0

            for i = 1,#actualText do
                local chr = actualText:sub(i,i)
                if chr == "\n" then
                    xPos = offsetX
                    lineBreaks = lineBreaks + 1
                elseif chr ~= " " then
                    local key = (self.Style == ENUM_TEXTIMAGE_STYLE_BOLD and characterSaves[chr .. "bold"]) and (chr .. "bold") or chr
                    local chosen = characterSaves[key] or characterSaves.unknown
                    local anim = alphabetAnimations[key]
                    local frame = alphabetFrames[anim.startFrame]

                    local width = frame.width
                    local height = frame.height
                    local yOffset = maxHeight - height

                    love.graphics.draw(alphabetImage,chosen[math.floor(self.dt)],xPos,(36 * (lineBreaks-1)) + yOffset, 0, 1, 1)
                    xPos = xPos + width
                else
                    xPos = xPos + 50
                end
            end


        love.graphics.pop()
    end
end

return file