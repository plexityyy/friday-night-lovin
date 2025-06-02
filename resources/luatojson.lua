local json = require("json")

local tableToConvert = {}

local file = io.open("file.json","w")
if file then
    file:write(json.encode(tableToConvert))
    file:close()
end
