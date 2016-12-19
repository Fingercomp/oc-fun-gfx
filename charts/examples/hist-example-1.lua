local charts = require("charts")

local container = charts.Container()
local payload = charts.Histogram()
payload.max = 100
payload.min = -100
payload.align = charts.sides.RIGHT
payload.colorFunc = function(index, perc, value, self, container)
  return 0xafff20
end
container.payload = payload

for i = 1, 400, 1 do
  table.insert(payload.values, math.sin(math.rad(i * 5)) * 100)
  container:draw()

  os.sleep(.05)
end
