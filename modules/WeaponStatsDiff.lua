local _update_weapon_stats_original = WeaponSelectionGui._update_weapon_stats

-- same as the local f2s in weaponselectiongui
local function f2s(value)
    value = math.floor(value * 10) / 10

    if value * 10 % 10 ~= 0 then
        return string.format("%.0f", tostring(value))
    else
        return tostring(value)
    end
end

function WeaponSelectionGui:_update_weapon_stats(reset_applied_stats, ...)
    if reset_applied_stats and self._weapon_stats._wg_show_diff then
        self._weapon_stats._wg_diff_mode = self:wg_get_diff_target() ~= nil
    end

    local result = _update_weapon_stats_original(self, reset_applied_stats, ...)

    if reset_applied_stats and self._weapon_stats._wg_diff_mode then
        self:wg_apply_equipped_baseline()
    end

    self:wg_apply_equipped_deltas()

    return result
end

-- returns the equipped weapon (and its slot, category) if the selected primary/secondary differs from it
function WeaponSelectionGui:wg_get_diff_target()
    local selected_item = self._weapon_list:selected_item()
    if not selected_item then
        return
    end

    local category_id = self._selected_weapon_category_id
    local category = managers.weapon_inventory:get_weapon_category_by_weapon_category_id(category_id)
    local equipped
    if category == WeaponInventoryManager.BM_CATEGORY_PRIMARY_NAME then
        equipped = managers.weapon_inventory:get_equipped_primary_weapon()
    elseif category == WeaponInventoryManager.BM_CATEGORY_SECONDARY_NAME then
        equipped = managers.weapon_inventory:get_equipped_secondary_weapon()
    end

    local selected = selected_item:data().value
    local equipped_slot = managers.blackmarket:equipped_weapon_slot(category) -- equipped item data has no slot field
    if not equipped or not selected or (equipped.weapon_id == selected.weapon_id and equipped_slot == selected.slot) then
        return
    end

    return equipped, equipped_slot, selected, category, category_id
end

-- shows the stats of the selected weapon as difference to the equipped one
function WeaponSelectionGui:wg_apply_equipped_baseline()
    local equipped, equipped_slot, selected, category, category_id = self:wg_get_diff_target()
    if not equipped then
        return
    end

    local ammo_mul = managers.player:upgrade_value("player", category == WeaponInventoryManager.BM_CATEGORY_PRIMARY_NAME and "primary_ammo_increase" or "secondary_ammo_increase", 1)
        * managers.player:upgrade_value("player", "pack_mule_ammo_total_increase", 1)
        * managers.player:upgrade_value("player", "cache_basket_ammo_total_increase", 1)

    local id = equipped.weapon_id
    local stats = self._weapon_stats

    -- weapon skills only count while their weapon is selected, so swap them for the calculation
    local skills = managers.weapon_skills
    skills:update_weapon_skills(category_id, selected.weapon_id, WeaponSkillsManager.UPGRADE_ACTION_DEACTIVATE)
    skills:update_weapon_skills(category_id, id, WeaponSkillsManager.UPGRADE_ACTION_ACTIVATE)

    local ok, err = blt.pcall(function()
        local base, _, skill = managers.weapon_inventory:get_weapon_stats(id, category, equipped_slot, nil)

        stats._wg_applied_ref = { weapon_id = id, slot = equipped_slot, category_id = category_id }
        stats:set_applied_stats({
            accuracy_applied_value = f2s(100 / (1 + tweak_data.weapon[id].spread.steelsight)) + f2s(skill.spread.value),
            accuracy_as_spread = false,
            damage_applied_value = f2s(base.damage.value) + f2s(skill.damage.value),
            magazine_applied_value = f2s(base.magazine.value) + f2s(skill.magazine.value),
            rate_of_fire_applied_value = f2s(base.fire_rate.value) + f2s(skill.fire_rate.value),
            stability_applied_value = f2s(base.recoil.value) + f2s(skill.recoil.value),
            total_ammo_applied_value = f2s(base.totalammo.value * ammo_mul),
        })
    end)
    stats._wg_applied_ref = nil

    skills:update_weapon_skills(category_id, id, WeaponSkillsManager.UPGRADE_ACTION_DEACTIVATE)
    skills:update_weapon_skills(category_id, selected.weapon_id, WeaponSkillsManager.UPGRADE_ACTION_ACTIVATE)

    if not ok then
        log("[WolfgangHUD] WeaponStatsDiff: " .. tostring(err))
        return
    end

    local v = stats._values
    stats:set_modified_stats({
        accuracy_as_spread = false,
        accuracy_modified_value = v.accuracy.modified_value,
        damage_modified_value = v.damage.modified_value,
        magazine_modified_value = v.magazine.modified_value,
        rate_of_fire_modified_value = v.rate_of_fire.modified_value,
        stability_modified_value = v.stability.modified_value,
        total_ammo_modified_value = v.total_ammo.modified_value,
    })
end

local function melee_values(id)
    local base = managers.weapon_inventory:get_melee_weapon_stats(id)
    return {
        damage = (base.damage.min_value + base.damage.max_value) / 2,
        knockback = (base.damage_effect.min_value + base.damage_effect.max_value) / 2,
        range = base.range.value,
        charge_time = base.charge_time.value,
    }
end

local function grenade_values(id, meters)
    local tweak = tweak_data.projectiles[id]
    local scale = meters and 0.01 or 1
    return {
        damage = tweak.damage or 0,
        range = (tweak.range or 0) * scale,
        distance = (tweak.launch_speed or 250) * scale,
        capacity = managers.player:get_max_grenades(id),
    }
end

-- melee and grenades: control only has plain values, so add the deltas to the equipped item here
function WeaponSelectionGui:wg_apply_equipped_deltas()
    if not self._weapon_stats._wg_show_diff then
        return
    end

    local selected_item = self._weapon_list:selected_item()
    local category = managers.weapon_inventory:get_weapon_category_by_weapon_category_id(self._selected_weapon_category_id)
    local selected = selected_item and selected_item:data().value
    if not selected then
        return
    end

    local stats, equipped_id, getter
    if category == WeaponInventoryManager.BM_CATEGORY_MELEE_NAME then
        stats = self._melee_weapon_stats
        equipped_id = managers.weapon_inventory:get_equipped_melee_weapon_id()
        getter = melee_values
    elseif category == WeaponInventoryManager.BM_CATEGORY_GRENADES_NAME then
        stats = self._grenade_weapon_stats
        equipped_id = managers.weapon_inventory:get_equipped_grenade_id()
        getter = grenade_values
    else
        return
    end

    local meters = stats._wg_convert_sizes_to_meters
    local selected_values = getter(selected.weapon_id, meters)
    local equipped_values = equipped_id ~= selected.weapon_id and getter(equipped_id, meters)

    for _, item in ipairs(stats._items) do
        local name = item:name()
        local delta = equipped_values and selected_values[name] and math.round_with_precision(selected_values[name] - equipped_values[name], 1) or 0

        item:set_value_delta(delta)

        -- lower charge time is better
        if name == "charge_time" then
            delta = -delta
        end

        RaidGUIControlWeaponStats.wg_color_delta(item, delta)
    end
end
