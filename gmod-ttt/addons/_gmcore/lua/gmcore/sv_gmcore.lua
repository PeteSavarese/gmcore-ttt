include("gmcore/sh_config.lua")
AddCSLuaFile("gmcore/sh_config.lua")

include("gmcore/sh_modules.lua")
AddCSLuaFile("gmcore/sh_modules.lua")

gmcore.print("Startup Routine Started")

gmcore.print("Loading Store Ranks")
AddCSLuaFile("gmcore/store_ranks/sh_store_ranks_init.lua")
include("gmcore/store_ranks/sh_store_ranks_init.lua")

gmcore.print("Loading Base GMCore Functionality")
AddCSLuaFile("gmcore/gmcore_scoreboard.lua")
include("gmcore/core/gmcore_init.lua")

gmcore.print("Loading HTTP module")
include("gmcore/core/gmcore_http.lua")

gmcore.print("Loading Time Keeper")
include("gmcore/core/gmcore_timekeeper.lua")

gmcore.print("Loading Stats Tracker Module")
include("gmcore/core/gmcore_stats_tracker.lua")

gmcore.print("Loading Player Controller")
include("gmcore/core/gmcore_player_controller.lua")

gmcore.print("Loading Server Updater")
include("gmcore/core/gmcore_serverstats.lua")

gmcore.print("Loading Punishments")
include("gmcore/core/gmcore_punishments.lua")

gmcore.print("Loading Connect manager")
include("gmcore/core/gmcore_connect.lua")

gmcore.print("Loading Forum Syncing")
--include("gmcore/sv_donate_database.lua")
include("gmcore/gmcore_forum_rank_syncing.lua")

gmcore.print("Loading Screensnapper")
include("gmcore/screensnapper/snap_load.lua")
AddCSLuaFile("gmcore/screensnapper/snap_load.lua")

gmcore.print("Startup Routine Finished. Starting module loading")

gmcore:LoadModules()

hook.Call("gmcore.PostInitialize")
