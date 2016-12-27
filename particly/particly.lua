local com = require("component")
local event = require("event")

local p = com.particle

local image = [[
####...###....#...#####
....#.#...#...#.......#
.###..#...#...#......#.
#.....#...#...#.....#..
#####..###....#....#...
]]

local px, py, pz = -5, 4.8, -5
local pname = "flame"
local pvx, pvy, pvz = 0, 0, 0
local step = .2
local doubleHeight = false

while 1 do
  local x = 0
  for line in image:gmatch("[^\n]+") do
    x = x + step * 2
    local z = 0
    for c in line:gmatch(".") do
      z = z + step
      if c == "#" then
        for i = 1, 5, 1 do
          p.spawn(pname, x + px, py, z + pz, pvx, pvy, pvz)
          if doubleHeight then
            p.spawn(pname, x + px + step, py, z + pz, pvx, pvy, pvz)
          end
        end
      end
    end
  end
  if event.pull(.05, "interrupted") then
    break
  end
end
