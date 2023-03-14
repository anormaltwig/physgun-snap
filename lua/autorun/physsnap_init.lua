local math_round = math.Round

local function snapVector(vec, vecSnap)
	return Vector(
		math_round(vec.x / vecSnap.x) * vecSnap.x,
		math_round(vec.y / vecSnap.y) * vecSnap.y,
		math_round(vec.z / vecSnap.z) * vecSnap.z
	)
end

local function snapAngle(ang, angSnap)
	return Angle(
		math_round(ang.p / angSnap.p) * angSnap.p,
		math_round(ang.y / angSnap.y) * angSnap.y,
		math_round(ang.r / angSnap.r) * angSnap.r
	)
end

if SERVER then
	util.AddNetworkString("PhysgunSnapPickup")

	local playerSettings = {}

	local function updatePlayerSettings(ply)
		playerSettings[ply] = {
			enabled = ply:GetInfoNum("physgunsnap_enabled", 0) > 0,

			obbSnap = ply:GetInfoNum("physgunsnap_obbsnap_enabled", 0) > 0,
			vecSnapEnabled = ply:GetInfoNum("physgunsnap_grid_enabled", 0) > 0,
			vecSnap = Vector(
				math.Clamp(ply:GetInfoNum("physgunsnap_grid_x", 1), 0, 1024),
				math.Clamp(ply:GetInfoNum("physgunsnap_grid_y", 1), 0, 1024),
				math.Clamp(ply:GetInfoNum("physgunsnap_grid_z", 1), 0, 1024)
			),

			angSnapEnabled = ply:GetInfoNum("physgunsnap_angsnap_enabled", 0) > 0,
			angSnap = Angle(
				math.max(0.5, ply:GetInfoNum("physgunsnap_angsnap_pitch", 0)),
				math.max(0.5, ply:GetInfoNum("physgunsnap_angsnap_yaw", 0)),
				math.max(0.5, ply:GetInfoNum("physgunsnap_angsnap_roll", 0))
			),

			freezeOnRelease = ply:GetInfoNum("physgunsnap_freezeonrelease", 0) > 0,
			nocollide = ply:GetInfoNum("physgunsnap_nocollide", 0) > 0,
		}
	end

	local physgunnedEntities = {}

	local function lockRotation(ent)
		if ent.rotationLockConstraint then ent.rotationLockConstraint:Remove() end

		ent.rotationLockConstraint = constraint.AdvBallsocket(
			ent, game.GetWorld(),
			0, 0, -- Bone
			Vector(), Vector(), -- LPos
			0, 0, -- Force Limit, Torque Limit
			0, 0, 0, -- Min Rotation Around Axis
			0, 0, 0, -- Max Rotation Around Axis
			0, 0, 0, -- Friction
			1, -- Rotation only
			0 -- Nocollide
		)
	end

	local function unlockRotation(ent)
		if IsValid(ent.rotationLockConstraint) then
			ent.rotationLockConstraint:Remove()
			ent.rotationLockConstraint = nil
		end
	end

	local function nocollide(ent)
		ent.oldCollisionGroup = ent.oldCollisionGroup or ent:GetCollisionGroup()
		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

		if ent.noCollideWorld then ent.noCollideWorld:Remove() end
		ent.noCollideWorld = constraint.AdvBallsocket(
			ent, game.GetWorld(),
			0, 0, Vector(), Vector(),
			0, 0,
			0, 0, 0,
			360, 360, 360,
			0, 0, 0,
			1,
			1
		)
	end

	local function recollide(ent)
		if ent.oldCollisionGroup then
			ent:SetCollisionGroup(ent.oldCollisionGroup)
			ent.oldCollisionGroup = nil
		end

		if ent.noCollideWorld then
			ent.noCollideWorld:Remove()
			ent.noCollideWorld = nil
		end
	end

	local function snapPosition(ent, gridScale)
		ent:SetPos(snapVector(ent:GetPos(), gridScale))
	end

	local function snapAngles(ent, angleSnap)
		ent:SetAngles(snapAngle(ent:GetAngles(), angleSnap))
	end

	hook.Add("OnPhysgunPickup", "PhysgunSnapping", function(ply, ent)
		updatePlayerSettings(ply)
		local settings = playerSettings[ply]
		if not settings.enabled then return end

		if ent:IsPlayer() then return end

		ent.holdingPlayer = ply

		lockRotation(ent)
		if settings.nocollide then
			nocollide(ent)
		end

		physgunnedEntities[ent] = true

		net.Start("PhysgunSnapPickup")
		net.WriteBool(true)
		net.WriteEntity(ent)
		net.Send(ply)
	end)

	hook.Add("PhysgunDrop", "PhysgunSnapping", function(ply, ent)
		local settings = playerSettings[ply]
		if not (settings and settings.enabled) then return end

		if ent:IsPlayer() then return end

		ent.holdingPlayer = nil

		unlockRotation(ent)

		if ent.noCollideWorld or ent.oldCollisionGroup then
			recollide(ent)
		end

		physgunnedEntities[ent] = nil

		if settings.vecSnapEnabled then
			if settings.obbSnap then
				snapPosition(ent, ent:OBBMaxs() - ent:OBBMins())
			else
				snapPosition(ent, settings.vecSnap)
			end
		end
		if settings.angSnapEnabled then
			snapAngles(ent, settings.angSnap)
		end

		if settings.freezeOnRelease then
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:EnableMotion(false)
			end
		end

		net.Start("PhysgunSnapPickup")
		net.WriteBool(false)
		net.Send(ply)
	end)

	hook.Add("EntityRemoved", "PhysgunSnapping", function(ent)
		if physgunnedEntities[ent] then
			physgunnedEntities[ent] = nil
		end
	end)

	hook.Add("Tick", "PhysgunSnapping", function()
		for ent in pairs(physgunnedEntities) do
			local ply = ent.holdingPlayer
			if not IsValid(ply) and ply:IsPlayer() then
				physgunnedEntities[ent] = nil
			else
				local settings = playerSettings[ply]

				if ply:KeyDown(IN_USE) then
					unlockRotation(ent)
				elseif not IsValid(ent.rotationLockConstraint) then
					if settings.angSnapEnabled then
						snapAngles(ent, settings.angSnap)
					end

					lockRotation(ent, settings.nocollide)
				end
			end
		end
	end)

	return
end

local physgunSnapEnabled = CreateConVar("physgunsnap_enabled", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)

local obbSnapEnabled = CreateConVar("physgunsnap_obbsnap_enabled", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)
local gridEnabled = CreateConVar("physgunsnap_grid_enabled", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)
local gridSnapX = CreateConVar("physgunsnap_grid_x", 1, FCVAR_USERINFO + FCVAR_ARCHIVE)
local gridSnapY = CreateConVar("physgunsnap_grid_y", 1, FCVAR_USERINFO + FCVAR_ARCHIVE)
local gridSnapZ = CreateConVar("physgunsnap_grid_z", 1, FCVAR_USERINFO + FCVAR_ARCHIVE)

local angSnapEnabled = CreateConVar("physgunsnap_angsnap_enabled", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)
local angSnapPitch = CreateConVar("physgunsnap_angsnap_pitch", 1, FCVAR_USERINFO + FCVAR_ARCHIVE)
local angSnapYaw   = CreateConVar("physgunsnap_angsnap_yaw",   1, FCVAR_USERINFO + FCVAR_ARCHIVE)
local angSnapRoll  = CreateConVar("physgunsnap_angsnap_roll",  1, FCVAR_USERINFO + FCVAR_ARCHIVE)

CreateConVar("physgunsnap_freezeonrelease", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)
CreateConVar("physgunsnap_nocollide", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)

local vectorSnap
local function updatePositionSnap()
	vectorSnap = Vector(
		gridSnapX:GetFloat(),
		gridSnapY:GetFloat(),
		gridSnapZ:GetFloat()
	)
end
updatePositionSnap()

local angleSnap
local function updateAngleSnap()
	angleSnap = Angle(
		angSnapPitch:GetFloat(),
		angSnapYaw:GetFloat(),
		angSnapRoll:GetFloat()
	)
end
updateAngleSnap()

local lineColor = Color(0, 90, 255)
local boxColor = Color(0, 100, 60, 30)
local highlightedBoxColor = Color(0, 255, 150)

local angleColor = Color(0, 160, 230)
local snappedAngleColor = Color(230, 0, 130)

local drawGrid = false
local drawAngleSnap = false
local heldEntity

net.Receive("PhysgunSnapPickup", function()
	if net.ReadBool() then
		if physgunSnapEnabled:GetInt() == 0 then return end

		drawGrid = gridEnabled:GetInt() > 0
		drawAngleSnap = angSnapEnabled:GetInt() > 0
		heldEntity = net.ReadEntity()

		if obbSnapEnabled:GetInt() > 0 then
			vectorSnap = heldEntity:OBBMaxs() - heldEntity:OBBMins()
		else
			updatePositionSnap()
		end
	else
		drawGrid = false
		drawAngleSnap = false
		heldEntity = nil
	end
end)

hook.Add("PreDrawTranslucentRenderables", "PhysgunSnapping", function(depth, skybox)
	if depth or skybox then return end
	if not (drawGrid or drawAngleSnap) then return end
	if not IsValid(heldEntity) then
		drawGrid = false
		drawAngleSnap = false
		return
	end

	local entPos = heldEntity:GetPos()
	local snappedPosition = entPos

	if drawGrid then
		snappedPosition = snapVector(entPos, vectorSnap)

		for i = -1, 1, 1 do
			for j = -1, 1 do
				for k = -1, 1 do
					render.DrawWireframeBox(
						snappedPosition + Vector(vectorSnap.x * i, vectorSnap.y * j, vectorSnap.z * k),
						Angle(),
						Vector(-vectorSnap.x / 2, -vectorSnap.y / 2, -vectorSnap.z / 2),
						Vector(vectorSnap.x / 2, vectorSnap.y / 2, vectorSnap.z / 2),
						boxColor
					)
				end
			end
		end
		render.DrawWireframeBox(
			snappedPosition,
			Angle(),
			Vector(-vectorSnap.x / 2, -vectorSnap.y / 2, -vectorSnap.z / 2),
			Vector(vectorSnap.x / 2, vectorSnap.y / 2, vectorSnap.z / 2),
			highlightedBoxColor
		)

		render.DrawLine(entPos, snappedPosition, lineColor)
	end

	if drawAngleSnap then
		render.DrawLine(entPos, entPos + heldEntity:GetForward() * 32, angleColor)
		render.DrawLine(entPos, entPos + heldEntity:GetRight() * 32, angleColor)
		render.DrawLine(entPos, entPos + heldEntity:GetUp() * 32, angleColor)

		local snappedAngle = snapAngle(heldEntity:GetAngles(), angleSnap)

		render.DrawLine(snappedPosition, snappedPosition + snappedAngle:Forward() * 32, snappedAngleColor)
		render.DrawLine(snappedPosition, snappedPosition + snappedAngle:Right() * 32, snappedAngleColor)
		render.DrawLine(snappedPosition, snappedPosition + snappedAngle:Up() * 32, snappedAngleColor)
	end
end)

hook.Add("AddToolMenuCategories", "PhysgunSnap", function()
	spawnmenu.AddToolCategory("Utilities", "PhysgunSnap", "PhysgunSnap")
end)

hook.Add("PopulateToolMenu", "PhysgunSnap", function()
	spawnmenu.AddToolMenuOption("Utilities", "PhysgunSnap", "physgunsnap_convar_menu", "Options", "", "", function(panel)
		panel:ClearControls()

		panel:CheckBox("PhysgunSnap Enabled", "physgunsnap_enabled"):SetTooltip("Enable PhysgunSnap.")

		panel:CheckBox("Freeze On Release", "physgunsnap_freezeonrelease"):SetTooltip("Always freeze entity when letting go.")
		panel:CheckBox("NoCollide", "physgunsnap_nocollide"):SetTooltip("When physgunning an entity, it will not collide with anything.")

		panel:CheckBox("Grid Snap Enabled", "physgunsnap_grid_enabled"):SetTooltip("Snap physgunned entity's position to a grid.")
		panel:CheckBox("Snap to Bounding Box", "physgunsnap_obbsnap_enabled"):SetTooltip("Snap physgunned entity's position to a grid based of the bounding box on the entity. (Needs Grid to be Enabled)")

		panel:NumSlider("X", "physgunsnap_grid_x", 1, 256, 0)
		panel:NumSlider("Y", "physgunsnap_grid_y", 1, 256, 0)
		panel:NumSlider("Z", "physgunsnap_grid_z", 1, 256, 0)

		panel:CheckBox("Angle Snap Enabled", "physgunsnap_angsnap_enabled"):SetTooltip("Snap physgunned entity's angles.")

		panel:NumSlider("Pitch", "physgunsnap_angsnap_pitch", 1, 180, 0)
		panel:NumSlider("Yaw",   "physgunsnap_angsnap_yaw",   1, 180, 0)
		panel:NumSlider("Roll",  "physgunsnap_angsnap_roll",  1, 180, 0)
	end)
end)

