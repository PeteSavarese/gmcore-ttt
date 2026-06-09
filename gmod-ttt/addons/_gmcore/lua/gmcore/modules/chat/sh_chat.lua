
if SERVER then
	AddCSLuaFile("cl_announcer.lua")
	AddCSLuaFile("cl_chat_cmd_tips.lua")
	AddCSLuaFile("cl_round_alerts.lua")
end

if CLIENT then
	include("cl_announcer.lua")
	include("cl_chat_cmd_tips.lua")
	include("cl_round_alerts.lua")
end
