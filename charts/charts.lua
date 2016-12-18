local component = require("component")

local sides = {
  TOP = 1,
  BOTTOM = 2,
  LEFT = 3,
  RIGHT = 4,
  "TOP",
  "BOTTOM",
  "LEFT",
  "RIGHT"
}

local Histogram

do
  local characters = {" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"}
  local meta = {}
  meta.__index = meta

  local function calcHeight(height, perc)
    return math.floor(perc * height * 8)
  end

  local function getBarChars(height, totalHeight)
    local blocks = math.floor(height / 8)
    local part = characters[height - blocks * 8 + 1]
    if blocks * 8 == height then
      part = ""
    end
    local spaces = totalHeight - blocks - (part ~= "" and 1 or 0)
    return characters[1]:rep(spaces) .. part .. characters[9]:rep(blocks)
  end

  local function getMinMax(tbl)
    local max = -math.huge
    local min = math.huge
    for k, v in pairs(tbl) do
      if v > max then
        max = v
      end
      if v < min then
        min = v
      end
    end
    return max
  end

  function meta:draw(container)
    if self.max == self.min and self.max == 0 then
      error("min and max are both 0!")
    end
    local loopStart, loopEnd = 1, container.width
    if self.align == sides.RIGHT then
      loopEnd = #self.values
      loopStart = loopEnd - container.width + 1
    end
    local max = self.max - self.min
    local min = 0
    local bar = 1
    for i = loopStart, loopEnd do
      local value = self.values[i] or self.min
      if value < self.min or value > self.max then
        error("incorrect min/max values: min = " .. min .. ", max = " .. max .. ", v = " .. value)
      end

      local perc = (value - self.min) / max
      if value - self.min == 0 and max == 0 then
        perc = 1
      end

      local height = calcHeight(container.height, perc)
      local chars = getBarChars(height, container.height)

      local fg, bg = self.colorFunc(i, perc, value, self, container)
      fg = fg or container.fg
      bg = bg or container.bg

      if container.gpu.getForeground() ~= fg then
        container.gpu.setForeground(fg)
      end

      if container.gpu.getBackground() ~= bg then
        container.gpu.setBackground(bg)
      end

      container.gpu.set(container.payloadX + bar - 1,
                        container.payloadY,
                        chars,
                        true)
      bar = bar + 1
    end
  end

  Histogram = function()
    local obj = {
      values = {},
      align = sides.LEFT,
      colorFunc = function()
        return 0xffffff
      end,
      min = 0,
      max = 1
    }
    return setmetatable(obj, meta)
  end
end

local Container
do
  local meta = {}
  meta.__index = meta

  function meta:draw()
    if self.payload then
      local fg = self.gpu.getForeground()
      local bg = self.gpu.getBackground()
      if fg ~= self.fg then
        self.gpu.setForeground(self.fg)
      end
      if bg ~= self.bg then
        self.gpu.setBackground(self.bg)
      end

      self.gpu.fill(self.x, self.y, self.width, self.height, " ")
      self.payload:draw(self)

      if self.gpu.getForeground() ~= fg then
        self.gpu.setForeground(fg)
      end
      if self.gpu.getBackground() ~= bg then
        self.gpu.setBackground(bg)
      end
    end
  end

  Container = function()
    local obj = {
      gpu = component.gpu,
      fg = 0xffffff,
      bg = 0x000000,
      x = 1,
      y = 1,
      payloadX = 1,
      payloadY = 1,
      width = 80,
      height = 25,
      payload = nil
    }

    return setmetatable(obj, meta)
  end
end

local mod = {
  Container = Container,
  Histogram = Histogram
}

local container = mod.Container()
local payload = mod.Histogram()
payload.max = 80
payload.align = sides.RIGHT
payload.colorFunc = function(index, perc, value, self, container)
  return 0x20ff20
end
container.payload = payload

for i = 1, 400, 1 do
  table.insert(payload.values, math.random(0, 80))
  container:draw()

  os.sleep(.05)
end

return mod