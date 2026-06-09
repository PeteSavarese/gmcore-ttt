---@class gmcoreButton : DLabel
local PANEL = {}

local FONT_BUTTON_TEXT = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 20,
	weight = 500,
})

AccessorFunc(PANEL, "m_bBorder", "DrawBorder", FORCE_BOOL)
AccessorFunc(PANEL, "m_Backgroundcolor", "BackgroundColor", FORCE_COLOR)

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
	self:SetTall(30)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self:SetCursor("hand")
	self:SetFont(FONT_BUTTON_TEXT)
	self:SetBackgroundColor(Color(255, 255, 255, 0))

	self.AlphaHover = 0

	-- Following is used for ripple click
	self.IsFirstDepression = false
	self.Radius, self.Alpha, self.ClickX, self.ClickY = 0, 0, 0, 0
	self.RippleClickColor = Color(230, 230, 230, 75)
	self.RippleclickSpeed = 5
end


---Allows different color from default white for ripple click
---@param color Color Color that self.RippleClickColor will be changed to
function PANEL:SetRippleClickColor(color)
	self.RippleClickColor = color
end

---Allows different speed from default speed of 5
---@param speed number Integer of speed that self.RippleclickSpeed will be changed to
function PANEL:SetRippleClickSpeed(speed)
	self.RippleclickSpeed = speed
end

---Whether button is currently in a clicked state
---@return boolean isDown True if the button is currently pressed
function PANEL:IsDown()
	return self.Depressed
end

---Sets image for button
---@param img string Image path to display on the button
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

	self.m_Image:SetImage(img)
	self.m_Image:SizeToContents()
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
	self.m_Image:SizeToContents()
	self:InvalidateLayout()
end

function PANEL:Paint(w, h)
	if not self:IsEnabled() then
		self:SetTextColor(BUTTON_DISABLED_TEXT_COLOR)
		draw.RoundedBox(8, 0, 0, w, h, BUTTON_DISABLED_COLOR)

		return
	end

	self:SetTextColor(color_white)

	if self:GetPaintBackground() then
		local bg = self:GetBackgroundColor()
		local isCta = not bg or bg.a == 0

		if isCta then
			surface.DrawRoundedGradient(0, 0, w, h, 8, BUTTON_CTA_GRADIENT_LEFT, BUTTON_CTA_GRADIENT_RIGHT)
		else
			draw.RoundedBox(8, 0, 0, w, h, bg)
		end

		if self:GetDrawBorder() then
			surface.SetDrawColor(FRAME_BORDER_COLOR)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		if self.Hovered then
			self.AlphaHover = Lerp(FrameTime() * 6, self.AlphaHover, 8)
		else
			self.AlphaHover = Lerp(FrameTime() * 6, self.AlphaHover, 0)
		end

		draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, self.AlphaHover))
	end
end

--[[
	Used for getting position of click on first depression and drawing ripple effect
]]
function PANEL:PaintOver(w, h)
	-- Will get our cursor pos on first click only
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

--[[
	Automatically apply padding
]]
function PANEL:SizeToText()
	self:SizeToContents()
	self:SetWide(self:GetWide() + 24)
	self:SetTall(self:GetTall() + 12)
end

function PANEL:PerformLayout(w, h)
	if IsValid(self.m_Image) then
		self.m_Image:SetPos(5, (self:GetTall() - self.m_Image:GetTall()) * 0.5)
	end

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

local PANEL = derma.DefineControl("GmcoreButton", "GL material button", PANEL, "DLabel")

PANEL = table.Copy(PANEL)

function PANEL:SetActionFunction(func)
	self.DoClick = function(self, val)
		func(self, "Command", 0, 0)
	end
end

function PANEL:GenerateExample( class, tabs, w, h )
end

derma.DefineControl( "Button", "Backwards Compatibility", PANEL, "DLabel" )
