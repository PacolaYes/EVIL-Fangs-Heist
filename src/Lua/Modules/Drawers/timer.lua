local module = {}

local orig_net = FangsHeist.require "Modules/Variables/net"
local text = FangsHeist.require "Modules/Libraries/text"

local APPEARANCE_TIME = 3*TICRATE

local x
local y
local alpha
local ticker
local took
local warning_active

function FangsHeist.doSignpostWarning(_took)
	took = (_took)
	ticker = 0
	alpha = 10
	warning_active = true
end

function module.init()
	y = 200*FU
	x = 160*FU
	alpha = 0
	ticker = 0
	took = false
	warning_active = false
end

function module.draw(v,p)
	local data = FangsHeist.getTypeData()

	if warning_active then
		ticker = $+1

		if ticker < APPEARANCE_TIME then
			alpha = max(0, $-1)
		else
			alpha = min($+1, 10)
			if alpha == 10 then
				warning_active = false
			end
		end

		local warning
		if not took then
			warning = v.cachePatch("FH_SIGNPOST_TAKEN")
		else
			warning = v.cachePatch("FH_TOOK_SIGNPOST")
		end

		local scale = FU/2

		if alpha ~= 10 then
			v.drawScaled(x-(warning.width*scale/2),
				y-2*FU-warning.height*scale,
				scale,
				warning,
				V_SNAPTOBOTTOM|(V_10TRANS*alpha))
		end
	end

	local bar = v.cachePatch"FH_BAR"
	local bar2 = v.cachePatch"FH_FULL_BAR"
	local time_scale = FixedDiv(FangsHeist.Net.max_time_left-FangsHeist.Net.time_left, FangsHeist.Net.max_time_left)
	local scale = FU*4/6

	local draw_x = x-(bar.width*scale/2)

	if (FangsHeist.Net.escape
	and not FangsHeist.isHurryUp())
	or FangsHeist.Net.is_boss then
		y = ease.linear(FU/6, $, 170*FU)
	end

	local objective = "Get the sign."
	if p and p.heist then
		local sign = false

		for p,_ in pairs(p.heist.team.players) do
			if p and p.heist then
				if FangsHeist.playerHasSign(p) then
					sign = true
					break
				end
			end
		end

		if sign then
			objective = "Get more Profit."
		end
	end
	if FangsHeist.Net.time_left <= 30*TICRATE then
		objective = "Get back to the door!"
	end

	v.drawString(x, y, "OBJECTIVE: "..objective, V_SNAPTOBOTTOM, "thin-fixed-center")

	v.drawScaled(draw_x, y+10*FU, scale, bar, V_SNAPTOBOTTOM)
	v.drawCropped(draw_x, y+10*FU, scale, scale,
		bar2,
		V_SNAPTOBOTTOM,
		nil,
		0, 0, bar2.width*time_scale, bar2.height*FU)

	local time = FangsHeist.Net.time_left
	local str = string.format("%02d:%02d", G_TicsToMinutes(time), G_TicsToSeconds(time))

	text.draw(v, x, y+10*FU, FixedMul(FixedDiv(21, 14), scale), str, "TMRFT", "center", V_SNAPTOBOTTOM)
end

return module