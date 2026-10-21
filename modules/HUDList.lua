if not (WolfgangHUD and WolfgangHUD:getSetting({"HUDList", "ENABLED"}, true)) then return end

if string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then
	local _setup_ingame_hud_saferect_original = HUDManager._setup_ingame_hud_saferect
	local update_original = HUDManager.update

	function HUDManager:_setup_ingame_hud_saferect(...)
		_setup_ingame_hud_saferect_original(self, ...)
		if managers.gameinfo then
			managers.hudlist = HUDListManager:new()
		else
			WolfgangHUD:print_log("(HUDList) GameInfoManager not present!", "error")
		end
	end

	function HUDManager:update(t, dt, ...)
		if managers.hudlist then
			managers.hudlist:update(Application:time(), dt)
		end

		return update_original(self, t, dt, ...)
	end

	function HUDManager:change_list_setting(setting, value)
		if managers.hudlist then
			return managers.hudlist:change_setting(setting, value)
		else
			HUDListManager.ListOptions[setting] = value
			return true
		end
	end

	-- HUDList --

	local HUDLIST_FONT = "din_compressed_outlined_20"

	local function get_icon_data(icon)
		local texture = icon.texture
		local texture_rect = icon.texture_rect

		if icon.skills then
			texture = "ui/atlas/skilltree/raid_atlas_skills"
			local x, y = unpack(icon.skills)
			texture_rect = {x * 78 + 2, y * 78 + 2, 76, 76}
		--elseif ... then
			-- TODO
		end

		return texture, texture_rect
	end

	HUDListManager = HUDListManager or class()
	HUDListManager.ListOptions = {
		-- General settings
		right_list_scale				= WolfgangHUD:getSetting({"HUDList", "right_list_scale"}, 1.2), --Size scale of unit count list
		right_list_progress_alpha		= WolfgangHUD:getSetting({"HUDList", "right_list_progress_alpha"}, 1),
		-- Color settings
		list_color						= WolfgangHUD:getColorSetting({"HUDList", "list_color"}, "white"),
		list_color_bg					= WolfgangHUD:getColorSetting({"HUDList", "list_color_bg"}, "black"),
		enemy_color						= WolfgangHUD:getColorSetting({"HUDList", "enemy_color"}, "orange"),
		special_color					= WolfgangHUD:getColorSetting({"HUDList", "special_color"}, "red"),
		objective_color					= WolfgangHUD:getColorSetting({"HUDList", "objective_color"}, "yellow"),
		valuable_color					= WolfgangHUD:getColorSetting({"HUDList", "valuable_color"}, "orange"),
		mission_pickup_color			= WolfgangHUD:getColorSetting({"HUDList", "mission_pickup_color"}, "white"),
		combat_pickup_color				= WolfgangHUD:getColorSetting({"HUDList", "combat_pickup_color"}, "light_gray"),
		revive_pickup_color				= WolfgangHUD:getColorSetting({"HUDList", "revive_pickup_color"}, "light_green"),
		flare_color						= WolfgangHUD:getColorSetting({"HUDList", "flare_color"}, "red"),

		-- Right side list
		show_enemies					= WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "show_enemies"}, true), --Currently spawned enemies
			aggregate_enemies			= WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "aggregate_enemies"}, false), --Aggregate all enemies into a single item
		show_objectives					= WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "show_objectives"}, true),
		show_loot						= WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "show_loot"}, true), -- carryables
	}

	-- UNIT TYPES

	HUDListManager.UNIT_TYPES = {
		german_light =								{type_id = "nazi",			category = "enemies"		},
		german_light_kar98 =						{type_id = "nazi",			category = "enemies"		},
		german_light_shotgun =						{type_id = "nazi",			category = "enemies"		},
		german_heavy =								{type_id = "nazi",			category = "enemies"		},
		german_heavy_mp38 =							{type_id = "nazi",			category = "enemies"		},
		german_heavy_kar98 =						{type_id = "nazi",			category = "enemies"		},
		german_heavy_shotgun =						{type_id = "nazi",			category = "enemies"		},
		german_grunt_light =						{type_id = "nazi",			category = "enemies"		},
		german_grunt_light_mp38 =					{type_id = "nazi",			category = "enemies"		},
		german_grunt_light_kar98 =					{type_id = "nazi",			category = "enemies"		},
		german_grunt_light_shotgun =				{type_id = "nazi",			category = "enemies"		},
		german_grunt_mid =							{type_id = "nazi",			category = "enemies"		},
		german_grunt_mid_mp38 =						{type_id = "nazi",			category = "enemies"		},
		german_grunt_mid_kar98 =					{type_id = "nazi",			category = "enemies"		},
		german_grunt_mid_shotgun =					{type_id = "nazi",			category = "enemies"		},
		german_grunt_heavy =						{type_id = "nazi",			category = "enemies"		},
		german_grunt_heavy_mp38 =					{type_id = "nazi",			category = "enemies"		},
		german_grunt_heavy_kar98 =					{type_id = "nazi",			category = "enemies"		},
		german_grunt_heavy_shotgun =				{type_id = "nazi",			category = "enemies"		},
		german_gebirgsjager_light =					{type_id = "nazi",			category = "enemies"		},
		german_gebirgsjager_light_mp38 =			{type_id = "nazi",			category = "enemies"		},
		german_gebirgsjager_light_kar98 =			{type_id = "nazi",			category = "enemies"		},
		german_gebirgsjager_light_shotgun =			{type_id = "nazi",			category = "enemies"		},
		german_gebirgsjager_heavy =					{type_id = "nazi",			category = "enemies"		},
		german_gebirgsjager_heavy_mp38 =			{type_id = "nazi",			category = "enemies"		},
		german_gebirgsjager_heavy_kar98 =			{type_id = "nazi",			category = "enemies"		},
		german_gebirgsjager_heavy_shotgun =			{type_id = "nazi",			category = "enemies"		},
		german_fallschirmjager_light =				{type_id = "nazi",			category = "enemies"		},
		german_fallschirmjager_light_mp38 =			{type_id = "nazi",			category = "enemies"		},
		german_fallschirmjager_light_kar98 =		{type_id = "nazi",			category = "enemies"		},
		german_fallschirmjager_light_shotgun =		{type_id = "nazi",			category = "enemies"		},
		german_fallschirmjager_heavy =				{type_id = "nazi",			category = "enemies"		},
		german_fallschirmjager_heavy_mp38 =			{type_id = "nazi",			category = "enemies"		},
		german_fallschirmjager_heavy_kar98 =		{type_id = "nazi",			category = "enemies"		},
		german_fallschirmjager_heavy_shotgun =		{type_id = "nazi",			category = "enemies"		},

		german_waffen_ss =							{type_id = "waffen_ss",		category = "enemies"		},
		german_waffen_ss_mp38 =						{type_id = "waffen_ss",		category = "enemies"		},
		german_waffen_ss_kar98 =					{type_id = "waffen_ss",		category = "enemies"		},
		german_waffen_ss_shotgun =					{type_id = "waffen_ss",		category = "enemies"		},

		german_gasmask =							{type_id = "gasmask",		category = "enemies"		},
		german_gasmask_shotgun =					{type_id = "gasmask",		category = "enemies"		},

		german_officer =							{type_id = "officer",		category = "enemies"		},
		german_commander =							{type_id = "officer",		category = "enemies"		},
		german_og_commander =						{type_id = "officer",		category = "enemies"		},

		german_spotter =							{type_id = "spotter",		category = "enemies"		},

		german_sniper =								{type_id = "sniper",		category = "enemies"		},

		german_flamer =								{type_id = "flamer",		category = "enemies"		},

		soviet_nkvd_int_security_captain =			{type_id = "general",		category = "objectives"		}, -- Strongpoint: Russian generals
		soviet_nkvd_int_security_captain_b =		{type_id = "general",		category = "objectives"		}, -- Strongpoint: Russian generals
	}

	HUDListManager.UnitCountItem_MAP = {
		enemies =		{class = "UnitCountItem",	skills =	{3, 8},		color_id = "enemy_color",		priority = 1	}, --Aggregated enemies

		nazi =			{class = "UnitCountItem",	skills =	{3, 8},		color_id = "enemy_color",		priority = 1	}, -- Regular nazis

		waffen_ss =		{class = "UnitCountItem",	skills =	{2, 7},		color_id = "special_color",		priority = 2	}, -- Waffen-SS
		gasmask =		{class = "UnitCountItem",	skills =	{3, 10},	color_id = "special_color",		priority = 3	}, -- Gasmasks
		officer =		{class = "UnitCountItem",	skills =	{3, 7},		color_id = "special_color",		priority = 4	}, -- Officers
		sniper =		{class = "UnitCountItem",	skills =	{0, 9},		color_id = "special_color",		priority = 5	}, -- Snipers
		spotter =		{class = "UnitCountItem",	skills =	{5, 10},	color_id = "special_color",		priority = 6	}, -- Spotters
		flamer =		{class = "UnitCountItem",	skills =	{3, 0},		color_id = "special_color",		priority = 7	}, -- Flamers

		general =		{class = "UnitCountItem",	skills =	{1, 3},		color_id = "objective_color",	priority = 50	}, -- Strongpoint: Russian generals

		--unknown =		{class = "UnitCountItem",	skills =	{3, 9},		color_id = "objective_color",	priority = 99	}, -- Debug
	}

	-- LOOT TYPES

	HUDListManager.LOOT_TYPES = {
		gold =												"gold",
		gold_bar =											"gold_bar",

		painting_sto =										"painting",
		painting_sto_cheap =								"painting",
		conspiracy_board =									"painting",

		baptismal_font =									"valuable",
		candelabrum =										"valuable",
		cigar_crate =										"valuable",
		chocolate_box =										"valuable",
		crucifix =											"valuable",
		religious_figurine =								"valuable",
		wine_crate =										"valuable",

		-- objectives
		plank =												"plank", -- urgent delivery
		crate_explosives =									"dynamite", -- full stop

		-- unneccessary stuff
		--flak_shell =										"flak_shell",
		--flak_shell_explosive =							"flak_shell",
		--flak_shell_shot_explosive =						"flak_shell",
		--flak_shell_pallete =								"unknown",
		--tank_shell_explosive =							"flak_shell",
		--parachute =										"unknown",
		--german_spy =										"alive",
		--codemachine_part_01
		--codemachine_part_02
		--codemachine_part_03
		--codemachine_part_04
		--contraband_jewelry
		--dev_pku_carry_light
		--dev_pku_carry_medium
		--dev_pku_carry_heavy
		--crate_of_fuel_canisters
		--spiked_wine_barrel
		--bonds_stack
		--torch_tank
		--turret_m2_gun
		--money_print_plate
		--ladder_4m

		corpse_body =										"corpse",
		german_grunt_body =									"corpse",
		german_grunt_light_body =							"corpse",
		german_grunt_mid_body =								"corpse",
		gebirgsjager_light_body =							"corpse",
		gebirgsjager_heavy_body =							"corpse",
		german_fallschirmjager_light_body =					"corpse",
		german_fallschirmjager_heavy_body =					"corpse",
		german_waffen_ss_body =								"corpse",
		german_commander_body =								"corpse",
		german_og_commander_body =							"corpse",
		german_black_waffen_sentry_light_body =				"corpse",
		german_black_waffen_sentry_gasmask_body =			"corpse",
		german_black_waffen_sentry_heavy_body =				"corpse",
		german_black_waffen_sentry_heavy_commander_body =	"corpse",
		german_black_waffen_sentry_light_commander_body =	"corpse",
		soviet_nkvd_int_security_captain_body =				"corpse",
	}

	HUDListManager.LootItem_MAP = {
		gold =			{class = "LootItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {877, 1399, 72, 72},	color_id = "valuable_color",	priority = 1	},
		gold_bar =		{class = "LootItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {877, 1399, 72, 72},	color_id = "valuable_color",	priority = 2	},
		painting =		{class = "LootItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {951, 1405, 72, 72},	color_id = "valuable_color",	priority = 3	},
		valuable =		{class = "LootItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {387, 1279, 72, 72},	color_id = "valuable_color",	priority = 4	},
		plank =			{class = "LootItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {875, 1473, 72, 72},									priority = 5	},
		dynamite =		{class = "LootItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {643, 1279, 32, 32},									priority = 6	},
		--flak_shell =	{class = "LootItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {535, 1279, 72, 72},									priority = 7	},
		--alive =		{class = "LootItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {887, 1281, 72, 72},									priority = 8	},
		corpse =		{class = "LootItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {461, 1279, 72, 72},									priority = 9	},

		--unknown =		{class = "LootItem",	skills =	{3, 9},		color_id = "valuable_color",	priority = 9	}, -- Debug
	}

	-- PICKUP TYPES

	HUDListManager.PICKUP_TYPES = {

		-- valuables
		folder_outlaw =						"document",
		regular_cache_box =					"cache",
		hold_take_loot =					"loot",
		press_take_loot =					"loot",
		press_take_loot_tight =				"loot",
		hold_take_dogtags =					"dogtags",
		press_take_dogtags =				"dogtags",

		-- equipment
		--take_sps_briefcase =				"briefcase",
		--take_code_book =					"code_book",
		gen_pku_crowbar =					"crowbar",
		--dynamite_x1_pku =					"dynamite",
		--dynamite_x4_pku =					"dynamite",
		--dynamite_x5_pku =					"dynamite",
		--take_dynamite_bag =				"dynamite_bag",
		hold_take_canister =				"full_fuel_canister",
		press_take_canister =				"full_fuel_canister",
		--take_enigma =						"enigma",
		--hold_take_gas_can =				"gas",
		--press_take_gas_can =				"gas",
		--take_gas_tank =					"gas_tank",
		--mine_pku =						"landmine",
		--take_portable_radio =				"portable_radio",
		--take_tools =						"repair_tools",
		--take_safe_key =					"safe_key",
		--take_safe_keychain =				"safe_keychain",
		--take_tank_grenade =				"tank_grenade",
		--take_tank_shell =					"tank_shell",
		--take_thermite =					"thermite",
		--gen_pku_thermite =				"thermite",
		open_crate_3 =						"army_crate",

		-- pickups
		health_bag =						"health_bag",
		health_bag_big =					"health_bag_big",
		health_bag_small =					"health_bag",
		ammo_bag =							"ammo_bag",
		ammo_bag_big =						"ammo_bag",
		ammo_bag_small =					"ammo_bag",
		grenade_crate =						"grenade_crate",
		grenade_crate_big =					"grenade_crate",
		grenade_crate_small =				"grenade_crate",

		-- flares
		extinguish_flare =					"flare",

	}

	HUDListManager.PickupItem_MAP = {

		-- valuables
		document =				{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {963, 175, 56, 56},			color_id = "valuable_color",		priority = 1,	category = "valuables",			ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "valuables"}, true)			},
		cache =					{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {677, 1317, 32, 32},		color_id = "valuable_color",		priority = 2,	category = "valuables",			ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "valuables"}, true)			},
		loot =					{class = "PickupItem",	texture = "ui/atlas/raid_atlas_missions", texture_rect = {8, 68, 64, 64},		color_id = "valuable_color",		priority = 3,	category = "valuables",			ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "valuables"}, true)			},
		dogtags =				{class = "PickupItem",	texture = "ui/atlas/raid_atlas_missions", texture_rect = {398, 2, 64, 64},		color_id = "valuable_color",		priority = 4,	category = "valuables",			ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "valuables"}, true)			},

		-- equipment
		--briefcase =			{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {977, 1757, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		--code_book =			{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {421, 1165, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		crowbar =				{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {489, 1165, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		--dynamite =			{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {643, 1279, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		--dynamite_bag =		{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {609, 1317, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		full_fuel_canister =	{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {643, 1313, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		--enigma =				{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {455, 1165, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		landmine =				{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {523, 1165, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		--portable_radio =		{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {361, 1705, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		--repair_tools =		{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {717, 1717, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		--safe_key =			{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {683, 1717, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		--safe_keychain =		{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {683, 1717, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		--tank_shell =			{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {717, 1717, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},
		--thermite =			{class = "PickupItem",	texture = "ui/atlas/raid_atlas_hud", texture_rect = {557, 1165, 32, 32},		color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",	ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},

		-- army (crowbar) crates
		army_crate =			{class = "PickupItem",	skills = {5, 3},																color_id = "mission_pickup_color",	priority = 10,	category = "mission_pickups",   ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "mission_pickups"}, true)	},

		-- pickups
		health_bag_big =		{class = "PickupItem",	skills = {2, 9},																color_id = "revive_pickup_color",	priority = 23,	category = "combat_pickups",	ignore = WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "combat_pickups_mode"}, 2) < 2	},
		health_bag =			{class = "PickupItem",	skills = {5, 2},																color_id = "combat_pickup_color",	priority = 22,	category = "combat_pickups",	ignore = WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "combat_pickups_mode"}, 2) < 3	},
		ammo_bag =				{class = "PickupItem",	skills = {4, 2},																color_id = "combat_pickup_color",	priority = 21,	category = "combat_pickups",	ignore = WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "combat_pickups_mode"}, 2) < 3	},
		grenade_crate =			{class = "PickupItem",	skills = {1, 8},																color_id = "combat_pickup_color",	priority = 20,	category = "combat_pickups",	ignore = WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "combat_pickups_mode"}, 2) < 3	},

		-- flares
		flare =					{class = "PickupItem",	skills = {0, 2},																color_id = "flare_color",			priority = 30,	category = "flares",			ignore = not WolfgangHUD:getSetting({"HUDList", "RIGHT_LIST", "SHOW_PICKUP_CATEGORIES", "flares"}, true)			},
	}

	function HUDListManager:init()
		self._lists = {}
		self._unit_count_listeners = 0

		self:_setup_right_list()
	end

	function HUDListManager:update(t, dt)
		for _, list in pairs(self._lists) do
			if list:is_active() then
				list:update(t, dt)
			end
		end
	end

    function HUDListManager:get_y()
		local lowest_y = nil
		for _, list in pairs(self:lists()) do
			for _, sublist in pairs(list:items()) do
				for _, item in pairs(sublist:items()) do
					local abs_y = list:y() + sublist:y() + item:y()
					if item:visible() and item:is_active() and ((lowest_y == nil) or (abs_y < lowest_y)) then
						lowest_y = abs_y
					end
				end
			end
		end
        return lowest_y
    end

	function HUDListManager:list(name)
		return self._lists[name]
	end

	function HUDListManager:lists()
		return self._lists
	end

	function HUDListManager:change_setting(setting, value)
		local clbk = "_set_" .. setting
		if HUDListManager[clbk] and HUDListManager.ListOptions[setting] ~= value then
			HUDListManager.ListOptions[setting] = value
			self[clbk](self, value)
			return true
		end
	end

	function HUDListManager:fade_lists(alpha)
		for _, list in pairs(self._lists) do
			if list:is_active() then
				list:_fade(alpha)
			end
		end
	end

	function HUDListManager:destroy()
		local function destroy_items(list)
			for _, item in pairs(list:items()) do
				if item.items then
					destroy_items(item)
				else
					item:destroy()
				end
			end
			list:destroy()
		end

		for _, list in pairs(self._lists) do
			destroy_items(list)
		end
		self._lists = {}
	end

	function HUDListManager:register_list(name, class, params, ...)
		if not self._lists[name] then
			class = type(class) == "string" and _G.HUDList[class] or class
			self._lists[name] = class and class:new(nil, name, params, ...)
		end

		return self._lists[name]
	end

	function HUDListManager:unregister_list(name, instant)
		if self._lists[name] then
			self._lists[name]:delete(instant)
		end
		self._lists[name] = nil
	end

	function HUDListManager:_setup_right_list()
		local hud_panel = managers.hud:script(PlayerBase.INGAME_HUD_SAFERECT).panel
		local scale = HUDListManager.ListOptions.right_list_scale or 1.2
		local list_width = hud_panel:w() / 3 -- use 1/3 of the space
		local list_height = 240 * scale -- 3 rows, 80 pixels each => 240, apply scale
		local x = hud_panel:w() / 3 * 2 -- align right
		local y = 0
		local is_vanilla = managers.hud:wolfganghud_layout_is_vanilla()
		local align = is_vanilla and "bottom" or "top"
		if is_vanilla then
			y = (hud_panel:h() - list_height) - HUDManager.WEAPONS_PANEL_H - 35 -- be 35 pixels above the weapons panel
		end

		local list = self:register_list("right_side_list", HUDList.VerticalList,
				{align = "right", x = x, y = y, w = list_width, h = list_height, scale = scale, top_to_bottom = not is_vanilla, bottom_to_top = is_vanilla, item_margin = 5})

		local unit_count_list = list:register_item("unit_count_list", HUDList.HorizontalList,
				{align = align, w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 1})

		local pickup_list = list:register_item("pickup_list", HUDList.HorizontalList,
				{align = align, w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 2})

		local loot_list = list:register_item("loot_list", HUDList.HorizontalList,
				{align = align, w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 3})

		self:_set_show_enemies()
		self:_set_show_objectives()

		self:_set_show_pickups()

		self:_set_show_loot()
	end

	function HUDListManager:_get_units_by_category(category)
		local all_types = {}
		local all_ids = {}

		for unit_id, data in pairs(HUDListManager.UNIT_TYPES) do
			if data.category == category then
				all_types[data.type_id] = all_types[data.type_id] or {}
				table.insert(all_types[data.type_id], unit_id)
				table.insert(all_ids, unit_id)
			end
		end

		return all_types, all_ids
	end

	function HUDListManager:_update_unit_count_list_items(list, id, members, show)
		if show then
			local data = HUDListManager.UnitCountItem_MAP[id] or {}
			local item = list:register_item(id, data.class or HUDList.UnitCountItem, id, members)
		else
			list:unregister_item(id, true)
		end
	end

	--Event handlers
	function HUDListManager:_unit_count_event(event, unit_type, value)
		if HUDListManager.UNIT_TYPES[unit_type] then
			local list = self:list("right_side_list"):item("unit_count_list")
			local type_id = HUDListManager.UNIT_TYPES[unit_type].type_id
			local category = HUDListManager.UNIT_TYPES[unit_type].category

			local item = list:item(type_id) or list:item(category)

			if item then
				if event == "change" then
					item:change_count(value)
				elseif event == "set" then
					item:set_count(value)
				end

				for _, id in pairs(HUDListManager.UNIT_TYPES[unit_type].force_update or {}) do
					local item = list:item(id)
					if item then
						item:change_count(0)
					end
				end
			end
		else
			WolfgangHUD:print_log("(HUDListManager) Unknown unit type: " .. unit_type, "info")
		end
	end

	--General config
	function HUDListManager:_set_right_list_scale(scale)
		local list = self:list("right_side_list")
		list:rescale(scale or HUDListManager.ListOptions.right_list_scale)
	end

	function HUDListManager:_set_right_list_progress_alpha(alpha)
		local list = self:list("right_side_list")
		if list then
			for _, sub_list in pairs(list:items()) do
				for _, item in pairs(sub_list:items()) do
					item:set_progress_alpha(alpha or HUDListManager.ListOptions.right_list_progress_alpha)
				end
			end
		end
	end

	function HUDListManager:_set_list_color(color)
		for _, list in pairs(self:lists()) do
			for _, item in pairs(list:items()) do
				item:set_color(color)
			end
		end
	end

	function HUDListManager:_set_list_color_bg(color)
		for _, list in pairs(self:lists()) do
			for _, item in pairs(list:items()) do
				item:set_bg_color(color)
			end
		end
	end

	-- Unit count list config
	function HUDListManager:_set_enemy_color(color)
		local list = self:list("right_side_list"):item("unit_count_list")
		if list then
			local map = HUDList.UnitCountItem_MAP
			for _, item in pairs(list:items()) do
				local u_id = item:unit_id()
				if map[u_id] and map[u_id].color_id == "enemy_color" then
					item:set_icon_color(color or HUDListManager.ListOptions.enemy_color)
				end
			end
		end
	end

	function HUDListManager:_set_special_color(color)
		local list = self:list("right_side_list"):item("unit_count_list")
		if list then
			local map = HUDList.UnitCountItem_MAP
			for _, item in pairs(list:items()) do
				local u_id = item:unit_id()
				if map[u_id] and map[u_id].color_id == "special_color" then
					item:set_icon_color(color or HUDListManager.ListOptions.special_color)
				end
			end
		end
	end

	function HUDListManager:_set_objective_color(color)
		local list = self:list("right_side_list"):item("unit_count_list")
		if list then
			local map = HUDList.UnitCountItem_MAP
			for _, item in pairs(list:items()) do
				local u_id = item:unit_id()
				if map[u_id] and map[u_id].color_id == "objective_color" then
					item:set_icon_color(color or HUDListManager.ListOptions.objective_color)
				end
			end
		end
	end

	function HUDListManager:_set_show_enemies()
		local list = self:list("right_side_list"):item("unit_count_list")
		local all_types, all_ids = self:_get_units_by_category("enemies")

		if HUDListManager.ListOptions.aggregate_enemies then
			self:_update_unit_count_list_items(list, "enemies", all_ids, HUDListManager.ListOptions.show_enemies)
		else
			for unit_type, unit_ids in pairs(all_types) do
				self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_enemies)
			end
		end
	end

	function HUDListManager:_set_aggregate_enemies()
		local list = self:list("right_side_list"):item("unit_count_list")
		local all_types, all_ids = self:_get_units_by_category("enemies")
		all_types.enemies = {}

		for unit_type, unit_ids in pairs(all_types) do
			list:unregister_item(unit_type)
		end

		self:_set_show_enemies()
	end

	function HUDListManager:_set_show_objectives()
		local list = self:list("right_side_list"):item("unit_count_list")
		local all_types, all_ids = self:_get_units_by_category("objectives")

		for unit_type, unit_ids in pairs(all_types) do
			self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_objectives)
		end
	end

	-- Loot count list config
	function HUDListManager:_set_show_loot()
		local list = self:list("right_side_list"):item("loot_list")
		local all_ids = {}
		local all_types = {}

		for loot_id, loot_type in pairs(HUDListManager.LOOT_TYPES) do
			all_types[loot_type] = all_types[loot_type] or {}
			table.insert(all_types[loot_type], loot_id)
			table.insert(all_ids, loot_id)
		end

		for loot_type, members in pairs(all_types) do
			if HUDListManager.ListOptions.show_loot then
				local loot_map = HUDListManager.LootItem_MAP[loot_type]
				if loot_map then
					local item = list:item(loot_type) or list:register_item(loot_type, loot_map.class or HUDList.LootItem, loot_type, members)
					list:set_item_disabled(item, "setting", loot_map.ignore)
				end
			else
				list:unregister_item(loot_type, true)
			end
		end
	end

	function HUDManager:change_lootlist_setting(name, show)
		if managers.hudlist then
			return managers.hudlist:change_loot_ignore(name, not show)
		else
			for _, data in pairs(HUDListManager.LootItem_MAP) do
				if data.category == name then
					data.ignore = not show
				end
			end
			return true
		end
	end

	function HUDListManager:change_loot_ignore(category_id, ignore)
		local loot_list = self:list("right_side_list"):item("loot_list")
		for _, item in pairs(loot_list:items()) do
			local loot_type = item:name()
			local loot_data = loot_type and HUDListManager.LootItem_MAP[loot_type]
			if loot_data and loot_data.category == category_id then
				loot_list:set_item_disabled(item, "setting", ignore)
				loot_data.ignore = ignore
			end
		end
	end

	-- Pickup count list config
	function HUDListManager:_set_show_pickups()
		local list = self:list("right_side_list"):item("pickup_list")
		local all_ids = {}
		local all_types = {}

		for pickup_id, pickup_type in pairs(HUDListManager.PICKUP_TYPES) do
			all_types[pickup_type] = all_types[pickup_type] or {}
			table.insert(all_types[pickup_type], pickup_id)
			table.insert(all_ids, pickup_id)
		end

		for pickup_type, members in pairs(all_types) do
			local pickup_map = HUDListManager.PickupItem_MAP[pickup_type]
			if pickup_map then
				local item = list:item(pickup_type) or list:register_item(pickup_type, pickup_map.class or HUDList.PickupItem, pickup_type, members)
				list:set_item_disabled(item, "setting", pickup_map.ignore)
			end
		end
	end

	function HUDListManager:_set_valuable_color(color)
		local pickup_list = self:list("right_side_list"):item("pickup_list")
		if pickup_list then
			local map = HUDList.PickupItem_MAP
			for _, item in pairs(pickup_list:items()) do
				local u_id = item:unit_id()
				if map[u_id] and map[u_id].color_id == "valuable_color" then
					item:set_icon_color(color or HUDListManager.ListOptions.valuable_color)
				end
			end
		end

		-- temp TODO FIXME
		local list = self:list("right_side_list"):item("loot_list")
		if list then
			local map = HUDList.LootItem_MAP
			for _, item in pairs(list:items()) do
				local u_id = item:unit_id()
				if map[u_id] and map[u_id].color_id == "valuable_color" then
					item:set_icon_color(color or HUDListManager.ListOptions.valuable_color)
				end
			end
		end
	end

	function HUDListManager:_set_mission_pickup_color(color)
		local pickup_list = self:list("right_side_list"):item("pickup_list")
		if pickup_list then
			local map = HUDList.PickupItem_MAP
			for _, item in pairs(pickup_list:items()) do
				local u_id = item:unit_id()
				if map[u_id] and map[u_id].color_id == "mission_pickup_color" then
					item:set_icon_color(color or HUDListManager.ListOptions.mission_pickup_color)
				end
			end
		end
	end

	function HUDListManager:_set_combat_pickup_color(color)
		local pickup_list = self:list("right_side_list"):item("pickup_list")
		if pickup_list then
			local map = HUDList.PickupItem_MAP
			for _, item in pairs(pickup_list:items()) do
				local u_id = item:unit_id()
				if map[u_id] and map[u_id].color_id == "combat_pickup_color" then
					item:set_icon_color(color or HUDListManager.ListOptions.combat_pickup_color)
				end
			end
		end
	end

	function HUDListManager:_set_flare_color(color)
		local pickup_list = self:list("right_side_list"):item("pickup_list")
		if pickup_list then
			local map = HUDList.PickupItem_MAP
			for _, item in pairs(pickup_list:items()) do
				local u_id = item:unit_id()
				if map[u_id] and map[u_id].color_id == "flare_color" then
					item:set_icon_color(color or HUDListManager.ListOptions.flare_color)
				end
			end
		end
	end

	function HUDManager:change_pickuplist_setting(name, show)
		if managers.hudlist then
			return managers.hudlist:change_pickup_ignore(name, not show)
		else
			for _, data in pairs(HUDListManager.PickupItem_MAP) do
				if data.category == name then
					data.ignore = not show
				end
			end
			return true
		end
	end

	function HUDListManager:change_pickup_ignore(category_id, ignore)
		local pickup_list = self:list("right_side_list"):item("pickup_list")
		for _, item in pairs(pickup_list:items()) do
			local pickup_type = item:name()
			local pickup_data = pickup_type and HUDListManager.PickupItem_MAP[pickup_type]
			if pickup_data and pickup_data.category == category_id then
				pickup_list:set_item_disabled(item, "setting", ignore)
				pickup_data.ignore = ignore
			end
		end
	end

	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	--LIST CLASS DEFINITION BLOCK
	HUDList = HUDList or {}

	HUDList.ItemBase = HUDList.ItemBase or class()
	function HUDList.ItemBase:init(parent_list, name, params)
		self._parent_list = parent_list
		self._name = name
		self._align = params.align or "center"
		self._fade_time = params.fade_time or 0.25
		self._move_speed = params.move_speed or 150
		self._priority = params.priority
		self._scale = params.scale or self._parent_list and self._parent_list:scale() or 1
		self._listener_clbks = {}
		self._disable_reason = {}

		self._panel = (self._parent_list and self._parent_list:panel() or params.native_panel or managers.hud:script(PlayerBase.INGAME_HUD_SAFERECT).panel):panel({
			name = name,
			visible = true,
			alpha = 0,
			w = params.w or 0,
			h = params.h or 0,
			x = params.x or 0,
			y = params.y or 0,
			layer = 10
		})
	end

	function HUDList.ItemBase:post_init()
		for i, data in ipairs(self._listener_clbks) do
			for _, event in pairs(data.event) do
				managers.gameinfo:register_listener(data.name, data.source, event, data.clbk, data.keys, data.data_only)
			end
		end
	end

	function HUDList.ItemBase:destroy()
		for i, data in ipairs(self._listener_clbks) do
			for _, event in pairs(data.event) do
				managers.gameinfo:unregister_listener(data.name, data.source, event)
			end
		end
	end

	function HUDList.ItemBase:_set_item_visible(status)
		self._panel:set_visible(status and self:enabled())
	end

	function HUDList.ItemBase:rescale(new_scale)
		local diff = self._scale - new_scale
		if math.abs(diff) > 0.01 then
			local size_mult = new_scale / self._scale
			self:set_size(self:w() * size_mult, self:h() * size_mult)
			self._scale = new_scale
			return true, size_mult
		end
	end

	function HUDList.ItemBase:enabled() return next(self._disable_reason) == nil end

	function HUDList.ItemBase:set_disabled(reason, status, instant)
		if self._parent_list then
			self._parent_list:set_item_disabled(self, reason, status)
		else
			self:_set_disabled(reason, status, instant)
		end
	end

	function HUDList.ItemBase:_set_disabled(reason, status, instant)
		self._disable_reason[reason] = status and true or nil

		local visible = self:enabled() and self:is_active()
		self:_fade(visible and 1 or 0, instant)
	end

	function HUDList.ItemBase:set_priority(priority)
		self._priority = priority
	end

	function HUDList.ItemBase:set_fade_time(time)
		self._fade_time = time
	end

	function HUDList.ItemBase:set_move_speed(speed)
		self._move_speed = speed
	end

	function HUDList.ItemBase:set_active(status)
		if status and WolfgangHUD:ShowHudElements() then
			self:activate()
		else
			self:deactivate()
		end
	end

	function HUDList.ItemBase:activate()
		self._active = true
		self._scheduled_for_deletion = nil
		self:_show()
	end

	function HUDList.ItemBase:deactivate()
		self._active = false
		self:_hide()
	end

	function HUDList.ItemBase:delete(instant)
		self._scheduled_for_deletion = true
		self._active = false
		self:_hide(instant)
	end

	function HUDList.ItemBase:_delete()
		self:destroy()
		if alive(self._panel) then
			if self._parent_list then
				self._parent_list:_remove_item(self)
				self._parent_list:set_item_visible(self, false)
			end
			if alive(self._panel:parent()) then
				self._panel:parent():remove(self._panel)
			end
		end
	end

	function HUDList.ItemBase:_show(instant)
		if alive(self._panel) then
			self:_set_item_visible(true)
			self:_fade(1, instant)
			if self._parent_list then
				self._parent_list:set_item_visible(self, true)
			end
		end
	end

	function HUDList.ItemBase:_hide(instant)
		if alive(self._panel) then
			self:_fade(0, instant)
			if self._parent_list then
				self._parent_list:set_item_visible(self, false)
			end
		end
	end

	function HUDList.ItemBase:_fade(target_alpha, instant, time_override)
		self._panel:stop()
		self._active_fade = {instant = instant or self._panel:alpha() == target_alpha, alpha = target_alpha, time_override = time_override}
		self:_animate_item()
	end

	function HUDList.ItemBase:move(x, y, instant, time_override)
		if alive(self._panel) then
			self._panel:stop()
			self._active_move = {instant = instant or (self._panel:x() == x and self._panel:y() == y), x = x, y = y, time_override = time_override}
			self:_animate_item()
		end
	end

	function HUDList.ItemBase:cancel_move()
		self._panel:stop()
		self._active_move = nil
		self:_animate_item()
	end

	function HUDList.ItemBase:_animate_item()
		if alive(self._panel) and self._active_fade then
			self._panel:animate(callback(self, self, "_animate_fade"), self._active_fade.alpha, self._active_fade.instant, self._active_fade.time_override)
		end

		if alive(self._panel) and self._active_move then
			self._panel:animate(callback(self, self, "_animate_move"), self._active_move.x, self._active_move.y, self._active_move.instant, self._active_move.time_override)
		end
	end

	function HUDList.ItemBase:_animate_fade(panel, alpha, instant, time_override)
		if not instant and self._fade_time > 0 then
			local init_alpha = panel:alpha()
			local fade_time = time_override and math.abs(alpha - init_alpha) / time_override or self._fade_time
			local change = alpha > init_alpha and 1 or -1
			local T = time_override or math.abs(alpha - init_alpha) * fade_time
			local t = 0

			while alive(panel) and t < T do
				panel:set_alpha(math.clamp(init_alpha + t * change * 1 / fade_time, 0, 1))
				t = t + coroutine.yield()
			end
		end

		self._active_fade = nil
		if alive(panel) then
			panel:set_alpha(alpha)
			self:_set_item_visible(alpha > 0)
		end
		if self._scheduled_for_deletion then
			self:_delete()
		end
	end

	function HUDList.ItemBase:_animate_move(panel, x, y, instant, time_override)
		if not instant and self._move_speed > 0 then
			local init_x = panel:x()
			local init_y = panel:y()
			local move_speed = time_override and math.abs(x - init_x) / time_override or self._move_speed
			local x_change = x > init_x and 1 or x < init_x and -1
			local y_change = y > init_y and 1 or y < init_y and -1
			local T = time_override or math.max(math.abs(x - init_x) / move_speed, math.abs(y - init_y) / move_speed)
			local t = 0

			while alive(panel) and t < T do
				if x_change then
					panel:set_x(init_x  + t * x_change * move_speed)
				end
				if y_change then
					panel:set_y(init_y  + t * y_change * move_speed)
				end
				t = t + coroutine.yield()
			end
		end

		self._active_move = nil
		if alive(panel) then
			panel:set_x(x)
			panel:set_y(y)
		end
	end

	function HUDList.ItemBase:name() return self._name end
	function HUDList.ItemBase:panel() return self._panel end
	function HUDList.ItemBase:alpha() return self._panel:alpha() end
	function HUDList.ItemBase:w() return self._panel:w() end
	function HUDList.ItemBase:h() return self._panel:h() end
	function HUDList.ItemBase:x() return self._panel:x() end
	function HUDList.ItemBase:y() return self._panel:y() end
	function HUDList.ItemBase:left() return self._panel:left() end
	function HUDList.ItemBase:right() return self._panel:right() end
	function HUDList.ItemBase:top() return self._panel:top() end
	function HUDList.ItemBase:bottom() return self._panel:bottom() end
	function HUDList.ItemBase:center() return self._panel:center() end
	function HUDList.ItemBase:center_x() return self._panel:center_x() end
	function HUDList.ItemBase:center_y() return self._panel:center_y() end
	function HUDList.ItemBase:visible() return self._panel:visible() end
	function HUDList.ItemBase:layer() return self._panel:layer() end
	function HUDList.ItemBase:text_rect() return self:x(), self:y(), self:w(), self:h() end
	function HUDList.ItemBase:set_alpha(v) self._panel:set_alpha(v) end
	function HUDList.ItemBase:set_x(v) self._panel:set_x(v) end
	function HUDList.ItemBase:set_y(v) self._panel:set_y(v) end
	function HUDList.ItemBase:set_w(v) self._panel:set_w(v)	end
	function HUDList.ItemBase:set_h(v) self._panel:set_h(v)	end
	function HUDList.ItemBase:set_size(w, h) self._panel:set_size(w, h)	end
	function HUDList.ItemBase:set_left(v) self._panel:set_left(v) end
	function HUDList.ItemBase:set_right(v) self._panel:set_right(v) end
	function HUDList.ItemBase:set_top(v) self._panel:set_top(v) end
	function HUDList.ItemBase:set_bottom(v) self._panel:set_bottom(v) end
	function HUDList.ItemBase:set_center(x, y) self._panel:set_center(x, y) end
	function HUDList.ItemBase:set_center_x(v) self._panel:set_center_x(v) end
	function HUDList.ItemBase:set_center_y(v) self._panel:set_center_y(v) end
	function HUDList.ItemBase:set_layer(v) self._panel:set_layer(v) end
	function HUDList.ItemBase:parent_list() return self._parent_list end
	function HUDList.ItemBase:align() return self._align end
	function HUDList.ItemBase:is_active() return self._active end
	function HUDList.ItemBase:priority() return self._priority end
	function HUDList.ItemBase:scale() return self._scale end
	function HUDList.ItemBase:fade_time() return self._fade_time end
	function HUDList.ItemBase:set_color(color) end
	function HUDList.ItemBase:set_bg_color(color) end
	function HUDList.ItemBase:set_progress_alpha(alpha) end

	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	HUDList.ListBase = HUDList.ListBase or class(HUDList.ItemBase) --DO NOT INSTANTIATE THIS CLASS
	function HUDList.ListBase:init(parent, name, params)
		params.fade_time = params.fade_time or 0
		HUDList.ListBase.super.init(self, parent, name, params)

		self._stack = params.stack or false
		self._queue = not self._stack
		self._item_fade_time = params.item_fade_time
		self._item_move_speed = params.item_move_speed
		self._item_margin = params.item_margin or 0
		self._margin = params.item_margin or 0
		self._items = {}
		self._shown_items = {}
	end

	function HUDList.ListBase:item(name)
		return self._items[name]
	end

	function HUDList.ListBase:items()
		return self._items
	end

	function HUDList.ListBase:num_items()
		return table.size(self._items)
	end

	function HUDList.ListBase:active_items()
		local count = 0
		for name, item in pairs(self._items) do
			if item:is_active() then
				count = count + 1
			end
		end
		return count
	end

	function HUDList.ListBase:shown_items()
		return #self._shown_items
	end

	function HUDList.ListBase:update(t, dt)
		for name, item in pairs(self._items) do
			if item.update and item:is_active() then
				item:update(t, dt)
			end
		end
	end

	function HUDList.ListBase:rescale(new_scale)
		local diff = self._scale - new_scale
		if math.abs(diff) > 0.01 then
			local size_mult = new_scale / self._scale
			self._scale = new_scale

			for _, item in pairs(self:items()) do
				item:rescale(new_scale)
			end

			self:_update_item_positions(nil, true)
			return true, size_mult
		end
	end

	function HUDList.ListBase:register_item(name, class, ...)
		if not self._items[name] then
			class = type(class) == "string" and _G.HUDList[class] or class
			local new_item = class and class:new(self, name, ...)

			if new_item then
				if self._item_fade_time then
					new_item:set_fade_time(self._item_fade_time)
				end
				if self._item_move_speed then
					new_item:set_move_speed(self._item_move_speed)
				end
				if self._scale then
					new_item:rescale(self._scale)
				end
				new_item:post_init(...)
				self:_set_default_item_position(new_item)
			end

			self._items[name] = new_item
		end

		return self._items[name]
	end

	function HUDList.ListBase:unregister_item(name, instant)
		if self._items[name] then
			self._items[name]:delete(instant)
		end
	end

	function HUDList.ListBase:set_static_item(class, ...)
		self:delete_static_item()

		if type(class) == "string" then
			class = _G.HUDList[class]
		end

		self._static_item = class and class:new(self, "static_list_item", ...)
		if self._static_item then
			self:setup_static_item()
			self._static_item:panel():show()
			self._static_item:panel():set_alpha(1)
		end

		return self._static_item
	end

	function HUDList.ListBase:setup_static_item()
	end

	function HUDList.ListBase:delete_static_item()
		if self._static_item then
			self._static_item:delete(true)
			self._static_item = nil
		end
	end

	function HUDList.ListBase:set_item_visible(item, visible)
		local index
		for i, shown_item in ipairs(self._shown_items) do
			if shown_item == item then
				index = i
				break
			end
		end

		if visible and not index then
			if #self._shown_items <= 0 then
				self:activate()
			end

			local insert_index = #self._shown_items + 1
			if item:priority() then
				for i, list_item in ipairs(self._shown_items) do
					if not list_item:priority() or (list_item:priority() > item:priority()) then
						insert_index = i
						break
					end
				end
			end

			table.insert(self._shown_items, insert_index, item)
		elseif not visible and index then
			table.remove(self._shown_items, index)
			if #self._shown_items <= 0 then
				managers.enemy:add_delayed_clbk("visibility_cbk_" .. self._name, callback(self, self, "_cbk_update_visibility"), Application:time() + item:fade_time())
			end
		else
			return
		end

		self:_update_item_positions(item)
	end

	function HUDList.ListBase:set_item_disabled(item, reason, status, instant)
		item:_set_disabled(reason, status, instant)
		self:update_item_positions()
	end

	function HUDList.ListBase:update_item_positions()
		self:_update_item_positions(nil, true)
	end

	function HUDList.ListBase:_update_item_positions(insert_item, instant_move, move_timer)
	end

	function HUDList.ListBase:_cbk_update_visibility()
		if #self._shown_items <= 0 then
			self:deactivate()
		end
	end

	function HUDList.ListBase:_remove_item(item)
		self._items[item:name()] = nil
	end

	function HUDList.ListBase:set_color(color)
		for _, item in pairs(self:items()) do
			item:set_color(color)
		end
	end
	function HUDList.ListBase:set_bg_color(color)
		for _, item in pairs(self:items()) do
			item:set_bg_color(color)
		end
	end

	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	HUDList.HorizontalList = HUDList.HorizontalList or class(HUDList.ListBase)
	function HUDList.HorizontalList:init(parent, name, params)
		params.align = params.align == "top" and "top" or params.align == "bottom" and "bottom" or "center"
		HUDList.HorizontalList.super.init(self, parent, name, params)
		self._left_to_right = params.left_to_right
		self._right_to_left = params.right_to_left and not self._left_to_right
		self._centered = params.centered and not (self._right_to_left or self._left_to_right)

		self._max_shown_items = params.max_items

		self._recheck_interval = params.recheck_interval
		self._next_recheck = self._recheck_interval

		self:setup_expansion_item()
	end

	function HUDList.HorizontalList:rescale(new_scale)
		local diff = self._scale - new_scale
		if math.abs(diff) > 0.01 then
			local size_mult = new_scale / self._scale
			self:set_h(self:h() * size_mult)
			self._scale = new_scale

			if self._static_item then
				self._static_item:rescale(new_scale)
			end
			for _, item in pairs(self:items()) do
				item:rescale(new_scale)
			end
			if self._expansion_indicator then
				self._expansion_indicator:rescale(new_scale)
			end

			self:_update_item_positions(nil, true)
			return true, size_mult
		end
	end

	function HUDList.HorizontalList:set_color(color)
		if self._static_item then
			self._static_item:set_color(color)
		end
		for _, item in pairs(self:items()) do
			item:set_color(color)
		end
		if self._expansion_indicator then
			self._expansion_indicator:set_color(color)
		end
	end
	function HUDList.HorizontalList:set_bg_color(color)
		if self._static_item then
			self._static_item:set_bg_color(color)
		end
		for _, item in pairs(self:items()) do
			item:set_bg_color(color)
		end
		if self._expansion_indicator then
			self._expansion_indicator:set_bg_color(color)
		end
	end

	function HUDList.HorizontalList:_set_default_item_position(item)
		local offset = self._panel:h() - item:panel():h()
		local y = item:align() == "top" and 0 or item:align() == "bottom" and offset or offset / 2
		item:panel():set_top(y)
	end

	function HUDList.HorizontalList:setup_static_item()
		local item = self._static_item
		local offset = self._panel:h() - item:panel():h()
		local y = item:align() == "top" and 0 or item:align() == "bottom" and offset or offset / 2
		local x = self._left_to_right and 0 or self._panel:w() - item:panel():w()
		item:panel():set_left(x)
		item:panel():set_top(y)
		self:_update_item_positions()
	end

	function HUDList.HorizontalList:setup_expansion_item()
		self._expansion_indicator = HUDList.ExpansionIndicator:new(self, "expansion_indicator", 1/5, 1, {})
		self._expansion_indicator:set_mirrored(self._right_to_left)
		self._expansion_indicator:set_active(self._max_shown_items and self._max_shown_items >= self:shown_items())
	end

	function HUDList.HorizontalList:update(t, dt)
		if self._recheck_interval ~= nil then
			self._next_recheck = self._next_recheck - dt

			if self:shown_items() > 0 and self._next_recheck <= 0 then
				self:reapply_item_priorities(true, self._recheck_interval / 2)
				self._next_recheck = self._recheck_interval
			end
		end

		HUDList.HorizontalList.super.update(self, t, dt)
	end

	function HUDList.HorizontalList:_update_item_positions(insert_item, instant_move, move_timer)
		local total_shown_items = 0
		local show_expansion = false
		if self._centered then
			local total_width = self._static_item and (self._static_item:panel():w() + self._item_margin) or 0
			local prev_disabled_i = {}
			for i, item in ipairs(self._shown_items) do
				local next_total_width = total_width + item:panel():w() + self._item_margin
				show_expansion = show_expansion or (next_total_width > self:w())
				if self._max_shown_items then
					show_expansion = show_expansion or (total_shown_items >= self._max_shown_items)
				end
				if not item:enabled() then
					table.insert(prev_disabled_i, i)
				end
				item:_set_disabled("max_items_reached", show_expansion)

				if item:enabled() then
					total_width = next_total_width
					total_shown_items = total_shown_items + 1
				end
			end
			total_width = total_width - self._item_margin

			local left = (self._panel:w() - math.min(total_width, self._panel:w())) / 2

			if self._static_item then
				self._static_item:move(left, self._static_item:panel():y(), instant_move, move_timer)
				left = left + self._static_item:panel():w() + self._item_margin
			end

			for i, item in ipairs(self._shown_items) do
				if item:enabled() then
					if insert_item and item == insert_item or table.contains(prev_disabled_i, i) then
						if item:panel():x() ~= left then
							item:panel():set_x(left - item:panel():w() / 2)
							item:move(left, item:panel():y(), instant_move, move_timer)
						end
					else
						item:move(left, item:panel():y(), instant_move, move_timer)
					end
					left = left + item:panel():w() + self._item_margin
				else
					item:panel():set_x(left)
				end
			end

			if self._expansion_indicator then
				self._expansion_indicator:set_active(show_expansion)
				self._expansion_indicator:panel():set_x(left)
				self._expansion_indicator:cancel_move()
			end
		else
			local prev_width = self._static_item and (self._static_item:panel():w() + self._item_margin) or 0
			for i, item in ipairs(self._shown_items) do
				local next_width = prev_width + item:panel():w() + self._item_margin
				show_expansion = show_expansion or (next_width > self:w())
				if self._max_shown_items then
					show_expansion = show_expansion or (total_shown_items >= self._max_shown_items)
				end
				local was_disabled = not item:enabled()
				item:_set_disabled("max_items_reached", show_expansion)

				if item:enabled() then
					local width = item:panel():w()
					local new_x = (self._left_to_right and prev_width) or (self._panel:w() - (width+prev_width))
					if insert_item and item == insert_item or was_disabled then
						item:panel():set_x(new_x)
						item:cancel_move()
					else
						item:move(new_x, item:panel():y(), instant_move, move_timer)
					end

					prev_width = prev_width + width + self._item_margin
					total_shown_items = total_shown_items + 1
				end
			end

			if self._expansion_indicator then
				self._expansion_indicator:set_active(show_expansion)
				local width = self._expansion_indicator:panel():w()
				local new_x = (self._left_to_right and math.min(prev_width, self._panel:w() - width)) or math.max(self._panel:w() - (width+prev_width), 0)
				self._expansion_indicator:panel():set_x(new_x)
				self._expansion_indicator:cancel_move()
			end

			self:set_disabled("no_visible_items", total_shown_items <= 0)
		end
	end

	function HUDList.HorizontalList:reapply_item_priorities(update_positions, move_time_override)
		local order_changed = false
		if not self._reorder_in_progress then
			self._reorder_in_progress = true

			local swapped = false
			repeat
				swapped = false

				for i = 2, #self._shown_items, 1 do
					local prev = self._shown_items[i-1]
					local cur = self._shown_items[i]

					local prev_prio, cur_prio = prev and prev:priority(), cur and cur:priority()
					if cur_prio then
						if not prev_prio or prev_prio > cur_prio then
							table.insert(self._shown_items, i, table.remove(self._shown_items, i-1))
							swapped = true
						end
					end
				end
				order_changed = order_changed or swapped
			until not swapped

			self._reorder_in_progress = nil

			if update_positions and order_changed then
				self:_update_item_positions(nil, false, move_time_override)
			end
		end

		return order_changed
	end

	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	HUDList.VerticalList = HUDList.VerticalList or class(HUDList.ListBase)
	function HUDList.VerticalList:init(parent, name, params)
		params.align = params.align == "left" and "left" or params.align == "right" and "right" or "center"
		HUDList.VerticalList.super.init(self, parent, name, params)
		self._top_to_bottom = params.top_to_bottom
		self._bottom_to_top = params.bottom_to_top and not self._top_to_bottom
		self._centered = params.centered and not (self._bottom_to_top or self._top_to_bottom)
	end

	function HUDList.VerticalList:_set_default_item_position(item)
		local offset = self._panel:w() - item:panel():w()
		local x = item:align() == "left" and 0 or item:align() == "right" and offset or offset / 2
		item:panel():set_left(x)
	end

	function HUDList.VerticalList:setup_static_item()
		local item = self._static_item
		local offset = self._panel:w() - item:panel():w()
		local x = item:align() == "left" and 0 or item:align() == "right" and offset or offset / 2
		local y = self._top_to_bottom and 0 or self._panel:h() - item:panel():h()
		item:panel():set_left(x)
		item:panel():set_y(y)
		self:_update_item_positions()
	end

	function HUDList.VerticalList:_update_item_positions(insert_item, instant_move, move_timer)
		if self._centered then
			local total_height = self._static_item and (self._static_item:panel():h() + self._item_margin) or 0
			for i, item in ipairs(self._shown_items) do
				if item:enabled() then
					total_height = total_height + item:panel():h() + self._item_margin
				end
			end
			total_height = total_height - self._item_margin

			local top = (self._panel:h() - math.min(total_height, self._panel:h())) / 2

			if self._static_item then
				self._static_item:move(self._static_item:panel():x(), top, instant_move, move_timer)
				top = top + self._static_item:panel():h() + self._item_margin
			end

			for i, item in ipairs(self._shown_items) do
				if item:enabled() then
					if insert_item and item == insert_item then
						if item:panel():y() ~= top then
							item:panel():set_y(top - item:panel():h() / 2)
							item:move(item:panel():x(), top, instant_move, move_timer)
						end
					else
						item:move(item:panel():x(), top, instant_move, move_timer)
					end
					top = top + item:panel():h() + self._item_margin
				end
			end
		else
			local prev_height = self._static_item and (self._static_item:panel():h() + self._item_margin) or 0
			for i, item in ipairs(self._shown_items) do
				if item:enabled() then
					local height = item:panel():h()
					local new_y = (self._top_to_bottom and prev_height) or (self._panel:h() - (height+prev_height))
					if insert_item and item == insert_item then
						item:panel():set_y(new_y)
						item:cancel_move()
					else
						item:move(item:panel():x(), new_y, instant_move, move_timer)
					end
					prev_height = prev_height + height + self._item_margin
				end
			end
		end
	end

	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	HUDList.ExpansionIndicator = HUDList.ExpansionIndicator or class(HUDList.ItemBase)

	function HUDList.ExpansionIndicator:init(parent, name, ratio_w, ratio_h, params)
		HUDList.ExpansionIndicator.super.init(self, parent, name, {align = "center", w = parent:panel():h() * (ratio_w or 1), h = parent:panel():h() * (ratio_h or 1)})

		local icon = params.icon or {}
		self._icon = self._panel:bitmap({
			name = "icon_expansion",
			texture = icon.texture or "ui/atlas/skilltree/raid_atlas_skills",
			texture_rect = icon.texture_rect or {158, 470, 76, 76},
			h = self:panel():h() * (icon.h or 1),
			w = self:panel():w() * (icon.w or 0.8),
			blend_mode = "add",
			align = "center",
			vertical = "center",
			valign = "scale",
			halign = "scale",
			color = icon.color or Color.white,
		})

		self._icon:set_center(self._panel:center())
	end

	function HUDList.ExpansionIndicator:set_mirrored(status)
		self._icon:set_rotation(status and 180 or 0)
	end

	function HUDList.ExpansionIndicator:_show(instant)
		if alive(self._panel) then
			self:_set_item_visible(true)
			self:_fade(1, instant)
		end
	end

	function HUDList.ExpansionIndicator:_hide(instant)
		if alive(self._panel) then
			self:_fade(0, instant)
		end
	end

	function HUDList.ExpansionIndicator:set_color(color)
		self._icon:set_color(color)
	end

	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	--LIST ITEM CLASS DEFINITION BLOCK

	--Right list

	HUDList.RightListItem = HUDList.RightListItem or class(HUDList.ItemBase)
	function HUDList.RightListItem:init(parent, name, icon, params)
		params = params or {}
		params.align = params.align or "right"
		params.w = params.w or parent:panel():h() / 2
		params.h = params.h or parent:panel():h()
		HUDList.RightListItem.super.init(self, parent, name, params)

		self._default_text_color = HUDListManager.ListOptions.list_color or Color.white
		self._default_icon_color = icon.color or icon.color_id and HUDListManager.ListOptions[icon.color_id]
		self._change_increase_color = Color.green
		self._change_decrease_color = Color.red


		local texture, texture_rect = get_icon_data(icon)

		self._icon = self._panel:bitmap({
			name = "icon",
			texture = texture,
			texture_rect = texture_rect,
			h = self._panel:w() * (icon.h_ratio or 1),
			w = self._panel:w() * (icon.w_ratio or 1),
			alpha = icon.alpha or 1,
			blend_mode = icon.blend_mode or "normal",
			color = self._default_icon_color or self._default_text_color,
		})
		self._icon:set_center(self._panel:w() * 0.5, self._panel:w() * 0.5)

		self._progress_bar = PanelFrame:new(self._panel, {
			w = self._panel:w(),
			h = self._panel:w(),
			invert_progress = true,
			bar_w = 2,
			bar_color = self._default_text_color,
			bg_color = (HUDListManager.ListOptions.list_color_bg or Color.black),
			bar_alpha = HUDListManager.ListOptions.right_list_progress_alpha or 1,
			add_bg = true,
		})
		self._progress_bar:set_ratio(1)

		local box = self._progress_bar:panel()
		box:set_bottom(self._panel:bottom())

		self._text = box:text({
			name = "text",
			text = "",
			align = "center",
			vertical = "center",
			w = box:w(),
			h = box:h(),
			color = self._default_text_color,
			font = tweak_data.gui.fonts[HUDLIST_FONT],
			font_size = box:h() * 0.6
		})

		self._count = 0
	end

	function HUDList.RightListItem:rescale(new_scale)
		local enabled, size_mult = HUDList.RightListItem.super.rescale(self, new_scale)

		if enabled then
			self._icon:set_size(self._icon:w() * size_mult, self._icon:h() * size_mult)
			self._icon:set_center(self._panel:w() * 0.5, self._panel:w() * 0.5)

			self._progress_bar:set_size(self._panel:w(), self._panel:w())
			self._progress_bar:set_bottom(self._panel:bottom())

			self._text:set_size(self._progress_bar:w(), self._progress_bar:h())
			self._text:set_font_size(self._progress_bar:h() * 0.6)
		end

		return enabled, size_mult
	end

	function HUDList.RightListItem:set_color(color)
		self._default_text_color = color or HUDListManager.ListOptions.list_color or Color.white
		self._icon:set_color(self._default_icon_color or self._default_text_color)
		self._progress_bar:set_color(self._default_text_color)
		self._text:set_color(self._default_text_color)
	end

	function HUDList.RightListItem:set_bg_color(color)
		self._progress_bar:set_bg_color(color)
	end

	function HUDList.RightListItem:set_icon_color(color)
		self._default_icon_color = color
		self._icon:set_color(self._default_icon_color or self._default_text_color)
	end

	function HUDList.RightListItem:set_progress_alpha(alpha)
		self._progress_bar:set_alpha(alpha)
	end

	function HUDList.RightListItem:change_count(diff)
		if not alive(self._text) then
			return
		end

		self:set_count(self._count + diff)

		if diff ~= 0 then
			self._text:stop()
			self._text:animate(callback(self, self, "_animate_change"), diff, self._progress_bar)
		end
	end

	function HUDList.RightListItem:set_count(num)
		if not alive(self._text) then
			return
		end

		self._count = num
		self._text:set_text(tostring(self._count))
		self:set_active(self._count > 0)
	end

	function HUDList.RightListItem:get_count()
		return self._count or 0
	end

	function HUDList.RightListItem:_animate_change(item, diff, progress_bar)
		if self:is_active() and alive(item) and diff ~= 0 then
			local duration = 0.5
			local t = duration
			local color = diff > 0 and self._change_increase_color or self._change_decrease_color

			item:set_color(color)
			while t > 0 do
				t = t - coroutine.yield()
				local ratio = math.clamp(t / duration, 0, 1)
				local new_color = math.lerp(self._default_text_color, color, ratio)
				item:set_color(new_color)
				if progress_bar then
					progress_bar:set_color(new_color)
					progress_bar:set_ratio((diff > 0 and (1-ratio) or ratio))
				end
			end

			item:set_color(self._default_text_color)
			if progress_bar then
				progress_bar:set_color(self._default_text_color)
				progress_bar:set_ratio(1)
			end
		end
	end

	HUDList.UnitCountItem = HUDList.UnitCountItem or class(HUDList.RightListItem)
	function HUDList.UnitCountItem:init(parent, name, id, unit_types)
		local unit_data = HUDListManager.UnitCountItem_MAP[id] or {}
		local params = {priority = unit_data.priority}

		HUDList.UnitCountItem.super.init(self, parent, name, unit_data, params)

		self._id = id
		self._unit_types = {}
		self._subtract_types = {}
		self._unit_count = {}

		local total_count = 0
		local keys = {}

		for _, unit_id in pairs(unit_types or {}) do
			local count = managers.gameinfo:get_unit_count(unit_id)
			total_count = total_count + count
			self._unit_count[unit_id] = count
			self._unit_types[unit_id] = true
			table.insert(keys, unit_id)
		end

		for _, unit_id in pairs(unit_data.subtract or {}) do
			local count = managers.gameinfo:get_unit_count(unit_id)
			total_count = total_count - count
			self._unit_count[unit_id] = count
			self._subtract_types[unit_id] = true
			table.insert(keys, unit_id)
		end

		self._listener_clbks = {
			{
				name = string.format("HUDList_%s_unit_count_listener", id),
				source = "unit_count",
				event = {"change"},
				clbk = callback(self, self, "_change_count_clbk"),
				keys = keys
			}
		}

		self:set_count(total_count)
	end

	function HUDList.UnitCountItem:unit_id()
		return self._id
	end

	function HUDList.UnitCountItem:_change_count_clbk(event, unit_type, value)
		self._unit_count[unit_type] = self._unit_count[unit_type] + value
		if self._subtract_types[unit_type] then
			self:change_count(-value)
		else
			self:change_count(value)
		end
	end

	HUDList.LootItem = HUDList.LootItem or class(HUDList.RightListItem)

	function HUDList.LootItem:init(parent, name, id, members)
		local loot_data = HUDListManager.LootItem_MAP[id]
		HUDList.LootItem.super.init(self, parent, name, loot_data, loot_data)

		self._loot_types = {}

		local keys = {}

		for _, loot_id in pairs(members) do
			self._loot_types[loot_id] = true
			table.insert(keys, loot_id)
		end

		local total_count = 0
		for _, data in pairs(managers.gameinfo:get_loot()) do
			if self._loot_types[data.carry_id] then
				total_count = total_count + 1
			end
		end

		self._listener_clbks = {
			{
				name = string.format("HUDList_%s_loot_count_listener", id),
				source = "loot_count",
				event = {"change"},
				clbk = callback(self, self, "_change_loot_count_clbk"),
				keys = keys
			}
		}

		self:set_count(total_count)
	end

	function HUDList.LootItem:_change_loot_count_clbk(event, carry_id, value, data)
		self:change_count(value)
	end

	HUDList.PickupItem = HUDList.PickupItem or class(HUDList.RightListItem)

	function HUDList.PickupItem:init(parent, name, id, members)
		local pickup_data = HUDListManager.PickupItem_MAP[id]
		HUDList.PickupItem.super.init(self, parent, name, pickup_data, pickup_data)

		self._pickup_types = {}

		local keys = {}
		for _, pickup_id in pairs(members) do
			self._pickup_types[pickup_id] = true
			table.insert(keys, pickup_id)
		end

		local total_count = 0
		for _, data in pairs(managers.gameinfo:get_pickups()) do
			if self._pickup_types[data.interact_id] then
				total_count = total_count + 1
			end
		end

		self._listener_clbks = {
			{
				name = string.format("HUDList_%s_pickup_count_listener", id),
				source = "pickup_count",
				event = {"change"},
				clbk = callback(self, self, "_change_pickup_count_clbk"),
				keys = keys
			}
		}

		self:set_count(total_count)
	end

	function HUDList.PickupItem:_change_pickup_count_clbk(event, interact_id, value, data)
		self:change_count(value)
	end

	PanelFrame = PanelFrame or class()

	function PanelFrame:init(parent, settings)
		settings = settings or {}

		local h = settings.h or parent:h()
		local w = settings.w or parent:w()

		self._panel = parent:panel({
			w = w,
			h = h,
			alpha = settings.alpha or 1,
		})

		if settings.add_bg then
			self._bg = self._panel:rect({
				name = "bg",
				valign = "grow",
				halign = "grow",
				blend_mode = "normal",
				layer = self._panel:layer() - 1,
				color = settings.bg_color or settings.color or Color.black,
				alpha = settings.bg_alpha or settings.alpha or 0.25,
			})
		end

		self._invert_progress = settings.invert_progress
		self._top = self._panel:rect({})
		self._bottom = self._panel:rect({})
		self._left = self._panel:rect({})
		self._right = self._panel:rect({})

		self:set_width(settings.bar_w or 2)
		self:set_color(settings.bar_color or settings.color or Color.white, settings.alpha or settings.bar_alpha or 1)
		self:reset()
	end

	function PanelFrame:panel()
		return self._panel
	end

	function PanelFrame:set_width(w)
		local pw, ph = self._panel:w(), self._panel:h()
		local total = 2*pw + 2*ph
		self._bar_w = w
		self._stages = {0, (pw - 2 * self._bar_w) / total, (pw + ph - self._bar_w) / total, (2 * pw + ph - 2 * self._bar_w) / total, 1}
		self._top:set_h(w)
		self._top:set_top(0)
		self._bottom:set_h(w)
		self._bottom:set_bottom(self._panel:h())
		self._left:set_w(w)
		self._left:set_left(0)
		self._right:set_w(w)
		self._right:set_right(self._panel:w())
	end

	function PanelFrame:set_color(c, alpha)
		self._top:set_color(c)
		self._bottom:set_color(c)
		self._left:set_color(c)
		self._right:set_color(c)
		if alpha then
			self._top:set_alpha(alpha)
			self._bottom:set_alpha(alpha)
			self._left:set_alpha(alpha)
			self._right:set_alpha(alpha)
		end
	end

	function PanelFrame:set_bg_color(c, alpha)
		if alive(self._bg) then
			self._bg:set_color(c)
			if alpha then
				self._bg:set_alpha(alpha)
			end
		end
	end

	function PanelFrame:set_alpha(alpha)
		self._top:set_alpha(alpha)
		self._bottom:set_alpha(alpha)
		self._left:set_alpha(alpha)
		self._right:set_alpha(alpha)
	end

	function PanelFrame:set_bg_alpha(alpha)
		if alive(self._bg) then
			self._bg:set_alpha(alpha)
		end
	end

	function PanelFrame:reset()
		self._current_stage = 1
		self._top:set_w(self._panel:w() - 2 * self._bar_w)
		self._top:set_left(self._bar_w)
		self._right:set_h(self._panel:h())
		self._right:set_bottom(self._panel:h())
		self._bottom:set_w(self._panel:w() - 2 * self._bar_w)
		self._bottom:set_right(self._panel:w() - self._bar_w)
		self._left:set_h(self._panel:h())
	end

	function PanelFrame:set_ratio(r)
		r = math.clamp(r, 0, 1)
		self._current_ratio = r
		if self._invert_progress then
			r = 1-r
		end

		if r < self._stages[self._current_stage] then
			self:reset()
		end

		while r > self._stages[self._current_stage + 1] do
			if self._current_stage == 1 then
				self._top:set_w(0)
			elseif self._current_stage == 2 then
				self._right:set_h(0)
			elseif self._current_stage == 3 then
				self._bottom:set_w(0)
			elseif self._current_stage == 4 then
				self._left:set_h(0)
			end
			self._current_stage = self._current_stage + 1
		end

		local low = self._stages[self._current_stage]
		local high = self._stages[self._current_stage + 1]
		local stage_progress = (r - low) / (high - low)

		if self._current_stage == 1 then
			self._top:set_w((self._panel:w() - 2 * self._bar_w) * (1-stage_progress))
			self._top:set_right(self._panel:w() - self._bar_w)
		elseif self._current_stage == 2 then
			self._right:set_h(self._panel:h() * (1-stage_progress))
			self._right:set_bottom(self._panel:h())
		elseif self._current_stage == 3 then
			self._bottom:set_w((self._panel:w() - 2 * self._bar_w) * (1-stage_progress))
		elseif self._current_stage == 4 then
			self._left:set_h(self._panel:h() * (1-stage_progress))
		end
	end

	function PanelFrame:ratio()
		local r = self._current_ratio or 0
		if self._invert_progress then
			r = 1-r
		end
		return r
	end

	function PanelFrame:alpha() return self._panel:alpha() end
	function PanelFrame:w() return self._panel:w() end
	function PanelFrame:h() return self._panel:h() end
	function PanelFrame:x() return self._panel:x() end
	function PanelFrame:y() return self._panel:y() end
	function PanelFrame:left() return self._panel:left() end
	function PanelFrame:right() return self._panel:right() end
	function PanelFrame:top() return self._panel:top() end
	function PanelFrame:bottom() return self._panel:bottom() end
	function PanelFrame:center() return self._panel:center() end
	function PanelFrame:center_x() return self._panel:center_x() end
	function PanelFrame:center_y() return self._panel:center_y() end
	function PanelFrame:visible() return self._panel:visible() end
	function PanelFrame:layer() return self._panel:layer() end
	function PanelFrame:text_rect() return self:x(), self:y(), self:w(), self:h() end
	function PanelFrame:set_x(v) self._panel:set_x(v) end
	function PanelFrame:set_y(v) self._panel:set_y(v) end
	function PanelFrame:set_w(v) self:set_size(v, nil)	end
	function PanelFrame:set_h(v) self:set_size(nil, v)	end
	function PanelFrame:set_size(w, h)
		w = w or self:w()
		h = h or self:h()

		self._panel:set_size(w, h)
		self:set_width(self._bar_w)
		self:reset()
		self:set_ratio(self._current_ratio or 1)
	end
	function PanelFrame:set_left(v) self._panel:set_left(v) end
	function PanelFrame:set_right(v) self._panel:set_right(v) end
	function PanelFrame:set_top(v) self._panel:set_top(v) end
	function PanelFrame:set_bottom(v) self._panel:set_bottom(v) end
	function PanelFrame:set_center(x, y) self._panel:set_center(x, y) end
	function PanelFrame:set_center_x(v) self._panel:set_center_x(v) end
	function PanelFrame:set_center_y(v) self._panel:set_center_y(v) end
	function PanelFrame:set_visible(v) self._panel:set_visible(v) end
	function PanelFrame:set_layer(v) self._panel:set_layer(v) end
elseif string.lower(RequiredScript) == "lib/setups/gamesetup" then
	local destroy_original = GameSetup.destroy

	function GameSetup:destroy(...)
		if managers.hudlist then
			managers.hudlist:destroy()
			managers.hudlist = nil
		end
		return destroy_original(self, ...)
	end

end
