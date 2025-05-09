function PhysSnap.GetSettings(ply)
	return {
		enabled = ply:GetInfoNum("physgunsnap_enabled", 0) > 0,

		snap_bounding_box = ply:GetInfoNum("physgunsnap_obbsnap_enabled", 0) > 0,

		snap_grid = ply:GetInfoNum("physgunsnap_grid_enabled", 0) > 0,
		snap_grid_scale = Vector(
			math.Clamp(ply:GetInfoNum("physgunsnap_grid_x", 1), 0, 1024),
			math.Clamp(ply:GetInfoNum("physgunsnap_grid_y", 1), 0, 1024),
			math.Clamp(ply:GetInfoNum("physgunsnap_grid_z", 1), 0, 1024)
		),

		snap_angle = ply:GetInfoNum("physgunsnap_angsnap_enabled", 0) > 0,
		snap_angle_scale = Angle(
			math.max(0.5, ply:GetInfoNum("physgunsnap_angsnap_pitch", 0)),
			math.max(0.5, ply:GetInfoNum("physgunsnap_angsnap_yaw", 0)),
			math.max(0.5, ply:GetInfoNum("physgunsnap_angsnap_roll", 0))
		),

		freeze = ply:GetInfoNum("physgunsnap_freezeonrelease", 0) > 0,
		nocollide = ply:GetInfoNum("physgunsnap_nocollide", 0) > 0,
	}
end
