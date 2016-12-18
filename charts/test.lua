local charts = require("charts")

local container = charts.Container()
local payload = charts.Histogram()
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
