local skynet = require "skynet"
local socket = require "skynet.socket"
local json = require "cjson"
local string = require "string"
local websocket = require "websocket"
local httpd = require "http.httpd"
local urllib = require "http.url"
local sockethelper = require "http.sockethelper"

local CMD = {}
local Action={}
local gate
local watchdog
local fd 
local _type  --websocket or socket
local message = {}
local myroom
local name
local web_socket --websocket
local unreceiveheatbeatcount = 0
local disconnect = false
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
	_type=conf.type

	--skynet.error(fd,watchdog,gate)
	if conf.type=="socket" then
		receiveMessage_socket()
	elseif conf.type=="websocket" then
	    receiveMessage_websocket()
    end
	
end
----------------------
----------------------
-------websocket------
local handler = {}
function handler.on_open(ws)
	web_socket=ws
    print(string.format("%d::open", ws.id))
end

function handler.on_message(ws, message)
    print(string.format("%d receive:%s", ws.id, message))
    toAllPeople(message)
	handleMessage(message)
    -- ws:send_text(message .. "from server")
    --ws:close()
end

function handler.on_close(ws, code, reason)
    print(string.format("%d close:%s  %s", ws.id, code, reason))
end

local function handle_socket(id)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
    if code then
        
        if url == "/ws" then
            local ws = websocket.new(id, header, handler)
            ws:start()
        end

    end


end



---------------------
---------------------

function receiveMessage_websocket( )
	fd=tonumber(fd)
	socket.start(fd)
	pcall(handle_socket, fd)
	
end
function receiveMessage_socket( )
	fd=tonumber(fd)
	socket.start(fd)
	skynet.fork(function (  )

		while true do
			local str = socket.readline(fd)
			if str then
				-- socket.write(fd, str.."\n")
				skynet.error(str)
				toAllPeople(str)
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
		if type(data)=='table' and data["action"] then
           f =  Action[data["action"]]
           f(data)
		end
	end
end

function beginHeatBeat(  )
	skynet.fork(function (  )
		while true do
			skynet.error("status",disconnect,unreceiveheatbeatcount)
			unreceiveheatbeatcount=unreceiveheatbeatcount+1
			if unreceiveheatbeatcount>3 then
				disconnect=true
			end
			if unreceiveheatbeatcount>=100 then
				skynet.send("USERDATA","lua","removeUser",name)
				exitService()
			end
			skynet.sleep(1000)
		end
	end)
end
function CMD.joinSuccess( room )
	myroom=room
	skynet.error("joinSuccess")
	local data= {}
	data.replyAction="joinSuccess"
	local success = skynet.call(myroom,"lua","addPlayer",name,skynet.self())
	CMD.toClient(data)
end
function CMD.toClient( data )
	local success,jsonstr = pcall(json.encode,data)
	if success then
		if _type=="socket" then
			socket.write(fd,jsonstr.."\n")
		end
		if _type=="websocket" then
			web_socket:send_text(jsonstr)
		end
	end
end
function CMD.oldData( oldData )
	message=oldData.message
	myroom=oldData.room
end
function CMD.reconnect( newagent )
	--data need to give the newagent
	skynet.send(newagent,"lua","oldData",{message=message,room=myroom})
	exitService()
end
function exitService(  )
	skynet.exit()
end
function Action.login( data )
   
    name = data.name

    local user = skynet.call("USERDATA","lua","getUser",name)
    if user==nil then
		skynet.send("USERDATA","lua","addUser",name,skynet.self())
	else
		skynet.send(user.agent,"lua","reconnect",skynet.self())
		skynet.send("USERDATA","lua","setAgent",name,skynet.self())
	end
	beginHeatBeat()
	-- local agent = skynet.call("USERDATA","lua","getUser",name)
	-- skynet.error(agent)
end
function Action.heatBeat(  )
	unreceiveheatbeatcount=0
end
function Action.logout( data )
	skynet.error("logout")
end
function toAllPeople( data )
	local agents = skynet.call("USERDATA","lua","getAllUser")
	for k,v in pairs(agents) do
		print(k,v)
		skynet.send(v.agent,"lua","toClient",data)
	end
end
function Action.sendMessageTo( data )
    local name = data.name
	local user = skynet.call("USERDATA","lua","getUser",name)
	if user~=nil then
		skynet.send(user.agent,"lua","toClient",data)
	end
end
function Action.newGame( data )
	skynet.send("ROOMMANAGER","lua","newGame",skynet.self(),name)

end
function Action.playChess( data )
	local success = skynet.call(myroom,"lua","playChess",name,data.x,data.y)
end