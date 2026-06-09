local TearGas_Time = 0
local TearGas_FadeIn = 2
local TearGas_FadeOut = 4
local TearGas_On = false

local function TearGas_Blur()
	local mult
	if TearGas_On then
		mult = math.min( ( ( CurTime() - TearGas_Time ) / TearGas_FadeIn ), 1 )
	else
		mult = 1 - ( math.min( ( ( CurTime() - TearGas_Time ) / TearGas_FadeOut ), 1 ) )
	end

	--local mod = {}
	--mod[ "$pp_colour_addr" ] = 0
	--mod[ "$pp_colour_addg" ] = 0
	--mod[ "$pp_colour_addb" ] = 0
	--mod[ "$pp_colour_brightness" ] = -0.2 * mult
	--mod[ "$pp_colour_contrast" ] = 1 + ( 0.2 * mult ) 
	--mod[ "$pp_colour_colour" ] = 1
	--mod[ "$pp_colour_mulr" ] = 0
	--mod[ "$pp_colour_mulg" ] = 0
	--mod[ "$pp_colour_mulb" ] = 0
	-- DrawColorModify( mod )

	--DrawMotionBlur( 0.5 * mult, 0.9 * mult, 0.2 * mult )
	--DrawToyTown( 10 * mult, ( ScrH() / 4 ) * mult )
	--DrawSharpen( 0.4 * mult, math.Rand( 0, 10 ) * mult )
	DrawMaterialOverlay( "effects/water_warp01", mult )
end

local function TearGas_Toggle( bool )
	if bool then
		if not TearGas_On then
			TearGas_On = true
			TearGas_Time = CurTime()
		end
		hook.Add( "RenderScreenspaceEffects", "TearGas_Blur", TearGas_Blur )
		--hook.Add( "AdjustMouseSensitivity", "TearGas_Sensitivity", function( default ) return math.Rand( 0.1, 5 ) end )
	else
		TearGas_On = false
		TearGas_Time = CurTime()
		timer.Simple( TearGas_FadeOut, function()
			hook.Remove( "RenderScreenspaceEffects", "TearGas_Blur" )
		--	hook.Remove( "AdjustMouseSensitivity", "TearGas_Sensitivity" )
		end )
	end
end

local function TearGas_Stop()
	hook.Remove( "RenderScreenspaceEffects", "TearGas_Blur" )
	--hook.Remove( "AdjustMouseSensitivity", "TearGas_Sensitivity" )
end

net.Receive( "TearGas_Toggle", function()
	TearGas_Toggle( ( net.ReadBit() == 1 ) )
end )

hook.Add( "TTTPrepareRound", "TearGas_Clear", function()
	TearGas_Stop()
end )