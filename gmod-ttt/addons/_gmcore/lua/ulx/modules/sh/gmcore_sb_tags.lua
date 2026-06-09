if CLIENT then

		function ulx.cl_ttt_mark( target, mark_type )
		if GetRoundState() != ROUND_ACTIVE then return end
				if not target then
						local current, vague = RADIO:GetTarget() --see cl_voice.lua, "current" won't be valid if disguised, dead
						print(current)
						print(vague)
						if vague then return end
						target = current
				end

				local mark_types = {
						{mark_type="f", tag=scoreboard_tags[1]},
						{mark_type="friend", tag=scoreboard_tags[1]},
						{mark_type="friendly", tag=scoreboard_tags[1]},

						{mark_type="s", tag=scoreboard_tags[2]},
						{mark_type="susp", tag=scoreboard_tags[2]},
						{mark_type="suspicious", tag=scoreboard_tags[2]},

						{mark_type="a", tag=scoreboard_tags[3]},
						{mark_type="avoid", tag=scoreboard_tags[3]},

						{mark_type="k", tag=scoreboard_tags[4]},
						{mark_type="kill", tag=scoreboard_tags[4]},

						{mark_type="m", tag=scoreboard_tags[5]},
						{mark_type="miss", tag=scoreboard_tags[5]},
						{mark_type="missing", tag=scoreboard_tags[5]}
				}

				local tag = nil

				for i,v in ipairs(mark_types) do
						if v.mark_type == mark_type then
								target.sb_tag = v.tag
								print(v.tag)
								break
						end
				end
	end
end

function ulx.ttt_mark( calling_ply, mark_type, target )
		if not calling_ply:IsValid() then
				return
		end

		if target == calling_ply then -- this means they didn't specify a target
				target = nil
		end

		ULib.clientRPC( calling_ply, "ulx.cl_ttt_mark", target, mark_type )
end

local ttt_mark = ulx.command( "TTT Utility", "ulx mark", ulx.ttt_mark, {"!mark"} )
ttt_mark:addParam{ type=ULib.cmds.StringArg, help="label", completes={"friendly", "suspicious", "avoid", "kill", "missing"} }
ttt_mark:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional, ULib.cmds.ignoreCanTarget }
ttt_mark:defaultAccess( ULib.ACCESS_ALL )
ttt_mark:help( "Marks the targeted player." )
