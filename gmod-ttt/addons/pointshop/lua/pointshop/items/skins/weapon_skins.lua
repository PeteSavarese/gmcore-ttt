PS.SkinEventInfo = {
	["server_launch_2025"] = {
		ID = "server_launch_2025",
		begin = 0,
		["end"] = 1757131199, -- Sept 5, 2025 11:59 PM EST
		name = "Server Launch 2025",
	},
	["halloween_2025"] = {
		ID = "server_launch_2025",
		begin = 1761430944,
		["end"] = 1763269140, -- Nov 15, 2025 11:59 PM EST
		name = "Halloween 2025",
	},
	["christmas_2025"] = {
		ID = "christmas_2025",
		begin = 0,
		["end"] = 1767934799, -- Jan 8, 2026 11:59 PM EST
		name = "Christmas 2025",
	}
}

PS.weapon_skins_table = {
	{
		ID = "founders_harpoon",
		Begin = 0,
		["End"] = 0,
		Name = "Founder's Harpoon",
		Weapon = "weapon_ttt_harpoon",
		Price = 5,
		Event = "server_launch_2025",
		Requirements = {
			{type = "ulx_rank", value = "member"},
		},
		ViewModel = "models/weapons/gl/weapon_skins/founders_harpoon/harpoon002a.mdl",
		WorldModel = "models/weapons/gl/weapon_skins/founders_harpoon/harpoon002a.mdl"
	},
	{
		ID = "grimwons_goresplatter",
		Begin = 0,
		["End"] = 0,
		Name = "Grimwon's Gore Splatter",
		Weapon = "weapon_zm_improvised",
		Price = 0,
		Event = "halloween_2025",
		Requirements = {
			{type = "ulx_rank", value = "member"},
		},
		ViewModel = "models/weapons/gl/weapon_skins/grimwons_goresplatter/v_grimwons_goresplatter.mdl",
		WorldModel = "models/weapons/gl/weapon_skins/grimwons_goresplatter/w_grimwons_goresplatter.mdl"
	},
	{
		ID = "reapaliums_reaper",
		Begin = 0,
		["End"] = 0,
		Name = "Repalium's Reaper",
		Weapon = "weapon_zm_improvised",
		Price = 0,
		Event = "halloween_2025",
		Requirements = {
			{type = "ulx_rank", value = "member"},
		},
		ViewModel = "models/weapons/gl/weapon_skins/reapaliums_reaper/v_reapaliums_reaper.mdl",
		WorldModel = "models/weapons/gl/weapon_skins/reapaliums_reaper/w_reapaliums_reaper.mdl"
	},
	{
		ID = "unholy_spear",
		Begin = 0,
		["End"] = 0,
		Name = "Unholy Spear",
		Weapon = "weapon_ttt_harpoon",
		Price = 0,
		Event = "halloween_2025",
		Requirements = {
			{type = "ulx_rank", value = "member"},
		},
		ViewModel = "models/weapons/gl/weapon_skins/unholy_spear/unholy_spear.mdl",
		WorldModel = "models/weapons/gl/weapon_skins/unholy_spear/unholy_spear.mdl"
	},
	{
		ID = "candycane_harpoon",
		Begin = 0,
		["End"] = 0,
		Name = "Candy Cane Harpoon",
		Weapon = "weapon_ttt_harpoon",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "ulx_rank", value = "member"},
			{type = "event_playtime", event = "christmas_2025", value = 15},
		},
		ViewModel = "models/weapons/gl/weapon_skins/candycane_harpoon/sgm_candycane_harpoon.mdl",
		WorldModel = "models/weapons/gl/weapon_skins/candycane_harpoon/sgm_candycane_harpoon.mdl"
	},
	{
		ID = "icepoon",
		Begin = 0,
		["End"] = 0,
		Name = "Icepoon",
		Weapon = "weapon_ttt_harpoon",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "ulx_rank", value = "member"},
			{type = "event_playtime", event = "christmas_2025", value = 20},
		},
		ViewModel = "models/weapons/gl/weapon_skins/ice_harpoon/sgm_icepoon.mdl",
		WorldModel = "models/weapons/gl/weapon_skins/ice_harpoon/sgm_icepoon.mdl"
	},
	{
		ID = "golden_deagle",
		Begin = 0,
		["End"] = 0,
		Name = "Golden Deagle",
		Weapon = "weapon_zm_revolver",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "store_rank", value = 2},
		},
		ViewMaterials = {
			[1] = "models/gl/weapon_skins/golden_deagle/v_deagle_golden"
		},
		WorldMaterials = {
			[1] = "models/gl/weapon_skins/golden_deagle/w_deagle_golden"
		}
	},
	{
		ID = "christmas_c4",
		Begin = 0,
		["End"] = 0,
		Name = "Christmas C4",
		Weapon = "weapon_ttt_c4",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "ulx_rank", value = "member"},
			{type = "event_playtime", event = "christmas_2025", value = 10},
		},
		ViewMaterials = {
			[1] = "models/gl/weapon_skins/christmas_c4/v_models/c4_light",
			[2] = "models/gl/weapon_skins/christmas_c4/v_models/c4"
		},
		WorldMaterials = {
			[1] = "models/gl/weapon_skins/christmas_c4/w_models/w_c4"
		}
	},
	{
		ID = "christmas_p90",
		Begin = 0,
		["End"] = 0,
		Name = "Christmas P90",
		Weapon = "weapon_ttt_p90",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "store_rank", value = 2},
		},
		ViewMaterials = {
			[2] = "models/gl/weapon_skins/christmas_p90/v_models/front",
			[3] = "models/gl/weapon_skins/christmas_p90/v_models/back",
			[4] = "models/gl/weapon_skins/christmas_p90/v_models/mag"
		},
		WorldMaterials = {
			[1] = "models/gl/weapon_skins/christmas_p90/w_models/front",
			[2] = "models/gl/weapon_skins/christmas_p90/w_models/back",
			[3] = "models/gl/weapon_skins/christmas_p90/w_models/mag"
		}
	},
	{
		ID = "christmas_galil",
		Begin = 0,
		["End"] = 0,
		Name = "Christmas Galil",
		Weapon = "weapon_ttt_galil",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "ulx_rank", value = "member"},
			{type = "event_playtime", event = "christmas_2025", value = 5},
		},
		ViewMaterials = {
			[1] = "models/gl/weapon_skins/christmas_galil/v_models/rif_galil",
		},
		WorldMaterials = {
			[1] = "models/gl/weapon_skins/christmas_galil/w_models/w_rif_galil",
		}
	},
	{
		ID = "present_health_death_station",
		Begin = 0,
		["End"] = 0,
		Name = "Present Health/Deathstation",
		Weapon = "weapon_ttt_health_station",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "store_rank", value = 2},
		},
		ViewModel = "models/weapons/gl/weapon_skins/christmas_present/present_comm/Present_Comm.mdl",
		WorldModel = "models/weapons/gl/weapon_skins/christmas_present/present_comm/Present_Comm.mdl"
	},
	{
		ID = "rank_knife",
		Begin = 0,
		["End"] = 0,
		Name = "Rank Knife",
		Weapon = "weapon_ttt_knife",
		Price = 0,
		Event = "christmas_2025",
		IsRankColored = true,
		Requirements = {
			{type = "store_rank", value = 2},
		},
		ViewMaterials = {
			[1] = "models/gl/weapon_skins/rank_knife/rank_knife_t",
		},
		WorldMaterials = {
			[1] = "models/gl/weapon_skins/rank_knife/w_rank_knife_t",
		}
	},
	{
		ID = "christmas_famas",
		Begin = 0,
		["End"] = 0,
		Name = "Snowflake Famas",
		Weapon = "weapon_ttt_famas",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "store_rank", value = 1},
			{type = "weapon_kills", weapon = "weapon_ttt_famas", key = "christmas2025_famas_kills", value = 15},
		},
		ViewMaterials = {
			[1] = "models/gl/weapon_skins/christmas_famas/main_carry",
			[2] = "models/gl/weapon_skins/christmas_famas/norm_map",
			[3] = "models/gl/weapon_skins/christmas_famas/map2_map",
		},
		WorldMaterials = {
			[1] = "models/gl/weapon_skins/christmas_famas/map2_map",
			[2] = "models/gl/weapon_skins/christmas_famas/norm_map",
			[3] = "models/gl/weapon_skins/christmas_famas/main_carry",
		}
	},
	{
		ID = "christmas_357python",
		Begin = 0,
		["End"] = 0,
		Name = "Python Suomi",
		Weapon = "weapon_ttt_python",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "store_rank", value = 1},
			{type = "weapon_kills", weapon = "weapon_ttt_python", key = "christmas2025_python_kills", value = 20},
		},
		ViewMaterials = {
			[3] = "models/gl/weapon_skins/christmas_python/ts_python_skin"
		},
		WorldMaterials = {
			[1] = "models/gl/weapon_skins/christmas_python/ts_python_skin"
		}
	},
	{
		ID = "christmas_m24",
		Begin = 0,
		["End"] = 0,
		Name = "Arctic M24",
		Weapon = "weapon_ttt_m24",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "store_rank", value = 1},
			{type = "weapon_kills", weapon = "weapon_ttt_m24", key = "christmas2025_m24_kills", value = 15},
		},
		ViewMaterials = {
			[2] = "models/gl/weapon_skins/christmas_m24/m24"
		},
		WorldMaterials = {
			[1] = "models/gl/weapon_skins/christmas_m24/m24"
		}
	},
	{
		ID = "christmas_m4a4",
		Begin = 0,
		["End"] = 0,
		Name = "Winter's Howl M4A4",
		Weapon = "weapon_ttt_m4a4",
		Price = 0,
		Event = "christmas_2025",
		Requirements = {
			{type = "store_rank", value = 2},
			{type = "weapon_kills", weapon = "weapon_ttt_m4a4", key = "christmas2025_m4a4_kills", value = 15},
		},
		ViewMaterials = {
			[2] = "models/gl/weapon_skins/christmas_m4a4/rif_m4a1"
		},
		WorldMaterials = {
			[1] = "models/gl/weapon_skins/christmas_m4a4/rif_m4a1"
		}
	},
}
-- {
--   ID = "big_iron_winchester_1873",
--   begin = 0,
--   ["end"] = 1659355200,
--   name = "Winchester 1873 | Big Iron",
--   weapon = "weapon_ttt_winchester_1873",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 100
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/big_iron_winchester_1873/winchester"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/big_iron_winchester_1873/winchester"
--   }
-- },
-- {
--   ID = "case_hardened_remington_1858",
--   begin = 0,
--   ["end"] = 1659355200,
--   name = "Remington 1858 | Case Hardened",
--   weapon = "weapon_ttt_remington_1858",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 100
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/case_hardened_remington_1858/map2",
--     [3] = "models/gl/wep_skins/case_hardened_remington_1858/map1",
--     [4] = "models/gl/wep_skins/case_hardened_remington_1858/map3"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/case_hardened_remington_1858/map2",
--     [2] = "models/gl/wep_skins/case_hardened_remington_1858/map1",
--     [3] = "models/gl/wep_skins/case_hardened_remington_1858/map3"
--   }
-- },
-- {
--   ID = "christmas_ak47",
--   begin = 0,
--   ["end"] = 1641704400,
-- event = "xmas2022",
--   name = "AK-47 | Arctic Revenge",
--   weapon = "weapon_ttt_ak47",
--   price = 0,
--   required_rank = "supporter",
--   criteria = {
--     kills = 50
--   },
--   view_materials = {
--     [3] = "models/gl/wep_skins/christmas_ak47/t1",
--     [4] = "models/gl/wep_skins/christmas_ak47/t2",
--     [5] = "models/gl/wep_skins/christmas_ak47/pbs"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/christmas_ak47/t1",
--     [2] = "models/gl/wep_skins/christmas_ak47/t2",
--     [3] = "models/gl/wep_skins/christmas_ak47/pbs"
--   }
-- },
-- {
--   ID = "christmas_p90",
--   begin = 0,
--   ["end"] = 1641704400,
-- event = "xmas2022",
--   name = "P90 | Snow Tree",
--   weapon = "weapon_ttt_p90",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 100
--   },
--   view_model = "models/weapons/p90_xmas/v_p90_smg.mdl",
--   world_model = "models/weapons/p90_xmas/w_fn_p90.mdl"
-- },
-- {
--   ID = "christmas_usc",
--   begin = 0,
--   ["end"] = 1641704400,
-- event = "xmas2022",
--   name = "USC | Blue Ice",
--   weapon = "weapon_ttt_usc",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     kills = 150
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/christmas_usc/uscmap2",
--     [3] = "models/gl/wep_skins/christmas_usc/uscmap1"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/christmas_usc/uscmap2",
--     [3] = "models/gl/wep_skins/christmas_usc/uscmap1"
--   }
-- },
-- {
--   ID = "doppler_m249",
--   begin = 0,
--   ["end"] = 1669464000,
-- event = "fall2022",
--   name = "M249 | Doppler",
--   weapon = "weapon_zm_sledge",
--   price = 0,
--   required_rank = "supporter",
--   criteria = {
--     kills = 300
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/doppler_m249/mach_m249para",
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/doppler_m249/w_mach_m249"
--   }
-- },
-- {
--   ID = "doppler_scout",
--   begin = 0,
--   ["end"] = 1669464000,
-- event = "fall2022",
--   name = "Scout | Doppler",
--   weapon = "weapon_zm_sledge",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 200
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/doppler_scout/snip_scout",
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/doppler_scout/w_snip_scout"
--   }
-- },
-- {
--   ID = "fall_intervention",
--   begin = 0,
--   ["end"] = 1669464000,
-- event = "fall2022",
--   name = "Intervention | Fall",
--   weapon = "weapon_ttt_intervention",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     headshots = 250
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/fall_intervention/mw2_intervention",
--   },
--   world_materials = {
--     [2] = "models/gl/wep_skins/fall_intervention/mw2_intervention"
--   }
-- },
-- {
--   ID = "halloween_357python",
--   begin = 0,
--   ["end"] = 0,
--   name = "Colt Python | Candy Corn",
--   weapon = "weapon_ttt_python",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     headshots = 100
--   },
--   view_materials = {
--     [3] = "models/gl/wep_skins/halloween_357python/ts_python_skin",
--     [4] = "models/gl/wep_skins/halloween_357python/ts_bulletz"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/halloween_357python/ts_python_skin"
--   }
-- },
-- {
--   ID = "halloween_awp",
--   begin = 0,
--   ["end"] = 0,
--   name = "AWP | Night",
--   weapon = "weapon_ttt_awp",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 100
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/halloween_awp/v_awp_halloween"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/halloween_awp/w_awp_halloween"
--   }
-- },
-- {
--   ID = "halloween_deagle",
--   begin = 0,
--   ["end"] = 0,
--   name = "Deagle | Night",
--   weapon = "weapon_zm_revolver",
--   price = 0,
--   required_rank = "supporter",
--   criteria = {
--     headshots = 50
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/halloween_deagle/v_deagle_halloween"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/halloween_deagle/w_deagle_halloween"
--   }
-- },
-- {
--   ID = "january_m24",
--   begin = 0,
--   ["end"] = 0,
--   name = "M24 | Corrupted",
--   weapon = "weapon_ttt_m24",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     headshots = 100
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/january_m24/m24(2)",
--     [3] = "models/gl/wep_skins/january_m24/M241",
--     [7] = "models/gl/wep_skins/january_m24/bipod"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/january_m24/m24(2)",
--     [2] = "models/gl/wep_skins/january_m24/M241",
--     [3] = "models/gl/wep_skins/january_m24/bipod"
--   }
-- },
-- {
--   ID = "july4_barrett",
--   begin = 0,
--   ["end"] = 0,
--   name = "Barrett M82 | Stars and Stripes",
--   weapon = "weapon_ttt_barrett_m82",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     headshots = 20
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/july4_barrett/july4_m82"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/july4_barrett/july4_m82"
--   }
-- },
-- {
--   ID = "july4_colt",
--   begin = 0,
--   ["end"] = 0,
--   name = "Colt M1911 | Stars and Stripes",
--   weapon = "weapon_ttt_colt_m1911",
--   price = 0,
--   required_rank = "supporter",
--   criteria = {
--     kills = 20
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/july4_colt/july4_colt_frame",
--     [2] = "models/gl/wep_skins/july4_colt/july4_colt_slide"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/july4_colt/july4_colt_frame",
--     [2] = "models/gl/wep_skins/july4_colt/july4_colt_slide"
--   }
-- },
-- {
--   ID = "july4_m14ebr",
--   begin = 0,
--   ["end"] = 0,
--   name = "M14 EBR | Stars and Stripes",
--   weapon = "weapon_ttt_m14ebr",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     headshots = 30
--   },
--   view_materials = {
--     [4] = "models/gl/wep_skins/july4_m14ebr/july4_m14ebr"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/july4_m14ebr/july4_m14ebr"
--   }
-- },
-- {
--   ID = "july4_m4",
--   begin = 0,
--   ["end"] = 0,
--   name = "M4A1 | Stars and Stripes",
--   weapon = "weapon_ttt_m16",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 30
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/july4_m4/mag",
--     [3] = "models/gl/wep_skins/july4_m4/lower",
--     [4] = "models/gl/wep_skins/july4_m4/barrel",
--     [5] = "models/gl/wep_skins/july4_m4/fore",
--     [6] = "models/gl/wep_skins/july4_m4/grip",
--     [7] = "models/gl/wep_skins/july4_m4/magpul",
--     [8] = "models/gl/wep_skins/july4_m4/upper",
--     [9] = "models/gl/wep_skins/july4_m4/gemtech",
--     [10] = "models/gl/wep_skins/july4_m4/carry"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/july4_m4/mag",
--     [2] = "models/gl/wep_skins/july4_m4/lower",
--     [3] = "models/gl/wep_skins/july4_m4/barrel",
--     [4] = "models/gl/wep_skins/july4_m4/fore",
--     [5] = "models/gl/wep_skins/july4_m4/grip",
--     [6] = "models/gl/wep_skins/july4_m4/magpul",
--     [7] = "models/gl/wep_skins/july4_m4/upper",
--     [8] = "models/gl/wep_skins/july4_m4/gemtech",
--     [9] = "models/gl/wep_skins/july4_m4/carry"
--   }
-- },
-- {
--   ID = "july4_usp",
--   begin = 0,
--   ["end"] = 0,
--   name = "USP | USPS",
--   weapon = "weapon_ttt_usp",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     kills = 30
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/july4_usp/usp_map2",
--     [2] = "models/gl/wep_skins/july4_usp/usp_map1"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/july4_usp/usp_map2",
--     [2] = "models/gl/wep_skins/july4_usp/usp_map1"
--   }
-- },
-- {
--   ID = "midnight_an94",
--   begin = 0,
--   ["end"] = 1669464000,
-- event = "fall2022",
--   name = "AN-94 | Midnight",
--   weapon = "weapon_ttt_an94",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     kills = 200
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/midnight_an94/abakan_mag",
--     [2] = "models/gl/wep_skins/midnight_an94/abakan"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/midnight_an94/abakan_mag",
--     [2] = "models/gl/wep_skins/midnight_an94/abakan"
--   }
-- },
-- {
--   ID = "molten_m4a4",
--   begin = 0,
--   ["end"] = 0,
--   name = "M4A4 | Molten",
--   weapon = "weapon_ttt_m4a4",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 150
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/molten_m4a4/rif_m4a1"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/molten_m4a4/rif_m4a1"
--   }
-- },
-- {
--   ID = "ohio_m1_garand",
--   begin = 0,
--   ["end"] = 0,
--   name = "M1 Garand | Ohio",
--   weapon = "weapon_ttt_m1_garand",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     headshots = 150
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/ohio_m1_garand/frame m1 garand body"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/ohio_m1_garand/frame m1 garand body"
--   }
-- },
-- {
--   ID = "psl_shotgun",
--   begin = 0,
--   ["end"] = 1669464000,
--   event = "fall2022",
--   name = "Shotgun | PSL",
--   weapon = "weapon_zm_shotgun",
--   price = 0,
--   required_rank = "supporter",
--   criteria = {
--     kills = 50
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/psl_shotgun/shot_xm1014"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/psl_shotgun/w_shot_xm1014"
--   }
-- },
-- {
--   ID = "spring2022_deagle",
--   begin = 0,
--   ["end"] = 0,
--   name = "Deagle | Emerald Jormungandr",
--   weapon = "weapon_zm_revolver",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 150
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/spring2022_deagle/v_pist_deagle/v_deagle_skin1"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/spring2022_deagle/w_pist_deagle/w_pist_deagle"
--   }
-- },
-- {
--   ID = "spring_awp",
--   begin = 0,
--   ["end"] = 0,
--   name = "AWP | Spring Lore",
--   weapon = "weapon_ttt_awp",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     kills = 300
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/spring_lore_awp/awp",
--     [3] = "models/gl/wep_skins/spring_lore_awp/scope",
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/spring_lore_awp/awp",
--     [2] = "models/gl/wep_skins/spring_lore_awp/scope",
--   }
-- },
-- {
--   ID = "spring_f2000",
--   begin = 0,
--   ["end"] = 0,
--   name = "F2000 | Circuit",
--   weapon = "weapon_ttt_f2000",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 150
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/circuit_f2000/f2000_2",
--     [3] = "models/gl/wep_skins/circuit_f2000/f2000_1c",
--     [4] = "models/gl/wep_skins/circuit_f2000/f2000mag",
--     [5] = "models/gl/wep_skins/circuit_f2000/sniper_1_c_edis_b",
--     [6] = "models/gl/wep_skins/circuit_f2000/sniper_2_c_edis"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/circuit_f2000/f2000_2",
--     [2] = "models/gl/wep_skins/circuit_f2000/f2000_1c",
--     [3] = "models/gl/wep_skins/circuit_f2000/f2000mag",
--     [4] = "models/gl/wep_skins/circuit_f2000/sniper_1_c_edis_b",
--     [5] = "models/gl/wep_skins/circuit_f2000/sniper_2_c_edis"
--   }
-- },
-- {
--   ID = "spring_scout",
--   begin = 0,
--   ["end"] = 0,
--   name = "Scout | Galaxy",
--   weapon = "weapon_zm_rifle",
--   price = 0,
--   required_rank = "supporter",
--   criteria = {
--     kills = 50
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/galaxy_scout/snip_scout/snip_scout"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/galaxy_scout/w_snip_scout/w_snip_scout"
--   }
-- },
-- {
--   ID = "tiedie_fn_scarh",
--   begin = 0,
--   ["end"] = 0,
--   name = "SCAR-H | Tie Dye",
--   weapon = "weapon_ttt_scar",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 150
--   },
--   view_materials = {
--     [7] = "models/gl/wep_skins/tiedie_fn_scarh/mag_d_black",
--     [8] = "models/gl/wep_skins/tiedie_fn_scarh/scar_diff"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/tiedie_fn_scarh/mag_d_black",
--     [8] = "models/gl/wep_skins/tiedie_fn_scarh/scar_diff"
--   }
-- },
-- {
--   ID = "usa_colt_python",
--   begin = 0,
--   ["end"] = 0,
--   name = "Colt Python | USA",
--   weapon = "weapon_ttt_python",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 100
--   },
--   view_materials = {
--     [3] = "models/gl/wep_skins/usa_colt_python/ts_python_skin"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/usa_colt_python/ts_python_skin"
--   }
-- },
-- {
--   ID = "valentines_colt1911",
--   begin = 0,
--   ["end"] = 0,
--   name = "Colt M1911 | Valentine",
--   weapon = "weapon_ttt_colt_m1911",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 100
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/valentines_colt1911/frame",
--     [2] = "models/gl/wep_skins/valentines_colt1911/slide"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/valentines_colt1911/frame",
--     [2] = "models/gl/wep_skins/valentines_colt1911/slide"
--   }
-- },
-- {
--   ID = "valentines_m1",
--   begin = 0,
--   ["end"] = 0,
--   name = "M1 Garand | Valentine",
--   weapon = "weapon_ttt_m1_garand",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     kills = 150
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/valentines_m1/frame m1 garand body",
--     [3] = "models/gl/wep_skins/valentines_m1/frame m1 garand scope"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/valentines_m1/frame m1 garand body",
--     [2] = "models/gl/wep_skins/valentines_m1/frame m1 garand scope"
--   }
-- },
-- {
--   ID = "valentines_thompson",
--   begin = 0,
--   ["end"] = 0,
--   name = "Thompson | Valentine",
--   weapon = "weapon_ttt_thompson",
--   price = 0,
--   required_rank = "supporter",
--   criteria = {
--     kills = 50
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/valentines_thompson/sights512",
--     [2] = "models/gl/wep_skins/valentines_thompson/stuff1024",
--     [3] = "models/gl/wep_skins/valentines_thompson/main1024"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/valentines_thompson/sights512",
--     [2] = "models/gl/wep_skins/valentines_thompson/stuff1024",
--     [3] = "models/gl/wep_skins/valentines_thompson/main1024"
--   }
-- },
-- {
--   ID = "northern_waves_acr",
--   event = "xmas2022",
--   name = "ACR | Northern Waves",
--   weapon = "weapon_ttt_acr",
--   price = 0,
--   required_rank = "vip+",
--   criteria = {
--     kills = 150
--   },
--   view_materials = {
--     [3] = "models/gl/wep_skins/northern_waves_acr/v_model/mw2_acr.vmt",
--     [4] = "models/gl/wep_skins/northern_waves_acr/v_model/mw2_acr_ironsights.vmt",
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/northern_waves_acr/w_model/gun.vmt",
--     [2] = "models/gl/wep_skins/northern_waves_acr/w_model/Material_#11.vmt",
--     [3] = "models/gl/wep_skins/northern_waves_acr/w_model/back.vmt",
--   }
-- },
-- {
--   ID = "sky_wave_mp5",
--   event = "xmas2022",
--   name = "MP5 | Sky Waves",
--   weapon = "weapon_ttt_mp5",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 50
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/sky_waves_mp5/mp5_1.vmt",
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/sky_waves_mp5/w_smg_mp5.vmt",
--   }
-- },
-- {
--   ID = "perkele_colt_m1911",
--   event = "xmas2022",
--   name = "Colt M1911 | PERKELE",
--   weapon = "weapon_ttt_colt_m1911",
--   price = 0,
--   required_rank = "supporter",
--   criteria = {
--     kills = 50
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/perkele_colt_m1911/frame",
--     [2] = "models/gl/wep_skins/perkele_colt_m1911/slide"
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/perkele_colt_m1911/frame",
--     [2] = "models/gl/wep_skins/perkele_colt_m1911/slide"
--   }
-- },
-- {
--   ID = "winters_howl_awp",
--   event = "xmas2022",
--   name = "AWP | Winter's Howl",
--   weapon = "weapon_ttt_awp",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 50
--   },
--   view_materials = {
--     [2] = "models/gl/wep_skins/winters_howl_awp/awp",
--     [3] = "models/gl/wep_skins/spring_lore_awp/scope",
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/winters_howl_awp/awp",
--     [2] = "models/gl/wep_skins/spring_lore_awp/scope",
--   }
-- },
-- {
--   ID = "candy_crowbar",
--   event = "xmas2022",
--   name = "Candy Crowbar",
--   weapon = "weapon_zm_improvised",
--   price = 0,
--   required_rank = "supporter",
--   criteria = {
--     kills = 10
--   },
--   view_model = "models/weapons/candy_crowbar/candycane.mdl",
--   world_model = "models/weapons/candy_crowbar/candycane.mdl"
-- },
-- {
--   ID = "balloon_gun",
--   begin = 0,
--   ["end"] = 0,
--   name = "Balloon Gun",
--   weapon = "weapon_ttt_manhack_gun",
--   price = 0,
--   required_rank = "event",
--   view_model = "models/weapons/c_pistol.mdl",
--   world_model = "models/weapons/w_pistol.mdl"
-- },
-- {
--   ID = "aurora_mac10",
--   event = "xmas2023",
--   name = "Mac 10 | Aurora",
--   weapon = "weapon_zm_mac10",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 150
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/aurora_mac10/smg_mac10_1",
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/aurora_mac10/w_smg_mac10",
--   }
-- },
-- {
--   ID = "knife_knife_baby",
--   event = "xmas2023",
--   name = "Knife Knife Baby",
--   weapon = "weapon_ttt_knife",
--   price = 0,
--   required_rank = "vip",
--   criteria = {
--     kills = 50
--   },
--   view_materials = {
--     [1] = "models/gl/wep_skins/knife_knife_baby/knife_t",
--   },
--   world_materials = {
--     [1] = "models/gl/wep_skins/knife_knife_baby/w_knife_t",
--   }
-- },