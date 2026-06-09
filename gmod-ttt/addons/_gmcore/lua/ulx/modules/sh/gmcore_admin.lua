local CATEGORY_NAME_ADMIN = "GL Admin"

function ulx.snap(calling_ply, target_ply, quality)
	snapper.addqueue(target_ply)
	snapper.snap(calling_ply, target_ply, (quality and quality) or 70)
end

local snap = ulx.command(CATEGORY_NAME_ADMIN, "ulx snap", ulx.snap)
snap:addParam{type=ULib.cmds.PlayerArg}
snap:addParam{type = ULib.cmds.NumArg, default = 70, min = 40, max = 90, hint = "quality of screenshot (default 70)", ULib.cmds.optional}
snap:defaultAccess(ULib.ACCESS_SUPERADMIN)
snap:help("Takes a screenshot of player's screen.")

function ulx.snapmenu(calling_ply, target_ply, quality)
	calling_ply:SendLua([[snapper.menu.admin()]])
end

local snapmenu = ulx.command(CATEGORY_NAME_ADMIN, "ulx snapmenu", ulx.snapmenu)
snapmenu:defaultAccess(ULib.ACCESS_SUPERADMIN)
snapmenu:help("Open screenshot menu to view all screenshots.")

function ulx.hlogs(calling_ply, target_ply)
	local base = ((gmcore.ForumsBaseUrl or ""):gsub("/+$", ""))
	calling_ply:SendLua(string.format([[gui.OpenURL(%q)]], base .. "/gl/hlogs/results?steamid=" .. target_ply:SteamID()))
end

local hlogs = ulx.command(CATEGORY_NAME_ADMIN, "ulx hlogs", ulx.hlogs, "!hlogs")
hlogs:addParam{type=ULib.cmds.PlayerArg}
hlogs:defaultAccess(ULib.ACCESS_SUPERADMIN)
hlogs:help("Open player's History Logs.")

function ulx.hlogsid(calling_ply, sid)
	if not ULib.isValidSteamID(sid) then
		ULib.tsayError(calling_ply, "Invalid steamid.")

		return
	end

	local base = ((gmcore.ForumsBaseUrl or ""):gsub("/+$", ""))
	calling_ply:SendLua(string.format([[gui.OpenURL(%q)]], base .. "/gl/hlogs/results?steamid=" .. sid))
end

local hlogsid = ulx.command(CATEGORY_NAME_ADMIN, "ulx hlogsid", ulx.hlogsid, "!hlogsid")
hlogsid:addParam{type=ULib.cmds.StringArg, hint="steamid", ULib.cmds.optional}
hlogsid:defaultAccess(ULib.ACCESS_SUPERADMIN)
hlogsid:help("Open player's History Logs using SteamID.")

function ulx.spraysmanager(calling_ply)
	calling_ply:SendLua([[
		Sprays.Menu:OpenMenu()
		Sprays.Menu.SideBarNav:SetActiveTab("Staff Manager")
	]])
end

local spraysmanager = ulx.command(CATEGORY_NAME_ADMIN, "ulx spraysmanager", ulx.spraysmanager, "!spraysmanager")
spraysmanager:defaultAccess(ULib.ACCESS_SUPERADMIN)
spraysmanager:help("Open spraysmanager menu to view all currently sprayed sprays.")

function ulx.force_mapvote(calling_ply)
	gmcore.MapVote:initializeMapVote()
	ulx.fancyLogAdmin(calling_ply, true, "#A has forced the MapVote to begin.")
end

local force_mapvote = ulx.command(CATEGORY_NAME_ADMIN, "ulx forcemapvote", ulx.force_mapvote)
force_mapvote:defaultAccess(ULib.ACCESS_SUPERADMIN)
force_mapvote:help("Forces Rock the Vote right away.")

function ulx.rtv(calling_ply)
	gmcore.RTV:AddToRTV(calling_ply)
end

local rtv = ulx.command("Voting", "ulx rtv", ulx.rtv, "!rtv")
rtv:defaultAccess(ULib.ACCESS_ALL)
rtv:help("Starts a vote to vote for next map.")

---Shows if a fun round is happening this map, and if so what round and what fun round
function ulx.checkfunround(calling_ply)
	if !gmcore.FunRounds then
		ULib.tsayError(calling_ply, "gl Module Fun Rounds has not loaded.")

		return
	end

	if gmcore.FunRounds.FunRoundThisMap then
		local iRound = gmcore.FunRounds.RoundToActivate
		local sType = gmcore.FunRounds.ChosenFunRound

		ULib.tsay(calling_ply, "Fun Round \"" .. sType .. "\" has been chosen and will be commence on round " .. iRound, true)

		return
	else
		ULib.tsayError(calling_ply, "A Fun Round has not been selected for this map.")

		return
	end
end

local checkfunround = ulx.command(CATEGORY_NAME_ADMIN, "ulx checkfunround", ulx.checkfunround, "!checkfunround")
checkfunround:defaultAccess(ULib.ACCESS_ADMIN)
checkfunround:help("Shows if a fun round is happening this map, and if so what round and what fun round")


---Queues a fun round for the following round
local availableFunRounds = {}

for funRoundId, _ in pairs(gmcore.FunRounds.RegisteredFunRounds) do
	table.insert(availableFunRounds, funRoundId)
end

function ulx.queuefunround(calling_ply, sFunRoundId)
	if !gmcore.FunRounds then
		ULib.tsayError(calling_ply, "gl Module Fun Rounds has not loaded.")

		return
	end

	if !gmcore.FunRounds.RegisteredFunRounds[sFunRoundId] then
		ULib.tsayError(calling_ply, "Fun round ID is invalid (Fun round doesn't exist?).")

		return
	end

	gmcore.FunRounds.FunRoundThisMap = true
	gmcore.FunRounds.RoundToActivate = GetConVar("ttt_round_limit"):GetInt() - GetGlobalInt("ttt_rounds_left", 6) + 1 -- Current round number + 1 for next round
	gmcore.FunRounds.ChosenFunRound = sFunRoundId
	gmcore.FunRounds.FunRoundULXQueued = true

	ULib.tsayColor(calling_ply, false, "(SILENT) ", Color(51, 111, 167), sFunRoundId, Color(255, 255, 255), " will commence at the start of the following round.")
end

local queuefunround = ulx.command(CATEGORY_NAME_ADMIN, "ulx queuefunround", ulx.queuefunround)
queuefunround:addParam{type=ULib.cmds.StringArg, completes=availableFunRounds, hint="Select fun round", ULib.cmds.restrictToCompletes}
queuefunround:defaultAccess(ULib.ACCESS_ADMIN)
queuefunround:help("Queues the selected fun round to be next round")
