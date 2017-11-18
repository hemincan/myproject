local skynet = require "skynet"
local socket = require "skynet.socket"
local CMD = {}
local watchdog = ...
function CMD.open( conf )
		local id = socket.listen(conf.address, conf.port)
		socket.start(id , function(id, addr)
			print("connect from " .. addr .. " " .. id)
			skynet.send(watchdog, "lua", "socket","open",id,addr)
			
		end)
end


skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		if CMD[cmd] then
			local f=CMD[cmd]
			f(...)
		end
	end)
     skynet.error("gate start!!","watchdog",watchdog)
end)