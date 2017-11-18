local skynet = require "skynet"
local sprotoloader = require "sprotoloader"

local max_client = 64
local port = 8888
local address = "0.0.0.0"
skynet.start(function()
	skynet.error("Server start")
	skynet.newservice("debug_console",8000)
	skynet.newservice("userdata")
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = port,
		address=address,
		maxclient = max_client,
		nodelay = true,
	})
	skynet.error("Watchdog listen on", port)
	skynet.exit()
end)
