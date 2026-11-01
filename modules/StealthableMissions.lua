if string.lower(RequiredScript) == "lib/managers/menu/raid_menu/controls/raidguicontrollistitemraids" then
    local _layout_raid_name_original = RaidGUIControlListItemRaids._layout_raid_name

    local icon_size = tweak_data.gui.font_sizes.small - 2

    local overrides = {
        -- not stealthable
        ["silo"] = OperationsTweakData.RAID_NOT_STEALTHABLE, -- Countdown

        -- partially stealthable
        ["clear_skies_mini_raid_1_park"] = OperationsTweakData.RAID_STARTS_STEALTHABLE,         -- Communication Breakdown v1
        ["clear_skies_mini_raid_1_destroyed"] = OperationsTweakData.RAID_STARTS_STEALTHABLE,    -- Communication Breakdown v2
        ["clear_skies_mini_raid_1_roundabout"] = OperationsTweakData.RAID_STARTS_STEALTHABLE,   -- Communication Breakdown v3
        ["clear_skies_mini_raid_2_park"] = OperationsTweakData.RAID_STARTS_STEALTHABLE,         -- Burning Man v1
        ["clear_skies_mini_raid_2_destroyed"] = OperationsTweakData.RAID_STARTS_STEALTHABLE,    -- Burning Man v2
        ["clear_skies_radio_defense"] = OperationsTweakData.RAID_STARTS_STEALTHABLE,            -- London Calling
        ["oper_flamable_mini_raid_1_park"] = OperationsTweakData.RAID_STARTS_STEALTHABLE,       -- Cloak And Dagger v1
        ["oper_flamable_mini_raid_1_destroyed"] = OperationsTweakData.RAID_STARTS_STEALTHABLE,  -- Cloak And Dagger v2
        ["oper_flamable_mini_raid_1_roundabout"] = OperationsTweakData.RAID_STARTS_STEALTHABLE, -- Cloak And Dagger v3
        ["oper_flamable_mini_raid_2_destroyed"] = OperationsTweakData.RAID_STARTS_STEALTHABLE,  -- Fuel For The Fire v1
        ["oper_flamable_mini_raid_2_roundabout"] = OperationsTweakData.RAID_STARTS_STEALTHABLE, -- Fuel For The Fire v2
        ["oper_flamable_castle"] = OperationsTweakData.RAID_STARTS_STEALTHABLE,                 -- Firestarter

        -- fully stealthable
        ["flakturm"] = OperationsTweakData.RAID_COMPLETELY_STEALTHABLE,              -- Odin's Fall
        ["clear_skies_gold_rush"] = OperationsTweakData.RAID_COMPLETELY_STEALTHABLE, -- Enigmatic
    }

    function RaidGUIControlListItemRaids:_layout_raid_name(params, data, ...)
        _layout_raid_name_original(self, params, data, ...)
        self:wghud_refresh_stealthable_icon()
    end

    function RaidGUIControlListItemRaids:wghud_init_stealthable_icon()
        return self._object:bitmap({
            texture = "ui/atlas/raid_atlas_waypoints",
            texture_rect = { 439, 437, 38, 38 },
            w = icon_size,
            h = icon_size,
            blend_mode = "normal",
            visible = false,
        })
    end

    function RaidGUIControlListItemRaids:wghud_refresh_stealthable_icon(mission_id_data_field)
        if (not WolfgangHUD:getSetting({ "MENU", "MARK_STEALTHABLES" }, true)) or
            (not self._object) or
            (not self._item_label) or
            (not self._data) or
            (type(self._data) ~= "table") then
            return
        end
        local mission_id = self._data[mission_id_data_field or "value"]
        if not mission_id then
            return
        end

        local raid_data = tweak_data.operations.missions[mission_id]
        if raid_data then
            local stealth_description = overrides[mission_id] or raid_data.stealth_description or
                OperationsTweakData.RAID_NOT_STEALTHABLE
            if stealth_description ~= OperationsTweakData.RAID_NOT_STEALTHABLE then
                if not self._stealthable_icon then
                    self._stealthable_icon = self:wghud_init_stealthable_icon()
                end

                local x, _, w, _ = self._item_label:text_rect()
                self._stealthable_icon:set_x(x + w + 4)
                self._stealthable_icon:set_center_y(self.NAME_CENTER_Y)

                self._stealthable_icon:set_color(
                    stealth_description == OperationsTweakData.RAID_COMPLETELY_STEALTHABLE
                    and tweak_data.gui.colors.progress_green
                    or tweak_data.gui.colors.raid_grey)

                self._stealthable_icon:set_visible(true)
                return
            end
        end

        if self._stealthable_icon then
            self._stealthable_icon:set_visible(false)
        end
    end
elseif string.lower(RequiredScript) == "lib/managers/menu/raid_menu/controls/raidguicontrollistitemoperations" then
    local _layout_operation_name_original = RaidGUIControlListItemOperations._layout_operation_name

    function RaidGUIControlListItemOperations:_layout_operation_name(params, data, ...)
        _layout_operation_name_original(self, params, data, ...)
        self:wghud_refresh_stealthable_icon()
        self:wghud_layout_free_play_exp(data)
    end

    -- free play entries show their XP right on the list item, like raids (RaidGUIControlListItemRaids:_layout_exp)
    function RaidGUIControlListItemOperations:wghud_layout_free_play_exp(data)
        local xp_value = data.free_play and data.mission_data and data.mission_data.xp
        if not xp_value or xp_value <= 0 then
            return
        end

        self._exp_label = self._object:text({
            align = "right",
            color = tweak_data.gui.colors.raid_grey,
            font = tweak_data.gui.fonts.din_compressed,
            font_size = tweak_data.gui.font_sizes.small,
            name = "list_item_exp_label_" .. self._name,
            text = utf8.to_upper(xp_value .. " XP"),
            vertical = "center",
        })

        local _, _, w, h = self._exp_label:text_rect()

        self._exp_label:set_size(w, h)
        self._exp_label:set_right(self._item_label:w() - 20)
        self._exp_label:set_center_y(RaidGUIControlListItemOperations.DIFFICULTY_CENTER_Y)
    end

    function RaidGUIControlListItemOperations:wghud_init_stealthable_icon()
        return RaidGUIControlListItemRaids.wghud_init_stealthable_icon(self)
    end

    function RaidGUIControlListItemOperations:wghud_refresh_stealthable_icon()
        return RaidGUIControlListItemRaids.wghud_refresh_stealthable_icon(self, "mission_id")
    end
end
