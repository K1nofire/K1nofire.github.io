local URL = "https://github.com/K1nofire/K1nofire.github.io/blob/main/main.lua"

local source = game:HttpGet(URL)
local fn, err = loadstring(source)

if not fn then
    error("Load error: " .. tostring(err))
end

fn()
