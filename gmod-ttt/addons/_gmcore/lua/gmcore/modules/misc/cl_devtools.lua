concommand.Add("_gl_dev_printwepsubmats", function(ply, cmd, args)
	if !ply:HasStaffPerms() then return end

	local sWeaponInput = args[1]

	if sWeaponInput == nil or sWeaponInput == "" then gmcore.print("[DEV] Invalid weapon class") return end

	local tWepInfo = weapons.Get(sWeaponInput)
	if tWepInfo == nil then gmcore.print("[DEV] Invalid weapon class") return end

	local tempEnt = ClientsideModel(tWepInfo.ViewModel)

	gmcore.print("[DEV] " .. sWeaponInput .. " viewmodel sub materials:")
	PrintTable(tempEnt:GetMaterials())

	tempEnt:SetModel(tWepInfo.WorldModel)

	print("\n")

	gmcore.print("[DEV] " .. sWeaponInput .. " worldmodel sub materials:")
	PrintTable(tempEnt:GetMaterials())

	tempEnt:Remove()
end)
