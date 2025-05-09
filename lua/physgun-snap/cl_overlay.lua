local enabled = GetConVar("physgunsnap_enabled")

local snap_to_obb = GetConVar("physgunsnap_obbsnap_enabled")

local grid_enabled = GetConVar("physgunsnap_grid_enabled")
local grid_x = GetConVar("physgunsnap_grid_x")
local grid_y = GetConVar("physgunsnap_grid_y")
local grid_z = GetConVar("physgunsnap_grid_z")

local angsnap_enabled = GetConVar("physgunsnap_angsnap_enabled")
local angsnap_p = GetConVar("physgunsnap_angsnap_pitch")
local angsnap_y = GetConVar("physgunsnap_angsnap_yaw")
local angsnap_r = GetConVar("physgunsnap_angsnap_roll")

local line_color = Color(0, 90, 255)
local box_color = Color(0, 100, 60, 30)
local box_color_alt = Color(0, 255, 150)

local angle_color = Color(0, 160, 230)
local angle_snap_color = Color(230, 0, 130)

local angle_snap
local grid_size
local held_ent

net.Receive("physgunsnap-pickup", function()
	if net.ReadBool() then
		if enabled:GetInt() == 0 then return end

		held_ent = net.ReadEntity()

		angle_snap = Angle(angsnap_p:GetFloat(), angsnap_y:GetFloat(), angsnap_r:GetFloat())
		if snap_to_obb:GetInt() > 0 then
			grid_size = held_ent:OBBMaxs() - held_ent:OBBMins()
		else
			grid_size = Vector(grid_x:GetFloat(), grid_y:GetFloat(), grid_z:GetFloat())
		end
	else
		held_ent = nil
	end
end)

local math_round = math.Round

local function snap_vec(vec, grid_scale)
	return Vector(
		math_round(vec.x / grid_scale.x) * grid_scale.x,
		math_round(vec.y / grid_scale.y) * grid_scale.y,
		math_round(vec.z / grid_scale.z) * grid_scale.z
	)
end

local function snap_ang(ang, ang_snap)
	return Angle(
		math_round(ang.p / ang_snap.p) * ang_snap.p,
		math_round(ang.y / ang_snap.y) * ang_snap.y,
		math_round(ang.r / ang_snap.r) * ang_snap.r
	)
end

hook.Add("PostDrawTranslucentRenderables", "physgunsnap", function(depth, skybox)
	if depth or skybox then return end
	if not IsValid(held_ent) then
		return
	end

	local ent_pos = held_ent:GetPos()
	local snapped_pos = ent_pos

	if grid_enabled:GetInt() > 0 then
		snapped_pos = snap_vec(ent_pos, grid_size)

		for i = -1, 1, 1 do
			for j = -1, 1 do
				for k = -1, 1 do
					render.DrawWireframeBox(
						snapped_pos + Vector(grid_size.x * i, grid_size.y * j, grid_size.z * k),
						Angle(),
						Vector(-grid_size.x / 2, -grid_size.y / 2, -grid_size.z / 2),
						Vector(grid_size.x / 2, grid_size.y / 2, grid_size.z / 2),
						box_color
					)
				end
			end
		end
		render.DrawWireframeBox(
			snapped_pos,
			Angle(),
			Vector(-grid_size.x / 2, -grid_size.y / 2, -grid_size.z / 2),
			Vector(grid_size.x / 2, grid_size.y / 2, grid_size.z / 2),
			box_color_alt
		)

		render.DrawLine(ent_pos, snapped_pos, line_color)
	end

	if angsnap_enabled:GetInt() > 0 then
		render.DrawLine(ent_pos, ent_pos + held_ent:GetForward() * 32, angle_color)
		render.DrawLine(ent_pos, ent_pos + held_ent:GetRight() * 32, angle_color)
		render.DrawLine(ent_pos, ent_pos + held_ent:GetUp() * 32, angle_color)

		local snapped_angle = snap_ang(held_ent:GetAngles(), angle_snap)

		render.DrawLine(snapped_pos, snapped_pos + snapped_angle:Forward() * 32, angle_snap_color)
		render.DrawLine(snapped_pos, snapped_pos + snapped_angle:Right() * 32, angle_snap_color)
		render.DrawLine(snapped_pos, snapped_pos + snapped_angle:Up() * 32, angle_snap_color)
	end
end)
