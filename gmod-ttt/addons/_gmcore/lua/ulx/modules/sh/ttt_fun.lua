local CATEGORY_NAME  = "TTT Fun"
local gamemode_error = "The current gamemode is not trouble in terrorest town"

function GamemodeCheck(calling_ply)
	if GetConVar("gamemode"):GetString() ~= "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)

		return true
	else
		return false
	end
end

--[Helper Functions]---------------------------------------------------------------------------
--[End]----------------------------------------------------------------------------------------
--[Toggle spectator]---------------------------------------------------------------------------
--[[ulx.spec][Forces <target(s)> to and from spectator.]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_plys   [The player(s) who will have the effects of the command applied to them.]
--]]
function ulx.credits(calling_ply, target_plys, amount, should_silent)
	if GetConVar("gamemode"):GetString() ~= "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		for i = 1, #target_plys do
			target_plys[i]:AddCredits(amount)
		end

		ulx.fancyLogAdmin(calling_ply, true, "#A gave #T #i credits", target_plys, amount)
	end
end
local credits = ulx.command( CATEGORY_NAME, "ulx credits", ulx.credits, "!credits")
credits:addParam{ type=ULib.cmds.PlayersArg }
credits:addParam{ type=ULib.cmds.NumArg, hint="Credits", ULib.cmds.round }
credits:defaultAccess( ULib.ACCESS_SUPERADMIN )
credits:setOpposite( "ulx silent credits", {_, _, _, true}, "!scredits", true )
credits:help( "Gives the <target(s)> credits." )
--[End]----------------------------------------------------------------------------------------

local CATEGORY_NAME = "Chat"

if SERVER then
	util.AddNetworkString("T2S") -- Adds the network string
end

if CLIENT then
	net.Receive("T2S", function(len)
		local text = ""
		text = net.ReadString()

		-- Play the sound from google's Text to Speech API (Developer API)
		sound.PlayURL("http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=" .. text .. "&tl=en", "mono", function(chan, num, str)
			-- Just for the info ( not needed at all )
		end )
	end )
end

function ulx.tts( calling_ply, text )
	if calling_ply and calling_ply:IsValid() then
		local str = "" -- makes it a local var

		text = string.Trim(text) -- No spaces at that frount or end
		text = string.Explode(" ", text) -- converts text to a table of the workds that need to be said

		if text == {} then return end -- If the table has no value then stop
		if text == "text to say" then ULib.tsayError( calling_ply, "You need to edit the default text", true ) end

		for k,v in pairs(text) do
			str = str .. v .. "%20" -- EX: would convert "I like pie" to "I%29like%20pie" which the url has to be
		end

		net.Start("T2S")
			net.WriteString(str)
		net.Broadcast()
	end
end

-- creates the command
local tts = ulx.command( CATEGORY_NAME, "ulx t2s", ulx.tts, "!t2s", true )
tts:addParam{ type=ULib.cmds.StringArg, hint="text to say", ULib.cmds.takeRestOfLine }
tts:defaultAccess( ULib.ACCESS_SUPERADMIN )
tts:help( "Text 2 speach." )

local Models = {
	"models/props_trainstation/train001.mdl",
	"models/props_combine/CombineTrain01a.mdl",
	"models/props_combine/combine_train02a.mdl"
}
local function SpawnTrain( Pos, Direction )
				local train = ents.Create( "prop_physics" )
				local random = math.random(1,#Models)
				train:SetModel(Models[random])
				train:SetAngles( Direction:Angle() + Angle(0,string.find(Models[random],"metrostroi") and 0 or 270,0) )
				train:SetPos( Pos )
				if math.random() > 0.6 then train:SetColor( Color(math.random(0,255),math.random(0,255),math.random(0,255)) ) end
				train:SetSkin(math.random(0,2))
				train:Spawn()
				train:Activate()
				train:EmitSound( "ambient/alarms/train_horn2.wav", 100, 100 )
				train:GetPhysicsObject():SetVelocity( Direction * math.random(1e7,1e9) )

				--timer.Create( "TrainRemove_"..CurTime(), 5, 1, function( train ) train:Remove() end, train )
				timer.Simple( 5, function() train:Remove() end )
end

function ulx.trainSlam(calling_ply, target_plys)
	local affected_plys = {}

	local gm = GetConVarNumber("sbox_godmode")
	if gm > 0 then RunConsoleCommand("sbox_godmode",0) end
	for i=1, #target_plys do
		local v = target_plys[ i ]

		if ulx.getExclusive( v, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
		elseif not v:Alive() then
			ULib.tsayError( calling_ply, v:Nick() .. " is already dead!", true )
		elseif v:IsFrozen() then
			ULib.tsayError( calling_ply, v:Nick() .. " is frozen!", true )
		elseif calling_ply.hasTrainSlamSession then
			ULib.tsayError( calling_ply, "You may only train slam once per map!", true )
		else
			v:SetMoveType( MOVETYPE_WALK )
			v:GodDisable()
			SpawnTrain( v:GetPos() + v:GetForward() * 1000 + Vector(0,0,120), v:GetForward() * -1 )
			table.insert( affected_plys, v )
		end
	end
	timer.Simple(1,function()
		RunConsoleCommand("sbox_godmode",gm)
	end)

	calling_ply.hasTrainSlamSession = true
	ulx.fancyLogAdmin( calling_ply, "#A train slammed #T", affected_plys )
end
local trainslam = ulx.command( "Fun", "ulx trainslam", ulx.trainSlam, "!trainslam", true )
trainslam:addParam{ type=ULib.cmds.PlayersArg }
trainslam:defaultAccess( ULib.ACCESS_ADMIN )
trainslam:help( "Train slams a player." )
