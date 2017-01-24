require("component").gpu.setResolution(80,25)
local com = require("component")
local event = require("event")
local term = require("term")
local comp = require("computer")
local forms=require("forms")

local gpu = com.gpu

local oldW, oldH = gpu.getResolution()
local oldFG = gpu.getForeground()
local oldBG = gpu.getBackground()

forms.ignoreAll()
local elements = {}

local main=forms.addForm()
main.color=1973790
elements.main = main

local topFrame=main:addFrame(1,1,0)
topFrame.W=80
topFrame.H=1
topFrame.color=0xcccccc
topFrame.fontColor=0
elements.topFrame = topFrame

local appName=topFrame:addLabel(3,1,"NETWORK SNIFFER")
appName.color=0xcccccc
appName.fontColor=0
elements.appName=appName

local function updateMsgData()
  local self = elements.msgList
  elements.modemAddr.caption = "MODEM:    " .. self.items[self.index][1]
  elements.sendAddr.caption =  "SENDER:   " .. self.items[self.index][2]
  elements.distance.caption =  "DISTANCE: " .. self.items[self.index][4]
  elements.port.caption =      "PORT:     " .. self.items[self.index][3]
  elements.chunkList:clear()
  for i = 5, #self.items[self.index], 1 do
    elements.chunkList:insert("#" .. tostring(i - 4), self.items[self.index][i])
  end
  if self.items[self.index][5] then
    elements.data.text = self.items[self.index][5]
  end
  main:redraw()
end
local msgList=main:addList(1,2,updateMsgData)
msgList.sfColor=0
msgList.selColor=16777215
msgList.color=3355443
msgList.border=0
msgList.W=80
msgList.H=9
elements.msgList = msgList

local msgInfo=main:addFrame(1,11,0)
msgInfo.H=15
msgInfo.color=12829635
msgInfo.W=80
msgInfo:hide()
elements.msgInfo = msgInfo

local modemAddr=msgInfo:addLabel(3,2,"MODEM: ")
modemAddr.fontColor=0
modemAddr.color=12829635
modemAddr.W=7
elements.modemAddr = modemAddr

local sendAddr=msgInfo:addLabel(3,3,"SENDER: ")
sendAddr.fontColor=0
sendAddr.color=12829635
sendAddr.W=7
elements.sendAddr = sendAddr

local distance=msgInfo:addLabel(3,4,"DISTANCE: ")
distance.fontColor=0
distance.color=12829635
distance.W=10
elements.distance = distance

local port=msgInfo:addLabel(3,5,"PORT: ")
port.fontColor=0
port.color=12829635
port.W=6
elements.port = port

local data=msgInfo:addEdit(3,6)
data.H=10
data.fontColor=0
data.color=13421772
data.W=72
elements.data = data

local chunkList=msgInfo:addList(74,6,function()
  local self = elements.chunkList
  elements.data.text = self.items[self.index]
  main:redraw()
end)
chunkList.sfColor=0
chunkList.H=10
chunkList.selColor=16777215
chunkList.fontColor=0
chunkList.border=1
chunkList.color=0xcccccc
chunkList.W=7
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
forms.run(main)
event.ignore("modem_message", modemListener)
gpu.setResolution(oldW, oldH)
gpu.setForeground(oldFG)
gpu.setBackground(oldBG)
term.clear()