---@class gmCore
---@diagnostic disable-next-line
gmcore = gmcore or {}

if SERVER then
	include("gmcore/sh_util.lua")
	include("gmcore/sh_ranks.lua")
	include("gmcore/sv_db.lua")
	include("gmcore/sv_gmcore.lua")

	AddCSLuaFile("gmcore/sh_util.lua")
	AddCSLuaFile("gmcore/sh_ranks.lua")
	AddCSLuaFile("gmcore/cl_gmcore.lua")
end

if CLIENT then
	include("gmcore/sh_util.lua")
	include("gmcore/sh_ranks.lua")
	include("gmcore/cl_gmcore.lua")
end
