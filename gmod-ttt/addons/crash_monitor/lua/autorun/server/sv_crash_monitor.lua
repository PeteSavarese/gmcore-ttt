local CrashMonitor_MapChange = false

local function CrashMonitor_serverCheckin()
	local status = {
		time = os.time(),
		map_change = CrashMonitor_MapChange
	}
	
	file.Write(
		"server_status.json", 
		util.TableToJSON(status)
	)
end

function CrashMonitor_onMapChange()
	CrashMonitor_MapChange = true
	CrashMonitor_serverCheckin()
end




-- Do checkin every second
local function CrashMonitor_createCheckinTimer()
	timer.Create("CrashMonitor_ServerCheckinTimer", 1, 0, CrashMonitor_serverCheckin)
end

hook.Add("Initialize", "CrashMonitor_createServerCheckinTimer", CrashMonitor_createCheckinTimer)
hook.Add("ShutDown", "CrashMonitor_onShutDown", CrashMonitor_onMapChange)
