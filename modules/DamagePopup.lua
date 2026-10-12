
if string.lower(RequiredScript) == "lib/units/enemies/cop/copdamage" then

	local _on_damage_received_original = CopDamage._on_damage_received
	local sync_damage_bullet_original = CopDamage.sync_damage_bullet
	local sync_damage_melee_original = CopDamage.sync_damage_melee
	local sync_damage_knockdown_original = CopDamage.sync_damage_knockdown

	function CopDamage:_on_damage_received(data, ...)
		self:_process_popup_damage(data)
		self._sync_ibody_popup = nil
		return _on_damage_received_original(self, data, ...)
	end

	function CopDamage:sync_damage_bullet(attacker_unit, damage_percent, i_body, ...)
		if i_body then
			self._sync_ibody_popup = i_body
		end

		return sync_damage_bullet_original(self, attacker_unit, damage_percent, i_body, ...)
	end

	function CopDamage:sync_damage_melee(attacker_unit, damage_percent, damage_effect_percent, i_body, ...)
		if i_body then
			self._sync_ibody_popup = i_body
		end

		return sync_damage_melee_original(self, attacker_unit, damage_percent, damage_effect_percent, i_body, ...)

	end

	function CopDamage:sync_damage_knockdown(attacker_unit, damage_percent, i_body, hit_offset_height, death, ...)
		if i_body then
			self._sync_ibody_popup = i_body
		end
		return sync_damage_knockdown_original(self, attacker_unit, damage_percent, i_body, hit_offset_height, death, ...)
	end

	function CopDamage:_process_popup_damage(data)
		CopDamage.DMG_POPUP_SETTING = WolfgangHUD:getSetting({"HUD", "DamagePopup", "DISPLAY_MODE"}, 3)

		local attacker = alive(data.attacker_unit) and data.attacker_unit
		local damage = tonumber(data.damage) or 0

		if attacker and damage >= 0.1 and CopDamage.DMG_POPUP_SETTING > 1 then
			local killer

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
			elseif attacker:in_slot(25) then
				--Turret
				local base = attacker.base and attacker:base()
				if base then
					local owner = base.get_owner_id and base:get_owner_id()
					if owner then
						killer = managers.criminals:character_unit_by_peer_id(owner)
					end
				end
			elseif attacker:base().thrower_unit then
				killer = attacker:base():thrower_unit()
			end

			if alive(killer) and alive(self._unit) then
				local body = data.col_ray and data.col_ray.body or self._sync_ibody_popup and self._unit:body(self._sync_ibody_popup)
				local headshot = body and self.is_head and self:is_head(body) or false
				if CopDamage.DMG_POPUP_SETTING == 2 then
					if killer:in_slot(2) then
						self:show_popup(damage, self._dead, headshot, data.critical_hit)
					end
				else
					local color_id = WolfgangHUD:character_color_id(killer)
					if color_id then
						self:show_popup(damage, self._dead, headshot, false, color_id)
					end
				end
			end
		end
	end

	function CopDamage:show_popup(damage, dead, headshot, critical, color_id)
		if managers.waypoints then
			local id = "damage_wp_" .. tostring(self._unit:key())
			local waypoint = managers.waypoints:get_waypoint(id)
			local waypoint_color = color_id and ((color_id == 5 and WolfgangHUD:getSetting({"HUD", "DamagePopup", "CUSTOM_AI_COLOR_USE"}, true)) and WolfgangHUD:getColorSetting({"HUD", "DamagePopup", "CUSTOM_AI_COLOR"}, "white") or tweak_data.chat_colors[color_id]) or WolfgangHUD:getColorSetting({"HUD", "DamagePopup", critical and "CRITICAL_COLOR" or headshot and "HEADSHOT_COLOR" or "COLOR"}, "yellow")
			waypoint_color = waypoint_color and waypoint_color:with_alpha(WolfgangHUD:getSetting({"HUD", "DamagePopup", "ALPHA"}, 0.8))
			local waypoint_duration = WolfgangHUD:getSetting({"HUD", "DamagePopup", "DURATION"}, 2)
			if waypoint and not waypoint:is_deleted() then
				managers.waypoints:set_waypoint_duration(id, "duration", waypoint_duration)
				managers.waypoints:set_waypoint_label(id, "label", self:build_popup_text(damage, headshot))
				managers.waypoints:set_waypoint_setting(id, "color", waypoint_color)
				managers.waypoints:set_waypoint_component_setting(id, "icon", "show", dead)
			else
				local params = {
					unit = self._unit,
					offset = Vector3(10, 10, WolfgangHUD:getSetting({"HUD", "DamagePopup", "HEIGHT"}, 30)),
					scale = 2 * WolfgangHUD:getSetting({"HUD", "DamagePopup", "SCALE"}, 0.6),
					color = waypoint_color,
					visible_distance = {
						min = 30,
						max = 10000
					},
					rescale_distance = {
						start_distance = 500,
						end_distance = 3000,
						final_scale = 0.5
					},
					fade_duration = {
						start = 0.5,
						stop = 1,
						alpha = true,
					},
					icon = {
						type = "icon",
						show = dead,
						scale = WolfgangHUD:getSetting({"HUD", "DamagePopup", "SKULL_SCALE"}, 0.9),
						texture = "ui/atlas/raid_atlas_waypoints",
						texture_rect = {401, 437, 38, 38},
						blend_mode = "normal",
					},
					label = {
						type = "label",
						show = true,
						text = self:build_popup_text(damage, headshot, true)
					},
					duration = {
						type = "duration",
						show = false,
						initial_value = waypoint_duration,
						fade_duration = {
							start = 0,
							stop = 1,
							position = Vector3(0, 0, 30),
						},
					},
					component_order = {WolfgangHUD:getSetting({"HUD", "DamagePopup", "SKULL_ALIGN"}, 2) == 1 and {"icon", "label"} or {"label", "icon"}, {"duration"}}
				}
				managers.waypoints:add_waypoint(id, "CustomWaypoint", params, true)
			end
		end
	end

	function CopDamage:build_popup_text(damage, headshot, is_new)
		self._dmg_value = (not is_new and self._dmg_value or 0) + (damage * 1)
		return math.floor(self._dmg_value) .. ((CopDamage.DMG_POPUP_SETTING == 3 and headshot) and "!" or "")
	end

elseif string.lower(RequiredScript) == "lib/units/civilians/civiliandamage" then

	local _on_damage_received_original = CivilianDamage._on_damage_received

	function CivilianDamage:_on_damage_received(data, ...)
		CivilianDamage.super._process_popup_damage(self, data)
		return _on_damage_received_original(self, data, ...)
	end

end
