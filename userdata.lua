local skynet = require "skynet"
require "skynet.manager"
local data = {}
local CMD = {}
function CMD.addUser(name,agent) 
	skynet.error("addUser!")
	data[name]=agent
end
function CMD.getUser( name )
	return data[name]
end
function CMD.getAllUser(  )
	return data
end
skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		if CMD[cmd] then
			local f = CMD[cmd]
			skynet.ret(skynet.pack(f(...)))
		end
	end)
     skynet.register("USERDATA")
end)