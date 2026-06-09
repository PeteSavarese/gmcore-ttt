---@type Color
local chatPrintColor = Color(0, 103, 196)
local discordUrl = "https://discord.gg/..."

---Removes HTTPS and trailing trailing slashes from URL.
---@return string
local function getSiteDisplay()
	return (GetGlobalString("gmcore.ForumsBaseUrl", ""):gsub("^https?://", ""):gsub("/+$", ""))
end

---Builds the announcement table, resolving the site URL from replicated config at call time.
---@return table[]
local function buildMessages()
	local site = getSiteDisplay()

	return {
		-- Adding "color_white" stops unpack from truncating last part of table
		{"Already purchased a rank? Open the pointshop to set and change your loadout!"},
		{"Too many chat announcements? Go to ", chatPrintColor, "F1 -> TTT Settings", color_white,  ", and edit the delay", color_white},
		{"Check our website out by going to ", chatPrintColor, site, color_white},
		{"Enjoying your time? Join the community by going to ", chatPrintColor, site, color_white, " and sign up!", color_white},
		{"Feeling lonely? Come check out the Discord at ", chatPrintColor, discordUrl, color_white},
		{"If you want to get extra perks, type ", CHAT_PRINT_BLUE, "!store", color_white, " in the chat!"},
		{"You can check your TTT stats by typing ", chatPrintColor, "!stats", color_white},
		{"For the member role link your Steam profile to our website, ", chatPrintColor, site, color_white}
	}
end

---@type ConVar
local AnnouncementInterval = CreateClientConVar("gmcore_chatannouncement_interval", 60, true, false, "Time inbetween each [GMCore] chat announcement", 25, 300)

local idx = 1

---Prints the next chat announcement and cycles the index.
local function DoAnnouncements()
	local msgs = buildMessages()
	gmcore.chatprint(Color(255, 255, 255), unpack(msgs[idx]))
	idx = idx + 1

	if idx > #msgs then
		idx = 1
	end
end

cvars.AddChangeCallback("gmcore_chatannouncement_interval", function(name, old, new)
	timer.Remove("gmcore.ChatAnnouncer")

	timer.Create("gmcore.ChatAnnouncer", new, 0, function()
		DoAnnouncements()
	end)
end, "DeathrunAnnouncementInterval")

timer.Create("gmcore.ChatAnnouncer", AnnouncementInterval:GetFloat(), 0, function()
	DoAnnouncements()
end)
