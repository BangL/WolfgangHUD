if string.lower(RequiredScript) == "lib/managers/statisticsmanager" then

	local shot_fired_original = StatisticsManager.shot_fired

	function StatisticsManager:shot_fired(data, ...)
		shot_fired_original(self, data, ...)
		managers.hud:set_teammate_accuracy(HUDManager.PLAYER_PANEL, self:session_hit_accuracy())
	end

elseif string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then

	function HUDManager:reset_accuracy()
		local player_panel = self._teammate_panels[HUDManager.PLAYER_PANEL]
		if player_panel.set_accuracy then
			player_panel:set_accuracy(0)
		end
	end

	function HUDManager:set_teammate_accuracy(i, value)
		if self._teammate_panels[i].set_accuracy then
			self._teammate_panels[i]:set_accuracy(value)
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/raidjobmanager" then

	local on_mission_started_original = RaidJobManager.on_mission_started
	local on_mission_ended_original = RaidJobManager.on_mission_ended

	function RaidJobManager:on_mission_started(...)
		on_mission_started_original(self, ...)
		if managers.hud then
			managers.hud:reset_accuracy()
		end
	end

	function RaidJobManager:on_mission_ended(...)
		on_mission_ended_original(self, ...)
		if managers.hud then
			managers.hud:reset_accuracy()
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammateplayer" then

	local init_original = HUDTeammatePlayer.init
	local _check_state_change_original = HUDTeammatePlayer._check_state_change

	HUDTeammatePlayer.ACCURACY_FONT_SIZE = 20
	HUDTeammatePlayer.ACCURACY_FONT = "din_compressed_outlined_22"

	function HUDTeammatePlayer:init(...)
		init_original(self, ...)
		self:_init_accuracy()
	end

	function HUDTeammatePlayer:_check_state_change()
		_check_state_change_original(self)
		if alive(self._accuracy_panel) then
			self._accuracy_panel:set_visible(WolfgangHUD:ShowHudElements() and WolfgangHUD:getSetting({"HUD", "PLAYER", "SHOW_ACCURACY"}, true))
		end
	end

	function HUDTeammatePlayer:_init_accuracy()
		local right_panel = self._right_panel
		self._accuracy_panel = right_panel:panel({
			name = "accuracy_panel",
			visible = WolfgangHUD:ShowHudElements() and WolfgangHUD:getSetting({"HUD", "PLAYER", "SHOW_ACCURACY"}, true),
			w = 100,
			h = self.ACCURACY_FONT_SIZE,
			x = right_panel:w() - 100,
			y = right_panel:h() - self.ACCURACY_FONT_SIZE,
			halign = "right"
		})
		local icon_side_len = self._accuracy_panel:h() * 0.9
		self._accuracy_icon = self._accuracy_panel:bitmap({
			texture = "ui/atlas/raid_atlas_waypoints",
			texture_rect = {451, 291, 38, 38},
			w = icon_side_len,
			h = icon_side_len,
			blend_mode = "normal",
			layer = 0,
			color = Color.white
		})
		self._accuracy_text = self._accuracy_panel:text({
			name = "accuracy_text",
			text = "0%",
			layer = 1,
			color = Color.white,
			x = self._accuracy_icon:w(),
			w = self._accuracy_panel:w() - self._accuracy_icon:w(),
			h = self._accuracy_panel:h(),
			vertical = "center",
			align = "right",
			font_size = self.ACCURACY_FONT_SIZE,
			font = tweak_data.gui.fonts[self.ACCURACY_FONT]
		})
		-- mirror the killcounter (centered on the name): same distance to the health bar, below it
		local health_panel = right_panel:child("health_panel")
		if health_panel and alive(self._player_name) then
			self._accuracy_panel:set_center_y(2 * health_panel:center_y() - self._player_name:center_y())
		end
		self:set_accuracy(0)
	end

	function HUDTeammatePlayer:set_accuracy(value)
		self._accuracy_text:set_text(tostring(value) .. "%")
		local _, _, w, _ = self._accuracy_text:text_rect()
		self._accuracy_text:set_w(w)
		self._accuracy_panel:set_w(self._accuracy_icon:w() + w)
		self._accuracy_panel:set_right(self._object:w() - HUDTeammatePlayer.RIGHT_PANEL_X)
	end

end
