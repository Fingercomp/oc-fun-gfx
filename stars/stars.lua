local unicode = require("unicode")

local gpu = require("component").gpu

local chars = {
  unicode.char(0x0020),  -- [ ]
  unicode.char(0x00b7),  -- [·]
  unicode.char(0x16eb),  -- [᛫]
  unicode.char(0x22c5),  -- [⋅]
  unicode.char(0xff65),  -- [･]
  unicode.char(0x2022),  -- [•]
  unicode.char(0x25cf)   -- [●]
}

local function line(x0, y0, x1, y1)
  local steep = false
  if math.abs(x0 - x1) < math.abs(y0 - y1) then
    x0, y0 = y0, x0
    x1, y1 = y1, x1
    steep = true
  end
  if x0 > x1 then
    x0, x1 = x1, x0
    y0, y1 = y1, y0
  end
  local dx = x1 - x0
  local dy = y1 - y0
  local derr = math.abs(dy) * 2;
  local err = 0;
  local y = y0
  local points = {}
  for x = x0, x1, 1 do
    if steep then
      table.insert(points, {y, x})
    else
      table.insert(points, {x, y})
    end
    err = err + derr
    if err > dx then
      if y1 > y0 then
        y = y + 1
      else
        y = y - 1
      end
      err = err - dx * 2
    end
  end
  return points
end

local width, height = gpu.getResolution()
local x, y = math.floor(width / 2), math.floor(height / 2)

local stars = {}
local distance = math.ceil(math.max(
  -- top-left
  math.sqrt(x^2 + y^2),
  -- top-right
  math.sqrt((width - x)^2 + y^2),
  -- bottom-left
  math.sqrt(x^2 + (height - y)^2),
  -- bottom-right
  math.sqrt((width -x)^2 + (height - y)^2)
))

while true do
  for n = 1, 8, 1 do
    local angle = math.random(0, 359)
    local x1 = math.floor(x + distance * math.cos(math.rad(angle)))
    local y1 = math.floor(y + distance * math.sin(math.rad(angle)))
    if x1 < 1 then x1 = 1 end
    if x1 > width then x1 = width end
    if y1 < 1 then y1 = 1 end
    if y1 > height then y1 = height end
    local points = line(x, y, x1, y1)
    if points[1][1] ~= x or points[1][2] ~= y then
      -- reverse the table
      for i = 1, math.floor(#points / 2), 1 do
        points[i], points[#points - i + 1] = points[#points - i + 1], points[i]
      end
    end
    local star = {
      points = points,
      angle = angle,
      i = 0,
      state = 2
    }
    table.insert(stars, star)
  end

  for i = #stars, 1, -1 do
    local star = stars[i]
    star.i = star.i + 1
    if not star.points[star.i] then
      table.remove(stars, i)
    end
    star.state = 2 + math.floor(star.i / (#star.points + 1) * 5)
  end

  gpu.fill(1, 1, width, height, " ")
  for _, star in pairs(stars) do
    gpu.set(star.points[star.i][1], star.points[star.i][2], chars[star.state])
  end

  os.sleep(.05)
end

gpu.fill(1, 1, width, height, " ")
