local escape = FangsHeist.require "Modules/Handlers/escape"
local music = FangsHeist.require "Modules/Handlers/music"
local orig_net = FangsHeist.require "Modules/Variables/net"
local dialogue = FangsHeist.require "Modules/Handlers/dialogue"

// Mode initialization.
addHook("MapChange", function(map)
	if not multiplayer then
		mapmusname = mapheaderinfo[map].musname or $
	end

	FangsHeist.initMode(map)
end)

addHook("NetVars", function(n)
	FangsHeist.Net = n($)
	FangsHeist.Save = n($)
end)

addHook("MapLoad", do
	if not FangsHeist.isMode() then
		return
	end

	FangsHeist.loadMap()
end)

addHook("PreThinkFrame", do
	if not FangsHeist.isMode() then
		return
	end

	for p in players.iterate do
		if not p.heist then continue end

		p.heist.lastbuttons = p.heist.buttons

		p.heist.buttons = p.cmd.buttons

		p.heist.lastforw = p.heist.forwardmove
		p.heist.lastside = p.heist.sidemove

		p.heist.forwardmove = p.cmd.forwardmove
		p.heist.sidemove = p.cmd.sidemove

		if FangsHeist.isPlayerAlive(p) then
			if p.heist.exiting
			or p.heist.weapon_hud then
				p.cmd.buttons = 0
				p.cmd.forwardmove = 0
				p.cmd.sidemove = 0
			end
		end
		if FangsHeist.Net.game_over
		or FangsHeist.Net.pregame then
			p.cmd.buttons = 0
			p.cmd.sidemove = 0
			p.cmd.forwardmove = 0
		end
	end
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then
		return
	end
	local data = FangsHeist.getTypeData()

	dialogue.tick()

	FangsHeist.Net.placements = {}

	for i = 0,31 do
		local p = players[i]

		if not (p
		and p.valid
		and FangsHeist.isPlayerAlive(p)
		and p.heist.team.leader == p) then
			FangsHeist.Net.placements[i] = nil
			continue
		end

		if not FangsHeist.Net.placements[i] then
			FangsHeist.Net.placements[i] = {p = p, place = 1}
		end
	end

	// ROUND 2:
	for _,data in pairs(FangsHeist.Net.placements) do
		data.place = 1

		local profit = FangsHeist.returnProfit(data.p)

		for _,data2 in pairs(FangsHeist.Net.placements) do
			if data == data2 then continue end

			local profit2 = FangsHeist.returnProfit(data2.p)

			if profit2 > profit then
				data.place = $+1
				continue
			end

			if profit2 == profit
			and #data2.p > #data.p then
				data.place = $+1
			end
		end
	end

	if FangsHeist.Net.pregame then
		if S_MusicName() ~= "FINDAY" then
			S_ChangeMusic("FINDAY", true)
		end

		FangsHeist.Net.pregame_time = max(0, $-1)
		local count = 0
		local confirmcount = 0
	
		for p in players.iterate do
			if p and p.heist then
				count = $+1
				if p.heist.confirmed_skin then
					confirmcount = $+1
				end
			end
		end
	
		if confirmcount == count then
			FangsHeist.Net.pregame_time = 0
		end
	
		if FangsHeist.Net.pregame_time == 0 then
			FangsHeist.Net.pregame = false
			S_ChangeMusic(mapmusname, true)

			for p in players.iterate do
				if p and p.heist then
					p.heist.invites = {}
				end
			end
		else
			return
		end
	end


	if FangsHeist.Net.game_over then
		if FangsHeist.Net.end_anim then
			FangsHeist.Net.end_anim = max(0, $-1)
			return
		end

		FangsHeist.Net.game_over_ticker = max(0, $+1)

		local t = FangsHeist.Net.game_over_ticker

		if t == FangsHeist.INTER_START_DELAY then
			S_ChangeMusic("KINPRI", true)
			mapmusname = "KINPRI"
		end

		if t >= FangsHeist.INTER_START_DELAY+FangsHeist.Net.game_over_length then
			local map = 1
			local votes = -1

			for i,selmap in pairs(FangsHeist.Net.map_choices) do
				if selmap.votes > votes then
					map = selmap.map
					votes = selmap.votes
				end
			end

			G_SetCustomExitVars(map)
			G_ExitLevel()
		end

		return
	end

	-- manage teams
	local teamsWithNoLeaders = {}
	local checkedTeams = {}

	for p in players.iterate do
		if not FangsHeist.isPlayerAlive(p) then continue end
		if checkedTeams[p.heist.team] then continue end

		checkedTeams[p.heist.team] = true

		for sp,_ in pairs(p.heist.team.players) do
			if not (sp and sp.valid and sp.heist and not sp.heist.spectator) then
				p.heist.team.players[sp] = nil
				if p.heist.team.leader == sp then
					table.insert(teamsWithNoLeaders, p.heist.team)
				end
			end
		end
	end

	for k,team in pairs(teamsWithNoLeaders) do
		local teamPlyrs = {}

		for p,_ in pairs(team.players) do
			if p and p.valid and p.heist and not p.heist.spectator then
				table.insert(teamPlyrs, p)
			end
		end

		if #teamPlyrs then
			team.leader = teamPlyrs[P_RandomRange(1, #teamPlyrs)]
		end
	end

	if FangsHeist.Net.is_boss then
		FangsHeist.Net.time_left = max(0, $-1)

		local playerCount = 0
		for p in players.iterate do
			if FangsHeist.isPlayerAlive(p) then
				playerCount = $+1
			end
		end

		if FangsHeist.Net.time_left == 0 or not (playerCount) then
			for p in players.iterate do
				if p.mo and p.mo.health then
					P_DamageMobj(p.mo, nil, nil, 999, DMG_INSTAKILL)
				end
			end
			FangsHeist.startIntermission()
		end
	else
		escape()
	end

	music()
	FangsHeist.manageTreasures()
	FangsHeist.teleportSign()
	// dialogue.tick()

	local count = FangsHeist.playerCount()

	if count.alive == 0
	and FangsHeist.Net.escape then
		FangsHeist.startIntermission()
	end
end)

addHook("PostThinkFrame", do
	local p = displayplayer

	if multiplayer then return end
	if not (p and p.heist) then return end

	if (p.exiting or p.pflags & PF_FINISHED)
	and not p.heist.exiting then
		p.exiting = 0
		p.pflags = $ & ~(PF_FINISHED|PF_FULLSTASIS)
	end
end)