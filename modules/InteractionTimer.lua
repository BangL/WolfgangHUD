if string.lower(RequiredScript) == "lib/units/beings/player/states/playerstandard" then

	local enter_original = PlayerStandard.enter
	local _update_interaction_timers_original = PlayerStandard._update_interaction_timers
	local _check_action_interact_original = PlayerStandard._check_action_interact
	local _start_action_reload_original = PlayerStandard._start_action_reload
	local _update_reload_timers_original = PlayerStandard._update_reload_timers
	local _interupt_action_reload_original = PlayerStandard._interupt_action_reload
	local _start_action_melee_original = PlayerStandard._start_action_melee
	local _update_melee_timers_original = PlayerStandard._update_melee_timers
	local _do_melee_damage_original = PlayerStandard._do_melee_damage

	local hide_int_state = {
		["bleed_out"] = true,
		["fatal"] = true,
		["incapacitated"] = true,
		["dead"] = true
	}

	function PlayerStandard:_update_interaction_timers(t, ...)
		self:_check_interaction_locked(t)
		return _update_interaction_timers_original(self, t, ...)
	end

	function PlayerStandard:_check_action_interact(t, input, ...)
		if not self:_check_interact_toggle(t, input) then
			return _check_action_interact_original(self, t, input, ...)
		end
	end

	function PlayerStandard:_check_interaction_locked(t)
		PlayerStandard.LOCK_MODE = WolfgangHUD:getSetting({"INTERACTION", "LOCK_MODE"}, 3) --Lock interaction, if MIN_TIMER_DURATION is longer then total interaction time, or current interaction time
		PlayerStandard.MIN_TIMER_DURATION = WolfgangHUD:getSetting({"INTERACTION", "MIN_TIMER_DURATION"}, 0) --Min interaction duration (in seconds) for the toggle behavior to activate
		local is_locked = false
		if self._interact_params ~= nil then
			local total_timer = self._interact_params.timer or 0
			if PlayerStandard.LOCK_MODE >= 3 then
				is_locked = self._interact_params and (self._interact_params.timer >= PlayerStandard.MIN_TIMER_DURATION) -- lock interaction, when total timer time is longer then given time
			elseif PlayerStandard.LOCK_MODE >= 2 then
				is_locked = (total_timer - (self._interact_expire_t - t)) >= PlayerStandard.MIN_TIMER_DURATION --lock interaction, when interacting longer then given time
			end
		end

		if self._interaction_locked ~= is_locked then
			managers.hud:set_interaction_bar_locked(is_locked, self._interact_params and self._interact_params.tweak_data or "")
			self._interaction_locked = is_locked
		end
	end

	function PlayerStandard:_check_interact_toggle(t, input)
		PlayerStandard.EQUIPMENT_PRESS_INTERRUPT = WolfgangHUD:getSetting({"INTERACTION", "EQUIPMENT_PRESS_INTERRUPT"}, true)	--Use the equipment key ('G') to toggle off active interactions
		local interrupt_key_press = input.btn_interact_press
		if PlayerStandard.EQUIPMENT_PRESS_INTERRUPT then
			interrupt_key_press = input.btn_use_item_press
		end

		if interrupt_key_press and self:_interacting() then
			self:_interupt_action_interact(t, input, false, true)
			return true
		elseif input.btn_interact_release and self._interact_params then
			if self._interaction_locked then
				return true
			end
		end
	end

	function PlayerStandard:enter(...)
		enter_original(self, ...)
		if hide_int_state[managers.player:current_state()] and (self._state_data.show_reload or self._state_data.show_melee) then
			managers.hud:hide_interaction_bar(false)
			self._state_data.show_reload = false
			self._state_data.show_melee = false
		end
	end

	function PlayerStandard:_start_action_reload(t, ...)
		_start_action_reload_original(self, t, ...)
		PlayerStandard.SHOW_RELOAD = WolfgangHUD:getSetting({"INTERACTION", "SHOW_RELOAD"}, false)
		if PlayerStandard.SHOW_RELOAD and not hide_int_state[managers.player:current_state()] then
			if self._equipped_unit and not self._equipped_unit:base():clip_full() then
				self._state_data.show_reload = true
				managers.hud:show_interaction_bar(0, (self._state_data.reload_expire_t or t) - t, true)
				self._state_data.reload_offset = t
			end
		end
	end

	function PlayerStandard:_update_reload_timers(t, ...)
		_update_reload_timers_original(self, t, ...)
		if PlayerStandard.SHOW_RELOAD then
			if self._state_data.show_reload and hide_int_state[managers.player:current_state()] then
				managers.hud:hide_interaction_bar(false)
				self._state_data.show_reload = false
			elseif not self._state_data.reload_expire_t and self._state_data.show_reload then
				managers.hud:hide_interaction_bar(true)
				self._state_data.show_reload = false
			elseif self._state_data.show_reload then
				managers.hud:set_interaction_bar_width(t and t - self._state_data.reload_offset or 0, self._state_data.reload_expire_t and self._state_data.reload_expire_t - self._state_data.reload_offset or 0 )
			end
		end
	end

	function PlayerStandard:_interupt_action_reload(...)
		local val = _interupt_action_reload_original(self, ...)
		if self._state_data.show_reload and PlayerStandard.SHOW_RELOAD then
			managers.hud:hide_interaction_bar(false)
			self._state_data.show_reload = false
		end
		return val
	end

	function PlayerStandard:_start_action_melee(t, input, instant, ...)
		local val = _start_action_melee_original(self, t, input, instant, ...)
		if not instant then
			PlayerStandard.SHOW_MELEE = WolfgangHUD:getSetting({"INTERACTION", "SHOW_MELEE"}, false)
			if PlayerStandard.SHOW_MELEE and self._state_data.meleeing and not hide_int_state[managers.player:current_state()] then
				self._state_data.show_melee = true
				self._state_data.melee_charge_duration = tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].stats.charge_time or 1
				managers.hud:show_interaction_bar(0, self._state_data.melee_charge_duration, true)
			end
		end
		return val
	end

	function PlayerStandard:_update_melee_timers(t, ...)
		local val = _update_melee_timers_original(self, t, ...)
		if PlayerStandard.SHOW_MELEE and self._state_data.meleeing and self._state_data.show_melee then
			local melee_lerp = self:_get_melee_charge_lerp_value(t)
			if hide_int_state[managers.player:current_state()] then
				managers.hud:hide_interaction_bar(false)
				self._state_data.show_melee = false
			elseif melee_lerp < 1 then
				managers.hud:set_interaction_bar_width(self._state_data.melee_charge_duration * melee_lerp, self._state_data.melee_charge_duration)
			elseif self._state_data.show_melee then
				managers.hud:hide_interaction_bar(true)
				self._state_data.show_melee = false
			end
		end
		return val
	end

	function PlayerStandard:_do_melee_damage(...)
		managers.hud:hide_interaction_bar(false)
		self._state_data.show_melee = false
		return _do_melee_damage_original(self, ...)
	end

elseif string.lower(RequiredScript) == "lib/units/beings/player/states/playerdriving" then

	local _update_action_timers_original = PlayerDriving._update_action_timers
	local _start_action_exit_vehicle_original = PlayerDriving._start_action_exit_vehicle
	local _check_action_exit_vehicle_original = PlayerDriving._check_action_exit_vehicle

	function PlayerDriving:_update_action_timers(t, ...)
		self:_check_interaction_locked(t)
		return _update_action_timers_original(self, t, ...)
	end

	function PlayerDriving:_start_action_exit_vehicle(t)
		if not self:_interacting() then
			return _start_action_exit_vehicle_original(self, t)
		end
	end

	function PlayerDriving:_check_action_exit_vehicle(t, input, ...)
		if not self:_check_interact_toggle(t, input) then
			return _check_action_exit_vehicle_original(self, t, input, ...)
		end
	end

	function PlayerDriving:_check_interact_toggle(t, input)
		PlayerDriving.EQUIPMENT_PRESS_INTERRUPT = WolfgangHUD:getSetting({"INTERACTION", "EQUIPMENT_PRESS_INTERRUPT"}, true) --Use the equipment key ('G') to toggle off active interactions
		local interrupt_key_press = input.btn_interact_press
		if PlayerDriving.EQUIPMENT_PRESS_INTERRUPT then
			interrupt_key_press = input.btn_use_item_press
		end
		if interrupt_key_press and self:_interacting() then
			self:_interupt_action_exit_vehicle()
			return true
		elseif input.btn_interact_release and self:_interacting() then
			if self._interaction_locked then
				return true
			end
		end
	end

	function PlayerDriving:_check_interaction_locked(t)
		PlayerDriving.LOCK_MODE = WolfgangHUD:getSetting({"INTERACTION", "LOCK_MODE"}, 3) --Lock interaction, if MIN_TIMER_DURATION is longer then total interaction time, or current interaction time
		PlayerDriving.MIN_TIMER_DURATION = WolfgangHUD:getSetting({"INTERACTION", "MIN_TIMER_DURATION"}, 0) --Min interaction duration (in seconds) for the toggle behavior to activate
		local is_locked = false
		if self._exit_vehicle_expire_t ~= nil and not WolfgangHUD:getSetting({"INTERACTION", "NO_LOCK_WHEN_DRIVING"}, false) then
			if PlayerDriving.LOCK_MODE >= 3 then
				is_locked = (PlayerDriving.EXIT_VEHICLE_TIMER >= PlayerDriving.MIN_TIMER_DURATION) -- lock interaction, when total timer time is longer then given time
			elseif PlayerDriving.LOCK_MODE >= 2 then
				is_locked = self._exit_vehicle_expire_t and (t - (self._exit_vehicle_expire_t - PlayerDriving.EXIT_VEHICLE_TIMER) >= PlayerDriving.MIN_TIMER_DURATION) --lock interaction, when interacting longer then given time
			end
		end

		if self._interaction_locked ~= is_locked then
			managers.hud:set_progress_timer_bar_locked(is_locked, "")
			self._interaction_locked = is_locked
		end
	end

elseif string.lower(RequiredScript) == "lib/units/beings/player/states/playerfoxhole" then

	local _update_action_timers_original = PlayerFoxhole._update_action_timers
	local _start_interaction_exit_foxhole_original = PlayerFoxhole._start_interaction_exit_foxhole
	local _check_action_exit_foxhole_original = PlayerFoxhole._check_action_exit_foxhole

	function PlayerFoxhole:_update_action_timers(t, ...)
		self:_check_interaction_locked(t)
		return _update_action_timers_original(self, t, ...)
	end

	function PlayerFoxhole:_start_interaction_exit_foxhole(t)
		if not self:_interacting() then
			return _start_interaction_exit_foxhole_original(self, t)
		end
	end

	function PlayerFoxhole:_check_action_exit_foxhole(t, input, ...)
		if not self:_check_interact_toggle(t, input) then
			return _check_action_exit_foxhole_original(self, t, input, ...)
		end
	end

	function PlayerFoxhole:_check_interact_toggle(t, input)
		PlayerFoxhole.EQUIPMENT_PRESS_INTERRUPT = WolfgangHUD:getSetting({"INTERACTION", "EQUIPMENT_PRESS_INTERRUPT"}, true) --Use the equipment key ('G') to toggle off active interactions
		local interrupt_key_press = input.btn_interact_press
		if PlayerFoxhole.EQUIPMENT_PRESS_INTERRUPT then
			interrupt_key_press = input.btn_use_item_press
		end
		if interrupt_key_press and self:_interacting() then
			self:_interupt_action_exit_foxhole()
			return true
		elseif input.btn_interact_release and self:_interacting() then
			if self._interaction_locked then
				return true
			end
		end
	end

	function PlayerFoxhole:_check_interaction_locked(t)
		PlayerFoxhole.LOCK_MODE = WolfgangHUD:getSetting({"INTERACTION", "LOCK_MODE"}, 3) --Lock interaction, if MIN_TIMER_DURATION is longer then total interaction time, or current interaction time
		PlayerFoxhole.MIN_TIMER_DURATION = WolfgangHUD:getSetting({"INTERACTION", "MIN_TIMER_DURATION"}, 0) --Min interaction duration (in seconds) for the toggle behavior to activate
		local is_locked = false
		if self._exit_foxhole_expire_t ~= nil then
			if PlayerFoxhole.LOCK_MODE >= 3 then
				is_locked = (PlayerFoxhole.EXIT_TIMER >= PlayerFoxhole.MIN_TIMER_DURATION) -- lock interaction, when total timer time is longer then given time
			elseif PlayerFoxhole.LOCK_MODE >= 2 then
				is_locked = self._exit_foxhole_expire_t and (t - (self._exit_foxhole_expire_t - PlayerFoxhole.EXIT_TIMER) >= PlayerFoxhole.MIN_TIMER_DURATION) --lock interaction, when interacting longer then given time
			end
		end

		if self._interaction_locked ~= is_locked then
			managers.hud:set_progress_timer_bar_locked(is_locked, "")
			self._interaction_locked = is_locked
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then

	function HUDManager:show_interaction_bar(current, total, is_non_interaction)
		self._hud_interaction:show_interaction_bar(current, total, is_non_interaction)
	end

	function HUDManager:set_interaction_bar_locked(status)
		self._hud_interaction:set_locked(status)
	end

	function HUDManager:set_progress_timer_bar_locked(status)
		if self._progress_timer_progress_bar then
			self._progress_timer_progress_bar:set_locked(status)
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudinteraction" then

	local init_original = HUDInteraction.init
	local show_interaction_bar_original = HUDInteraction.show_interaction_bar
	local hide_interaction_bar_original = HUDInteraction.hide_interaction_bar
	local show_interact_original = HUDInteraction.show_interact
	local destroy_original = HUDInteraction.destroy
	local set_interaction_bar_width_original = HUDInteraction.set_interaction_bar_width

	function HUDInteraction:init(...)
		init_original(self, ...)

		local interact_text = self._hud_panel:child(self._child_name_text)
		local invalid_text = self._hud_panel:child(self._child_ivalid_name_text)
		self._original_progress_bar_width = self._progress_bar_width
		self._original_progress_bar_height = self._progress_bar_height
		self._original_interact_text_font_size = interact_text:font_size()
		self._original_invalid_text_font_size = invalid_text:font_size()

		self:_rescale()
	end

	function HUDInteraction:set_interaction_bar_width(current, total)
		set_interaction_bar_width_original(self, current, total)

		local perc = current / total

		if self._progress_bar_locked then
			self._progress_bar_locked:set_width(perc * self._progress_bar_width + 4)
		end

		if self._interact_time then
			local text = string.format("%.1fs", math.max(total - current, 0))
			self._interact_time:set_text(text)
			local show = perc < 1
			local color = math.lerp(HUDInteraction.GRADIENT_COLOR_START, WolfgangHUD:getColor(HUDInteraction.GRADIENT_COLOR_NAME, 0.4), perc)
			self._interact_time:set_color(color)
			self._interact_time:set_alpha(1)
			self._interact_time:set_visible(show)
		end
	end

	function HUDInteraction:show_interaction_bar(current, total, is_non_interaction)
		self:_rescale()
		if self._progress_bar_locked then
			self._progress_bar_locked:parent():remove(self._progress_bar_locked)
			self._progress_bar_locked = nil
		end

		show_interaction_bar_original(self, current, total)

		self._progress_bar:set_layer(4)

		HUDInteraction.SHOW_LOCK_INDICATOR = WolfgangHUD:getSetting({"INTERACTION", "SHOW_LOCK_INDICATOR"}, false)
		HUDInteraction.SHOW_TIME_REMAINING = WolfgangHUD:getSetting({"INTERACTION", "SHOW_TIME_REMAINING"}, true)
		HUDInteraction.TIMER_OFFSET_X = WolfgangHUD:getSetting({"INTERACTION", "TIMER_OFFSET_X"}, 0)
		HUDInteraction.TIMER_OFFSET_Y = WolfgangHUD:getSetting({"INTERACTION", "TIMER_OFFSET_Y"}, 36)
		HUDInteraction.HIDE_MOTION_DOT = WolfgangHUD:getSetting({"INTERACTION", "HIDE_MOTION_DOT"}, false)
		HUDInteraction.SHOW_BAR = WolfgangHUD:getSetting({"INTERACTION", "SHOW_BAR"}, false)
		HUDInteraction.LOCK_MODE = PlayerStandard.LOCK_MODE or 1
		HUDInteraction.GRADIENT_COLOR_NAME = WolfgangHUD:getSetting({"INTERACTION", "GRADIENT_COLOR"}, "white")
		HUDInteraction.GRADIENT_COLOR_START = WolfgangHUD:getColorSetting({"INTERACTION", "GRADIENT_COLOR_START"}, "orange")
		if HUDInteraction.SHOW_BAR then
			if HUDInteraction.LOCK_MODE > 1 and HUDInteraction.SHOW_LOCK_INDICATOR and not is_non_interaction then
				self._progress_bar_locked = self._hud_panel:bitmap({
					layer = 3,
					x = self._progress_bar_x - 2,
					y = self._progress_bar_y - 2,
					w = 4,
					h = self._progress_bar_height + 4,
					color = self._old_text and Color.green or Color.red,
					alpha = 0.8,
				})
			end
			self._progress_bar:set_alpha(1)
			self._progress_bar_bg:set_alpha(1)
		else
			HUDInteraction.SHOW_LOCK_INDICATOR = false
			self._progress_bar:set_visible(false)
			self._progress_bar_bg:set_visible(false)
			self._progress_bar:set_alpha(0)
			self._progress_bar_bg:set_alpha(0)
		end

		if HUDInteraction.SHOW_TIME_REMAINING then
			local fontSize = 32 * WolfgangHUD:getSetting({"INTERACTION", "TIMER_SCALE"}, 1.2)
			if not self._interact_time then
				self._interact_time = self._hud_panel:text({
					name = "interaction_timer",
					visible = false,
					text = "",
					valign = "center",
					align = "center",
					layer = 2,
					color = HUDInteraction.GRADIENT_COLOR_START,
					font = tweak_data.gui.fonts.din_compressed_outlined_32,
					font_size = fontSize,
					h = 64
				})
			else
				self._interact_time:set_font_size(fontSize)
			end
			local text = string.format("%.1fs", total)
			self._interact_time:set_x(HUDInteraction.TIMER_OFFSET_X + self._hud_panel:center_x() - self._interact_time:w() / 2)
			self._interact_time:set_y(HUDInteraction.TIMER_OFFSET_Y + self._hud_panel:center_y() - self._interact_time:h() / 2)
			self._interact_time:set_text(text)
			self._interact_time:show()

			if HUDInteraction.HIDE_MOTION_DOT and managers.user:get_setting("motion_dot") >= 2 then
				self._motion_dot_hidden = true
				managers.hud:fade_out_motion_dot()
			end
		end
	end

	function HUDInteraction:hide_interaction_bar(complete, show_interact_at_finish, ...)
		if self._progress_bar_locked then
			self._progress_bar_locked:parent():remove(self._progress_bar_locked)
			self._progress_bar_locked = nil
		end

		if self._interact_time then
			self._interact_time:set_text("")
			self._interact_time:set_visible(false)
		end

		if self._old_text then
			self._hud_panel:child(self._child_name_text):set_text(self._old_text or "")
			self._hud_panel:child(self._child_name_text):set_visible(false)
			self._old_text = nil
		end

		if HUDInteraction.SHOW_BAR then
			hide_interaction_bar_original(self, complete, show_interact_at_finish, ...)
		else
			if self._progress_bar then
				self._progress_bar:parent():remove(self._progress_bar)
				self._progress_bar = nil
			end
			if show_interact_at_finish then
				self:show_interact()
			end
		end

		if self._motion_dot_hidden and managers.user:get_setting("motion_dot") >= 2 then
			self._motion_dot_hidden = nil
			managers.hud:fade_in_motion_dot()
		end
	end

	function HUDInteraction:set_locked(status)
		if self._progress_bar_locked then
			self._progress_bar_locked:set_color(status and Color.green or Color.red)
		end

		if status then
			self._old_text = self._hud_panel:child(self._child_name_text):text()
			local locked_text = ""
			if WolfgangHUD:getSetting({"INTERACTION", "SHOW_INTERRUPT_HINT"}, true) then
				local btn_cancel = PlayerStandard.EQUIPMENT_PRESS_INTERRUPT and (managers.localization:btn_macro("use_item", true) or managers.localization:get_default_macro("BTN_USE_ITEM")) or (managers.localization:btn_macro("interact", true) or managers.localization:get_default_macro("BTN_INTERACT"))
				locked_text = managers.localization:to_upper_text("wolfganghud_int_locked", {BTN_CANCEL = btn_cancel})
			end
			self._hud_panel:child(self._child_name_text):set_text(locked_text)
			self._hud_panel:child(self._child_name_text):set_visible(true)
		end
	end

	function HUDInteraction:show_interact(data)
		self:_rescale()
		if not self._old_text then
			return show_interact_original(self, data)
		end
	end

	function HUDInteraction:destroy()
		if self._interact_time and self._hud_panel then
			self._interact_time:parent():remove(self._interact_time)
			self._interact_time = nil
		end
		destroy_original(self)
	end

	function HUDInteraction:_rescale(bar_scale, text_scale)
		local bar_scale = bar_scale or WolfgangHUD:getSetting({"INTERACTION", "BAR_SCALE"}, 1)
		local text_scale = text_scale or WolfgangHUD:getSetting({"INTERACTION", "TEXT_SCALE"}, 1)
		local interact_text = self._hud_panel:child(self._child_name_text)
		local invalid_text = self._hud_panel:child(self._child_ivalid_name_text)
		local changed = false
		if self._bar_scale ~= bar_scale then
			self._progress_bar_width = self._original_progress_bar_width * bar_scale
			self._progress_bar_height = self._original_progress_bar_height * bar_scale
			self._progress_bar_bg:set_width(self._progress_bar_width)
			self._progress_bar_bg:set_height(self._progress_bar_height)
			self._bar_scale = bar_scale
			changed = true
		end
		if self._text_scale ~= text_scale then
			local interact_text = self._hud_panel:child(self._child_name_text)
			local invalid_text = self._hud_panel:child(self._child_ivalid_name_text)
			interact_text:set_font_size(self._original_interact_text_font_size * text_scale)
			invalid_text:set_font_size(self._original_invalid_text_font_size * text_scale)
			self._text_scale = text_scale
			changed = true
		end
		if changed then
			interact_text:set_bottom(self._progress_bar_bg:y())
			invalid_text:set_bottom(interact_text:bottom())
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/progressbarguiobject" then

	local init_original = ProgressBarGuiObject.init
	local show_original = ProgressBarGuiObject.show
	local hide_original = ProgressBarGuiObject.hide
	local destroy_original = ProgressBarGuiObject.destroy
	local set_progress_original = ProgressBarGuiObject.set_progress

	function ProgressBarGuiObject:set_layer(layer)
		if not self._progress_bar then
			return
		end
		self._progress_bar_bg:set_layer(layer)
		if self._progress_bar_locked then
			self._progress_bar_locked:set_layer(layer + 1)
		end
		self._progress_bar:set_layer(layer + 2)
	end

	-- covers exiting vehicles and foxholes
	function ProgressBarGuiObject:init(...)
		init_original(self, ...)
		if self._description then
			self._description:set_height(64) -- fix vanilla height bug
		end
		self._progress_bar_bg:set_y(self._y - self._height / 2) -- fix vanilla height bug
		self._progress_bar:set_layer(4) -- set above lock indicator

		self._original_progress_bar_width = self._width
		self._original_progress_bar_height = self._height

		if self._description then
			self._original_description_font_size = self._description:font_size()
		end

		self:_rescale()
	end

	function ProgressBarGuiObject:set_progress(current, total)
		set_progress_original(self, current, total)

		local perc = current / total

		if self._progress_bar_locked then
			self._progress_bar_locked:set_width(perc * self._width + 4)
		end

		if self._interact_time then
			local text = string.format("%.1fs", math.max(total - current, 0))
			self._interact_time:set_text(text)
			local show = perc < 1
			local color = math.lerp(ProgressBarGuiObject.GRADIENT_COLOR_START, WolfgangHUD:getColor(ProgressBarGuiObject.GRADIENT_COLOR_NAME, 0.4), perc)
			self._interact_time:set_color(color)
			self._interact_time:set_alpha(1)
			self._interact_time:set_visible(show)
		end
	end

	function ProgressBarGuiObject:show(description, ...)
		self:_rescale()
		if self._progress_bar_locked then
			self._progress_bar_locked:parent():remove(self._progress_bar_locked)
			self._progress_bar_locked = nil
		end

		show_original(self, description, ...)

		ProgressBarGuiObject.SHOW_LOCK_INDICATOR = WolfgangHUD:getSetting({"INTERACTION", "SHOW_LOCK_INDICATOR"}, false)
		ProgressBarGuiObject.SHOW_TIME_REMAINING = WolfgangHUD:getSetting({"INTERACTION", "SHOW_TIME_REMAINING"}, true)
		ProgressBarGuiObject.TIMER_OFFSET_X = WolfgangHUD:getSetting({"INTERACTION", "TIMER_OFFSET_X"}, 0)
		ProgressBarGuiObject.TIMER_OFFSET_Y = WolfgangHUD:getSetting({"INTERACTION", "TIMER_OFFSET_Y"}, 36)
		ProgressBarGuiObject.HIDE_MOTION_DOT = WolfgangHUD:getSetting({"INTERACTION", "HIDE_MOTION_DOT"}, false)
		ProgressBarGuiObject.SHOW_BAR = WolfgangHUD:getSetting({"INTERACTION", "SHOW_BAR"}, false)
		ProgressBarGuiObject.LOCK_MODE = PlayerStandard.LOCK_MODE or 1
		ProgressBarGuiObject.GRADIENT_COLOR_NAME = WolfgangHUD:getSetting({"INTERACTION", "GRADIENT_COLOR"}, "white")
		ProgressBarGuiObject.GRADIENT_COLOR_START = WolfgangHUD:getColorSetting({"INTERACTION", "GRADIENT_COLOR_START"}, "orange")
		if ProgressBarGuiObject.SHOW_BAR then
			if ProgressBarGuiObject.LOCK_MODE > 1 and ProgressBarGuiObject.SHOW_LOCK_INDICATOR then
				self._progress_bar_locked = self._panel:bitmap({
					layer = 3,
					x = self._x - self._width / 2 - 2,
					y = self._y - self._height / 2 - 2,
					w = 4,
					h = self._height + 4,
					color = self._old_text and Color.green or Color.red,
					alpha = 0.8,
				})
			end
			self._progress_bar:set_alpha(1)
			self._progress_bar_bg:set_alpha(1)
		else
			ProgressBarGuiObject.SHOW_LOCK_INDICATOR = false
			self._progress_bar:set_visible(false)
			self._progress_bar_bg:set_visible(false)
			self._progress_bar:set_alpha(0)
			self._progress_bar_bg:set_alpha(0)
		end

		if ProgressBarGuiObject.SHOW_TIME_REMAINING then
			local fontSize = 32 * WolfgangHUD:getSetting({"INTERACTION", "TIMER_SCALE"}, 1.2)
			if not self._interact_time then
				self._interact_time = self._panel:text({
					name = "interaction_timer",
					visible = false,
					text = "",
					valign = "center",
					align = "center",
					layer = 2,
					color = ProgressBarGuiObject.GRADIENT_COLOR_START,
					font = tweak_data.gui.fonts.din_compressed_outlined_32,
					font_size = fontSize,
					h = 64
				})
			else
				self._interact_time:set_font_size(fontSize)
			end
			local text = string.format("%.1fs", 0)
			self._interact_time:set_x(ProgressBarGuiObject.TIMER_OFFSET_X + self._panel:center_x() - self._interact_time:w() / 2)
			self._interact_time:set_y(ProgressBarGuiObject.TIMER_OFFSET_Y + self._panel:center_y() - self._interact_time:h() / 2)
			self._interact_time:set_text(text)
			self._interact_time:show()

			if ProgressBarGuiObject.HIDE_MOTION_DOT and managers.user:get_setting("motion_dot") >= 2 then
				self._motion_dot_hidden = true
				managers.hud:fade_out_motion_dot()
			end
		end
	end

	function ProgressBarGuiObject:hide(complete, ...)
		if self._interact_time then
			self._interact_time:set_text("")
			self._interact_time:set_visible(false)
		end

		if self._description then
			self._panel:remove(self._description)
			self._description = nil
		end

		if ProgressBarGuiObject.SHOW_BAR then
			hide_original(self, complete, ...)
		end

		if self._progress_bar_locked then
			self._progress_bar_locked:parent():remove(self._progress_bar_locked)
			self._progress_bar_locked = nil
		end

		if self._motion_dot_hidden and managers.user:get_setting("motion_dot") >= 2 then
			self._motion_dot_hidden = nil
			managers.hud:fade_in_motion_dot()
		end
	end

	function ProgressBarGuiObject:set_locked(status)
		if self._progress_bar_locked then
			self._progress_bar_locked:set_color(status and Color.green or Color.red)
		end

		if status and self._description then
			self._old_text = self._description:text()
			local locked_text = ""
			if WolfgangHUD:getSetting({"INTERACTION", "SHOW_INTERRUPT_HINT"}, true) then
				local btn_cancel = PlayerStandard.EQUIPMENT_PRESS_INTERRUPT and (managers.localization:btn_macro("use_item", true) or managers.localization:get_default_macro("BTN_USE_ITEM")) or (managers.localization:btn_macro("interact", true) or managers.localization:get_default_macro("BTN_INTERACT"))
				locked_text = managers.localization:to_upper_text("wolfganghud_int_locked", {BTN_CANCEL = btn_cancel})
			end
			self._description:set_text(locked_text)
			self._description:set_visible(true)
		end
	end

	function ProgressBarGuiObject:destroy()
		if self._interact_time and self._panel then
			self._interact_time:parent():remove(self._interact_time)
			self._interact_time = nil
		end
		destroy_original(self)
	end

	function ProgressBarGuiObject:_rescale(bar_scale, text_scale)
		local bar_scale = bar_scale or WolfgangHUD:getSetting({"INTERACTION", "BAR_SCALE"}, 1)
		local text_scale = text_scale or WolfgangHUD:getSetting({"INTERACTION", "TEXT_SCALE"}, 1)
		local changed = false
		if self._bar_scale ~= bar_scale then
			self._width = self._original_progress_bar_width * bar_scale
			self._height = self._original_progress_bar_height * bar_scale
			self._progress_bar_bg:set_width(self._width)
			self._progress_bar_bg:set_height(self._height)
			self._bar_scale = bar_scale
			changed = true
		end
		if self._text_scale ~= text_scale then
			if self._description then
				self._description:set_font_size(self._original_description_font_size * text_scale)
			end
			self._text_scale = text_scale
			changed = true
		end
		if changed then
			if self._description then
				self._description:set_bottom(self._progress_bar_bg:y())
			end
		end
	end

end