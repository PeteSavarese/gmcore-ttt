---Client-side GMCore initialization. Entrypoint for module loader.

include("gmcore/sh_modules.lua")
include("gmcore/store_ranks/sh_store_ranks_init.lua")
include("gmcore/screensnapper/snap_load.lua")
include("gmcore/gmcore_scoreboard.lua")

gmcore:LoadModules()

hook.Call("gmcore.PostInitialize")
