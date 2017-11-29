local skynet = require "skynet"
require "skynet.manager"
local data = {}
local CMD = {}
function CMD.addUser(name,agent) 
	skynet.error("addUser!")
	data[name]={agent=agent}
end
function CMD.getUser( name )
	return data[name]
end
function CMD.getAllUser(  )
	return data
end
function CMD.removeUser(name)
	skynet.error("removeUser",name)
	data[name]=nil
end
function CMD.setAgent( name,agent )
	if data[name] then
		data[name].agent=agent
	else
		skynet.error("userdata noexit this user",name)
	end
	

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