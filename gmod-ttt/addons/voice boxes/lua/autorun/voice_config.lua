--[[ Version 2.0 by Ilya]]--

VOICEVIS = VOICEVIS or {}
VOICEVIS.VisualizerSetting = {}

-- Your visualizer's mode.
-- 1 = Bar graph
-- 2 = Loading bar thing
-- 3 = The wave
-- 4 = Line graph
-- 5 = Circles
-- 6 = Cooler line graph
VOICEVIS.Visualizer = 4

-- 1 = Default color for all
-- 2 = Color depending on volume ( fade from green to red )
-- 3 = Color depending on rank (in color for player function below)
VOICEVIS.ColorMode = 2

-- The border color of the visualizer box
VOICEVIS.BorderColor = Color(40,40,40)

-- The foreground color of the visualizer
VOICEVIS.PanelColor = Color(25,25,25)

-- The default color of the visualizer when it finds no color
VOICEVIS.DefaultColor = Color(50,50,50,100)

-- The direct opacity of the visualizer
VOICEVIS.DefaultOpacity = 100

-- Increase to have more rounded corners on the box (keep it an even number)
VOICEVIS.CornerRounding = 0

-- How wide should the visualizer be?
VOICEVIS.Width = 250

-- How tall should the visualizer be?
VOICEVIS.Height = 50

-- Use this option if you want the voice boxes to start higher
-- Make this lower or in the negatives to make the first box start lower.
-- 100 is default
VOICEVIS.YCord = 100

-- Here you can edit the player name font settings
VOICEVIS.PlayerNameFont = {
	FONT = "Cordia New",
	SIZE = 22,
	THICKNESS = 1,
	COLOR = Color(255,255,255,255)
}

-- Settings for Player Tag Font
VOICEVIS.PlayerTagFont = {
	FONT = "Cordia New",
	SIZE = 15,
	THICKNESS = 1,
	COLOR = Color(255,255,255,160)
}

-- Settings for top right font
VOICEVIS.PlayerTopRightFont = {
	FONT = "Cordia New",
	SIZE = 13,
	THICKNESS = 1,
	COLOR = Color(160,160,160,10)
}

-- Here you can customize what players get what tags.
-- Keep in mind ULX uses ply:IsUserGroup("rank name") and Evolve uses ply:EV_GetRank() == "rank name"
function VOICEVIS:GetTagForPlayers(ply)
	if IsValid(ply) and ply:IsStaffRank() then
		local tGroupInfo = gmcore.Ranks[ply:GetUserGroup()]
		if !tGroupInfo then return "" end

		return tGroupInfo.niceName
	end
end

-- Here you can customize what players get what colors for their visualizers
-- Keep in mind ULX uses ply:IsUserGroup("rank name") and Evolve uses ply:EV_GetRank() == "rank name"
function VOICEVIS:GetColorForPlayer(ply)
	if ply:SteamID() == "STEAM_0:0:68825805" then -- You should leave my steam ID here. :3
		return HSVToColor(math.abs(math.sin(0.3 * RealTime()) * 128), 1, 1) -- Color fade
	end
end

-- Visualizer settings for visualizer #4
VOICEVIS.VisualizerSetting[4] = {
	WIDTH = 5, -- Width of each line segment
	SPACING = -1, -- Space between each line segment
	MULTIPLIER = 100 -- Multiplier for player voice
}
