local hostname = GetConVar("hostname"):GetString()
timer.Simple(2, function() SetGlobalString("ServerName", hostname) end)