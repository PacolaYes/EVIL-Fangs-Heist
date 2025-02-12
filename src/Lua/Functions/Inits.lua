local files = {}
// Used internally to get modules from the mod.
function FangsHeist.require(path)
	if not (files[path]) then
		files[path] = dofile(path)
	end

	return files[path]
end

local copy = FangsHeist.require "Modules/Libraries/copy"
local spawnpos = FangsHeist.require "Modules/Libraries/spawnpos"

local orig_net = FangsHeist.require "Modules/Variables/net"
local orig_save = FangsHeist.require "Modules/Variables/save"
local orig_plyr = FangsHeist.require "Modules/Variables/player"
local orig_hud = FangsHeist.require "Modules/Variables/hud"

// Initalize player.
function FangsHeist.initPlayer(p)
	p.heist = copy(orig_plyr)
	p.heist.spectator = FangsHeist.Net.escape
	p.heist.locked_skin = p.skin
	p.heist.team.players[p] = true
	p.heist.team.leader = p
end

function FangsHeist.initMode(map)
	FangsHeist.Net = copy(orig_net)
	FangsHeist.HUD = copy(orig_hud)

	FangsHeist.Net.gametype = tonumber(mapheaderinfo[map].fh_gametype) or 0
	FangsHeist.Net.is_boss = string.lower(mapheaderinfo[map].fh_boss or "") == "true"

	local info = mapheaderinfo[map]

	if info.fh_escapetheme then
		FangsHeist.Net.escape_theme = info.fh_escapetheme
	end
	if info.fh_escapehurryup then
		FangsHeist.Net.escape_hurryup = info.fh_escapehurryup:lower() == "true"
	end

	if info.fh_hellstage
	and info.fh_hellstage:lower() == "true" then
		FangsHeist.Net.hell_stage = true
	end

	if FangsHeist.Net.is_boss then
		FangsHeist.Net.time_left = ((2*60)*TICRATE)+(20*TICRATE)
		FangsHeist.Net.max_time_left = ((2*60)*TICRATE)+(20*TICRATE)
	end

	for p in players.iterate do
		p.camerascale = FU
		FangsHeist.initPlayer(p)
	end

	for _,obj in ipairs(FangsHeist.Objects) do
		local object = obj[2]

		if object.init then
			object.init()
		end
	end
end

local treasure_things = {
	[312] = true
}
local bean_things = {
	[402] = true,
	[408] = true,
	[409] = true
}

function FangsHeist.loadMap()
	FangsHeist.spawnSign()

	local exit
	local treasure_spawns = {}

	for thing in mapthings.iterate do
		if thing.mobj
		and thing.mobj.valid
		and (thing.mobj.type == MT_ATTRACT_BOX
		or thing.mobj.type == MT_1UP_BOX
		or thing.mobj.type == MT_INVULN_BOX
		or thing.mobj.type == MT_STARPOST) then
			P_RemoveMobj(thing.mobj)
		end

		if thing.type == 3844 then
			exit = thing
		end

		if thing.type == 3842 then
			FangsHeist.Net.hell_stage_teleport.pos = {
				x = thing.x*FU,
				y = thing.y*FU,
				z = spawnpos.getThingSpawnHeight(MT_PLAYER, thing, thing.x*FU, thing.y*FU),
				a = thing.angle*ANG1
			}
		end

		if thing.type == 3843 then
			FangsHeist.Net.hell_stage_teleport.sector = R_PointInSubsector(thing.x*FU, thing.y*FU).sector
		end

		if treasure_things[thing.type] then
			table.insert(treasure_spawns, {
				x = thing.x*FU,
				y = thing.y*FU,
				z = spawnpos.getThingSpawnHeight(MT_PLAYER, thing, thing.x*FU, thing.y*FU)
			})
		end

		if thing.type == 1
		and exit == nil then
			exit = thing
		end
	end

	if exit then
		local x = exit.x*FU
		local y = exit.y*FU
		local z = spawnpos.getThingSpawnHeight(MT_PLAYER, exit, x, y)
		local a = FixedAngle(exit.angle*FU)

		FangsHeist.defineExit(x, y, z, a)
	end

	for i = 1,5 do
		if not (#treasure_spawns) then
			break
		end

		local choice = P_RandomRange(1, #treasure_spawns)
		local thing = treasure_spawns[choice]

		FangsHeist.defineTreasure(thing.x, thing.y, thing.z)
		table.remove(treasure_spawns, choice)
	end
end