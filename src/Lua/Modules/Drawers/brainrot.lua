local module = {}
local text = FangsHeist.require"Modules/Libraries/text"

local time = 0
local subwayPos = 0
function module.init()
	time = 0
	subwayPos = 0
end

function module.draw(v,p)
	time = $+1
	
	subwayPos = pos%5 and $ or $+1
	--if pos%5 == 0 then subwayPos = $+1 end
	if subwayPos > 1724 then
		subwayPos = $-1724
	end
	v.draw(320-113, 0, v.cachePatch("SURFERS"+subwayPos), V_SNAPTORIGHT|V_PERPLAYER)
end

return module