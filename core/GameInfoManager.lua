
local print_debug = function(text, ...)
	text = string.format("(GameInfo) %s", tostring(text))
	WolfgangHUD:print_log(text, ...)
end

if string.lower(RequiredScript) == "lib/setups/setup" then

	local init_managers_original = Setup.init_managers

	function Setup:init_managers(managers, ...)
		managers.gameinfo = managers.gameinfo or GameInfoManager:new()
		return init_managers_original(self, managers, ...)
	end

	GameInfoManager = GameInfoManager or class()

	GameInfoManager._INTERACTIONS = {
		INTERACTION_TO_CALLBACK = {

			-- valuables
			folder_outlaw =						"_pickup_interaction_handler", -- outlaw raid documents
			regular_cache_box =					"_pickup_interaction_handler", -- gold cache
			hold_take_loot =					"_pickup_interaction_handler", -- loot
			press_take_loot =					"_pickup_interaction_handler", -- loot
			press_take_loot_tight =				"_pickup_interaction_handler", -- loot
			hold_take_dogtags =					"_pickup_interaction_handler", -- dogtags
			press_take_dogtags =				"_pickup_interaction_handler", -- dogtags

			-- mission pickups
			take_sps_briefcase =				"_pickup_interaction_handler", -- briefcase
			take_code_book =					"_pickup_interaction_handler", -- code book
			gen_pku_crowbar =					"_pickup_interaction_handler", -- crowbar
			dynamite_x1_pku =					"_pickup_interaction_handler", -- dynamite
			dynamite_x4_pku =					"_pickup_interaction_handler", -- dynamite
			dynamite_x5_pku =					"_pickup_interaction_handler", -- dynamite
			take_dynamite_bag =					"_pickup_interaction_handler", -- dynamite_bag
			hold_take_canister =				"_pickup_interaction_handler", -- fuel canister
			press_take_canister =				"_pickup_interaction_handler", -- fuel canister
			take_enigma =						"_pickup_interaction_handler", -- code device
			hold_take_gas_can =					"_pickup_interaction_handler", -- gas can
			press_take_gas_can =				"_pickup_interaction_handler", -- gas can
			take_gas_tank =						"_pickup_interaction_handler", -- gas tank
			mine_pku =							"_pickup_interaction_handler", -- mine
			take_portable_radio =				"_pickup_interaction_handler", -- portable radio
			take_tools =						"_pickup_interaction_handler", -- repair tools
			take_safe_key =						"_pickup_interaction_handler", -- key
			take_safe_keychain =				"_pickup_interaction_handler", -- keychain
			take_tank_grenade =					"_pickup_interaction_handler", -- tank grenade
			take_tank_shell =					"_pickup_interaction_handler", -- tank shell
			take_thermite =						"_pickup_interaction_handler", -- thermite
			gen_pku_thermite =					"_pickup_interaction_handler", -- thermite
			hold_pku_intelligence =				"_pickup_interaction_handler", -- mission documents
			open_crate_3 =						"_pickup_interaction_handler", -- crowbar crate

			-- combat pickups
			health_bag =						"_pickup_interaction_handler", -- health bag
			health_bag_big =					"_pickup_interaction_handler", -- health bag
			health_bag_small =					"_pickup_interaction_handler", -- health bag
			ammo_bag =							"_pickup_interaction_handler", -- ammo bag
			ammo_bag_big =						"_pickup_interaction_handler", -- ammo bag
			ammo_bag_small =					"_pickup_interaction_handler", -- ammo bag
			grenade_crate =						"_pickup_interaction_handler", -- grenade crate
			grenade_crate_big =					"_pickup_interaction_handler", -- grenade crate
			grenade_crate_small =				"_pickup_interaction_handler", -- grenade crate

			-- flares
			extinguish_flare =					"_pickup_interaction_handler", -- spotter flares

			-- NOT USED
			--[[
			anwser_radio =						"_pickup_interaction_handler", -- mission radio (not a typo)
			close_cargo_door =					"_pickup_interaction_handler", -- cargo door
			close_container =					"_pickup_interaction_handler", -- container
			crane_joystick_release =			"_pickup_interaction_handler", -- crane
			destroy_valve =						"_pickup_interaction_handler", -- valve
			driving_drive =						"_pickup_interaction_handler", -- car
			hold_connect_cable =				"_pickup_interaction_handler",
			hold_contact_mrs_white =			"_pickup_interaction_handler",
			hold_fill_canister =				"_pickup_interaction_handler", -- fill canister
			hold_ignite_flag =					"_pickup_interaction_handler",
			hold_open_barrier =					"_pickup_interaction_handler",
			hold_open_crate_tut =				"_pickup_interaction_handler",
			hold_open_hatch =					"_pickup_interaction_handler", -- open door hatch
			hold_place_canister =				"_pickup_interaction_handler", -- place canister
			hold_place_codemachine =			"_pickup_interaction_handler",
			hold_pull_lever =					"_pickup_interaction_handler", -- mission lever
			hold_remove_latch =					"_pickup_interaction_handler", -- mission latch
			hold_take_empty_canister =			"_pickup_interaction_handler", -- canister
			press_take_empty_canister =			"_pickup_interaction_handler", -- canister
			hold_take_recording_device =		"_pickup_interaction_handler", -- recording device
			press_take_recording_device =		"_pickup_interaction_handler", -- recording device
			hold_start_plane =					"_pickup_interaction_handler", -- plane propeller
			hold_unlock_bank_door =				"_pickup_interaction_handler", -- lockpick: bank door
			lift_trap_door =					"_pickup_interaction_handler",
			load_shell =						"_pickup_interaction_handler", -- load flak
			lockpick_cargo_door =				"_pickup_interaction_handler", -- lockpick: cargo door
			main_menu_select_interaction =		"_pickup_interaction_handler", -- camp tables
			move_crane =						"_pickup_interaction_handler", -- crane
			open_army_crate =					"_pickup_interaction_handler", -- crowbar crate
			open_cargo_door =					"_pickup_interaction_handler", -- cargo door
			open_crate_2 =						"_pickup_interaction_handler", -- crate
			open_door =							"_pickup_interaction_handler", -- cargo door
			open_drop_pod =						"_pickup_interaction_handler", -- airdrop
			open_fusebox =						"_pickup_interaction_handler",
			open_hatch =						"_pickup_interaction_handler", -- hatch
			open_truck_trunk =					"_pickup_interaction_handler", -- truck trunk
			piano_key_instant_01 =				"_pickup_interaction_handler", -- camp: piano
			piano_key_instant_02 =				"_pickup_interaction_handler", -- camp: piano
			piano_key_instant_03 =				"_pickup_interaction_handler", -- camp: piano
			piano_key_instant_04 =				"_pickup_interaction_handler", -- camp: piano
			plant_dynamite =					"_pickup_interaction_handler", -- dynamite bag
			plant_dynamite_bag =				"_pickup_interaction_handler", -- dynamite bag
			revive =							"_pickup_interaction_handler", -- downed teammates
			set_fire_barrel =					"_pickup_interaction_handler",
			set_up_radio =						"_pickup_interaction_handler", -- mission radio
			shut_off_valve =					"_pickup_interaction_handler", -- valve
			sii_lockpick_easy =					"_pickup_interaction_handler", -- lockpick crate/door
			sii_lockpick_easy_y_direction =		"_pickup_interaction_handler", -- lockpick crate/door
			sii_lockpick_medium =				"_pickup_interaction_handler", -- lockpick crate/door
			sii_lockpick_medium_y_direction =	"_pickup_interaction_handler", -- lockpick crate/door
			sii_lockpick_hard =					"_pickup_interaction_handler", -- lockpick crate/door
			sii_lockpick_hard_y_direction =		"_pickup_interaction_handler", -- lockpick crate/door
			sii_tune_radio =					"_pickup_interaction_handler", -- mission radio
			take_flak_shell =					"_pickup_interaction_handler", -- flak shell
			temp_interact_box =					"_pickup_interaction_handler",
			train_yard_open_door =				"_pickup_interaction_handler",
			tune_radio =						"_pickup_interaction_handler", -- mission radio
			turn_on_valve =						"_pickup_interaction_handler", -- valve
			turn_searchlight =					"_pickup_interaction_handler",
			turret_m2 =							"_pickup_interaction_handler", -- turret
			turret_flak_88 =					"_pickup_interaction_handler", -- turret
			turret_flakvierling =				"_pickup_interaction_handler", -- turret
			use_flare =							"_pickup_interaction_handler",
			wake_up_spy =						"_pickup_interaction_handler", -- spy mission
			]]
		},
		INTERACTION_TO_CARRY = {
			corpse_dispose =					"corpse_body", -- fresh corpse
		},
		COMPOSITE_LOOT_UNITS = {
			[141918] = 4, [141917] = 3, [141916] = 2, --[141932] = 1, -- Kelly vault gold
			[141938] = 4, [141937] = 3, [141933] = 2, --[141919] = 1, -- Kelly vault gold
			[141942] = 4, [141941] = 3, [141940] = 2, --[141939] = 1, -- Kelly vault gold
			[141946] = 4, [141945] = 3, [141944] = 2, --[141943] = 1, -- Kelly vault gold
			[141950] = 4, [141949] = 3, [141948] = 2, --[141947] = 1, -- Kelly vault gold
			[141954] = 4, [141953] = 3, [141952] = 2, --[141951] = 1, -- Kelly vault gold
			[141958] = 4, [141957] = 3, [141956] = 2, --[141955] = 1, -- Kelly vault gold
			[141962] = 4, [141961] = 3, [141960] = 2, --[141959] = 1, -- Kelly vault gold
		},
		IGNORE_IDS = {
			-- Extraction
			spies_test = {
				[100614] = true, -- small loot in unreachable wall part
			},

			-- Full Stop
			forest_bunker = {
				[105147] = true, -- small loot in unreachable box
			},

			-- Enigmatic
			clear_skies_gold_rush = {
				[100695] = true, -- dogtag
				[100696] = true, -- dogtag
				[100698] = true, -- dogtag
				[100700] = true, -- dogtag
				[100981] = true, -- small loot
				[101157] = true, -- greed cache
				[101159] = true, -- greed cache
				[101160] = true, -- greed cache
				[101235] = true, -- small loot
				[101236] = true, -- small loot
				[101237] = true, -- small loot
				[101238] = true, -- small loot
				[101239] = true, -- small loot
				[101240] = true, -- small loot
				[101241] = true, -- small loot
				[101242] = true, -- small loot
				[101243] = true, -- small loot
				[101244] = true, -- small loot
				[101245] = true, -- small loot
				[101246] = true, -- small loot
				[101247] = true, -- small loot
				[101248] = true, -- small loot
				[101284] = true, -- greed cache
				[101285] = true, -- greed cache
			},
			-- Rolling Stock
			clear_skies_railyard = {
				[100247] = true, -- intel
				[100361] = true, -- small loot
				[100362] = true, -- small loot
				[100363] = true, -- small loot
				[100364] = true, -- small loot
				[100365] = true, -- small loot
				[100366] = true, -- small loot
				[100367] = true, -- small loot
				[100368] = true, -- small loot
				[100369] = true, -- small loot
				[100370] = true, -- small loot
				[100371] = true, -- small loot
				[100372] = true, -- small loot
				[100373] = true, -- small loot
				[100374] = true, -- small loot
				[100376] = true, -- small loot
				[100377] = true, -- small loot
				[100378] = true, -- small loot
				[100379] = true, -- small loot
				[100380] = true, -- small loot
				[100381] = true, -- small loot
				[100382] = true, -- small loot
				[100383] = true, -- small loot
				[100384] = true, -- small loot
				[100385] = true, -- small loot
				[100386] = true, -- small loot
				[100387] = true, -- small loot
				[100388] = true, -- small loot
				[100389] = true, -- small loot
				[100390] = true, -- small loot
				[100391] = true, -- small loot
				[100392] = true, -- small loot
				[100393] = true, -- small loot
				[100394] = true, -- small loot
				[100395] = true, -- small loot
				[100397] = true, -- small loot
				[100398] = true, -- small loot
				[100399] = true, -- small loot
				[100400] = true, -- small loot
				[100401] = true, -- small loot
				[100402] = true, -- small loot
				[100403] = true, -- small loot
				[100404] = true, -- small loot
				[100405] = true, -- small loot
				[100406] = true, -- small loot
				[100407] = true, -- small loot
				[100408] = true, -- small loot
				[100409] = true, -- small loot
				[100410] = true, -- small loot
				[100411] = true, -- small loot
				[100412] = true, -- small loot
				[100413] = true, -- small loot
				[100414] = true, -- small loot
				[100415] = true, -- small loot
				[100416] = true, -- small loot
				[100417] = true, -- small loot
				[100418] = true, -- small loot
				[100419] = true, -- small loot
				[100420] = true, -- small loot
				[100422] = true, -- small loot
				[100423] = true, -- small loot
				[100424] = true, -- small loot
				[100425] = true, -- small loot
				[100426] = true, -- small loot
				[100427] = true, -- small loot
				[100428] = true, -- small loot
				[100429] = true, -- small loot
				[100430] = true, -- small loot
				[100431] = true, -- small loot
				[100432] = true, -- small loot
				[100433] = true, -- small loot
				[100434] = true, -- small loot
				[100435] = true, -- small loot
				[100436] = true, -- small loot
				[100437] = true, -- small loot
				[100438] = true, -- small loot
				[100439] = true, -- small loot
				[100440] = true, -- small loot
				[100441] = true, -- small loot
				[100442] = true, -- small loot
				[100443] = true, -- small loot
				[100444] = true, -- small loot
				[100445] = true, -- small loot
				[100446] = true, -- small loot
				[100447] = true, -- small loot
				[100448] = true, -- small loot
				[100449] = true, -- small loot
				[100450] = true, -- small loot
				[100451] = true, -- small loot
				[100452] = true, -- small loot
				[100454] = true, -- small loot
				[100455] = true, -- small loot
				[100456] = true, -- small loot
				[100457] = true, -- small loot
				[100458] = true, -- small loot
				[100459] = true, -- small loot
				[100460] = true, -- small loot
				[100461] = true, -- small loot
				[100462] = true, -- small loot
				[100464] = true, -- small loot
				[100465] = true, -- small loot
				[100466] = true, -- small loot
				[100467] = true, -- small loot
				[100468] = true, -- small loot
				[100469] = true, -- small loot
				[100470] = true, -- small loot
				[100471] = true, -- small loot
				[100472] = true, -- small loot
				[100473] = true, -- small loot
				[100474] = true, -- small loot
				[100475] = true, -- small loot
				[100479] = true, -- small loot
				[100480] = true, -- small loot
				[100481] = true, -- small loot
				[100482] = true, -- small loot
				[100483] = true, -- small loot
				[100484] = true, -- small loot
				[100485] = true, -- small loot
				[100486] = true, -- small loot
				[100487] = true, -- small loot
				[100488] = true, -- small loot
				[100489] = true, -- small loot
				[100493] = true, -- small loot
				[100494] = true, -- small loot
				[100495] = true, -- small loot
				[100496] = true, -- small loot
				[100497] = true, -- small loot
				[100500] = true, -- small loot
				[100501] = true, -- small loot
				[100502] = true, -- small loot
				[100503] = true, -- small loot
				[100504] = true, -- small loot
				[100505] = true, -- small loot
				[100506] = true, -- small loot
				[100507] = true, -- small loot
				[100509] = true, -- small loot
				[100515] = true, -- small loot
				[100516] = true, -- small loot
				[100517] = true, -- small loot
				[100518] = true, -- small loot
				[100519] = true, -- small loot
				[100520] = true, -- small loot
				[100521] = true, -- small loot
				[100522] = true, -- small loot
				[100525] = true, -- small loot
				[100526] = true, -- small loot
				[100527] = true, -- small loot
				[100528] = true, -- small loot
				[100529] = true, -- small loot
				[100530] = true, -- small loot
				[100531] = true, -- small loot
				[100532] = true, -- small loot
				[100533] = true, -- small loot
				[100534] = true, -- small loot
				[100535] = true, -- small loot
				[100537] = true, -- small loot
				[100538] = true, -- small loot
				[100539] = true, -- small loot
				[100540] = true, -- small loot
				[100541] = true, -- small loot
				[100542] = true, -- small loot
				[100543] = true, -- small loot
				[100544] = true, -- small loot
				[100545] = true, -- small loot
				[100546] = true, -- small loot
				[100547] = true, -- small loot
				[100548] = true, -- small loot
				[100549] = true, -- small loot
				[100550] = true, -- small loot
				[100551] = true, -- small loot
				[100552] = true, -- small loot
				[100553] = true, -- small loot
				[100554] = true, -- small loot
				[100555] = true, -- small loot
				[100556] = true, -- small loot
				[100557] = true, -- small loot
				[100558] = true, -- small loot
				[100559] = true, -- small loot
				[100560] = true, -- small loot
				[100561] = true, -- small loot
				[100562] = true, -- small loot
				[100563] = true, -- small loot
				[100564] = true, -- small loot
				[100565] = true, -- small loot
				[100566] = true, -- small loot
				[100567] = true, -- small loot
				[100568] = true, -- small loot
				[100569] = true, -- small loot
				[100570] = true, -- small loot
				[100572] = true, -- greed cache
				[100574] = true, -- greed cache
				[100575] = true, -- greed cache
				[100576] = true, -- greed cache
				[100578] = true, -- greed cache
				[100690] = true, -- dogtag
				[401423] = true, -- small loot
				[401424] = true, -- small loot
				[401425] = true, -- small loot
				[401426] = true, -- small loot
				[401427] = true, -- small loot
				[401428] = true, -- small loot
				[401429] = true, -- small loot
				[401430] = true, -- small loot
				[401432] = true, -- small loot
				[401433] = true, -- small loot
				[401434] = true, -- small loot
				[401435] = true, -- small loot
				[401436] = true, -- small loot
				[401437] = true, -- small loot
				[401438] = true, -- small loot
				[401439] = true, -- small loot
				[401440] = true, -- small loot
				[401441] = true, -- small loot
				[401442] = true, -- small loot
				[401443] = true, -- small loot
				[401444] = true, -- small loot
				[401445] = true, -- small loot
				[401446] = true, -- small loot
				[401447] = true, -- small loot
				[401448] = true, -- small loot
				[401449] = true, -- small loot
				[401450] = true, -- small loot
				[401451] = true, -- small loot
			},
			-- Blinding Heimdall
			clear_skies_flakturm = {
				[200235] = true, -- crowbar
				[200237] = true, -- crowbar
				[200238] = true, -- crowbar
				[200239] = true, -- crowbar
				[800526] = true, -- small loot
				[800536] = true, -- small loot
				[800544] = true, -- small loot
				[800545] = true, -- small loot
				[800546] = true, -- small loot
				[800547] = true, -- small loot
				[800556] = true, -- small loot
				[800557] = true, -- small loot
				[800559] = true, -- small loot
				[800560] = true, -- small loot
				[800561] = true, -- small loot
				[800569] = true, -- small loot
				[800571] = true, -- small loot
				[800572] = true, -- small loot
				[800573] = true, -- small loot
				[800584] = true, -- small loot
				[800600] = true, -- small loot
				[800602] = true, -- small loot
				[800621] = true, -- small loot
				[800624] = true, -- small loot
				[800625] = true, -- small loot
				[800637] = true, -- small loot
				[800647] = true, -- small loot
				[800648] = true, -- small loot
				[800658] = true, -- small loot
				[800659] = true, -- small loot
				[800670] = true, -- small loot
			},

			-- Urgent Delivery
			oper_flamable_bridge = {
				[100765] = true, -- intel
				[100766] = true, -- intel
				[100767] = true, -- intel
				[100768] = true, -- intel
				[100769] = true, -- intel
				[100770] = true, -- intel
				[100813] = true, -- small loot
				[100814] = true, -- small loot
				[100815] = true, -- small loot
				[100816] = true, -- small loot
				[100817] = true, -- small loot
				[100818] = true, -- small loot
				[100819] = true, -- small loot
				[100820] = true, -- small loot
				[100821] = true, -- small loot
				[100822] = true, -- small loot
				[100823] = true, -- small loot
				[100824] = true, -- small loot
				[100825] = true, -- small loot
				[100826] = true, -- small loot
				[100827] = true, -- small loot
				[100828] = true, -- small loot
				[100829] = true, -- small loot
				[100830] = true, -- small loot
				[100831] = true, -- small loot
				[100832] = true, -- small loot
				[100833] = true, -- small loot
				[100834] = true, -- small loot
				[100835] = true, -- small loot
				[100836] = true, -- small loot
				[100869] = true, -- small loot
				[100870] = true, -- small loot
				[100871] = true, -- small loot
				[100872] = true, -- small loot
				[100873] = true, -- small loot
				[100874] = true, -- small loot
				[100875] = true, -- small loot
				[100876] = true, -- small loot
				[100877] = true, -- small loot
				[100878] = true, -- small loot
				[100879] = true, -- small loot
				[100880] = true, -- small loot
				[100881] = true, -- small loot
				[100882] = true, -- small loot
				[100883] = true, -- small loot
				[100884] = true, -- small loot
				[100885] = true, -- small loot
				[100886] = true, -- small loot
				[100887] = true, -- small loot
				[100888] = true, -- small loot
				[100889] = true, -- small loot
				[100925] = true, -- small loot
				[100926] = true, -- small loot
				[100927] = true, -- small loot
				[100928] = true, -- small loot
				[100929] = true, -- small loot
				[100930] = true, -- small loot
				[100931] = true, -- small loot
				[100933] = true, -- small loot
				[100934] = true, -- small loot
				[100945] = true, -- greed cache
				[100946] = true, -- greed cache
				[100947] = true, -- greed cache
				[100948] = true, -- greed cache
				[100949] = true, -- greed cache
				[100950] = true, -- greed cache
				[100952] = true, -- greed cache
				[100953] = true, -- greed cache
				[100981] = true, -- small loot
			},
			-- Firestarter
			oper_flamable_castle = {
				[100282] = true, -- dogtag
				[100239] = true, -- dogtag
				[100623] = true, -- greed cache
				[100624] = true, -- greed cache
				[100628] = true, -- greed cache
				[100629] = true, -- greed cache
			},
		},
		-- loot only reachable when a random door pair is open (see LootFixer)
		DOOR_AREAS = {
			-- Tiger Trap
			tnd = {
				-- ElementDisableUnit (sewer_entrance_*) executed by the random -> area with open doors
				open = {
					[101739] = "n", -- ss, doors 141 + 143
					[100119] = "w", -- se, doors 144 + 146
					[101740] = "w", -- ne, doors 144 + 146
					[101741] = "s", -- nn, doors 142 + 145 (no loot)
				},
				items = {
					-- north: between doors 141 and 143
					[100567] = "n", [100483] = "n", [100568] = "n", [100584] = "n", [100480] = "n", [100484] = "n",
					-- north: sewers in front of door 141
					[100482] = "n", [100583] = "n", [100481] = "n",
					-- west: between doors 144 and 146
					[100580] = "w", [100479] = "w", [100563] = "w", [100564] = "w", [100581] = "w",
					-- west: sewers in front of door 144
					[100565] = "w", [100566] = "w", [100582] = "w",
				},
			},
		},
		IGNORE_INACTIVE = {
			hold_take_canister = true,
			press_take_canister = true,
			gold_pile_inactive = true,
			gold_pile_inactive_repeating = true,
			carry_drop_gold = true,
			take_flak_shell = true,
			take_painting = true,
			hold_take_crate_canisters = true,
			take_ladder = true,
			take_conspiracy_board = true,
		},
	}

	function GameInfoManager:init()
		self._t = 0
		self._scheduled_callbacks = {}
		self._listeners = {}

		self._units = {}
		self._unit_count = {}
		self._loot = {}
		self._pickups = {}
	end

	function GameInfoManager:event(source, ...)
		local target = "_" .. source .. "_event"

		if self[target] then
			self[target](self, ...)
		else
			print_debug("No event handler for %s", target, "error")
		end
	end

	function GameInfoManager:register_listener(listener_id, source_type, event, clbk, keys, data_only)
		local listener_keys

		if keys then
			listener_keys = {}
			for _, key in ipairs(keys) do
				listener_keys[key] = true
			end
		end

		self._listeners[source_type] = self._listeners[source_type] or {}
		self._listeners[source_type][event] = self._listeners[source_type][event] or {}
		self._listeners[source_type][event][listener_id] = {clbk = clbk, keys = listener_keys, data_only = data_only}
	end

	function GameInfoManager:unregister_listener(listener_id, source_type, event)
		if self._listeners[source_type] then
			if self._listeners[source_type][event] then
				self._listeners[source_type][event][listener_id] = nil
			end
		end
	end

	function GameInfoManager:_listener_callback(source, event, key, ...)
		for listener_id, data in pairs(self._listeners[source] and self._listeners[source][event] or {}) do
			if not data.keys or data.keys[key] then
				if data.data_only then
					data.clbk(...)
				else
					data.clbk(event, key, ...)
				end
			end
		end
	end

	-- UNIT

	function GameInfoManager:_unit_event(event, key, data)
		if event == "add" then
			if not self._units[key] then
				local unit_type = data.unit:base()._tweak_table
				self._units[key] = {unit = data.unit, type = unit_type}
				self:_listener_callback("unit", event, key, self._units[key])
				self:_unit_count_event("change", unit_type, 1)
			end
		elseif event == "remove" then
			if self._units[key] then
				self:_listener_callback("unit", event, key, self._units[key])
				self:_unit_count_event("change", self._units[key].type, -1)
				self._units[key] = nil
			end
		end
	end

	function GameInfoManager:_unit_count_event(event, unit_type, value)
		if event == "change" then
			if value ~= 0 then
				self._unit_count[unit_type] = (self._unit_count[unit_type] or 0) + value
				self:_listener_callback("unit_count", "change", unit_type, value)
			end
		elseif event == "set" then
			self:_unit_count_event("change", unit_type, value - (self._unit_count[unit_type] or 0))
		end
	end

	function GameInfoManager:get_units(key)
		if key then
			return self._units[key]
		else
			return self._units
		end
	end

	function GameInfoManager:get_unit_count(id)
		if id then
			return self._unit_count[id] or 0
		else
			return self._unit_count
		end
	end

	-- INTERACTIVE UNIT

	function GameInfoManager:_is_closed_door_area_unit(job_id, unit)
		local areas = GameInfoManager._INTERACTIONS.DOOR_AREAS[job_id]
		local area = areas and areas.items[unit:editor_id() % 1000000]
		if not area then
			return false
		end
		local world_def = managers.worldcollection:get_worlddefinition_by_unit_id(unit:unit_data().unit_id)
		if not world_def then
			return false
		end
		local world_id = world_def:world_id()
		local mission = managers.worldcollection._missions[world_id]
		if not mission then
			return false
		end
		for _, script in pairs(mission._scripts) do
			for element_id, open_area in pairs(areas.open) do
				local element = script._elements[element_id]
				if element and element._has_executed then
					return area ~= open_area
				end
			end
		end
		return false
	end

	function GameInfoManager:_interactive_unit_event(event, key, data)
		local lookup = GameInfoManager._INTERACTIONS

		local job_id = (managers.raid_job:current_job() and managers.raid_job:current_job().job_type == OperationsTweakData.JOB_TYPE_OPERATION)
			and managers.raid_job:current_operation_event().mission_id
			or managers.raid_job:current_job_id()
		if lookup.IGNORE_IDS[job_id] and (lookup.IGNORE_IDS[job_id][data.editor_id % 1000000]) then
			return
		end
		if self:_is_closed_door_area_unit(job_id, data.unit) then
			return
		end

		local interact_clbk = lookup.INTERACTION_TO_CALLBACK[data.interact_id]
		if interact_clbk then
			self[interact_clbk](self, event, key, data)
		else
			local carry_id = data.unit:carry_data() and data.unit:carry_data():carry_id() or lookup.INTERACTION_TO_CARRY[data.interact_id] or (self._loot[key] and self._loot[key].carry_id)
			self._logged_combos = self._logged_combos or {}
			if carry_id then
				if not self._logged_combos[data.interact_id .. "_" .. carry_id] then
					print_debug("carry interaction! interact_id: %s - carry_id: %s", data.interact_id, carry_id, "info")
					self._logged_combos[data.interact_id .. "_" .. carry_id] = true
				end
				data.carry_id = carry_id
				self:_loot_interaction_handler(event, key, data)
			else
				if not self._logged_combos[data.interact_id] then
					print_debug("interactable unit! interact_id: %s", data.interact_id, "info")
					self._logged_combos[data.interact_id] = true
				end
				self:_listener_callback("interactable_unit", event, key, data.unit, data.interact_id, carry_id)
			end
		end
	end

	function GameInfoManager:_pickup_interaction_handler(event, key, data)
		if event == "add" then
			if not self._pickups[key] then
				if data.unit.greed and data.unit:greed() and data.unit:greed().reserve_left and data.unit:greed():reserve_left() == 0 then -- ignore emptied greed caches as drop-in
					return
				end
				self._pickups[key] = {unit = data.unit, interact_id = data.interact_id, value = 1}
				if data.unit.loot_drop and data.unit:loot_drop() and WolfgangHUD:getSetting({"HUDList", "use_dogtag_values"}, true) then
					self._pickups[key].value = data.unit:loot_drop():value()
				end
				self:_listener_callback("pickup", "add", key, self._pickups[key])
				self:_pickup_count_event("change", data.interact_id, self._pickups[key].value, self._pickups[key])
			end
		elseif event == "remove" then
			if self._pickups[key] then
				self:_listener_callback("pickup", "remove", key, self._pickups[key])
				self:_pickup_count_event("change", data.interact_id, -self._pickups[key].value, self._pickups[key])
				self._pickups[key] = nil
			end
		end
	end

	-- units deleted without an interaction destroy (e.g. greed items culled on drop-in) would stay counted forever
	function GameInfoManager:_remove_dead_pickups()
		for key, pickup in pairs(self._pickups) do
			if not alive(pickup.unit) then
				self:_pickup_interaction_handler("remove", key, {interact_id = pickup.interact_id})
			end
		end
	end

	function GameInfoManager:_pickup_count_event(event, interact_id, value, data)
		if event == "change" then
			if value ~= 0 then
				self:_listener_callback("pickup_count", "change", interact_id, value, data)
			end
		end
	end

	function GameInfoManager:get_pickups(key)
		if key then
			return self._pickups[key]
		else
			return self._pickups
		end
	end

	function GameInfoManager:_loot_interaction_handler(event, key, data)
		if event == "add" then
			if not self._loot[key] then
				local composite_lookup = GameInfoManager._INTERACTIONS.COMPOSITE_LOOT_UNITS
				local count = composite_lookup[data.editor_id % 1000000] or composite_lookup[data.interact_id] or 1

				self._loot[key] = {unit = data.unit, carry_id = data.carry_id, count = count }
				self:_listener_callback("loot", "add", key, self._loot[key])
				self:_loot_count_event("change", data.carry_id, count, self._loot[key])
			end
		elseif self._loot[key] then
			if event == "remove"then
				self:_listener_callback("loot", "remove", key, self._loot[key])
				self:_loot_count_event("change", data.carry_id, -self._loot[key].count, self._loot[key])
				self._loot[key] = nil
			elseif event == "interact" then
				local composite_lookup = GameInfoManager._INTERACTIONS.COMPOSITE_LOOT_UNITS
				local count = composite_lookup[data.editor_id % 1000000] or composite_lookup[data.interact_id] or 1
				local change = count - self._loot[key].count

				self._loot[key].count = count
				self:_listener_callback("loot", "interact", key, self._loot[key])
				self:_loot_count_event("change", data.carry_id, change, self._loot[key])
			end
		end
	end

	function GameInfoManager:_loot_count_event(event, carry_id, value, data)
		if event == "change" then
			if value ~= 0 then
				self:_listener_callback("loot_count", "change", carry_id, value, data)
			end
		end
	end

	function GameInfoManager:get_loot(key)
		if key then
			return self._loot[key]
		else
			return self._loot
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/enemymanager" then

	local on_enemy_registered_original = EnemyManager.on_enemy_registered
	local on_enemy_unregistered_original = EnemyManager.on_enemy_unregistered

	function EnemyManager:on_enemy_registered(unit, ...)
		managers.gameinfo:event("unit", "add", tostring(unit:key()), {unit = unit})
		on_enemy_registered_original(self, unit, ...)
	end

	function EnemyManager:on_enemy_unregistered(unit, ...)
		managers.gameinfo:event("unit", "remove", tostring(unit:key()))
		on_enemy_unregistered_original(self, unit, ...)
	end

elseif string.lower(RequiredScript) == "lib/managers/objectinteractionmanager" then

	local init_original = ObjectInteractionManager.init
	local update_original = ObjectInteractionManager.update
	local add_unit_original = ObjectInteractionManager.add_unit
	local remove_unit_original = ObjectInteractionManager.remove_unit
	local end_action_interact_original = ObjectInteractionManager.end_action_interact

	function ObjectInteractionManager:init(...)
		init_original(self, ...)
		self._queued_units = {}
	end

	function ObjectInteractionManager:update(t, ...)
		update_original(self, t, ...)
		self:_process_queued_units(t)
		if not self._next_dead_pickup_check or t >= self._next_dead_pickup_check then
			self._next_dead_pickup_check = t + 1
			managers.gameinfo:_remove_dead_pickups()
		end
	end

	function ObjectInteractionManager:add_unit(unit, ...)
		self:add_unit_clbk(unit)
		return add_unit_original(self, unit, ...)
	end

	function ObjectInteractionManager:remove_unit(unit, ...)
		self:remove_unit_clbk(unit)
		return remove_unit_original(self, unit, ...)
	end

	function ObjectInteractionManager:end_action_interact(...)
		local value = end_action_interact_original(self, ...)

		if alive(self._active_unit) and self._active_unit:interaction() then
			local id = self._active_unit:interaction().tweak_data
			local editor_id = self._active_unit:editor_id()
			managers.gameinfo:event("interactive_unit", "interact", tostring(self._active_unit:key()), {unit = self._active_unit, editor_id = editor_id, interact_id = id})
		end

		return value
	end

	function ObjectInteractionManager:add_unit_clbk(unit)
		self._queued_units[tostring(unit:key())] = unit
	end

	function ObjectInteractionManager:remove_unit_clbk(unit, interact_id)
		local key = tostring(unit:key())

		if self._queued_units[key] then
			self._queued_units[key] = nil
		else
			local id = interact_id or unit:interaction() and unit:interaction().tweak_data
			if id then
				local editor_id = unit:editor_id()
				managers.gameinfo:event("interactive_unit", "remove", key, {unit = unit, editor_id = editor_id, interact_id = id})
			end
		end
	end

	function ObjectInteractionManager:_process_queued_units(t)
		for key, unit in pairs(self._queued_units) do
			if alive(unit) then
				local interaction = unit:interaction()
				local interact_id = interaction.tweak_data
				local editor_id = unit:editor_id()
				if interaction:active() or not GameInfoManager._INTERACTIONS.IGNORE_INACTIVE[interact_id] then
					managers.gameinfo:event("interactive_unit", "add", key, {unit = unit, editor_id = editor_id, interact_id = interact_id})
				end
			end
			self._queued_units[key] = nil
		end
	end

elseif string.lower(RequiredScript) == "lib/units/interactions/interactionext" then

	local init_original = BaseInteractionExt.init
	local destroy_original = BaseInteractionExt.destroy
	local set_tweak_data_original = BaseInteractionExt.set_tweak_data

	function BaseInteractionExt:init(unit, ...)
		init_original(self, unit, ...)
		managers.interaction:add_unit_clbk(self._unit)
	end

	function BaseInteractionExt:destroy(...)
		managers.interaction:remove_unit_clbk(self._unit, self.tweak_data)
		destroy_original(self, ...)
	end

	function BaseInteractionExt:set_tweak_data(...)
		local old_tweak = self.tweak_data

		set_tweak_data_original(self, ...)

		if self.tweak_data ~= old_tweak then
			managers.interaction:remove_unit_clbk(self._unit, old_tweak)
			managers.interaction:add_unit_clbk(self._unit)
		end
	end

elseif string.lower(RequiredScript) == "lib/units/pickups/greedcacheitem" then

	local on_interacted_original = GreedCacheItem.on_interacted

	function GreedCacheItem:on_interacted(amount, ...)
		local pickup_amount = on_interacted_original(self, amount, ...)

		if self:reserve_left() == 0 then
			local unit = self._unit
			local key = tostring(unit:key())
			local editor_id = unit:editor_id()
			local interact_id = unit:interaction().tweak_data
			managers.gameinfo:event("interactive_unit", "remove", key, {unit = unit, editor_id = editor_id, interact_id = interact_id})
		end

		return pickup_amount
	end

end
