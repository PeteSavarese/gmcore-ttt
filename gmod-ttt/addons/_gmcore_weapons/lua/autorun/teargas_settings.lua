if SERVER then AddCSLuaFile() end

TearGas_Config = {}

--How much DPS the gas deals while you stand in it (default: 4)
TearGas_Config.DamagePerSecond = 1

--How many seconds the player is disorientated for (default: 8)
TearGas_Config.DisorientationLength = 5

--How many seconds the gas stays for (default: 30)
TearGas_Config.GasLength = 30

--Radius of the tear gas cloud (default: 75)
TearGas_Config.GasRadius = 75
TearGas_Config.GasThickness = 25

--Can you only buy one tear gas grenade? (default: false)
TearGas_Config.LimitedStock = false

--Seconds it takes for the grenade to explode, including time in hand (default: 5)
TearGas_Config.ExplodeTime = 5
