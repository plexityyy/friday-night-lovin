-- converts pre v0.6.4 FNF charts into something Friday Night Lovin' can understand. assumes hard difficulty. doesn't include any FocusCamera events.
local json = require("json")

local file = io.open("chart.json","r")
if file then
    local contents = ""
    for line in file:lines() do
        contents = contents .. line
    end
    file:close()
    contents = json.decode(contents)

    local newContents = {
        scrollSpeed = {
            hard = contents.song.speed
        },
        events = {},
        notes = {
            hard = {}
        }
    }

    for _,section in pairs(contents.song.notes) do
        for _,note in pairs(section.sectionNotes) do
            if #note == 3 then
                local direction
                if section.mustHitSection then
                    direction = tostring(note[2])
                else
                    local conversionShit = {
                        [0] = "4",
                        [1] = "5",
                        [2] = "6",
                        [3] = "7",
                        [4] = "0",
                        [5] = "1",
                        [6] = "2",
                        [7] = "3"
                    }
                    direction = conversionShit[note[2]]
                end

                table.insert(newContents.notes.hard,{
                    t = note[1],
                    d = direction,
                    l = note[3] or 0
                })
            end
        end
    end

    local newFile = io.open("newChart.json","w")
    if newFile then
        newFile:write(json.encode(newContents))
        newFile:close()
    end
end