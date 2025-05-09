CreateConVar("physgunsnap_enabled", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)

CreateConVar("physgunsnap_obbsnap_enabled", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)
CreateConVar("physgunsnap_grid_enabled", 1, FCVAR_USERINFO + FCVAR_ARCHIVE)
CreateConVar("physgunsnap_grid_x", 1, FCVAR_USERINFO + FCVAR_ARCHIVE)
CreateConVar("physgunsnap_grid_y", 1, FCVAR_USERINFO + FCVAR_ARCHIVE)
CreateConVar("physgunsnap_grid_z", 1, FCVAR_USERINFO + FCVAR_ARCHIVE)

CreateConVar("physgunsnap_angsnap_enabled", 1, FCVAR_USERINFO + FCVAR_ARCHIVE)
CreateConVar("physgunsnap_angsnap_pitch", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)
CreateConVar("physgunsnap_angsnap_yaw",   0, FCVAR_USERINFO + FCVAR_ARCHIVE)
CreateConVar("physgunsnap_angsnap_roll",  0, FCVAR_USERINFO + FCVAR_ARCHIVE)

CreateConVar("physgunsnap_freezeonrelease", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)
CreateConVar("physgunsnap_nocollide", 0, FCVAR_USERINFO + FCVAR_ARCHIVE)

hook.Add("AddToolMenuCategories", "physgunsnap", function()
	spawnmenu.AddToolCategory("Utilities", "PhysgunSnap", "PhysgunSnap")
end)

hook.Add("PopulateToolMenu", "physgunsnap", function()
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

