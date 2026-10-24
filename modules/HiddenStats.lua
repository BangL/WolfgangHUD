if string.lower(RequiredScript) == "lib/managers/menu/raid_menu/controls/raidguicontrolweaponstats" then
    local init_original = RaidGUIControlWeaponStats.init
    local _create_items_original = RaidGUIControlWeaponStats._create_items
    local _set_default_values_original = RaidGUIControlWeaponStats._set_default_values
    local _get_tabs_params_original = RaidGUIControlWeaponStats._get_tabs_params
    local set_modified_stats_original = RaidGUIControlWeaponStats.set_modified_stats
    local set_applied_stats_original = RaidGUIControlWeaponStats.set_applied_stats

    RaidGUIControlWeaponStats.WGFLAG_WEAPONS = 1
    RaidGUIControlWeaponStats.WGFLAG_GRENADES = 2
    RaidGUIControlWeaponStats.WGFLAG_MELEE = 3

    function RaidGUIControlWeaponStats.wg_color_delta(item, delta)
        item:set_label_default_color()

        local label = item._label._label_value_with_delta
        if label and delta ~= 0 then
            label:set_color(delta > 0 and tweak_data.gui.colors.progress_green or tweak_data.gui.colors.progress_red)
        end
    end

    local function f2s(val)
        return tostring(math.round_with_precision(val, 1))
    end

    RaidGUIControlWeaponStats.WG_HIDDEN_STATS = {
        {
            name = "zoom",
            getter = function(_, parts, _, _, tweak_stats, tweak_wpn)
                local fov = tweak_stats.zoom[math.min(
                    ((tweak_wpn.stats and tweak_wpn.stats.zoom or 2))
                    + (parts.zoom or 0)
                    + managers.player:upgrade_value(tweak_wpn.category, "zoom_increase", 0),
                    #tweak_stats.zoom)]
                return f2s((100 - fov) / 35) -- fictional formula, which should make most sense for the end user (i hope)
            end,
            visible_flags = {
                RaidGUIControlWeaponStats.WGFLAG_WEAPONS,
                --RaidGUIControlWeaponStats.WGFLAG_GRENADES, -- disabled for now, because all are equal (1) as of U21.6
                --RaidGUIControlWeaponStats.WGFLAG_MELEE -- disabled for now, because all are equal (1) as of U21.6
            }
        },
        -- { -- couldnt make any logical sense out of these values, so lets still hide them for now
        --     name = "suppression",
        --     getter = function(base, parts, mods, skill, tweak_stats, tweak_wpn)
        --         return (tweak_wpn.SUPPRESSION or tweak_wpn.suppression) or
        --             tweak_stats.suppression[math.clamp((base.suppression and base.suppression.value or 16)
        --                 + (parts.suppression or 0)
        --                 + (mods.suppression and mods.suppression.value or 0)
        --                 + (skill.suppression and skill.suppression.value or 0),
        --                 1,
        --                 #tweak_stats.suppression
        --             )]
        --     end,
        --     visible_flags = {
        --         RaidGUIControlWeaponStats.WGFLAG_WEAPONS,
        --         --RaidGUIControlWeaponStats.WGFLAG_GRENADES, -- disabled for now, because all are equal (1) as of U21.6
        --         --RaidGUIControlWeaponStats.WGFLAG_MELEE -- disabled for now, because all are equal (1) as of U21.6
        --     }
        -- },
        -- concealment/detection risk got streamlined with U24, so it's obsolete now
        -- { -- we could convert these to a "suspicion" value, but we know concealment from pd2, so most people are used to it
        --     name = "concealment",
        --     getter = function(base, parts, mods, skill, _, tweak_wpn)
        --         return (tweak_wpn.concealment or (base.concealment and base.concealment.value or 0))
        --             + (parts.concealment or 0)
        --             + (mods.concealment and mods.concealment.value or 0)
        --             + (skill.concealment and skill.concealment.value or 0)
        --     end,
        --     visible_flags = {
        --         RaidGUIControlWeaponStats.WGFLAG_WEAPONS,
        --         --RaidGUIControlWeaponStats.WGFLAG_GRENADES, -- bs
        --         --RaidGUIControlWeaponStats.WGFLAG_MELEE -- disabled for now, because all are equal (30) as of U21.6
        --     }
        -- },
        {
            name = "alert_size",
            getter = function(_, parts, _, _, tweak_stats, tweak_wpn)
                if tweak_wpn.stat_group == "distraction" then
                    return "-" -- ignore coin
                end
                return
                -- grenades
                    tweak_wpn.alert_size
                    or
                    -- weapons
                    tweak_stats.alert_size[math.clamp(
                        (tweak_wpn.stats and tweak_wpn.stats.alert_size or 20)
                        + (parts.alert_size or 0),
                        1,
                        #tweak_stats.alert_size)]
            end,
            visible_flags = {
                RaidGUIControlWeaponStats.WGFLAG_WEAPONS,
                RaidGUIControlWeaponStats.WGFLAG_GRENADES,
                --RaidGUIControlWeaponStats.WGFLAG_MELEE -- bs
            }
        },
    }

    function RaidGUIControlWeaponStats:init(parent, params, ...)
        self._wg_flag = self._wg_flag or RaidGUIControlWeaponStats.WGFLAG_WEAPONS
        self._wg_show_hidden_stats = WolfgangHUD:getSetting({ "MENU", "SHOW_HIDDEN_WEAPON_STATS" }, true)
        self._wg_convert_sizes_to_meters = WolfgangHUD:getSetting({ "MENU", "CONVERT_SIZES_TO_METERS" }, true)
        self._wg_show_diff = WolfgangHUD:getSetting({ "MENU", "SHOW_WEAPON_STAT_DIFF" }, true)

        if self._wg_show_hidden_stats and (self._wg_flag == RaidGUIControlWeaponStats.WGFLAG_WEAPONS) then
            params.tab_width = 120
        end

        local result = init_original(self, parent, params, ...)

        -- if self._wg_show_hidden_stats and (self._wg_flag == RaidGUIControlWeaponStats.WGFLAG_WEAPONS) then
        --     self:set_x(500)
        -- end

        return result
    end

    function RaidGUIControlWeaponStats:_create_items(...)
        local result = _create_items_original(self, ...)

        -- the delta sits right of the centered value and gets clipped by the tab panel, so make the panels wider but keep the content where it was
        for _, item in ipairs(self._wg_show_diff and self._items or {}) do
            local label = item._label
            if label and label._label_value and label._label_text then
                local w = item._object:w()
                label._label_text:set_w(w)
                item._object:set_w(w * 1.5)
                label._object:set_w(w * 1.5)
                label.set_value = function(this, text)
                    this._label_value:set_text(text)
                    local _, _, text_w = this._label_value:text_rect()
                    this._label_value:set_w(text_w)
                    this._label_value:set_center_x(w / 2)
                end
            end
        end

        if self._params.tabs_params and (self._wg_flag == RaidGUIControlWeaponStats.WGFLAG_WEAPONS) and self._items and #self._items > 0 then
            for _, item in ipairs(self._items) do
                local label_value = item._label._label_value
                if label_value then
                    label_value:set_font_size(tweak_data.gui.font_sizes.size_38)
                end
                local label_value_with_delta = item._label._label_value_with_delta
                if label_value_with_delta then
                    label_value_with_delta:set_font_size(tweak_data.gui.font_sizes.medium)
                end
                local label_text = item._label._label_text
                if label_text then
                    label_text:set_font_size(tweak_data.gui.font_sizes.extra_small)
                end
            end
        end

        return result
    end

    function RaidGUIControlWeaponStats:_set_default_values(...)
        local result = _set_default_values_original(self, ...)

        if self._wg_show_hidden_stats then
            self:wg_set_hidden_default_values()
        end

        return result
    end

    function RaidGUIControlWeaponStats:_get_tabs_params(...)
        local tabs_params = _get_tabs_params_original(self, ...)

        if self._wg_show_hidden_stats then
            tabs_params = self:wg_attach_hidden_tabs_params(tabs_params)
        end

        return tabs_params
    end

    function RaidGUIControlWeaponStats:set_modified_stats(params, ...)
        if self._wg_show_hidden_stats then
            for stat_name, value in pairs(self:wg_get_selected_weapon_hidden_stats()) do
                self._values[stat_name].modified_value = value
            end
        end

        local result = set_modified_stats_original(self, params, ...)

        if not self._wg_diff_mode then
            return result -- vanilla display (e.g. weapon skill preview)
        end

        -- big number = new value, only the delta is colored
        for _, item in ipairs(self._items) do
            local item_data = self._values[item:name()]
            if item_data then
                local modified = tonumber(item_data.modified_value) or 0
                local delta = math.round_with_precision(modified - (tonumber(item_data.applied_value) or 0), 1)
                item:set_value(tostring(modified))
                item:set_value_delta(delta) -- reposition after the value changed
                RaidGUIControlWeaponStats.wg_color_delta(item, delta)
            end
        end

        return result
    end

    function RaidGUIControlWeaponStats:set_applied_stats(params, ...)
        if self._wg_show_hidden_stats then
            for stat_name, value in pairs(self:wg_get_selected_weapon_hidden_stats(self._wg_applied_ref)) do
                self._values[stat_name].applied_value = value
            end
        end

        return set_applied_stats_original(self, params, ...)
    end

    function RaidGUIControlWeaponStats:wg_set_hidden_default_values()
        for _, stat in ipairs(self.WG_HIDDEN_STATS) do
            if table.contains(stat.visible_flags, self._wg_flag) then
                self._values[stat.name] = {
                    value = "00",
                    delta_value = "00",
                    text = string.upper(self:translate("wolfganghud_menu_weapons_stats_" .. stat.name, true))
                }
            end
        end
    end

    function RaidGUIControlWeaponStats:wg_attach_hidden_tabs_params(tabs_params)
        for _, stat in ipairs(self.WG_HIDDEN_STATS) do
            if table.contains(stat.visible_flags, self._wg_flag) then
                table.insert(tabs_params, {
                    name = stat.name,
                    text = self._values[stat.name].text,
                    modified_value = self._values[stat.name].modified_value or 0,
                    applied_value = self._values[stat.name].applied_value or 0
                })
            end
        end

        return tabs_params
    end

    function RaidGUIControlWeaponStats:wg_get_selected_weapon_hidden_stats(ref)
        local result = {}
        local shown_stats = {}
        for _, stat in ipairs(self.WG_HIDDEN_STATS) do
            if table.contains(stat.visible_flags, self._wg_flag) then
                result[stat.name] = 0
                table.insert(shown_stats, stat)
            end
        end

        if managers.menu_component then
            local weapon_select_gui = managers.menu_component._raid_menu_weapon_select_gui
            if weapon_select_gui then
                local selected_item = ref or weapon_select_gui._weapon_list:selected_item()
                if selected_item then
                    local selected_weapon_data = ref or selected_item:data().value
                    local weapon_id = selected_weapon_data.weapon_id
                    local weapon_category_id = ref and ref.category_id or weapon_select_gui._selected_weapon_category_id
                    local weapon_category = managers.weapon_inventory:get_weapon_category_by_weapon_category_id(
                        weapon_category_id)

                    local tweak_stats = tweak_data.weapon.stats
                    local tweak_weapon = tweak_data.weapon[weapon_id]
                    local weapon_factory_id = managers.weapon_factory:get_factory_id_by_weapon_id(weapon_id)
                    local blueprint = managers.weapon_skills:recreate_weapon_blueprint(weapon_id, weapon_category_id,
                        nil, false)
                    local parts_stats = managers.weapon_factory:get_stats(weapon_factory_id, blueprint)

                    local base_stats, mods_stats, skill_stats = {}, {}, {}
                    if weapon_category == WeaponInventoryManager.BM_CATEGORY_PRIMARY_NAME or weapon_category == WeaponInventoryManager.BM_CATEGORY_SECONDARY_NAME then
                        base_stats, mods_stats, skill_stats = managers.weapon_inventory:get_weapon_stats(weapon_id,
                            weapon_category, selected_weapon_data.slot, nil)
                    elseif weapon_category == WeaponInventoryManager.BM_CATEGORY_MELEE_NAME then
                        base_stats, mods_stats, skill_stats = managers.weapon_inventory:get_melee_weapon_stats(weapon_id)
                        tweak_weapon = tweak_data.blackmarket.melee_weapons[weapon_id]
                    end

                    for _, stat in ipairs(shown_stats) do
                        local value = stat.getter(base_stats, parts_stats, mods_stats, skill_stats, tweak_stats,
                            tweak_weapon) or 0
                        if self._wg_convert_sizes_to_meters and stat.name == "alert_size" and tonumber(value) then
                            value = tonumber(value) / 100
                        end
                        result[stat.name] = value
                    end

                    return result
                end
            end
        end

        return result
    end
elseif string.lower(RequiredScript) == "lib/managers/menu/raid_menu/controls/raidguicontrolgrenadeweaponstats" then
    local init_original = RaidGUIControlGrenadeWeaponStats.init
    local _set_default_values_original = RaidGUIControlGrenadeWeaponStats._set_default_values
    local _get_tabs_params_original = RaidGUIControlGrenadeWeaponStats._get_tabs_params
    local set_stats_original = RaidGUIControlGrenadeWeaponStats.set_stats

    function RaidGUIControlGrenadeWeaponStats:init(parent, params, ...)
        self._wg_flag = RaidGUIControlWeaponStats.WGFLAG_GRENADES
        self._wg_show_hidden_stats = WolfgangHUD:getSetting({ "MENU", "SHOW_HIDDEN_WEAPON_STATS" }, true)
        self._wg_convert_sizes_to_meters = WolfgangHUD:getSetting({ "MENU", "CONVERT_SIZES_TO_METERS" }, true)
        self._wg_show_diff = WolfgangHUD:getSetting({ "MENU", "SHOW_WEAPON_STAT_DIFF" }, true)
        if self._wg_show_diff then
            params.label_class = RaidGUIControlLabelNamedValueWithDelta -- needed for WeaponStatsDiff
            params.value_delta_font_size = tweak_data.gui.font_sizes.medium
        end
        return init_original(self, parent, params, ...)
    end

    function RaidGUIControlGrenadeWeaponStats:_set_default_values(...)
        local result = _set_default_values_original(self, ...)

        if self._wg_show_hidden_stats then
            self:wg_set_hidden_default_values()
        end

        return result
    end

    function RaidGUIControlGrenadeWeaponStats:_get_tabs_params(...)
        local tabs_params = _get_tabs_params_original(self, ...)

        if self._wg_show_hidden_stats then
            tabs_params = self:wg_attach_hidden_tabs_params(tabs_params)
        end

        return tabs_params
    end

    function RaidGUIControlGrenadeWeaponStats:set_stats(damage, range, distance, ...)
        if self._wg_show_hidden_stats then
            for stat_name, value in pairs(self:wg_get_selected_weapon_hidden_stats()) do
                self._values[stat_name].value = value
            end
        end

        if self._wg_convert_sizes_to_meters then
            range = range / 100
            distance = distance / 100
        end

        return set_stats_original(self, damage, range, distance, ...)
    end
elseif string.lower(RequiredScript) == "lib/managers/menu/raid_menu/controls/raidguicontrolmeleeweaponstats" then
    local init_original = RaidGUIControlMeleeWeaponStats.init
    local _set_default_values_original = RaidGUIControlMeleeWeaponStats._set_default_values
    local _get_tabs_params_original = RaidGUIControlMeleeWeaponStats._get_tabs_params
    local set_stats_original = RaidGUIControlMeleeWeaponStats.set_stats

    function RaidGUIControlMeleeWeaponStats:init(parent, params, ...)
        self._wg_flag = RaidGUIControlWeaponStats.WGFLAG_MELEE
        self._wg_show_hidden_stats = WolfgangHUD:getSetting({ "MENU", "SHOW_HIDDEN_WEAPON_STATS" }, true)
        self._wg_convert_sizes_to_meters = WolfgangHUD:getSetting({ "MENU", "CONVERT_SIZES_TO_METERS" }, true)
        self._wg_show_diff = WolfgangHUD:getSetting({ "MENU", "SHOW_WEAPON_STAT_DIFF" }, true)
        if self._wg_show_diff then
            params.label_class = RaidGUIControlLabelNamedValueWithDelta -- needed for WeaponStatsDiff
            params.value_delta_font_size = tweak_data.gui.font_sizes.medium
        end
        return init_original(self, parent, params, ...)
    end

    function RaidGUIControlMeleeWeaponStats:_set_default_values(...)
        local result = _set_default_values_original(self, ...)

        if self._wg_show_hidden_stats then
            self:wg_set_hidden_default_values()
        end

        return result
    end

    function RaidGUIControlMeleeWeaponStats:_get_tabs_params(...)
        local tabs_params = _get_tabs_params_original(self, ...)

        if self._wg_show_hidden_stats then
            tabs_params = self:wg_attach_hidden_tabs_params(tabs_params)
        end

        return tabs_params
    end

    function RaidGUIControlMeleeWeaponStats:set_stats(damage, knockback, range, charge_time, ...)
        if self._wg_show_hidden_stats then
            for stat_name, value in pairs(self:wg_get_selected_weapon_hidden_stats()) do
                self._values[stat_name].value = value
            end
        end

        return set_stats_original(self, damage, knockback, range, charge_time, ...)
    end
elseif string.lower(RequiredScript) == "lib/managers/menu/menucomponentmanager" then
    local _create_raid_menu_weapon_select_gui_original = MenuComponentManager._create_raid_menu_weapon_select_gui

    function MenuComponentManager:_create_raid_menu_weapon_select_gui(node, component, ...)
        local result = _create_raid_menu_weapon_select_gui_original(self, node, component, ...)

        if result._weapon_stats._wg_show_hidden_stats then
            result:_update_weapon_stats(true) -- force reload once more (needed to fix hidden stats initial value, as managers.menu_component is still nil when wg_get_selected_weapon_hidden_stats is called first time)
        end

        return result
    end
end
