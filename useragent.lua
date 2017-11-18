local skynet = require "skynet"
local socket = require "skynet.socket"
local json = require "cjson"
local CMD = {}
local Action={}
local gate
local watchdog
local fd 

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		if CMD[cmd] then
			local f = CMD[cmd]
			f(...)
		end
	end)
     skynet.error("agent start!!!")
end)
function CMD.start( conf )
	gate=conf.gate
	watchdog=conf.watchdog
	fd=conf.fd
	--skynet.error(fd,watchdog,gate)
	receiveMessage()
end
function receiveMessage( )
	fd=tonumber(fd)
	socket.start(fd)
	skynet.fork(function (  )
		while true do
			local str = socket.readline(fd)
			if str then
				socket.write(fd, str.."\n")
				handleMessage(str)
			else
				socket.close(fd)
				return
			end
		end
	end)
end
function handleMessage( str )
	local success,data=pcall(json.decode,str)
	skynet.error(success,data)
	if success then
		local f
		if data["action"] then
           f =  Action[data["action"]]
           f(data)
		end
	end
end
function toClient( data )
	local success,jsonstr = pcall(json.encode,data)
	if success then
		socket.write(fd,jsonstr.."\n")
	end
end
function Action.login( data )
    --login success add user
    math.randomseed(os.time())    
    local name = math.random(1000)
	skynet.send("USERDATA","lua","addUser",name,skynet.self())
	local agent = skynet.call("USERDATA","lua","getUser",name)
	skynet.error(agent)
end
function Action.logout( data )
	skynet.error("logout")
end
function Action.reconnect( data )
	skynet.error("reconnect")
end

function Action.sendMessageTo( data )
    local name = data.name
	local agent = skynet.call("USERDATA","lua","getUser",name)
	skynet.send(agent,"lua","toClient",data)
end