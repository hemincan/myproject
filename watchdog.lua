local skynet = require "skynet"

local CMD = {}
local SOCKET = {}
local gate

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	local agent = skynet.newservice("useragent")
	skynet.send(agent, "lua", "start", { gate = gate, fd = fd, watchdog = skynet.self() })
end


function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end


skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("networdgate",skynet.self())
end)
