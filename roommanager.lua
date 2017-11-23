local skynet = require "skynet"
require "skynet.manager"
local queue = require "skynet.queue"
local lock
local CMD = {}
skynet.start(function()
	lock = queue()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		if CMD[cmd] then
			local f = CMD[cmd]
			skynet.ret(skynet.pack(f(...)))
		end
	end)
    skynet.error("roommanager start!!!")
    skynet.register("ROOMMANAGER")
end)
local room = {}
local player = {}
function CMD.newGame( agent,name )
	skynet.error("newGame",name)
   	lock(function (  )
   		table.insert(player,{name=name,agent=agent})
		if #player>=2 then
			local newroomagent = skynet.newservice("gobangroom")
			skynet.send(player[1].agent,"lua","joinSuccess",newroomagent)
			skynet.send(player[2].agent,"lua","joinSuccess",newroomagent)
			player={}
		end
    end)
	
end
