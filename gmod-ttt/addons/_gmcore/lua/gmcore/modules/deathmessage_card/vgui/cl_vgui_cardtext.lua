surface.CreateFont("BebasNeue", {
	font = "Bebas Neue",
	size = 30,
	weight = 400,
	blursize = 0,
	scanlines = 0,
	antialias = true
})

surface.CreateFont("BebasNeue2", {
	font = "Bebas Neue",
	size = 42,
	weight = 400,
	blursize = 0,
	scanlines = 0,
	antialias = true
})

surface.CreateFont("BebasNeue3", {
	font = "Bebas Neue",
	size = 100,
	weight = 400,
	blursize = 0,
	scanlines = 0,
	antialias = true
})

surface.CreateFont("BebasNeue4", {
	font = "Tahoma",
	size = 16,
	weight = 1000,
	blursize = 0,
	scanlines = 0,
	antialias = true
})

---@class gmcoreDeathcardText : Panel
local TXT = {}

function TXT:Init()
	self.FirstColor = color_white
	self.SecondColor = self.FirstColor
	self.Text = ""
	self.Font = "BebasNeue"
end

---@param font string Font name used to render the card text
function TXT:SetFont(font)
	self.Font = font
end

---@param txt string Text content to display on the card
function TXT:SetText(txt)
	self.Text = txt

	surface.SetFont(self.Font)

	local _, h = surface.GetTextSize("A")
	local w, _ = surface.GetTextSize(txt)
	self:SetSize(w, h)
end

---@param col Color Color for the top half of the split-color text
function TXT:SetFirstColor(col)
	self.FirstColor = col
end

---@param col Color Color for the bottom half of the split-color text
function TXT:SetSecondColor(col)
	self.SecondColor = col
end

function TXT:Paint(w, h)
	surface.SetFont(self.Font)
	surface.SetTextColor(self.SecondColor)
	surface.SetTextPos(0, 0)
	surface.DrawText(self.Text)

	local x, y = self:LocalToScreen(0, 0)
	render.SetScissorRect(x, y, x + w, y + h / 2, true)
		surface.SetTextColor(self.FirstColor)
		surface.SetTextPos(0, 0)
		surface.DrawText(self.Text)
	render.SetScissorRect(x, y, x + w, y + h, false)
end

vgui.Register("GmcoreDeathcardText", TXT, "Panel")
