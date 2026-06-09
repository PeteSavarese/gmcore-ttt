local CATEGORY_NAME = "Chat"

local warnings = {
	"Traitors, please make a move. Thank you.",
	"Traitors, please start traiting.",
	"Remember, camping isn't allowed, no matter the role.",
	"Please do not delay."
}

function ulx.gwarn( calling_ply, message )
	local color = gmcore.Ranks[calling_ply:GetUserGroup()].color or Color(255,255,255)

	message = ": " .. message
	ULib.tsayColor(nil, false, color, calling_ply:GetName(), Color(255, 255, 255), message)
end

local gwarn = ulx.command( CATEGORY_NAME, "ulx gwarn", ulx.gwarn )
gwarn:addParam{ type=ULib.cmds.StringArg, completes=warnings, hint="Select message", ULib.cmds.restrictToCompletes}
gwarn:defaultAccess( ULib.ACCESS_ADMIN )
gwarn:help( "Sends message in chat for all to see. Use this to prevent ghosting (Makes you look alive when sending)" )

function ulx.psay( calling_ply, target_ply, message )
	if calling_ply:GetNWBool( "ulx_muted", false ) then
		ULib.tsayError( calling_ply, "You are muted, and therefore cannot speak! Use asay for admin chat if urgent.", true )
		return
	end

	hook.Run("gmcore.Admin.PSayTracker", calling_ply, target_ply, message)
	ulx.fancyLog( { target_ply, calling_ply }, "#P to #P: " .. message, calling_ply, target_ply )
end

local psay = ulx.command( CATEGORY_NAME, "ulx psay", ulx.psay, {"!p", "!pm"}, true )
psay:addParam{ type=ULib.cmds.PlayerArg, target="!^", ULib.cmds.ignoreCanTarget }
psay:addParam{ type=ULib.cmds.StringArg, hint="message", ULib.cmds.takeRestOfLine }
psay:defaultAccess( ULib.ACCESS_ALL )
psay:help( "Send a private message to target." )

---System for round gag and round mute.
---This is a hack way, but it works. 1 means the rgag is active and placed. Set to 0 when the next round begins and is still active. false when no longer active at TTTEndRound
function ulx.rgag(calling_ply, target_ply, bIsUngagging)
	if !bIsUngagging then
		target_ply.ulx_gagged = true
		target_ply:SetNWBool("ulx_gagged", true)
		target_ply.roundGagged = 1

		ulx.fancyLogAdmin(calling_ply, "#A gagged #T for a round", target_ply)
	elseif bIsUngagging == true then
		if !target_ply.roundGagged then
			ULib.tsayError( calling_ply, target_ply:Nick() .. " doesn't have any active round gags!", true )
			return
		end

		target_ply.ulx_gagged = false
		target_ply:SetNWBool("ulx_gagged", false)
		target_ply.roundGagged = false

		ulx.fancyLogAdmin(calling_ply, "#A removed #T's round gag", target_ply)
	end
end

local rgag = ulx.command( CATEGORY_NAME, "ulx rgag", ulx.rgag, "!rgag", true )
rgag:addParam{ type=ULib.cmds.PlayerArg, target="!^", ULib.cmds.ignoreCanTarget }
rgag:addParam{ type=ULib.cmds.BoolArg, invisible=true }
rgag:defaultAccess( ULib.ACCESS_ADMIN )
rgag:help( "Gags player for an entire round until the round ends." )
rgag:setOpposite( "ulx unrgag", {_, _, true}, "!unrgag" )

function ulx.rmute(calling_ply, target_ply, bIsUnmuting)
	if !bIsUnmuting then
		target_ply.gimp = 2
		target_ply:SetNWBool("ulx_muted", true)
		target_ply.roundMuted = 1

		ulx.fancyLogAdmin(calling_ply, "#A muted #T for a round", target_ply)
	elseif bIsUnmuting == true then
		if !target_ply.roundMuted then
			ULib.tsayError( calling_ply, target_ply:Nick() .. " doesn't have any active round mutes!", true )
			return
		end

		target_ply.gimp = nil
		target_ply:SetNWBool("ulx_muted", false)
		target_ply.roundMuted = false

		ulx.fancyLogAdmin(calling_ply, "#A removed #T's round mutes", target_ply)
	end
end

local rmute = ulx.command( CATEGORY_NAME, "ulx rmute", ulx.rmute, "!rmute", true )
rmute:addParam{ type=ULib.cmds.PlayerArg, target="!^", ULib.cmds.ignoreCanTarget }
rmute:addParam{ type=ULib.cmds.BoolArg, invisible=true }
rmute:defaultAccess( ULib.ACCESS_ADMIN )
rmute:help( "Mutes player for an entire round until the round ends." )
rmute:setOpposite( "ulx unrmute", {_, _, true}, "!unrmute" )

hook.Add("TTTBeginRound", "gmcore.Chat.RoundGagMuteCheckBegin", function()
	for _, ply in ipairs(player.GetAll()) do
		if ply.roundGagged == 1 then
			-- Player has pending rgag. Set to 0 so they are still gagged this round
			ply.roundGagged = 0
		end

		if ply.roundMuted == 1 then
			-- Player has pending rgag. Set to 0 so they are still muted this round
			ply.roundMuted = 0
		end
	end
end)

hook.Add("TTTEndRound", "gmcore.Chat.RoundGagMuteCheckEnd", function()
	local tUngaggedPlys = {}
	local tUnmutedPlys = {}

	for _, ply in ipairs(player.GetAll()) do
		if ply.roundGagged == 0 then
			-- Player has pending rgag. Set to 0 so they are still gagged this round
			ply.roundGagged = false
			ply.ulx_gagged = false
			ply:SetNWBool("ulx_gagged", false)
			table.insert(tUngaggedPlys, ply)
		end

		if ply.roundMuted == 0 then
			-- Player has pending rgag. Set to 0 so they are still muted this round
			ply.roundMuted = false
			ply.gimp = nil
			ply:SetNWBool("ulx_muted", false)
			table.insert(tUnmutedPlys, ply)
		end
	end

	if #tUngaggedPlys != 0 then
		local filler = (#tUngaggedPlys == 1 and "has") or "have"

		ulx.fancyLogAdmin(nil, "#T " .. filler .. " been ungagged", tUngaggedPlys)
	end

	if #tUnmutedPlys != 0 then
		local filler = (#tUnmutedPlys == 1 and "has") or "have"

		ulx.fancyLogAdmin(nil, "#T " .. filler .. " been unmuted", tUnmutedPlys)
	end
end)
