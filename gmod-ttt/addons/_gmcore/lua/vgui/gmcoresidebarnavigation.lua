---@class gmcoreSideBarNav : DIconLayout
local PANEL = {}

local SIDEBAR_ACTIVE_BG = Color(52, 152, 219, 25)
local SIDEBAR_HOVER_BG = Color(255, 255, 255, 8)

function PANEL:Init()
	self.TabPanelFuncs = {}
	self.CachedPanels = {}
	self.MainContainer = nil
	self.ActiveSideButton = nil
	self.SidebarIndicatorAnimStart = 0
	self.ActiveIndicatorYPos = 0
	self.ButtonFont = gmcore.Fonts:Get({
		font = "Space Grotesk",
		size = 18,
		weight = 600,
		antialias = true,
	})

	self:SetSpaceX(0)
	self:SetSpaceY(2)
end

function PANEL:SetTabContainer(panel)
	self.MainContainer = panel
end

function PANEL:SetButtonFont(fontName)
	self.ButtonFont = fontName
end

function PANEL:GetTabContainer()
	return self.MainContainer
end

function PANEL:AddTab(tabName, tabPanelFunc, showCondition, tabLabel)
	if showCondition and isfunction(showCondition) then
		local result = showCondition(LocalPlayer())
		if not result then return end
	end

	self.TabPanelFuncs[tabName] = tabPanelFunc

	local sideButton = self:Add("GmcoreButton")
	sideButton:SetText(tabLabel or tabName)
	sideButton:SetFont(self.ButtonFont)
	sideButton:SetSize(self:GetWide(), 44)
	sideButton:SetDrawBorder(false)
	sideButton:SetBackgroundColor(Color(0, 0, 0, 0))
	sideButton:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)

	sideButton.IsActiveTab = false

	sideButton.Paint = function(s, w, h)
		if s.IsActiveTab then
			draw.RoundedBox(6, 4, 2, w - 8, h - 4, SIDEBAR_ACTIVE_BG)
			s:SetTextColor(color_white)
		elseif s.Hovered then
			draw.RoundedBox(6, 4, 2, w - 8, h - 4, SIDEBAR_HOVER_BG)
			s:SetTextColor(CARD_TITLE_TEXT_COLOR)
		else
			s:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
		end
	end

	sideButton.DoClick = function(s)
		if self.ActiveSideButton == s then return end
		self:LoadTab(tabName, s)
	end

	if table.Count(self.TabPanelFuncs) <= 1 then
		self:LoadTab(tabName, sideButton)
	end

	return sideButton
end

function PANEL:LoadTab(tabName, tabBtn)
	for _, pnl in pairs(self.MainContainer:GetChildren()) do
		pnl:Hide()
	end

	-- Update active state on all buttons
	for _, btn in ipairs(self:GetChildren()) do
		if btn.IsActiveTab ~= nil then
			btn.IsActiveTab = (btn == tabBtn)
		end
	end

	if self.CachedPanels[tabName] then
		self.CachedPanels[tabName]:Show()
		self.ActiveSideButton = tabBtn
		self.SidebarIndicatorAnimStart = CurTime()
		return
	end

	local tabPanel = self.TabPanelFuncs[tabName](self.MainContainer)
	self.CachedPanels[tabName] = tabPanel

	self.ActiveSideButton = tabBtn
	self.SidebarIndicatorAnimStart = CurTime()
end

function PANEL:PaintOver()
	if self.ActiveSideButton then
		local frac = math.TimeFraction(self.SidebarIndicatorAnimStart, self.SidebarIndicatorAnimStart + 0.5, CurTime())
		self.ActiveIndicatorYPos = Lerp(math.ease.InOutQuart(frac), self.ActiveIndicatorYPos, self.ActiveSideButton.y)

		if (self.ActiveIndicatorYPos >= self.ActiveSideButton.y - 1) and (self.ActiveIndicatorYPos <= self.ActiveSideButton.y + 1) then
			self.ActiveIndicatorYPos = self.ActiveSideButton.y
		end

		-- Left accent bar
		draw.RoundedBox(2, 0, self.ActiveIndicatorYPos + 6, 3, self.ActiveSideButton:GetTall() - 12, PRIMARY_ACCENT_COLOR)
	end
end

function PANEL:Paint(w, h)
	draw.RoundedBox(0, 0, 0, w, h, FRAME_HEADER_COLOR)
end

function PANEL:SetActiveTab(tab)
	for _, pnl in pairs(self:GetChildren()) do
		if pnl:GetText() == tab then
			pnl:DoClick()
			return
		end
	end
end

derma.DefineControl("GmcoreSideBarNav", "Sidebar navigation for multiple panels", PANEL, "DIconLayout")
