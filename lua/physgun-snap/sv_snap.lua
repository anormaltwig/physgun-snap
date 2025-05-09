local math_round = math.Round

local function snap_vec(vec, grid_scale)
	return Vector(
		math_round(vec.x / grid_scale.x) * grid_scale.x,
		math_round(vec.y / grid_scale.y) * grid_scale.y,
		math_round(vec.z / grid_scale.z) * grid_scale.z
	)
end

local function snap_position(ent, grid_scale)
	ent:SetPos(snap_vec(ent:GetPos(), grid_scale))
end

local function snap_ang(ang, ang_snap)
	return Angle(
		math_round(ang.p / ang_snap.p) * ang_snap.p,
		math_round(ang.y / ang_snap.y) * ang_snap.y,
		math_round(ang.r / ang_snap.r) * ang_snap.r
	)
end

local function snap_angles(ent, angle_snap)
	ent:SetAngles(snap_ang(ent:GetAngles(), angle_snap))
end

local zero_vec = Vector(0, 0, 0)

local rotation_locks = {}
local function lock_rotation(ent)
	if rotation_locks[ent] then rotation_locks[ent]:Remove() end

	rotation_locks[ent] = constraint.AdvBallsocket(
		ent, game.GetWorld(),
		0, 0, -- Bone
		zero_vec, zero_vec, -- LPos
		0, 0, -- Force Limit, Torque Limit
		0, 0, 0, -- Min Rotation Around Axis
		0, 0, 0, -- Max Rotation Around Axis
		0, 0, 0, -- Friction
		1, -- Rotation only
		0 -- Nocollide
	)
end

local function unlock_rotation(ent)
	local lock = rotation_locks[ent]
	rotation_locks[ent] = nil

	if IsValid(lock) then
		lock:Remove()
	end
end

local nocollided_ents = {}
local function nocollide(ent)
	local entry = nocollided_ents[ent]
	if not entry then
		entry = {}
		nocollided_ents[ent] = entry
	end

	if entry.constraint then entry.constraint:Remove() end

	if not entry.old_collision_group then
		entry.old_collision_group = ent:GetCollisionGroup()
	end
	ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

	entry.constraint = constraint.AdvBallsocket(
		ent, game.GetWorld(),
		0, 0,
		zero_vec, zero_vec,
		0, 0,
		0, 0, 0,
		360, 360, 360,
		0, 0, 0,
		1,
		1
	)
end

local function recollide(ent)
	local entry = nocollided_ents[ent]
	nocollided_ents[ent] = nil

	if not entry then return end

	ent:SetCollisionGroup(entry.old_collision_group)
	if IsValid(entry.constraint) then
		entry.constraint:Remove()
	end
end

util.AddNetworkString("physgunsnap-pickup")
local physgunned_entities = {}
hook.Add("OnPhysgunPickup", "physgunsnap", function(ply, ent)
	if ent:IsPlayer() then return end

	local settings = PhysSnap.GetSettings(ply)
	if not settings.enabled then return end

	lock_rotation(ent)
	if settings.nocollide then
		nocollide(ent)
	end

	physgunned_entities[ent] = ply

	net.Start("physgunsnap-pickup")
	net.WriteBool(true)
	net.WriteEntity(ent)
	net.Send(ply)
end)

hook.Add("PhysgunDrop", "physgunsnap", function(ply, ent)
	if ent:IsPlayer() then return end

	if not physgunned_entities[ent] then return end
	physgunned_entities[ent] = nil

	local settings = PhysSnap.GetSettings(ply)
	if not settings.enabled then return end

	if settings.freeze then
		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion(false)
		end
	end

	unlock_rotation(ent)
	if nocollided_ents[ent] then
		recollide(ent)
	end

	if settings.snap_grid then
		if settings.snap_bounding_box then
			snap_position(ent, ent:OBBMaxs() - ent:OBBMins())
		else
			snap_position(ent, settings.snap_grid_scale)
		end
	end
	if settings.snap_angle then
		snap_angles(ent, settings.snap_angle_scale)
	end

	net.Start("physgunsnap-pickup")
	net.WriteBool(false)
	net.Send(ply)
end)

hook.Add("EntityRemoved", "physgunsnap", function(ent)
	if physgunned_entities[ent] then
		physgunned_entities[ent] = nil
	end
end)

hook.Add("Tick", "physgunsnap", function()
	for ent, ply in pairs(physgunned_entities) do
		if not IsValid(ply) then
			physgunned_entities[ent] = nil
		else
			local settings = PhysSnap.GetSettings(ply)

			if ply:KeyDown(IN_USE) then
				unlock_rotation(ent)
			elseif not rotation_locks[ent] then
				if settings.snap_angle then
					snap_angles(ent, settings.snap_angle_scale)
				end
				lock_rotation(ent)
			end
		end
	end
end)
