local FONT_FRAME_HEADER = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 32,
	weight = 600,
	antialias = true,
})

local FONT_CLOSE_BTN = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 22,
	weight = 500,
	antialias = true,
})

local HEADER_HEIGHT = 56
local CORNER_RADIUS = 10
local CLOSE_BTN_SIZE = 36

---@class gmcoreFrame : EditablePanel
---@field OnRemove fun(self: GLFrame)? Called by the engine just before the panel is removed from the hierarchy.
---@field OnClose  fun(self: GLFrame)? Called when the frame is closed (e.g. close button pressed).
local PANEL = {}

AccessorFunc(PANEL, "m_bIsMenuComponent", "IsMenu", FORCE_BOOL)
AccessorFunc(PANEL, "m_bDraggable", "Draggable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bSizable", "Sizable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bScreenLock", "ScreenLock", FORCE_BOOL)
AccessorFunc(PANEL, "m_bDeleteOnClose", "DeleteOnClose", FORCE_BOOL)
AccessorFunc(PANEL, "m_bPaintShadow", "PaintShadow", FORCE_BOOL)
AccessorFunc(PANEL, "m_iMinWidth", "MinWidth", FORCE_NUMBER)
AccessorFunc(PANEL, "m_iMinHeight", "MinHeight", FORCE_NUMBER)
AccessorFunc(PANEL, "m_bBackgroundBlur", "BackgroundBlur", FORCE_BOOL)
AccessorFunc(PANEL, "m_bFadeOnOpen", "FadeOnOpen", FORCE_BOOL)
AccessorFunc(PANEL, "m_bFadeOnRemove", "FadeOnRemove", FORCE_BOOL)

function PANEL:Init()
	self:SetFocusTopLevel(true)
	self:SetPaintShadow(true)
	self:SetFadeOnOpen(true)
	self:SetFadeOnRemove(true)

	self.CreateTime = CurTime()
	self.RemoveTime = 0

	self.btnClose = vgui.Create("DLabel", self)
	self.btnClose:SetSize(CLOSE_BTN_SIZE, CLOSE_BTN_SIZE)
	self.btnClose:SetText("\xE2\x9C\x95")
	self.btnClose:SetFont(FONT_CLOSE_BTN)
	self.btnClose:SetContentAlignment(5)
	self.btnClose:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
	self.btnClose:SetCursor("hand")
	self.btnClose:SetMouseInputEnabled(true)
	self.btnClose.AlphaHover = 0

	self.btnClose.Paint = function(s, w, h)
		if s.Hovered then
			s.AlphaHover = Lerp(FrameTime() * 8, s.AlphaHover, 1)
		else
			s.AlphaHover = Lerp(FrameTime() * 8, s.AlphaHover, 0)
		end

		local bgAlpha = Lerp(s.AlphaHover, 0, 25)
		local borderAlpha = Lerp(s.AlphaHover, 0, 120)

		draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, bgAlpha))

		if borderAlpha > 1 then
			surface.SetDrawColor(Color(52, 152, 219, borderAlpha))
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		s:SetTextColor(Color(
			Lerp(s.AlphaHover, BTN_UNFOCUSED_TEXT_COLOR.r, CARD_TITLE_TEXT_COLOR.r),
			Lerp(s.AlphaHover, BTN_UNFOCUSED_TEXT_COLOR.g, CARD_TITLE_TEXT_COLOR.g),
			Lerp(s.AlphaHover, BTN_UNFOCUSED_TEXT_COLOR.b, CARD_TITLE_TEXT_COLOR.b),
			255
		))
	end

	self.btnClose.OnMousePressed = function(s)
		self.RemoveTime = CurTime()
		self:SetMouseInputEnabled(false)
		self:OnRemoveClicked()
	end

	self.lblTitle = vgui.Create("DLabel", self)
	self.lblTitle:SetFont(FONT_FRAME_HEADER)
	self.lblTitle:SetTextColor(CARD_TITLE_TEXT_COLOR)

	self:SetDraggable(true)
	self:SetSizable(false)
	self:SetScreenLock(false)
	self:SetDeleteOnClose(true)
	self:SetTitle("Window")

	self:SetMinWidth(50)
	self:SetMinHeight(50)

	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)

	self:DockPadding(8, HEADER_HEIGHT + 8, 8, 8)
end

function PANEL:ShowCloseButton(bShow)
	self.btnClose:SetVisible(bShow)
end

function PANEL:GetTitle()
	return self.lblTitle:GetText()
end

function PANEL:SetTitle(strTitle)
	self.lblTitle:SetText(strTitle)
end

function PANEL:OnRemoveClicked(s)
end

function PANEL:SetFadeOnOpen(val)
	if val == true then
		self:SetAlpha(0)
	else
		self:SetAlpha(255)
	end

	self.m_bFadeOnOpen = val
end

function PANEL:Close()
	self:SetMouseInputEnabled(false)
	self.RemoveTime = CurTime()

	if not self:GetFadeOnRemove() then
		if self:GetDeleteOnClose() then
			self:Remove()
		else
			self:SetVisible(false)
		end
	end

	self:OnClose()
end

function PANEL:OnClose()
end

function PANEL:Center()
	self:InvalidateLayout(true)
	self:CenterVertical()
	self:CenterHorizontal()
end

function PANEL:IsActive()
	if self:HasFocus() then return true end
	if vgui.FocusedHasParent(self) then return true end

	return false
end

function PANEL:SetIcon(str)
	if not str and IsValid(self.imgIcon) then return self.imgIcon:Remove() end

	if not IsValid(self.imgIcon) then
		self.imgIcon = vgui.Create("DImage", self)
	end

	if IsValid(self.imgIcon) then
		self.imgIcon:SetMaterial(Material(str))
	end
end

function PANEL:Think()
	if self.RemoveTime == 0 and self:GetFadeOnOpen() then
		local frac = math.TimeFraction(self.CreateTime, self.CreateTime + 0.45, CurTime())
		self:SetAlpha(Lerp(math.ease.InOutQuart(frac), self:GetAlpha(), 255))
	elseif self.RemoveTime ~= 0 and self:GetFadeOnRemove() then
		if self:GetAlpha() == 0 then
			self:Remove()
		end

		local frac = math.TimeFraction(self.RemoveTime, self.RemoveTime + 0.45, CurTime())
		self:SetAlpha(Lerp(math.ease.InOutQuart(frac), self:GetAlpha(), 0))
	end

	local mousex = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
	local mousey = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

	if self.Dragging then
		local x = mousex - self.Dragging[1]
		local y = mousey - self.Dragging[2]

		if self:GetScreenLock() then
			x = math.Clamp(x, 0, ScrW() - self:GetWide())
			y = math.Clamp(y, 0, ScrH() - self:GetTall())
		end

		self:SetPos(x, y)
	end

	if self.Sizing then
		local x = mousex - self.Sizing[1]
		local y = mousey - self.Sizing[2]
		local px, py = self:GetPos()

		if x < self.m_iMinWidth then x = self.m_iMinWidth
		elseif (x > ScrW() - px and self:GetScreenLock()) then x = ScrW() - px end

		if y < self.m_iMinHeight then y = self.m_iMinHeight
		elseif (y > ScrH() - py and self:GetScreenLock()) then y = ScrH() - py end

		self:SetSize(x, y)
		self:SetCursor("sizenwse")
		return
	end

	local screenX, screenY = self:LocalToScreen(0, 0)

	if (self.Hovered and self.m_bSizable and mousex > (screenX + self:GetWide() - 20) and mousey > (screenY + self:GetTall() - 20)) then
		self:SetCursor("sizenwse")
		return
	end

	if (self.Hovered and self:GetDraggable() and mousey < (screenY + 24)) then
		self:SetCursor("sizeall")
		return
	end

	self:SetCursor("arrow")

	if self.y < 0 then
		self:SetPos(self.x, 0)
	end
end

function PANEL:Paint(w, h)
	if self.m_bBackgroundBlur then
		Derma_DrawBackgroundBlur(self, self.m_fCreateTime)
	end

	-- Drop shadow
	if self:GetPaintShadow() then
		local posX, posY = self:GetPos()
		DisableClipping(true)
			BSHADOWS.BeginShadow()
				draw.RoundedBox(CORNER_RADIUS, posX, posY, w, h, FRAME_BACKGROUND_COLOR)
			BSHADOWS.EndShadow(1, 2, 2)
		DisableClipping(false)
	end

	-- Outer border ring drawn first so everything paints on top of it
	draw.RoundedBox(CORNER_RADIUS, 0, 0, w, h, FRAME_BORDER_COLOR)

	-- Main background inset 1px inside border ring
	draw.RoundedBox(CORNER_RADIUS, 1, 1, w - 2, h - 2, FRAME_BACKGROUND_COLOR)

	-- Header background inset 1px from sides and top
	draw.RoundedBoxEx(CORNER_RADIUS, 1, 1, w - 2, HEADER_HEIGHT - 1, FRAME_HEADER_COLOR, true, true, false, false)
end

function PANEL:OnMousePressed()
	local screenX, screenY = self:LocalToScreen(0, 0)

	if (self.m_bSizable and gui.MouseX() > (screenX + self:GetWide() - 20) and gui.MouseY() > (screenY + self:GetTall() - 20)) then
		self.Sizing = {gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall()}
		self:MouseCapture(true)
		return
	end

	if (self:GetDraggable() and gui.MouseY() < (screenY + 24)) then
		self.Dragging = {gui.MouseX() - self.x, gui.MouseY() - self.y}
		self:MouseCapture(true)
		return
	end
end

function PANEL:OnMouseReleased()
	self.Dragging = nil
	self.Sizing = nil
	self:MouseCapture(false)
end

function PANEL:PerformLayout()
	local titlePush = 0

	if IsValid(self.imgIcon) then
		self.imgIcon:SetPos(14, (HEADER_HEIGHT - 20) / 2)
		self.imgIcon:SetSize(20, 20)
		titlePush = 28
	end

	self.btnClose:SetPos(self:GetWide() - CLOSE_BTN_SIZE - 10, (HEADER_HEIGHT - CLOSE_BTN_SIZE) / 2)

	self.lblTitle:SetPos(14 + titlePush, (HEADER_HEIGHT - self.lblTitle:GetTall()) / 2)
	self.lblTitle:SizeToContents()
end

derma.DefineControl("GmcoreFrame", "A simple window", PANEL, "EditablePanel")
