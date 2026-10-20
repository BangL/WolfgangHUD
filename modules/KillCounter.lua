if string.lower(RequiredScript) == "lib/units/enemies/cop/copdamage" then

	local _on_damage_received_original = CopDamage._on_damage_received
	local sync_damage_knockdown_original = CopDamage.sync_damage_knockdown
	local sync_damage_bullet_original = CopDamage.sync_damage_bullet
	local sync_damage_melee_original = CopDamage.sync_damage_melee

	function CopDamage:_process_kill(data)
		local killer

		local attacker = alive(data.attacker_unit) and data.attacker_unit

		if attacker then
			local attacker_base = attacker:base()
			if attacker:in_slot(3) or attacker:in_slot(5) then
				--Human team mate
				killer = attacker
			elseif attacker:in_slot(2) then
				--Player
				killer = attacker
			elseif attacker:in_slot(16) then
				--Bot
				killer = attacker
			elseif attacker:in_slot(12) then
				--Enemy
			elseif attacker:in_slot(25)	then
				--Turret
				local owner = (attacker_base and attacker_base.get_owner_id) and attacker_base:get_owner_id() or nil
				if owner then
					killer = managers.criminals:character_unit_by_peer_id(owner)
				end
			elseif attacker_base and attacker_base.thrower_unit then
				killer = attacker_base:thrower_unit()
			end

			if alive(killer) and alive(self._unit) then
				local tweak_id = self._unit:base()._tweak_table
				local is_special = tweak_data.character[tweak_id] and tweak_data.character[tweak_id].is_special
				local body = data.col_ray and data.col_ray.body or self._sync_ibody_killcount and self._unit:body(self._sync_ibody_killcount)
				local headshot = body and self.is_head and self:is_head(body) or false

				local end_stats = WolfgangHUD.EndStats
				if end_stats then
					local crim_data = managers.criminals:character_data_by_unit(killer)
					if crim_data and not crim_data.ai then
						end_stats:observe_kill(managers.criminals:character_peer_id_by_unit(killer), is_special, headshot)
					end
				end

				if killer:in_slot(2) then
					managers.hud:increment_teammate_kill_count(HUDManager.PLAYER_PANEL, is_special, headshot)
				else
					local crim_data = managers.criminals:character_data_by_unit(killer)
					if crim_data and crim_data.panel_id then
						managers.hud:increment_teammate_kill_count(crim_data.panel_id, is_special, headshot)
					end
				end
			end
		end
	end

	function CopDamage:_on_damage_received(data, ...)
		if self._dead then
			self:_process_kill(data)
		end
		self._sync_ibody_killcount = nil
		return _on_damage_received_original(self, data, ...)
	end

	function CopDamage:sync_damage_knockdown(attacker_unit, damage_percent, i_body, hit_offset_height, death, ...)
		if i_body then
			self._sync_ibody_killcount = i_body
		end
		return sync_damage_knockdown_original(self, attacker_unit, damage_percent, i_body, hit_offset_height, death, ...)
	end

	function CopDamage:sync_damage_bullet(attacker_unit, damage_percent, i_body, ...)
		if i_body then
			self._sync_ibody_killcount = i_body
		end
		return sync_damage_bullet_original(self, attacker_unit, damage_percent, i_body, ...)
	end

	function CopDamage:sync_damage_melee(attacker_unit, damage_percent, damage_effect_percent, i_body, ...)
		if i_body then
			self._sync_ibody_killcount = i_body
		end
		return sync_damage_melee_original(self, attacker_unit, damage_percent, damage_effect_percent, i_body, ...)
	end

elseif string.lower(RequiredScript) == "lib/units/equipment/sentry_gun/sentrygunbase" then

	local sync_setup_original = SentryGunBase.sync_setup

	function SentryGunBase:sync_setup(upgrade_lvl, peer_id, ...)
		sync_setup_original(self, upgrade_lvl, peer_id, ...)
		self._owner_id = self._owner_id or peer_id
	end

elseif string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then

	function HUDManager:increment_teammate_kill_count(i, is_special, headshot)
		if self._teammate_panels[i].increment_kill_count then
			self._teammate_panels[i]:increment_kill_count(is_special, headshot)
		end
	end

	function HUDManager:reset_kill_counters()
		for _, panel in ipairs(self._peer_teammate_panels) do
			if panel.reset_kill_count then
				panel:reset_kill_count()
			end
		end
		for _, panel in ipairs(self._ai_teammate_panels) do
			if panel.reset_kill_count then
				panel:reset_kill_count()
			end
		end
		local player_panel = self._teammate_panels[HUDManager.PLAYER_PANEL]
		if player_panel.reset_kill_count then
			player_panel:reset_kill_count()
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/raidjobmanager" then

	local on_mission_started_original = RaidJobManager.on_mission_started
	local on_mission_ended_original = RaidJobManager.on_mission_ended

	function RaidJobManager:on_mission_started(...)
		on_mission_started_original(self, ...)
		if managers.hud then
			managers.hud:reset_kill_counters()
		end
		if WolfgangHUD.EndStats then
			WolfgangHUD.EndStats:reset_observed()
		end
	end

	function RaidJobManager:on_mission_ended(...)
		on_mission_ended_original(self, ...)
		if managers.hud then
			managers.hud:reset_kill_counters()
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammatebase" then

	local _check_state_change_original = HUDTeammateBase._check_state_change
	local set_x_original = HUDTeammateBase.set_x

	HUDTeammateBase.KILLCOUNTER_FONT_SIZE = 20
	HUDTeammateBase.KILLCOUNTER_FONT = "din_compressed_outlined_22"

	function HUDTeammateBase:_check_state_change()
		_check_state_change_original(self)
		if alive(self._kills_panel) then
			self._kills_panel:set_visible(WolfgangHUD:ShowHudElements() and not WolfgangHUD:getSetting({"HUD", self._setting_prefix, "KILLCOUNTER", "HIDE"}, false))
		end
	end

	function HUDTeammateBase:set_x(x)
		set_x_original(self, x)
		if alive(self._kills_panel) then
			local is_ai = self:is_ai()
			if managers.hud:wolfganghud_layout_is_vanilla() then
				self._kills_panel:set_right((self._right_panel:w() - x) - 60) -- fix for ai panels alignment if human_teammates_exist (see HUDManager:_layout_teammate_panels())
			elseif managers.hud:wolfganghud_layout_is_pd2() and is_ai then
				self._kills_panel:set_right(self._right_panel:w() - 60)
			end
			if self._player_name and (is_ai or WolfgangHUD:getSetting({ "HUD", "LEVELS_BEFORE_NAME" }, true)) then
				self._kills_panel:set_y(self._player_name:y() + 1)
			end
		end
	end

	function HUDTeammateBase:_init_killcount()
		local right_panel = self._right_panel
		local y = right_panel:h() - self.KILLCOUNTER_FONT_SIZE
		if self._player_name and (self:is_ai() or WolfgangHUD:getSetting({ "HUD", "LEVELS_BEFORE_NAME" }, true)) then
			y = self._player_name:y() + 1
		end
		self._kills_panel = right_panel:panel({
			name = "kills_panel",
			visible = WolfgangHUD:ShowHudElements() and not WolfgangHUD:getSetting({"HUD", self._setting_prefix, "KILLCOUNTER", "HIDE"}, false),
			w = 150,
			h = self.KILLCOUNTER_FONT_SIZE,
			x = right_panel:w() - 150,
			y = y,
			halign = "right"
		})
		local killcount_color = WolfgangHUD:getColorSetting({"HUD", self._setting_prefix, "KILLCOUNTER", "COLOR"}, "orange")
		local icon_side_len = self._kills_panel:h() * 0.9
		self._kill_icon = self._kills_panel:bitmap({
			texture = "ui/atlas/raid_atlas_waypoints",
			texture_rect = {401, 437, 38, 38},
			w = icon_side_len,
			h = icon_side_len,
			blend_mode = "normal",
			layer = 0,
			color = killcount_color
		})
		self._kills_text = self._kills_panel:text({
			name = "kills_text",
			text = "-",
			layer = 1,
			color = killcount_color,
			x = self._kill_icon:w(),
			w = self._kills_panel:w() - self._kill_icon:w(),
			h = self._kills_panel:h(),
			vertical = "center",
			align = "right",
			font_size = self.KILLCOUNTER_FONT_SIZE,
			font = tweak_data.gui.fonts[self.KILLCOUNTER_FONT]
		})
		self:reset_kill_count()
	end

	function HUDTeammateBase:_update_kill_count_text()
		local kill_string = tostring(self._kill_count)
		if WolfgangHUD:getSetting({"HUD", self._setting_prefix, "KILLCOUNTER", "SHOW_SPECIAL_KILLS"}, true) then
			kill_string = kill_string .. "/" .. tostring(self._kill_count_special)
		end
		if WolfgangHUD:getSetting({"HUD", self._setting_prefix, "KILLCOUNTER", "SHOW_HEADSHOT_KILLS"}, true) then
			kill_string = kill_string .. " (" .. tostring(self._headshot_kills) .. ")"
		end
		self._kills_text:set_text(kill_string)
		local _, _, w, _ = self._kills_text:text_rect()
		self._kill_icon:set_right(self._kills_panel:w() - w)

		local color = WolfgangHUD:getColorSetting({"HUD", self._setting_prefix, "KILLCOUNTER", "COLOR"}, "orange")
		self._kill_icon:set_color(color)
		self._kills_text:set_color(color)
	end

	function HUDTeammateBase:increment_kill_count(is_special, headshot)
		self._kill_count = self._kill_count + 1
		self._kill_count_special = self._kill_count_special + (is_special and 1 or 0)
		self._headshot_kills = self._headshot_kills + (headshot and 1 or 0)
		self:_update_kill_count_text()
	end

	function HUDTeammateBase:reset_kill_count()
		self._kill_count = 0
		self._kill_count_special = 0
		self._headshot_kills = 0
		self:_update_kill_count_text()
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammateplayer" then

	local init_original = HUDTeammatePlayer.init

	function HUDTeammatePlayer:init(...)
		init_original(self, ...)
		self._setting_prefix = "PLAYER"
		self:_init_killcount()
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammatepeer" then

	local init_original = HUDTeammatePeer.init
	local set_name_original = HUDTeammatePeer.set_name

	function HUDTeammatePeer:init(...)
		init_original(self, ...)
		self._setting_prefix = "PEER"
		self:_init_killcount()
	end

	function HUDTeammatePeer:set_name(teammate_name, ...)
		if teammate_name ~= self._name then
			self._name = teammate_name
			self:reset_kill_count()
		end
		return set_name_original(self, teammate_name, ...)
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammateai" then

	local init_original = HUDTeammateAI.init

	function HUDTeammateAI:init(...)
		init_original(self, ...)
		self._setting_prefix = "AI"
		self:_init_killcount()
	end

end
