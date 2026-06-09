
---@class gmcoreFunRoundWinner : DPanel
local PANEL = {}

local FONT_FUNROUND_MERIT = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 28,
	weight = 0
})

local FONT_FUNROUND_WINNER = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 20,
	weight = 0
})

function PANEL:Init()

	local container = vgui.Create("DPanel", self)
	container.Paint = function() end
	self.p_Container = container

	local merit = vgui.Create("DLabel", container)
	merit:SetText("Last Alive")
	merit:SetFont(FONT_FUNROUND_MERIT)
	merit:SetContentAlignment(5)
	merit:SetTall(30)
	self.p_Merit = merit

	local avatar = vgui.Create("AvatarImage", container)
	avatar:SetSize(90, 90)
	self.p_Avatar = avatar

	local image = vgui.Create("DImage", container)
	image:SetSize(90, 90)
	self.p_Image = image

	local name = vgui.Create("DLabel", container)
	name:SetText("Nobody!")
	name:SetFont(FONT_FUNROUND_WINNER)
	name:SetContentAlignment(5)
	self.p_Name = name

	local name2 = vgui.Create("DLabel", container)
	name2:SetText("Nobody!")
	name2:SetFont(FONT_FUNROUND_WINNER)
	name2:SetContentAlignment(5)
	name2:SetVisible(false)
	self.p_Name2 = name2
end

---@class FunRoundWinnerInfo: {ply?: Player, text?: string, image?: string, name?: string, name2?: string}

---@param winnerInfo FunRoundWinnerInfo Winner details to display on the panel
function PANEL:SetWinner(winnerInfo)
	self.p_Merit:SetText(winnerInfo.text)

	if winnerInfo.name then
		self.p_Name:SetText(winnerInfo.name)
	end

	if winnerInfo.name2 then
		self.p_Name2:SetText(winnerInfo.name2)
		self.p_Name2:SetVisible(true)
	end

	if winnerInfo.ply then
		self.p_Avatar:SetPlayer(winnerInfo.ply, 184)
		self.p_Name:SetText(IsValid(winnerInfo.ply) and winnerInfo.ply:Nick() or "N/A (Left)")
	end

	if winnerInfo.image then
		self.p_Image:SetImage(winnerInfo.image)
	end

end

local darker = Color(0, 0, 0, 150)
function PANEL:Paint(w, h)
	--draw.RoundedBox(8, 0, 0, w, h, darker)
end

function PANEL:PerformLayout(w, h)

	self.p_Container:SetSize(w, h)

	local mw, mh = self.p_Merit:GetSize()
	self.p_Merit:SetWide(w)
	self.p_Merit:SetPos(0, 24)

	local aw, ah = self.p_Avatar:GetSize()
	self.p_Avatar:Center()
	self.p_Image:Center()

	local win2 = self.p_Name2:IsVisible()
	self.p_Name:SetWide(w)
	self.p_Name:SetPos(0, h - (win2 and 64 or 48))

	self.p_Name2:SetWide(w)
	self.p_Name2:SetPos(0, h - 38)
end

function PANEL:DoFadeIn(delay)
	local x, y = self.p_Container:GetPos()
	self.p_Container:SetPos(x, y - 50)
	self.p_Container:SetAlpha(0)
	self.p_Container:MoveTo(x, y, delay + (delay / 2), 0.1)
	self.p_Container:AlphaTo(255, 0.5, delay)
end

vgui.Register("GmcoreFunRoundWinner", PANEL, "DPanel")
