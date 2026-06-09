---@class gmcoreStackedIconButton : DLabel
local PANEL = {}

local FONT_BUTTON_TEXT = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 20,
	weight = 400,
})

AccessorFunc(PANEL, "m_bBorder", "DrawBorder", FORCE_BOOL)
AccessorFunc(PANEL, "m_Backgroundcolor", "BackgroundColor", FORCE_COLOR)
AccessorFunc(PANEL, "m_bActiveButton", "ActiveButton")

local function drawCircle(x, y, r)
	local circle = {}

	for i = 1, 360 do
		circle[i] = {}
		circle[i].x = x + math.cos(math.rad(i * 360) / 360) * r
		circle[i].y = y + math.sin(math.rad(i * 360) / 360) * r
	end

	surface.DrawPoly(circle)
end

function PANEL:Init()
	self:SetContentAlignment(5)
	self:SetDrawBorder(true)
	self:SetPaintBackground(true)
	self:SetTall(22)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self:SetCursor("hand")
	self:SetFont(FONT_BUTTON_TEXT)
	self:SetBackgroundColor(Color(255, 255, 255, 0))
	self:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
	self.AlphaHover = 0
	self.ActiveAccent = 0

	self.IsFirstDepression = false
	self.Radius, self.Alpha, self.ClickX, self.ClickY = 0, 0, 0, 0
	self.RippleClickColor = Color(230, 230, 230, 75)
	self.RippleclickSpeed = 5
end

function PANEL:SetRippleClickColor(color)
	self.RippleClickColor = color
end

function PANEL:SetRippleClickSpeed(speed)
	self.RippleclickSpeed = speed
end

function PANEL:IsDown()
	return self.Depressed
end

function PANEL:SetImage(img)
	if not img then
		if IsValid(self.m_Image) then
			self.m_Image:Remove()
		end
		return
	end

	if not IsValid(self.m_Image) then
		self.m_Image = vgui.Create("DImage", self)
	end

	self.m_Image.Material = Material(img, "mips smooth")
	self.m_Image:SetSize(22, 20)
	self.m_Image.Paint = function(s, w, h)
		surface.SetMaterial(s.Material)
		surface.SetDrawColor(Color(147, 160, 190))
		surface.DrawTexturedRect(0, 0, w, h)
	end

	self:InvalidateLayout()
end

PANEL.SetIcon = PANEL.SetImage

function PANEL:SetMaterial(mat)
	if not mat then
		if IsValid(self.m_Image) then
			self.m_Image:Remove()
		end
		return
	end

	if not IsValid(self.m_Image) then
		self.m_Image = vgui.Create("DImage", self)
	end

	self.m_Image:SetMaterial(mat)
	self.m_Image:SetSize(22, 20)
	self:InvalidateLayout()
end

function PANEL:Paint(w, h)
	if self:GetDisabled() then
		self:SetTextColor(BUTTON_DISABLED_TEXT_COLOR)
		draw.RoundedBox(8, 0, 0, w, h, BUTTON_DISABLED_COLOR)
		return
	end

	self:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
	if IsValid(self.m_Image) then
		self.m_Image:SetImageColor(BTN_UNFOCUSED_TEXT_COLOR)
	end

	if self:GetActiveButton() then
		self:SetTextColor(color_white)
		if IsValid(self.m_Image) then
			self.m_Image:SetImageColor(color_white)
		end

		self.ActiveAccent = math.Approach(self.ActiveAccent, w, 1000 * FrameTime())

		surface.SetDrawColor(PRIMARY_ACCENT_COLOR)
		surface.DrawRect(w / 2 - self.ActiveAccent / 2, h - 3, self.ActiveAccent, 3)
	else
		self.ActiveAccent = math.Approach(self.ActiveAccent, 0, 1000 * FrameTime())
	end

	local bg = self:GetBackgroundColor()
	if not bg or bg.a == 0 then
		bg = CARD_BACKGROUND_COLOR
	end

	local parent = self:GetParent()
	if not IsValid(parent) or parent == vgui.GetWorldPanel() then
		draw.RoundedBox(8, 0, 0, w, h, CARD_BORDER_COLOR)
		draw.RoundedBox(8, 1, 1, w - 2, h - 2, bg)
	else
		draw.RoundedBox(8, 0, 0, w, h, bg)
	end

	if self.Hovered then
		self.AlphaHover = Lerp(FrameTime() * 6, self.AlphaHover, 8)
	else
		self.AlphaHover = Lerp(FrameTime() * 6, self.AlphaHover, 0)
	end

	draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, self.AlphaHover))
end

function PANEL:PaintOver(w, h)
	if self:IsDown() and not self.IsFirstDepression then
		self.IsFirstDepression = true
		self.ClickX, self.ClickY = self:CursorPos()
		self.Radius = 0
		self.Alpha = self.RippleClickColor.a
	elseif not self:IsDown() and self.IsFirstDepression then
		self.IsFirstDepression = false
	end

	if self.Alpha >= 1 then
		surface.SetDrawColor(ColorAlpha(self.RippleClickColor, self.Alpha))
		draw.NoTexture()
		drawCircle(self.ClickX, self.ClickY, self.Radius)
		self.Radius = Lerp(FrameTime() * self.RippleclickSpeed, self.Radius, w)

		if not self:IsDown() then
			self.Alpha = Lerp(FrameTime() * self.RippleclickSpeed, self.Alpha, 0)
		end
	end
end

function PANEL:SizeToText()
	self:SizeToContents()
	self:SetWide(self:GetWide() + 20)
	self:SetTall(self:GetTall() + 10)
end

function PANEL:PerformLayout(w, h)
	if IsValid(self.m_Image) then
		self.m_Image:SetPos(self:GetWide() / 2 - self.m_Image:GetWide() / 2, 10)
	end

	self:SetTextInset(0, 10)
	DLabel.PerformLayout(self, w, h)
end

function PANEL:SetConsoleCommand(strName, strArgs)
	self.DoClick = function(self, val)
		RunConsoleCommand(strName, strArgs)
	end
end

function PANEL:SizeToContents()
	local w, h = self:GetContentSize()
	self:SetSize(w + 8, h + 4)
end

function PANEL:GenerateExample(ClassName, PropertySheet, Width, Height)
	local ctrl = vgui.Create(ClassName)
	ctrl:SetText("Example Button")
	ctrl:SetWide(200)
	PropertySheet:AddSheet(ClassName, ctrl, nil, true, true)
end

local PANEL = derma.DefineControl("GmcoreStackedIconButton", "GL material button", PANEL, "DLabel")
