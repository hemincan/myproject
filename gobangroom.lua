local skynet = require "skynet"
local CMD = {}
local player = {}
local white = "1"
local black = "2"
local chessborad ={}
local chessboradwidth = 15
local chessboradheight = 15
skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		if CMD[cmd] then
			local f = CMD[cmd]
			skynet.ret(skynet.pack(f(...)))
		end
	end)
	gameBegin(  )
    skynet.error("gobangroom start!!!")
end)
function initChessborad(  )
	chessborad={}
	for i=1,chessboradwidth do
		chessborad[i]={}
		for s=1,chessboradheight do
			chessborad[i][s]=0
		end
	end
end
function CMD.addPlayer( name )
	if player[white]~=nil and player[black]~=nil  then
		return false
	end
	if player[white]==nil then
		player[white]=name
		player[name]=white
		return true
	end
	if player[black]==nil then
		player[black]=name
		player[name]=black
		return true
	end
	return false
end

function CMD.playChess( name,x,y )
	if x>chessboradwidth or x<0 then
		return false;
	end
	if y>chessboradheight or y<0 then
		return false;
	end
	chessborad[x][y]=player[name]
end
function printChessBorad(  )
	for i=1,chessboradwidth do
		for s=1,chessboradheight do
			io.write(chessborad[i][s].."  ")
		end
		print()
	end
end
function gameBegin(  )
	initChessborad()
	skynet.fork(function (  )
		while true do
			-- printChessBorad(  )
			skynet.sleep(200)
		end

	end)
end