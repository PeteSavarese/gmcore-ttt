---Damagelog role constants for players who aren't in standard TTT roles.

-- ROLES
-- Defined in terrortown/gamemode/shared.lua
-- ROLE_INNOCENT  = 0
-- ROLE_TRAITOR   = 1
-- ROLE_DETECTIVE = 2
DAMAGELOG_ROLE_SPECTATOR            = -3 -- Used when a player is spectating at the start of a round
DAMAGELOG_ROLE_JOINAFTERROUNDSTART  = -2 -- Used when a player joins after the round has already started
DAMAGELOG_ROLE_DISCONNECTED         = "disconnected" -- Used when a player uses a radio command on a disconnected player's dead body
