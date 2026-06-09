local EVENT = gmcore.FunRounds.RegisteredFunRounds["Valentine"]

local teams -- Set once we receive 'sgm.funround.valentine.SendTeams' net msg
local iOurTeamId -- Set once we receive 'sgm.funround.valentine.SendTeams' net msg
local tOurEnemyTeam -- Set once we recive 'sgm.funround.valentine.SendEnemyTeams'

--[[function EVENT:DisplayWinners(tWinners, panel)
	local tLastTeamStanding = tWinners.lastTeamStanding
	local tMostKillsTeam = tWinners.teamMostKills
	local iTeamMostKillsCount = tWinners.iMostKillsCount

	local sImageLastTeamStanding = "icon16/heart.png"
	local sImageTeamMostKills = "icon16/gun.png"

	self.rewardsPanel = vgui.Create("DPanel")
	self.rewardsPanel:SetSize(ScrW(), ScrH()) -- Doesn't matter, just give me a blank canvas to draw on
	self.rewardsPanel:Center()
	self.rewardsPanel.Paint = function() end -- No background please.

	local sLastTeamNicks = "";
	local sMostKillsTeamNicks = "";

	for k, ply in ipairs(tLastTeamStanding.players) do
		sLastTeamNicks = sLastTeamNicks .. ply:Nick() .. " "

		-- second to last value
		if !tLastTeamStanding.players[k + 2] and tLastTeamStanding.players[k + 1] then
			sLastTeamNicks = sLastTeamNicks .. "and "
		end
	end

	for k, ply in ipairs(tMostKillsTeam.players) do
		sMostKillsTeamNicks = sMostKillsTeamNicks .. ply:Nick() .. " "

		-- second to last value
		if !tMostKillsTeam.players[k + 2] and tMostKillsTeam.players[k + 1] then
			sMostKillsTeamNicks = sMostKillsTeamNicks .. "and "
		end
	end

	local lastTeamNicks = vgui.Create("DLabel", self.rewardsPanel)
	lastTeamNicks:SetFont("gmcore.FunRounds.Description")
	lastTeamNicks:SetText("(" .. self.Rewards.iLastStandingTeam .. " pts) Last Team Standing: " .. sLastTeamNicks)
	lastTeamNicks:SizeToContents()
	lastTeamNicks:SetPos(ScrW() / 2 - lastTeamNicks:GetWide() / 2, ScrH() / 2 - lastTeamNicks:GetTall() / 2)

	local lastTeamIcon = vgui.Create("DImage", self.rewardsPanel)
	lastTeamIcon:SetMaterial(sImageLastTeamStanding)
	lastTeamIcon:SetSize(48, 48)
	lastTeamIcon:SetPos(ScrW() / 2 - lastTeamNicks:GetWide() / 2 - 58, ScrH() / 2 - 48 / 2)

	local mostKillsNick = vgui.Create("DLabel", self.rewardsPanel)
	mostKillsNick:SetFont("gmcore.FunRounds.Description")
	mostKillsNick:SetText("(" .. self.Rewards.iMostKills .. " pts w/ " .. iTeamMostKillsCount .. " kills) Team with Most Kills: " .. sMostKillsTeamNicks)
	mostKillsNick:SizeToContents()
	mostKillsNick:SetPos(ScrW() / 2 - lastTeamNicks:GetWide() / 2, (ScrH() / 2 - lastTeamNicks:GetTall() / 2) + lastTeamIcon:GetTall() + 10) -- Take largest element and add 10px of padding

	local teamMostKills = vgui.Create("DImage", self.rewardsPanel)
	teamMostKills:SetMaterial(sImageTeamMostKills)
	teamMostKills:SetSize(48, 48)
	teamMostKills:SetPos(ScrW() / 2 - lastTeamNicks:GetWide() / 2 - 58, (ScrH() / 2 - 48 / 2) + lastTeamIcon:GetTall() + 10)
end--]]

function EVENT:GetWinnerPanels(tWinners)
	local winners = {}

	local tLastTeamStanding = tWinners.lastTeamStanding
	local tMostKillsTeam = tWinners.teamMostKills
	local iTeamMostKillsCount = tWinners.iMostKillsCount

	local sImageLastTeamStanding = "icon16/heart.png"
	local sImageTeamMostKills = "icon16/gun.png"

	-- (2) Create panels for each winner.
	---------------------------------------------------------
	local lastAlive = vgui.Create("GmcoreFunRoundWinner")
	lastAlive:SetWinner({
		text = string.format("Last Team Standing"),
		name = "Team Name",
		image = sImageLastTeamStanding
	})
	table.insert(winners, lastAlive)
	---------------------------------------------------------

	---------------------------------------------------------
	local mostKills = vgui.Create("GmcoreFunRoundWinner")
	mostKills:SetWinner({
		text = string.format("Team Most Kills"),
		name = "Team Name",
		image = sImageTeamMostKills
	})
	table.insert(winners, mostKills)
	---------------------------------------------------------

	return winners
end

function EVENT:RemoveWinners()
	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:Remove()
		gmcore.FunRounds.funRoundWinnersPnl = nil
	end
end

function EVENT:InitTeams(tTeams)
	teams = tTeams

	for teamId, team in ipairs(teams) do
		if table.HasValue(team.players, LocalPlayer()) then
			iOurTeamId = teamId

			break;
		end
	end

	self:AddHook("PostDrawTranslucentRenderables", self.DrawLovers)
end

local heartIcon = Material("icon16/heart.png")

function EVENT:DrawLovers()
	for _, ply in ipairs(teams[iOurTeamId].players) do
		if ply == LocalPlayer() then continue end -- Don't draw us

		if IsValid(ply) and ply:Alive() then
			local dir = LocalPlayer():GetForward() * -1
			local pos = ply:GetPos()

			pos.z = pos.z + 74

			render.SetMaterial(heartIcon)

			cam.IgnoreZ(true)
				render.DrawQuadEasy(pos, dir, 16, 16, color_white, 180)
			cam.IgnoreZ(false)
		end
	end
end

function EVENT:RefreshOurEnemyTeam(teamToEnemys)
	local iOurEnemyTeam = teamToEnemys[iOurTeamId] -- The value is our enemy team
	tOurEnemyTeam = teams[iOurEnemyTeam]

	self:AddHook("PostDrawTranslucentRenderables", self.DrawEnemyTeamMembers)
end

local enemyHeadIcon = Material("icon16/find.png")

function EVENT:DrawEnemyTeamMembers()
	if !tOurEnemyTeam then return end

	for _, ply in ipairs(tOurEnemyTeam.players) do
		if ply == LocalPlayer() then continue end -- Don't draw us

		if IsValid(ply) and ply:Alive() then
			local dir = LocalPlayer():GetForward() * -1
			local pos = ply:GetPos()

			pos.z = pos.z + 74

			render.SetMaterial(enemyHeadIcon)

			cam.IgnoreZ(true)
				render.DrawQuadEasy(pos, dir, 16, 16, color_white, 180)
			cam.IgnoreZ(false)
		end
	end
end

net.Receive("sgm.funround.valentine.SendTeams", function()
	EVENT:InitTeams(net.ReadTable())
end)

net.Receive("sgm.funround.valentine.SendEnemyTeams", function()
	EVENT:RefreshOurEnemyTeam(net.ReadTable())
end)

gmcore.FunRounds:RegisterFunRound("Valentine", EVENT)
