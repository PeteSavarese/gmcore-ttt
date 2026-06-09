if SERVER then return end

VOICEVIS = VOICEVIS or {}

VOICEVIS.vgui = {}
surface.CreateFont( "Voice_Player_Name", {font = VOICEVIS.PlayerNameFont.FONT, size = VOICEVIS.PlayerNameFont.SIZE, weight = VOICEVIS.PlayerNameFont.THICKNESS} )
surface.CreateFont( "Voice_Player_Tag", {font = VOICEVIS.PlayerTagFont.FONT, size = VOICEVIS.PlayerTagFont.SIZE, weight = VOICEVIS.PlayerTagFont.THICKNESS} )

function VOICEVIS.Box(x, y, w, h, c, p)
	VOICEVIS.vgui[#VOICEVIS.vgui + 1] = VGUIRect(x, y, w, h)
	VOICEVIS.vgui[#VOICEVIS.vgui]:SetColor(c)
	VOICEVIS.vgui[#VOICEVIS.vgui]:SetParent(p)

	return #VOICEVIS.vgui
end

function VOICEVIS.Text(x, y, w, h, tt, f, c, p)
	VOICEVIS.vgui[#VOICEVIS.vgui + 1] = vgui.Create("DLabel", p)
	VOICEVIS.vgui[#VOICEVIS.vgui]:SetPos(x, y)
	VOICEVIS.vgui[#VOICEVIS.vgui]:SetSize(w, h)
	VOICEVIS.vgui[#VOICEVIS.vgui]:SetText(tt)
	VOICEVIS.vgui[#VOICEVIS.vgui]:SetFont(f)
	VOICEVIS.vgui[#VOICEVIS.vgui]:SetColor(c)

	return #VOICEVIS.vgui
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

function surface.GetSizesEz(t, f)
	surface.SetFont(f)

	return surface.GetTextSize(t)
end

local PANEL = {}
local PlayerVoicePanels = {}

function PANEL:Init(ply)
	self.Visualizer = vgui.Create("VoiceVisualizer", self)
	self.Visualizer:SetSize(VOICEVIS.Width, VOICEVIS.Height)
	self.Visualizer:SetVis(VOICEVIS.Visualizer)

	local _, plyNameTextH = surface.GetSizesEz("TEMP", "Voice_Player_Name")
	local _, plyTagTextH = surface.GetSizesEz("TEMP", "Voice_Player_Tag")

	self.Avatar = vgui.Create("AvatarImage", self)
	self.Avatar:SetSize(32, 32)
	self.Avatar:SetPos(7, VOICEVIS.Height / 2 - 16)

	self.PlayerName = VOICEVIS.Text(44, VOICEVIS.Height / 2 - plyNameTextH / 2 - 8, 0, 0, "", "Voice_Player_Name", VOICEVIS.PlayerNameFont.COLOR, self)
	self.PlayerTag = VOICEVIS.Text(44, self.Avatar.y + self.Avatar:GetTall() - plyTagTextH, 0, 0, "", "Voice_Player_Tag", VOICEVIS.PlayerTagFont.COLOR, self)


	self.Color = color_transparent

	self:SetSize(VOICEVIS.Width, VOICEVIS.Height)
	self:DockPadding(4, 4, 4, 4)
	self:DockMargin(2, 2, 2, 2)
	self:Dock(BOTTOM)
end

function PANEL:Setup(ply)
	self.ply = ply

	self.Visualizer:SetPly(ply)

	local w, h = surface.GetSizesEz(ply:Nick() or "", "Voice_Player_Name")
	VOICEVIS.vgui[self.PlayerName]:SetSize(w, h)
	VOICEVIS.vgui[self.PlayerName]:SetAutoStretchVertical(true)
	VOICEVIS.vgui[self.PlayerName]:SetText(ply:Nick())

	-- Tag stuff (Rank)
	local w, h = surface.GetSizesEz(VOICEVIS:GetTagForPlayers(ply) or "", "Voice_Player_Tag")
	VOICEVIS.vgui[self.PlayerTag]:SetSize(w, h)
	VOICEVIS.vgui[self.PlayerTag]:SetAutoStretchVertical(true)
	VOICEVIS.vgui[self.PlayerTag]:SetText(VOICEVIS:GetTagForPlayers(ply) or "")

	self.Avatar:SetPlayer(ply)
	self.Color = team.GetColor(ply:Team())
	self:InvalidateLayout()
end

function PANEL:VoicePaint( w, h )
	if !IsValid(self.ply) then return end
	self.BoxBorderCol = VOICEVIS.BorderColor
	self.BoxPanelCol = VOICEVIS.PanelColor

	self.BoxBorderCol = self.Color
	self.BoxPanelCol = Color(0,0,0,180)

	draw.RoundedBox(VOICEVIS.CornerRounding, 0, 0, w, h, self.BoxBorderCol)
	draw.RoundedBox(VOICEVIS.CornerRounding, 1, 1, w - 2, h - 2, self.BoxPanelCol)
end

function PANEL:Think()
	self.Paint = self.VoicePaint

	if !IsValid(self.ply) or !self.ply:IsSpeaking() then
		self:Remove()
	end
end

function PANEL:FadeOut()
	-- void
end

timer.Simple(0.5, function()
	derma.DefineControl("VoiceNotify", "", PANEL, "DPanel")
end)

local function VoiceClean()
	for k, v in pairs(PlayerVoicePanels) do
		if !IsValid(k) then
			VOICEVIS:PlayerEndVoice(k)
		end
	end
end
timer.Create("VoiceClean", 10, 0, VoiceClean)

function VOICEVIS:PlayerEndVoice(ply)
	if IsValid(PlayerVoicePanels[ply]) then
		PlayerVoicePanels[ply]:Remove()
	end
end

hook.Add("Think", "ConstantlyOverrideVoiceSize", function()
	if !IsValid(g_VoicePanelList) then return end

	g_VoicePanelList:SetSize(250, ScrH() - 200)
end)

function CreateVoiceVGUI()
	g_VoicePanelList = vgui.Create("DPanel")
	g_VoicePanelList:ParentToHUD()
	g_VoicePanelList:SetPos(ScrW() - 300, VOICEVIS.YCord)
	g_VoicePanelList:SetSize(VOICEVIS.Width, ScrH() - 200)
	g_VoicePanelList:SetPaintBackground(false)
end

hook.Add("InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI)
