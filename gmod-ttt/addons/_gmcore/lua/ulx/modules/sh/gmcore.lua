function ulx.store(calling_ply)
	local base = ((gmcore.ForumsBaseUrl or ""):gsub("/+$", ""))
	calling_ply:SendLua(string.format([[gui.OpenURL(%q)]], base .. "/store"))
end

local store = ulx.command("GL", "ulx store", ulx.store, "!store")
store:defaultAccess(ULib.ACCESS_ALL)
store:help("Open the store to view purchasable ranks.")

function ulx.spray(calling_ply)
	calling_ply:SendLua([[
		Sprays.Menu:OpenMenu()
	]])
end

local spray = ulx.command("GL", "ulx spray", ulx.spray, "!spray", true)
spray:defaultAccess(ULib.ACCESS_ALL)
spray:help("Opens spray menu to setup your spray.")

function ulx.website(calling_ply)
	local base = ((gmcore.ForumsBaseUrl or ""):gsub("/+$", ""))
	calling_ply:SendLua(string.format([[gui.OpenURL(%q)]], base .. "/"))
end

local website = ulx.command("GL", "ulx website", ulx.website, "!website")
website:defaultAccess(ULib.ACCESS_ALL)
website:help("View the forums.")
