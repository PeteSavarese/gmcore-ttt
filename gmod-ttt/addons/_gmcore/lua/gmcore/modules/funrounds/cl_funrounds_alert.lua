---@type Panel|nil
gmcore.FunRounds.funRoundAlertPnl = gmcore.FunRounds.funRoundAlertPnl or nil
---@type Panel|nil
gmcore.FunRounds.funRoundWinnersPnl = gmcore.FunRounds.funRoundAlertPnl or nil

---Creates and displays the fun round alert panel for the active round.
function gmcore.FunRounds:DrawActiveRoundInfo()
	if !gmcore.FunRounds.ActiveRound then
		error("Attempted to draw fun round alert panel while there is no active Fun Round.")
	end

	if IsValid(gmcore.FunRounds.funRoundAlertPnl) then
		gmcore.FunRounds.funRoundAlertPnl:Remove()
	end

	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:Remove()
		gmcore.FunRounds.funRoundWinnersPnl = nil
	end

	local funRoundAlertPnl = vgui.Create("GmcoreFunRoundAlert")
	funRoundAlertPnl:SetSize(0, 0)
	funRoundAlertPnl:Center()
	funRoundAlertPnl:SetFunRound(gmcore.FunRounds.ChosenFunRound)
	gmcore.FunRounds.funRoundAlertPnl = funRoundAlertPnl
end

---@type IMaterial
local grad = Material("gui/center_gradient")
---Displays winners panel and prepares winner cards for the alert.
---@param winnersTbl table List of winning players to display on the alert
function gmcore.FunRounds:DisplayWinners(winnersTbl)
	if not IsValid(gmcore.FunRounds.funRoundAlertPnl) then return end
	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:Remove()
	end

	local rnd = gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.CurrentlyActiveRound]
	if not rnd then return end

	local pnl = vgui.Create("DPanel")
	gmcore.FunRounds.funRoundWinnersPnl = pnl

	gmcore.FunRounds.funRoundAlertPnl:DisplayWinners(winnersTbl, pnl)

	local winners = rnd:GetWinnerPanels(winnersTbl)
	local num_winners = #winners
	local tw = 240 * num_winners + (num_winners * 12)

	pnl:SetSize(tw, 240)
	pnl.Paint = function(self, w, h)
		local old = DisableClipping(true)

		surface.SetMaterial(grad)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawTexturedRect(-150, 0, w + 300, h)

		DisableClipping(old)
	end

	pnl:SetAlpha(0)
	pnl:Center()

	local grid = vgui.Create("GmcoreCenteredGrid", pnl)
	grid:SetChildWidth(240)
	grid:SetChildHeight(240)
	grid:Dock(FILL)
	pnl.grid = grid

	for i, winner in ipairs(winners) do
		grid:Add(winner)
	end
end

---Shows the winners panel with a fade-in animation.
function gmcore.FunRounds:ShowWinners()
	if not IsValid(gmcore.FunRounds.funRoundAlertPnl) then return end
	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:AlphaTo(255, 0.5, 0)

		local childs = gmcore.FunRounds.funRoundWinnersPnl.grid:GetChildren()
		local fadeDelay = 0.75

		for i, win in ipairs(childs) do
			win:DoFadeIn(fadeDelay * i)
		end
	end
end

hook.Add("TTTPrepareRound", "gmcore.FunRounds.RemoveInfoPanel", function()
	if IsValid(gmcore.FunRounds.funRoundAlertPnl) then
		gmcore.FunRounds.funRoundAlertPnl:Remove()
		gmcore.FunRounds.funRoundAlertPnl = nil
		-- comment this hook if you are in debug mode or you will pull your hair out.
		-- because things will not get removed after the first fun round
		hook.Remove("TTTPrepareRound", "gmcore.FunRounds.RemoveInfoPanel")
	end

	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:Remove()
		gmcore.FunRounds.funRoundWinnersPnl = nil
	end

end)

hook.Add("TTTBeginRound", "gmcore.FunRounds.UpdateAlertState", function()
	if IsValid(gmcore.FunRounds.funRoundAlertPnl) then
		gmcore.FunRounds.funRoundAlertPnl:UpdateAlertPanelState("MinimizedTitle")
	end
end)

net.Receive("gmcore.FunRounds.SendWinners", function()
	local winnersTbl = net.ReadTable()

	gmcore.FunRounds:DisplayWinners(winnersTbl)
end)
