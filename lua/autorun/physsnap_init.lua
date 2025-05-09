PhysSnap = {}

local dir = "physgun-snap/"
if SERVER then
	include(dir .. "sv_playersettings.lua")
	include(dir .. "sv_snap.lua")

	AddCSLuaFile(dir .. "cl_menu.lua")
	AddCSLuaFile(dir .. "cl_overlay.lua")

	return
end

include(dir .. "cl_menu.lua")
include(dir .. "cl_overlay.lua")
