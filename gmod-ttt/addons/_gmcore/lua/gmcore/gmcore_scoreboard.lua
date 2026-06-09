---TTT Scoreboard customization: name colors and custom columns for staff/store ranks

hook.Add("TTTScoreboardColorForPlayer", "gmcore.Scoreboard.PlayerColor", function(ply)
	if !IsValid(ply) then return color_white end

	-- ULX Group Name Coloring
	if ply:IsStaffRank() then
		local tGroupInfo = gmcore.Ranks[ply:GetUserGroup()]
		if !tGroupInfo then return end

		return tGroupInfo.color
	end

	-- Store Rank Name Coloring
	if !ply:IsStoreRank() then
		return Color(255, 255, 255)
	elseif ply:IsStoreRank() and !ply:IsStaffRank() then
		return gmcore.StoreRank.Ranks[ply:GetStoreRank()].color
	end
end)

hook.Add("TTTScoreboardColumns", "gmcore.Scoreboard.StaffGroupDisplay", function(pnl)
	-- ULX Groups Label & Label Color
	pnl:AddColumn("Staff Rank", function(ply, label)
		if IsValid(ply) and ply:IsStaffRank() then
			local tGroupInfo = gmcore.Ranks[ply:GetUserGroup()]
			if !tGroupInfo then return "" end

			label:SetTextColor(tGroupInfo.color)

			return tGroupInfo.niceName
		end

		return ""
	end, 150)

	-- Store Ranks Label & Label Color
	pnl:AddColumn("User Rank", function(ply, label)
		if IsValid(ply) then
			local sReturnGroup = ""

			if !ply:IsStoreRank() then
				if ply:IsUserGroup("member") then
					sReturnGroup = "Member"
					label:SetColor(Color(255, 255, 255))

					return sReturnGroup
				else
					label:SetColor(Color(255, 255, 255))

					return sReturnGroup
				end
			else
				label:SetColor(gmcore.StoreRank.Ranks[ply:GetStoreRank()].color)

				return gmcore.StoreRank.Ranks[ply:GetStoreRank()].name
			end
		end

		return ""
	end, 100)
end)
