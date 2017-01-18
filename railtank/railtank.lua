local com = require("component")
local event = require("event")
local term = require("term")

local charts = require("charts")

local gpu = com.gpu

local colors = {
  ["water"] = 0x20afff,
  ["lava"] = 0xff2020,
  ["creosote"] = 0xcfaf20,
  ["seedoil"] = 0xffdf20,
  0xffffff
}

local histUpdateInterval = 5
local tankAmount = 4
local bg = 0xe1e1e1
local fg = 0x2d2d2d
local graphBG = 0xffffff


tankAmount = math.min(math.floor((gpu.maxResolution() - 5) / 25), tankAmount)
local oldW, oldH = gpu.getResolution()
local w, h = 5 + 25 * tankAmount, 25
gpu.setResolution(w, h)

local tanks = {}

local function newTank(pos)
  tanks[pos] = {
    bar = {},
    hist = {},
    x = (pos - 1) * 25 + 1 + 5
  }
  local tank = tanks[pos]
  tank.bar.container = charts.Container()
  tank.bar.container.x = tank.x
  tank.bar.container.y = 6
  tank.bar.container.width = 20
  tank.bar.container.height = 9
  tank.bar.container.fg = colors[1]
  tank.bar.container.bg = graphBG

  tank.bar.payload = charts.ProgressBar()
  tank.bar.payload.direction = charts.sides.TOP

  tank.bar.container.payload = tank.bar.payload


  tank.hist.container = charts.Container()
  tank.hist.container.x = tank.x
  tank.hist.container.y = 16
  tank.hist.container.width = 20
  tank.hist.container.height = 9
  tank.hist.container.fg = colors[1]
  tank.hist.container.bg = graphBG
  
  tank.hist.payload = charts.Histogram()
  tank.hist.payload.align = charts.sides.RIGHT
  tank.hist.payload.min = 0
  tank.hist.payload.colorFunc = function()
    return tank.hist.container.fg, tank.hist.container.bg
  end

  tank.hist.container.payload = tank.hist.payload
end

local oldBG = gpu.setBackground(bg)
local oldFG = gpu.setForeground(fg)
os.sleep(0)
gpu.fill(1, 1, w, h, " ")

local cycle = 0
while true do
  do
    local clear = false
    for pos = #tanks, 1, -1 do
      if not com.proxy(tanks[pos].addr) then
        table.remove(tanks, pos)
        clear = true
      end
    end
    if clear then
      gpu.fill(1, 1, w, h, " ")
    end
    local i = #tanks + 1
    for addr in com.list("tank_controller") do
      for side = 0, 5, 1 do
        if i > tankAmount then
          break
        end
        local found = false
        for _, tank in pairs(tanks) do
          if tank.addr == addr then
            found = true
            break
          end
        end
        if not found then
          if com.proxy(addr) and com.invoke(addr, "getFluidInTank", side).n == 1 then
            newTank(i)
            tanks[i].proxy = com.proxy(addr)
            tanks[i].addr = addr
            tanks[i].side = side
            i = i + 1
          end
        end
      end
    end
  end

  for i = 1, tankAmount, 1 do
    local tank = tanks[i]
    if tank then
      tank.x = (i - 1) * 25 + 5
      tank.hist.container.x = tank.x
      tank.bar.container.x = tank.x
      local data = {}
      if com.proxy(tank.addr) then
        data = tank.proxy.getFluidInTank(tank.side)
      end
      if data[1] then
        if cycle % (histUpdateInterval * 2) == 0 then
          tank.hist.payload.max = math.max(tank.hist.payload.max, data[1].capacity)
          table.insert(tank.hist.payload.values, data[1].amount)
          if #tank.hist.payload.values > tank.hist.container.width then
            table.remove(tank.hist.payload.values, 1)
          end
        end

        tank.bar.payload.max = data[1].capacity
        tank.bar.payload.value = data[1].amount

        gpu.set(tank.x, 2, data[1].amount .. "mB")
        gpu.set(tank.x, 3, data[1].capacity .. "mB")
        gpu.set(tank.x, 4, ("%6.2f"):format(100 * data[1].amount / data[1].capacity) .. "%")
        if data[1].label then
          tank.bar.container.fg = colors[data[1].name] or colors[1]
          if tank.hist.container.fg ~= tank.bar.container.fg then
            tank.hist.payload.values = {}
          end
          tank.hist.container.fg = tank.bar.container.fg
          gpu.set(tank.x, 1, data[1].label)
        else
          tank.bar.container.fg = colors[1]
          tank.hist.container.fg = colors[1]
          gpu.set(tank.x, 1, "Empty")
        end
      end
      tank.hist.container:draw()
      tank.bar.container:draw()
    else
      gpu.set(25 * (i - 1) + 5 + 1, 12, "Connect a tank")
    end
  end
  if event.pull(.5, "interrupted") then
    break
  end
  cycle = cycle + 1
end

gpu.setBackground(oldBG)
gpu.setForeground(oldFG)
gpu.setResolution(oldW, oldH)
gpu.fill(1, 1, oldW, oldH, " ")
term.clear()
