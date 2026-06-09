if SERVER then
	gmcore.print("Initalizing store ranks")

	AddCSLuaFile("gmcore/store_ranks/sh_store_ranks.lua")
	include("gmcore/store_ranks/sh_store_ranks.lua")
	include("gmcore/store_ranks/sv_store_ranks.lua")
end

if CLIENT then
	gmcore.print("Initalizing store ranks client")

	include("gmcore/store_ranks/sh_store_ranks.lua")
end
