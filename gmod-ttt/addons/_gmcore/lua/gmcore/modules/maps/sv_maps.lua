
include("sv_jondome_sword.lua")
include("sv_map_stats_JSONwriter.lua")

hook.Add("AcceptInput","RaiseJoyVol",function(e,i) if IsValid(e) and e:GetClass()=="ambient_generic" and string.find(string.lower(e:GetInternalVariable("m_iszSound")),"sam_halliday_christmas_joy",1,true) then e:SetKeyValue("health","10") end end)


if CLIENT then
	hook.Add("InitPostEntity", "ClampHDR", function()
		if game.GetMap() ~= "gm_capitol" then return end

		RunConsoleCommand("mat_autoexposure_min", "0.9")
		RunConsoleCommand("mat_autoexposure_max", "1.1")
		RunConsoleCommand("mat_bloomscale", "0.35")
	end)
end
