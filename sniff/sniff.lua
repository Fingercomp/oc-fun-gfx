local com = require("component")
local event = require("event")
local term = require("term")
local comp = require("computer")
local forms = require("forms")

local gpu = com.gpu

local oldW, oldH = gpu.getResolution()
local oldFG = gpu.getForeground()
local oldBG = gpu.getBackground()

gpu.setResolution(80, 25)

forms.ignoreAll()
local elements = {}

local main = forms.addForm()
main.color = 0x333333
elements.main = main

local topFrame = main:addFrame(1,1,0)
topFrame.W = 80
topFrame.H = 1
topFrame.color = 0xCCCCCC
topFrame.fontColor = 0
elements.topFrame = topFrame

local appName = topFrame:addLabel(3,1,"NETWORK SNIFFER")
appName.color = 0xCCCCCC
appName.fontColor = 0
elements.appName = appName

local function updateMsgData()
  local self = elements.msgList
  elements.recvAddr.caption = "RECEIVER: " .. self.items[self.index][1]
  elements.sendAddr.caption =  "SENDER:   " .. self.items[self.index][2]
  elements.distance.caption =  "DISTANCE: " .. self.items[self.index][4]
  elements.port.caption =      "PORT:     " .. self.items[self.index][3]
  elements.chunkList:clear()
  for i = 5, #self.items[self.index], 1 do
    elements.chunkList:insert("#" .. tostring(i - 4), self.items[self.index][i])
  end
  if self.items[self.index][5] then
    elements.data:setTextHex(self.items[self.index][5])
  end
  main:redraw()
end
local msgList = main:addList(1,2,updateMsgData)
msgList.sfColor = 0x000000
msgList.selColor = 0xFFFFFF
msgList.color = 0x333333
msgList.border = 0
msgList.W = 80
msgList.H = 9
elements.msgList = msgList

local msgInfo = main:addFrame(1,11,0)
msgInfo.H = 15
msgInfo.color = 0xCCCCCC
msgInfo.W = 80
msgInfo:hide()
elements.msgInfo = msgInfo

local recvAddr = msgInfo:addLabel(3,2,"RECEIVER: ")
recvAddr.fontColor = 0x00000
recvAddr.color = 0xCCCCCC
recvAddr.W = 7
elements.recvAddr = recvAddr

local sendAddr = msgInfo:addLabel(3,3,"SENDER: ")
sendAddr.fontColor = 0x00000
sendAddr.color = 0xCCCCCC
sendAddr.W = 7
elements.sendAddr = sendAddr

local distance = msgInfo:addLabel(3,4,"DISTANCE: ")
distance.fontColor = 0x00000
distance.color = 0xCCCCCC
distance.W = 10
elements.distance = distance

local port = msgInfo:addLabel(3,5,"PORT: ")
port.fontColor = 0x00000
port.color = 0xCCCCCC
port.W = 6
elements.port = port

local data = msgInfo:addEdit(3,6)
data.H = 10
data.fontColor = 0x00000
data.color = 0xCCCCCC
data.W = 72
function data:setTextHex(bytes)
  local text = {}
  for i = 1, #bytes, 8 do
    local sub = bytes:sub(i, i + 7)
    table.insert(text, ("%-20s"):format(sub:gsub(".", function(c) return ("%02X"):format(c:byte()) end):gsub("^........", "%1 ")) .. sub:gsub(".", function(c) return " " .. c end):gsub("[^\x20-\x7e]", "᛫"))
  end
  self.text = text
end
elements.data = data

local chunkList = msgInfo:addList(74,6,function()
  local self = elements.chunkList
  elements.data:setTextHex(self.items[self.index])
  main:redraw()
end)
chunkList.sfColor = 0
chunkList.H = 10
chunkList.selColor = 0xFFFFFF
chunkList.fontColor = 0x00000
chunkList.border = 1
chunkList.color = 0xCCCCCC
chunkList.W = 7
elements.chunkList = chunkList

local function modemListener(name, recv, send, port, dist, ...)
  elements.msgList:insert(
    ("[" .. ("%10.2f"):format(comp.uptime()) .. "] #" .. ("%5d"):format(port) ..
    " " .. send:sub(1,8) .. "… → " .. recv:sub(1,8) .. "…"),
     {recv, send, port, dist, ...})
  msgInfo:show()
  updateMsgData()
end

local quitListener = main:addEvent("interrupted", function()
  forms.stop()
end)

event.listen("modem_message", modemListener)

local invoke = com.invoke
com.invoke = function(address, method, ...)
  if com.type(address) == "modem" then
    local modem = com.proxy(address)
    if method == "send" then
      local result = {invoke(address, "send", ...)}
      local args = {...}
      local addr = table.remove(args, 1)
      local port = table.remove(args, 1)
      local distance = modem.isWireless() and modem.getStrength() or 0
      elements.msgList:insert(
        ("[" .. ("%10.2f"):format(comp.uptime()) .. "] #" .. ("%5d"):format(port) ..
        " " .. modem.address:sub(1, 8) .. "… → " .. addr:sub(1, 8) .. "…"),
        {addr, modem.address, port, distance, table.unpack(args)})
      msgInfo:show()
      updateMsgData()
      return table.unpack(result)
    elseif method == "broadcast" then
      local result = {invoke(address, "broadcast", ...)}
      local args = {...}
      local port = table.remove(args, 1)
      local distance = modem.isWireless() and modem.getStrength() or 0
      elements.msgList:insert(
        ("[" .. ("%10.2f"):format(comp.uptime()) .. "] #" .. ("%5d"):format(port) ..
        " " .. modem.address:sub(1, 8) .. "… → BROADCAST"),
        {"BROADCAST", modem.address, port, distance, table.unpack(args)})
      msgInfo:show()
      updateMsgData()
      return table.unpack(result)
    end
  end
  return invoke(address, method, ...)
end

forms.run(main)

com.invoke = invoke

event.ignore("modem_message", modemListener)
gpu.setResolution(oldW, oldH)
gpu.setForeground(oldFG)
gpu.setBackground(oldBG)
term.clear()
