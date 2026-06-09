resource.OldAddWorkshop("3489328811") -- GL Modded Map Vote Icons
resource.OldAddWorkshop("3489487398") -- GL Shared Server Content
resource.AddWorkshop("3489487718")    -- GL TTT Modded Weapon Content
resource.AddWorkshop("3515992795")    -- GL TTT Jihad Sounds
resource.AddWorkshop("3516027203")    -- GL TTT Playermodels
resource.AddWorkshop("3531642093")    -- GL Weapon Skins
resource.OldAddWorkshop("3581252772") -- GL Halloween 2025 Map Vote Icons
resource.AddWorkshop("3590261369")    -- GL Halloween 2025 Content
resource.AddWorkshop("3626437410")    -- GL Christmas 2025 Content
resource.AddWorkshop("3671860517")    -- GL February 2026 Playermodels

-- resource.AddWorkshop("2914673702") -- AHG Weapons v2
-- resource.OldAddWorkshop("2896459208") -- AHG Modded Extras v2
-- resource.OldAddWorkshop("2896459358") -- AHG Player Models v2
-- resource.OldAddWorkshop("2896459695") -- AHG Shared Extras v2
-- resource.OldAddWorkshop("2896459848") -- AHG UI v2
-- resource.OldAddWorkshop("2896459046") -- AHG Jihad Sounds v2
-- resource.OldAddWorkshop("2896460013") -- AHG Weapon Skins v2
-- resource.OldAddWorkshop("2867759964") -- AHG Modded map vote icons
-- resource.OldAddWorkshop("2712929635") -- AHG Shared Map Vote Icons
-- resource.OldAddWorkshop("2783993587") -- TTT Boogie Bomb
-- resource.OldAddWorkshop("2896524281") -- AHG Winter Mapvote icons
-- resource.OldAddWorkshop("2920178872") -- AHG 2022 Winter Content (USAS, F1 Menu)
-- resource.OldAddWorkshop("2932043094") -- Balloon
-- resource.OldAddWorkshop("1732572337") -- Bump Mine
-- resource.OldAddWorkshop("3102131216") -- AHG 2023 Winter Content
--
-- -- non-AHG addons
-- resource.OldAddWorkshop("1940868291") -- Airpods Addon
-- resource.OldAddWorkshop("428553583") -- Agent Smith sunglasses addon

-- resource.AddFile("resource/shared/example/index.html.dat")

---Table to convert map names into their workshop IDs; reduces network traffic by downloading from Steam Workshop.
---@type table<string, string> Map file name -> Workshop ID
mapsToWorkshopID = {
	["classified_map"] = "2867110139",
	["cs_assault"] = "2867112800",
	["cs_desperados_2"] = "2867133809",
	["cs_parkhouse"] = "2867254878",
	["de_crash"] = "2867135971",
	["de_dust2"] = "2926580315",
	["de_fang"] = "2867211369",
	["ttt_67thway_v14"] = "298470515",
	["ttt_airbus_b3"] = "253297309",
	["ttt_aircraft_v1b"] = "2867225842",
	["ttt_albatross_fbeta"] = "2867226621",
	["ttt_alien"] = "3489440577",
	["ttt_alps"] = "2867227253",
	["ttt_amsterville_2015"] = "104518391",
	["ttt_bank_b13"] = "610493442",
	["ttt_bb_suburbia_b3"] = "2867232207",
	["ttt_bb_teenroom_b2"] = "2326356403",
	["ttt_beachbar"] = "2867234067",
	["ttt_bikinibottom"] = "2867234743",
	["ttt_black_mesa_east_2019"] = "2530803294",
	["ttt_bungalows"] = "2867236193",
	["ttt_camel_fix2"] = "2867236622",
	["ttt_canyon_a4"] = "224282233",
	["ttt_chaser_v2"] = "109410344",
	["ttt_clue_se"] = "281454209",
	["ttt_cod4_vacant"] = "2867338533",
	["ttt_comet_observatory"] = "2867340076",
	["ttt_community_bowling_v5a"] = "131667838",
	["ttt_community_pool_2017_b4"] = "2867341112",
	["ttt_crackhouse"] = "2867341711",
	["ttt_cruise"] = "2867343582",
	["ttt_crummycradle_b1fix"] = "2867344045",
	["ttt_datmap_v2b"] = "384171364",
	["ttt_devoz_v4"] = "2054763555",
	["ttt_dolls"] = "195227686",
	["ttt_forest_final"] = "147635981",
	["ttt_hairyhouse"] = "3489437590",
	["ttt_heaven"] = "2867350342",
	["ttt_hotline_miami"] = "2867351821",
	["ttt_hotwireslum2016"] = "2867352150",
	["ttt_innocentmotel_v1"] = "285372790",
	["ttt_intergalactic"] = "346194598",
	["ttt_island_2013"] = "183797802",
	["ttt_lego_fix"] = "2867353549",
	["ttt_lifetheroof_b2_fix2017"] = "927598931",
	["ttt_lttp_kakariko_a5"] = "2867354096",
	["ttt_magma_v2a"] = "208061322",
	["ttt_manorhouse"] = "2871812791",
	["ttt_mc_airship_fix"] = "323390749",
	["ttt_mc_bank"] = "2243078088",
	["ttt_mc_dinkledome"] = "3350519501",
	["ttt_mc_dolls_v4"] = "627510499",
	["ttt_mc_electricavenue"] = "2748316431",
	["ttt_minecraft_expedition_small"] = "843525860",
	["ttt_mc_nuketown"] = "2867356548",
	["ttt_mc_nuketown_b1"] = "1599146184",
	["ttt_mc_office"] = "2227051551",
	["ttt_mc_richland"] = "1942717329",
	["ttt_mc_seriouscraft_b6"] = "492448364",
	["ttt_mc_snow_v2"] = "699415263",
	["ttt_mc_tinytown_b69"] = "2362023165",
	["ttt_minecraft_haven"] = "389346280",
	["ttt_minecraft_mythic_r2"] = "883367518",
	["ttt_minecraftmotel_b2u"] = "644815396",
	["ttt_skycraftfinal"] = "964809283",
	["ttt_metropolis"] = "153600777",
	["ttt_minecraft_b5"] = "2867358112",
	["ttt_minecraftcity_v4"] = "2867358730",
	["ttt_mountainresort_snow"] = "2867362855",
	["ttt_museum_heist_v6"] = "472909258",
	["ttt_mw2_rust"] = "2867364512",
	["ttt_mw2_scrapyard"] = "2867364710",
	["ttt_mw2_terminal"] = "2867364936",
	["ttt_highrise_dinks"] = "3416203129",
	["ttt_northsea"] = "2867365193",
	["ttt_nuclear_power_v4_fix"] = "1198663315",
	["ttt_oldruins"] = "2867367855",
	["ttt_orange_v8_reworked"] = "2867368156",
	["ttt_pelicantown"] = "2867368480",
	["ttt_plaza_b7e"] = "2867368685",
	["ttt_poolparty"] = "2867369164",
	["ttt_portals_v9"] = "2867369435",
	["ttt_rats_kitchen"] = "3489430596",
	["ttt_resort"] = "2867369830",
	["ttt_richland_remix"] = "2867370115",
	["ttt_rivercliff"] = "2871812995",
	["ttt_rooftops_2016_v1"] = "2867370655",
	["ttt_roy_the_ship"] = "108040571",
	["ttt_safetown"] = "2871813378",
	["ttt_sands"] = "2867371562",
	["ttt_scavenge"] = "468382688",
	["ttt_sens"] = "2867371921",
	["ttt_signal_v2"] = "595172792",
	["ttt_skatepark"] = "2871813532",
	["ttt_skeld"] = "2867372207",
	["ttt_ski_resort"] = "2867372478",
	["ttt_skyworld_dxm"] = "2897024672",
	["ttt_spacecraft_03d"] = "2867372726",
	["ttt_summermansion_b3"] = "2867373121",
	["ttt_terrortrain_2020"] = "2867374029",
	["ttt_thething"] = "2867374888",
	["ttt_tilted_towers"] = "2867375113",
	["ttt_tokyodistrict"] = "2867375290",
	["ttt_trappycottage"] = "2871813984",
	["ttt_upstate"] = "2868206328",
	["ttt_vessel"] = "121935805",
	["ttt_villa2"] = "2867375600",
	["ttt_volcano"] = "2867375843",
	["ttt_waterworld_2020"] = "2867376109",
	["ttt_westwood_v4_ahg_v2"] = "2871811539",
	["ttt_whitehouse_v9"] = "2867377202",
	["ttt_xdea"] = "2871814147",
	["ttt_xmas_nipperhouse"] = "3519808020",
	-- Fall Maps
	["de_haunts"] = "2871811092",
	["ttt_mw2_rust_halloween"] = "2874193076",
	["de_chateau_night"] = "2871810744",
	["de_dust2_halloween"] = "2871814739",
	["ttt_68thway_zombient"] = "2871811821",
	["ttt_community_pool_halloween"] = "2871814915",
	["ttt_der_riese"] = "2871812496",
	["ttt_lazertag"] = "2868206777",
	["ttt_magma_halloween"] = "2871815185",
	["ttt_slender"] = "2871813719",
	["ttt_spookymotel"] = "2871815548",
	["ttt_terrorception"] = "2871813832",
	["ttt_livehouse_v2"] = "3583274702",
	["ttt_minecraftcity_v4_dark"] = "270336755",
	["ttt_minecraft_b6_spooky"] = "1894068776",
	-- Winter Maps
	["de_icehouse"] = "2896998926",                 -- done
	["gg_woods_xmas"] = "2896999653",               -- done
	["ttt_apehouse_xmas"] = "2897009285",           -- done
	["ttt_christmas_village"] = "2897013533",       -- done
	["ttt_clue_xmas"] = "2897015359",               -- done
	["ttt_community_pool_xmas"] = "2897017536",     -- done
	["ttt_hotline_miami_xmas"] = "3367055328",      -- done
	["ttt_icecap"] = "2897020256",                  -- done
	["ttt_island_xmas"] = "2897020930",             -- done
	["ttt_jingle_street"] = "2897021532",           -- done
	["ttt_lifetheroof_xmas"] = "2897021992",        -- done
	["ttt_mc_christmastown_ahg"] = "2897022474",        -- done
	["ttt_mc_santas_workshop"] = "2897023690",      -- done
	["ttt_minecraft_snowden"] = "2897024012",       -- done
	["ttt_snowy_eve"] = "2897024989",               -- done
	["ttt_the_room_christmas"] = "2897026118",      -- done
	["ttt_xdea_xmas"] = "2897028071",               -- done
	["xmas_90srowhouseneighborhood"] = "2897028981", -- done
	["xmas_j2eve"] = "2897029668",                  -- done
	["ttt_community_skating_v1i"] = "2897041725",   -- done
	["ttt_fastfood_xmas"] = "2900092125",           -- done
	["ttt_northsea_xmas"] = "2901111331",           -- done
	["ttt_poolparty_xmas"] = "2902624795",          -- done
	["ttt_roy_the_ship_xmas"] = "2902625355",       -- done
	["ttt_upstate_snow"] = "2902625898",            -- done
	["ttt_volcano_xmas"] = "2903113088",            -- done
	["ttt_alps_snow"] = "2903113637",               -- done
	["ttt_hairyhouse_xmas"] = "2903144137",         -- done
	["ttt_mc_nuketown_xmas"] = "2905784214",        -- done
	["ttt_icehouse"] = "2914965312",                -- done-- done
	["ttt_xmas_downtown"] = "2917403684",           -- done
	["ttt_waterworld_xmas"] = "2867376771",         -- done
	["ttt_winterholiday"] = "2897027806",           -- done
	["ttt_wintermansion"] = "2867380326",           -- done
	["ttt_dolls_xmas"] = "2897018379",              -- done
	["ttt_xmas_lodge"] = "2897028569",              -- done
	["ttt_xmas_rats"] = "2867383890",               -- done
	["ttt_taiga_forest"] = "2897025397",            -- done
	["ttt_office_xmas"] = "2897024288",             -- done
	["ttt_minecraft_b5c"] = "2867358376",           -- done
	["ttt_mc_richland_holiday"] = "2897022973",     -- done
	["ttt_crackhouse_xmas"] = "2897017923",         -- done
	["ttt_cbble_xmas"] = "2897010967",              -- done
	["ttt_christmas_bowling"] = "2897011554",       -- done
	["ttt_christmas_bungalow"] = "2897012395",      -- done
	["ttt_christmas_in_the_suburbs"] = "2898871041", -- done
	["ttt_christmasmotel"] = "2897014867",          -- done
	["ttt_christmastown"] = "2867297020",           -- done
	["de_mirage_xmas"] = "2896999239",              -- done
	["de_dust2_xmas"] = "2896997764",
	["cs_xmas"] = "2896997126",
	["ttt_67thway_v14_xmas_gfl"] = "2671279677",
	["ttt_alstoybarnxmas"] = "1932802632",
	["ttt_orange_christmas"] = "2901540680",
	["gm_capitol"] = "2709922145",
	["ttt_innocentmotel"] = "3161564955"
}

---Trims `_gl`, `_ahg`, and `_opt` suffixes from a map name.
---@param mapName string The raw map name to trim
---@return string trimmedName The map name with _gl, _ahg, and _opt suffixes removed
local function trimMapName(mapName)
	local first_gl = string.find(mapName, "_gl")
	local first_ahg = string.find(mapName, "_ahg")
	local first_opt = string.find(mapName, "_opt")
	local first = first_gl or first_ahg or first_opt
	if first == nil then return mapName end

	return string.sub(mapName, 1, first - 1)
end

local sCurMap = trimMapName(game.GetMap())
local map_workshop_id = mapsToWorkshopID[sCurMap]

if map_workshop_id then
	resource.OldAddWorkshop(map_workshop_id)
end
