--[[
	TTT Extension for Pointshop by Peter Savarese (TrueKnife GMod)
	Description: Awards points to players for playing gamemode (Killing traitors, innocents as traitor, etc.)
]]

---@type number Accumulated reward points for the current batch display
local iTotalPoints = 0

---Begins a delayed total point count display after reward accumulation.
local function beginTotalPointCount() -- This is hacky I know
	if iTotalPoints > 0 then return end -- Don't run twice

	timer.Simple(1, function()
		HeaderMoneyFlow(iTotalPoints)
		iTotalPoints = 0
	end)
end

net.Receive("gmcore.PointShop.TTTRewardReceive", function()
	if !gmcore.PointFeed then return end

	local message = net.ReadString()
	local points = net.ReadInt(16)
	local small = net.ReadBool()

	beginTotalPointCount()
	iTotalPoints = iTotalPoints + points

	gmcore.PointFeed:AddPointNotification(message, points, small)
end)
