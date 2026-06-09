--[[
	I ripped this from Pointshop 2
--]]

surface.CreateFont("gmcore.PointFeed.SmallHeader", {
	font = "Segoe UI 8",
	size = 24
})

surface.CreateFont("gmcore.PointFeed.Normal", {
	font = "Segoe UI Semilight 8",
	size = 20
})

surface.CreateFont("gmcore.PointFeed.TabLarge", {
	font = "Segoe UI 8",
	size = 28
})

surface.CreateFont("gmcore.PointFeed.MoneyFlow", {
	font = "Segoe UI 8",
	size = 28
})


surface.CreateFont("gmcore.PointFeed.MoneyFlowPointCount", {
	font = "Segoe UI Semilight 8",
	size = 28
})

local function createPointFeed()
	if IsValid(GAMEMODE.PS_PF) then
		GAMEMODE.PS_PF:Remove() -- for reloads
	end

	gmcore.PointFeed = vgui.Create("DPointFeed")
	gmcore.PointFeed:SetSize(ScrW() / 3, ScrH() / 5)
	gmcore.PointFeed:ParentToHUD()
	gmcore.PointFeed:SetPos(ScrW() / 2 - gmcore.PointFeed:GetWide() / 2, ScrH() - gmcore.PointFeed:GetTall() - 20)
	GAMEMODE.PS_PF = gmcore.PointFeed
end

local PANEL = {}

function PANEL:Init( )
	self.panelsWaiting = {}
	self.panels = {}
	self.scrollingPanel = nil

	self.spaceY = 2
	self.fadeDuration = 0.3
	self.maxPanels = 5

	self.notificationsPanel = vgui.Create("DPanel", self)
	self.notificationsPanel:Dock(FILL)
	self.notificationsPanel.Paint = function() end

	self.totalScorePanel = vgui.Create("DLabel", self)
	self.totalScorePanel:Dock(RIGHT)
	self.totalScorePanel:SetWide(100)
	self.totalScorePanel:DockMargin(15, 0, 0, 0)
	self.totalScorePanel:SetFont("gmcore.PointFeed.TabLarge")
	self.totalScorePanel:SetContentAlignment(7)
	self.totalScorePanel:SetColor(color_white)
	self.totalScorePanel:SetAlpha(0)

	self.scoreAnim = Derma_Anim("Anim", self, function(self, anim, delta, data)
		if anim.Finished then
			if data.To == 0 then
				self.accumulatedPoints = 0
				self.totalScorePanel:SetText(self.accumulatedPoints)
			end

			return
		end

		self.totalScorePanel:SetAlpha(Lerp(delta, data.From, data.To))
	end)

	self.accumulatedPoints = 0
	self.lastPointAdd = 0
end

function PANEL:PointsAdded(points)
	self.accumulatedPoints = self.accumulatedPoints + points
	self.lastPointAdd = RealTime()
	self.totalScorePanel:SetText(self.accumulatedPoints)

	self.scoreAnim:Start(0.3, {
		From = self.totalScorePanel:GetAlpha(),
		To = 255
	})
end
function PANEL:Think()
	if #self.panelsWaiting > 0 and #self.panels < self.maxPanels and not IsValid(self.scrollingPanel) then
		self.scrollingPanel = table.remove(self.panelsWaiting, 1) -- POP
		self:StartScrollingPanel()
	end

	self:InvalidateLayout()
	self.scoreAnim:Run()

	if self.lastPointAdd + 3 < RealTime() and #self.panels == 0 then
		if not self.scoreAnim:Active() then
			self.scoreAnim:Start(0.3, {
				From = self.totalScorePanel:GetAlpha(),
				To = 0
			})
		end
	end
end

function PANEL:StartScrollingPanel()
	local panel = self.scrollingPanel
	panel:SetVisible(true)
	panel:SetParent(self.notificationsPanel)
	panel:SetPos(0, -panel:GetTall())
	panel:SetWide(self.notificationsPanel:GetWide())
	local amountToScroll = -panel:GetTall()

	tween(easing.inQuad, self.fadeDuration, function(progress)
		panel:SetPos(0, amountToScroll * (1 - progress))
		panel:SetAlpha(255 * progress)
	end):Done(function()
		table.insert(self.panels, 1, panel) --Enqueue
		self.scrollingPanel = nil

		--Fade out when lifetime expired
		timer.Simple(panel._scrollLifetime, function()
			local size = panel:GetTall()

			tween(easing.outQuad, self.fadeDuration, function(progress)
				panel:SetAlpha(255 * (1 - progress))
				panel:SetTall(size * (1 - progress))
			end):Done(function()
				panel:Remove()

				for k, v in pairs(self.panels) do
					if v == panel then
						self.panels[k] = nil
					end
				end
			end)
		end)
	end)
end

function PANEL:PerformLayout()
	local yPos = 0

	if IsValid(self.scrollingPanel) then
		local x, y = self.scrollingPanel:GetPos()
		yPos = y + self.scrollingPanel:GetTall()
	end

	for k, panel in pairs(self.panels) do
		local x, y = panel:GetPos()
		panel:SetPos(x, yPos)
		yPos = yPos + self.spaceY + panel:GetTall()
	end
end

function PANEL:AddNotify(pnl, lifetime)
	lifetime = lifetime or 3
	pnl._scrollLifetime = lifetime
	pnl:SetVisible(false)
	table.insert(self.panelsWaiting, pnl)
end

function PANEL:AddPointNotification(text, points, small)
	local panel = vgui.Create("DLabel")

	local message = string.upper(text) .. " " .. points

	if points > 0 then
		message = string.upper(text) .. " +" .. points
	end

	panel:SetText(message)
	panel:SetContentAlignment(6)

	if small then
		panel:SetFont("gmcore.PointFeed.Normal")
	else
		panel:SetFont("gmcore.PointFeed.SmallHeader")
	end

	panel:SizeToContents()
	panel:SetColor(color_white)

	self:AddNotify(panel)
	self:PointsAdded(points)
end

function PANEL:Paint(w, h)

end

vgui.Register("DPointFeed", PANEL, "DPanel")

local bIsActiveMoneyFlow = false -- Is the full animation currently active?

function HeaderMoneyFlow(points)
	if points == 0 then return end
	if bIsActiveMoneyFlow then return end -- TODO: Hacky fix to prevent ghosted money until I can get two animations to stack their points and just create extra money images to flow over

	local bOverrideAnimationCancel = false -- Incase we bug out with 0 points and cancel anim, this stops the fading transition on a nil panel
	local iPointsByTen = math.ceil(points / 10) -- Have cash icon represent
	local imageRepresentations = {} -- Table which refrences all DImages created of money
	local iMoneyPosX, iPosY = ScrW() / 2 - 250, ScrH() * 0.10
	local iItterateCount = 1 -- Used for moving each money with delay inbetween
	local fTimeBetweenFlow = 0.5 -- If there are more than 4 money icons and it takes more than 2 seconds for all money to flow, reduce it so entire animation is no longer than 2 seconds.
	local walletImage
	local totalPointsCount = 0 -- Used for counting the points up on right side of wallet

	for i = 1, iPointsByTen do
		local iAddSubX, iAddSubY

		-- Make money like a "stack" make a circle of cash
		if math.random(0, 1) == 1 then
			iAddSubX = math.random(1, 5) -- Add to X-pos

			if math.random(0, 1) == 1 then -- Add to Y-pos
				iAddSubY = math.random(1, 5)
			else
				iAddSubY = -math.random(1, 5) -- Sub to Y-pos
			end
		else
			iAddSubX = -math.random(1, 5)

			if math.random(0, 1) == 1 then -- Add to Y-pos
				iAddSubY = -math.random(1, 5)
			else
				iAddSubY = math.random(1, 5) -- Sub to Y-pos
			end
		end

		imageRepresentations[i] = vgui.Create("DImage")
		imageRepresentations[i]:SetSize(16, 16)
		imageRepresentations[i]:SetPos(iMoneyPosX + iAddSubX, iPosY + iAddSubY)
		imageRepresentations[i]:SetImage("icon16/money.png")
	end

	if #imageRepresentations * fTimeBetweenFlow > 2 then
		fTimeBetweenFlow = 2 / #imageRepresentations -- Set so animation is no longer than 2 seconds
	end

	local pointsEarned = vgui.Create("DLabel")
	pointsEarned:SetFont("gmcore.PointFeed.MoneyFlow")
	pointsEarned:SetText("Points Earned This Round:")
	pointsEarned:SizeToContents()
	pointsEarned:SetPos(iMoneyPosX, iPosY - 32)
	pointsEarned:SetColor(color_white)

	local pointsCount = vgui.Create("DLabel")
	pointsCount:SetFont("gmcore.PointFeed.MoneyFlowPointCount")
	pointsCount:SetText("0")
	pointsCount:SizeToContents()
	pointsCount:SetContentAlignment(6)
	pointsCount:SetPos(ScrW() / 2 + 250, iPosY - 32)
	pointsCount:SetColor(color_white)

	bIsActiveMoneyFlow = true

	timer.Create("gmcore.MoneyFlowHeader.MoneyImageItteration", fTimeBetweenFlow, 0, function()
		local iCurImage = iItterateCount -- We have to do this since the ease function will try refrencing an image after iItterateCount has been incremented

		if imageRepresentations[iCurImage] == nil then
			timer.Simple(2.5, function() -- Let user review their points earned
				if bOverrideAnimationCancel then return end -- Somethign went wrong and had 0 points supplied

				timer.Remove("gmcore.MoneyFlowHeader.MoneyImageItteration")

				walletImage:AlphaTo(0, 1, 0)
				pointsEarned:AlphaTo(0, 1, 0)
				pointsCount:AlphaTo(0, 1, 0, function()
					bIsActiveMoneyFlow = false
				end)

				timer.Simple(4, function() -- Since AlphaTo is stupid and attempts to lerp after the TransitionFinished function runs and removes the panel
					walletImage:Remove()
					pointsEarned:Remove()
					pointsCount:Remove()
				end)
			end)

			return false
		end

		gmcore:ChangeEoRVolume(0.25)

		imageRepresentations[iCurImage]:MoveTo(ScrW() / 2 + 250, iPosY, fTimeBetweenFlow, 0, 0.5, function()
			surface.PlaySound("gmcore/ui/points.mp3")
			imageRepresentations[iCurImage]:Remove()
		end)

		iItterateCount = iItterateCount + 1

		if imageRepresentations[iItterateCount] == nil and points / 10 ~= math.floor(points / 10) then -- Check if we earned base 10 points or not. Points after rounds are only x5 or x0, never x(0-9)			totalPointsCount = totalPointsCount + 5
			totalPointsCount = totalPointsCount + math.abs(math.floor(points / 10) * 10 - points) -- Ceil points to nearest 10th then substract points awarded to get difference
		else
			totalPointsCount = totalPointsCount + 10
		end

		pointsCount:SetText(totalPointsCount)
		pointsCount:SizeToContents()
	end)

	walletImage = vgui.Create("DImage")
	walletImage:SetSize(32, 32)
	walletImage:SetPos(ScrW() / 2 + 250, iPosY - 16 / 2) -- 16/2 to put in middle of money
	walletImage:SetImage("gmcore/ui/wallet.png")

	timer.Simple(5, function()
		if tonumber(pointsCount:GetText()) then -- Extra check incase we bug out
			bOverrideAnimationCancel = true

			walletImage:AlphaTo(0, 1, 0)
			pointsEarned:AlphaTo(0, 1, 0)
			pointsCount:AlphaTo(0, 1, 0)

			gmcore:ChangeEoRVolume(GetConVar("gl_music_volume"):GetFloat()) -- Return to their prefered volume

			timer.Simple(4, function() -- Since AlphaTo is stupid and attempts to lerp after the TransitionFinished function runs and removes the panel
				walletImage:Remove()
				pointsEarned:Remove()
				pointsCount:Remove()
			end)
		end
	end)
end

hook.Add("InitPostEntity", "AddPointFeed", function()
	createPointFeed()
end)
