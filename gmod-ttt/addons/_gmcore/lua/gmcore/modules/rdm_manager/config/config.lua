--[[User rights.

	First argument: name of usergroup (e. g. "user" or "admin").

	Second argument: access level. Default value is 2 (will be used if a usergroup isn't here).
	1 : Can't view 'Logs before your death' tab in !report frame
	2 : Can't view logs of active rounds
	3 : Can view logs of active rounds as a spectator
	4 : Can always view logs of active rounds

	Everyone can view logs of previous rounds.

	Third argument: access to RDM Manager tab in Damagelogs (true/false).
]]
--
Damagelog:AddUser("owner", 4, true)
Damagelog:AddUser("communitymanager", 4, true)
Damagelog:AddUser("developer", 4, true)
Damagelog:AddUser("leadadmin", 4, true)
Damagelog:AddUser("admin", 3, true)
Damagelog:AddUser("mod", 3, true)
Damagelog:AddUser("trialmod", 3, true)
Damagelog:AddUser("advisor", 3, true)
Damagelog:AddUser("user", 1, false)

-- The F-key
Damagelog.Key = KEY_F8

--[[Is a message shown when an alive player opens the menu?
	0 : if you want to only show it to superadmins
	1 : to let others see that you have abusive admins
]]
--
Damagelog.AbuseMessageMode = 0
-- true to enable the RDM Manager, false to disable it
Damagelog.RDM_Manager_Enabled = true
-- Command to open the report menu. Don't forget the quotation marks
Damagelog.RDM_Manager_Command = "!report"
-- Command to open the respond menu while you're alive
Damagelog.Respond_Command = "!respond"
--[[Set to true if you want to enable MySQL (it needs to be configured on config/mysqloo.lua)
	Setting it to false will make the logs use SQLite (garrysmod/sv.db)
]]
--
Damagelog.Use_MySQL = false
-- The number of days the logs last on the database (to avoid lags when opening the menu)
Damagelog.LogDays = 61
-- Hide the Donate button on the top-right corner
Damagelog.HideDonateButton = false
-- Force a language - When empty use user-defined language
Damagelog.ForcedLanguage = ""
-- Allow reports even with no staff online
Damagelog.NoStaffReports = true
-- Allow more than 2 reports per round
Damagelog.MoreReportsPerRound = true
-- Allow reports before playing
Damagelog.ReportsBeforePlaying = true
-- Discord Webhooks
-- You can create a webhook on your Discord server that will automatically post messages when a report is created.
-- IMPORTANT:
-- 		Discord blocks webhooks from GMod servers.
--		You will need to proxy your requests through a web server
--		GMod Server -> Web Server -> Discord
-- Webhook mode:
-- 0 - disabled
-- 1 - create messages for new reports when there are no admins online
-- 2 - create messages for every report
Damagelog.DiscordWebhookMode = 0

---@return table config
function Damagelog:getConfig()
	return {
		Key = Damagelog.Key,
		AbuseMessageMode = Damagelog.AbuseMessageMode,
		RDM_Manager_Enabled = Damagelog.RDM_Manager_Enabled,
		RDM_Manager_Command = Damagelog.RDM_Manager_Command,
		Respond_Command = Damagelog.Respond_Command,
		Use_MySQL = Damagelog.Use_MySQL,
		LogDays = Damagelog.LogDays,
		HideDonateButton = Damagelog.HideDonateButton,
		ForcedLanguage = Damagelog.ForcedLanguage,
		NoStaffReports = Damagelog.NoStaffReports,
		MoreReportsPerRound = Damagelog.MoreReportsPerRound,
		ReportsBeforePlaying = Damagelog.ReportsBeforePlaying,
		EnableFullRoundDeathScenes = Damagelog.EnableFullRoundDeathScenes,
		DiscordWebhookMode = Damagelog.DiscordWebhookMode
	}
end

-- Don't forget to set the value of "ttt_dmglogs_discordurl" convar to your webhook URL in server.cfg
function Damagelog:loadMySQLConfig()
	if not file.Exists("damagelog/mysql.json", "DATA") then --If no mysql config exists save the default and return as if we loaded one.
		Damagelog:saveMySQLConfig()

		return
	end

	local config = util.JSONToTable(file.Read("damagelog/mysql.json", "DATA"))
	if not config then
		ErrorNoHalt("Damagelogs: ERROR - MySQL Config Exists but is not valid JSON!")

		return
	end

	Damagelog.MySQL_Informations = config
end

function Damagelog:saveMySQLConfig()
	file.Write("damagelog/mysql.json", util.TableToJSON(Damagelog.MySQL_Informations, true))
end
