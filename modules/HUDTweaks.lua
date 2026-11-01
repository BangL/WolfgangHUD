if string.lower(RequiredScript) == "lib/managers/hud/hudteammatebase" then
    function HUDTeammateBase:wh_refresh_level(is_player)
        if alive(self._player_level) and alive(self._player_name) then
            self._player_level:set_x(0)
            self._player_level:set_y(is_player and 0 or 2)
            self._player_level:set_h(self._player_name:h())
            self._player_level:set_valign("left")
            self._player_level:set_halign(self._player_name:halign())
            self._player_level:set_font_size(self._player_name:font_size())
            BLT:make_fine_text(self._player_level)
            self:wh_refresh_name()
        end
    end

    function HUDTeammateBase:wh_refresh_name()
        if alive(self._player_level) and alive(self._player_name) then
            self._player_name:set_x(self._player_level:w() + 4)
            self._player_name:set_y(0)
            if alive(self._voice_chat_panel) then
                local name_w = select(3, self._player_name:text_rect())
                local chat_x = math.min(name_w, self._player_name:w())
                self._voice_chat_panel:set_left(self._player_name:x() + chat_x)
                self._voice_chat_panel:set_top(self._player_name:y())
            end
        end
    end

    -- numeric HP centered on the health bar; lives on the right panel, the health panel clips its children
    function HUDTeammateBase:wh_update_health_text(data)
        local right_panel = alive(self._right_panel) and self._right_panel
        local health_panel = right_panel and right_panel:child("health_panel")
        if not health_panel then
            return
        end

        local text = right_panel:child("wh_health_text")
        if not WolfgangHUD:getSetting({ "HUD", "HEALTH_NUMBERS" }, true) then
            if text then
                text:set_visible(false)
            end
            return
        end

        if not text then
            text = right_panel:text({
                name = "wh_health_text",
                align = "center",
                vertical = "center",
                font = tweak_data.gui.fonts.din_compressed_outlined_22,
                font_size = 22,
                color = Color.white,
                layer = health_panel:layer() + 10,
                w = health_panel:w(),
                h = 24,
            })
        end

        -- center on the bar itself, the panel can be wider than the bar (bots)
        local bg = health_panel:child("health_background")
        if bg then
            text:set_center(health_panel:x() + bg:center_x(), health_panel:y() + bg:center_y())
        else
            text:set_center(health_panel:center_x(), health_panel:center_y())
        end

        text:set_visible(true)
        if data.total > 0 and (data.total <= 1 or self:is_ai()) then
            -- capped: BHFR can give clients more health than max
            text:set_text(string.format("%d%%", math.min(100, math.ceil(data.current / data.total * 100))))
        else
            text:set_text(string.format("%d / %d", math.ceil(data.current), math.ceil(data.total)))
        end
    end

    -- time until a dead human player is respawned (bots: BotsHaveFeelingsReborn), shown right of the name
    function HUDTeammateBase:wh_set_respawn_timer(character_name)
        if self:is_ai() or not (alive(self._right_panel) and alive(self._player_name)) then
            return
        end

        local text = self._right_panel:child("wh_respawn_text")
        if not text then
            text = self._right_panel:text({
                name = "wh_respawn_text",
                align = "left",
                vertical = "center",
                font = tweak_data.gui.fonts.din_compressed_outlined_22,
                font_size = 22,
                color = Color.white,
                layer = 1,
                w = 80,
                h = 24,
                visible = false,
            })
        end

        self._wh_respawn_name = character_name
        text:stop()
        text:set_visible(true)

        text:animate(callback(self, self, "wh_animate_respawn_timer"))
    end

    function HUDTeammateBase:wh_animate_respawn_timer(text)
        while alive(text) and managers.trade:is_criminal_in_custody(self._wh_respawn_name) do
            local seconds = math.floor(managers.trade:respawn_delay_by_name(self._wh_respawn_name))

            -- 0 = waiting for the trade to be allowed (e.g. stealth): show nothing
            text:set_text(seconds > 0 and string.format("%d:%02d", math.floor(seconds / 60), seconds % 60) or "")
            if alive(self._player_name) then
                local name_w = select(3, self._player_name:text_rect())
                text:set_left(self._player_name:x() + math.min(name_w, self._player_name:w()) + 40)
                text:set_center_y(self._player_name:center_y())
            end

            local t = 0
            while t < 0.25 do
                t = t + coroutine.yield()
            end
        end

        self._wh_respawn_name = nil
        if alive(text) then
            text:set_visible(false)
        end
    end

    function HUDTeammateBase:wh_set_unit(unit)
        if alive(unit) and managers.criminals and alive(self._player_name) then
            local color_id = WolfgangHUD:character_color_id(unit, self._id)
            if color_id then
                local color = tweak_data.chat_colors[color_id]
                if color then
                    self._player_name:set_color(color)
                end
            end
        end
    end
elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammatepeer" then
    local set_health_original = HUDTeammatePeer.set_health

    function HUDTeammatePeer:set_health(data, ...)
        set_health_original(self, data, ...)
        self:wh_update_health_text(data)
    end

    local set_name_original = HUDTeammatePeer.set_name
    local set_level_original = HUDTeammatePeer.set_level

    function HUDTeammatePeer:set_name(name, ...)
        set_name_original(self, name, ...)
        if not (self._player_name and managers.criminals and tweak_data.chat_colors) then
            return
        end

        if WolfgangHUD:getSetting({ "HUD", "COLORIZE_NAMES" }, true) then
            local peer_id = self:peer_id()
            if peer_id then
                local unit = managers.criminals:character_unit_by_peer_id(peer_id)
                self:wh_set_unit(unit)
            end
        end

        if WolfgangHUD:getSetting({ "HUD", "LEVELS_BEFORE_NAME" }, true) then
            self:wh_refresh_name()
        end
    end

    function HUDTeammatePeer:set_level(level, ...)
        set_level_original(self, level, ...)
        if WolfgangHUD:getSetting({ "HUD", "LEVELS_BEFORE_NAME" }, true) then
            self:wh_refresh_level(false)
        end
    end
elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammateplayer" then
    local set_name_original = HUDTeammatePlayer.set_name
    local set_level_original = HUDTeammatePlayer.set_level

    function HUDTeammatePlayer:set_name(name, ...)
        set_name_original(self, name, ...)
        if not (self._player_name and managers.criminals and managers.player and managers.player.player_unit) then
            return
        end

        if WolfgangHUD:getSetting({ "HUD", "COLORIZE_NAMES" }, true) then
            self:wh_set_unit(managers.player:player_unit())
        end

        if WolfgangHUD:getSetting({ "HUD", "LEVELS_BEFORE_NAME" }, true) then
            self:wh_refresh_name()
        end
    end

    local set_health_original = HUDTeammatePlayer.set_health

    function HUDTeammatePlayer:set_health(data, ...)
        set_health_original(self, data, ...)
        self:wh_update_health_text(data)
    end

    function HUDTeammatePlayer:set_level(level, ...)
        set_level_original(self, level, ...)
        if WolfgangHUD:getSetting({ "HUD", "LEVELS_BEFORE_NAME" }, true) then
            self:wh_refresh_level(true)
        end
    end
elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammateai" then
    local set_health_original = HUDTeammateAI.set_health

    function HUDTeammateAI:set_health(data, ...)
        set_health_original(self, data, ...)
        self:wh_update_health_text(data)
    end
elseif string.lower(RequiredScript) == "lib/units/beings/player/huskplayermovement" then
    local set_character_anim_variables_original = HuskPlayerMovement.set_character_anim_variables

    function HuskPlayerMovement:set_character_anim_variables(...)
        set_character_anim_variables_original(self, ...)

        local char_name = managers.criminals:character_name_by_unit(self._unit)

        if not char_name then
            return
        end

        local color_id = WolfgangHUD:character_color_id(self._unit)

        if color_id then
            self._unit:contour():change_color("teammate", tweak_data.peer_vector_colors[color_id])
        end
    end
elseif string.lower(RequiredScript) == "lib/managers/hud/hudnamelabel" then
    local _create_panel_original = HUDNameLabel._create_panel

    -- vanilla width (200) cuts off long names; all children are centered on the panel width
    HUDNameLabel.WH_W = 400

    function HUDNameLabel:_create_panel(...)
        _create_panel_original(self, ...)
        if alive(self._object) then
            self._object:set_w(HUDNameLabel.WH_W)
        end
    end

    function HUDNameLabel:wh_colorize()
        local unit = self._movement and self._movement._unit
        if not (alive(unit) and alive(self._character_name) and managers.criminals and tweak_data.chat_colors) then
            return
        end
        if not WolfgangHUD:getSetting({ "HUD", "COLORIZE_NAMES" }, true) then
            return
        end

        local data = managers.criminals:character_data_by_unit(unit)
        if data and data.ai then
            self._character_name:set_color(Color.white)
            return
        end

        local color_id = WolfgangHUD:character_color_id(unit)
        local color = color_id and tweak_data.chat_colors[color_id]
        if color then
            self._character_name:set_color(color)
        end
    end

    local refresh_original = HUDNameLabel.refresh

    function HUDNameLabel:refresh(...)
        self:wh_colorize()
        return refresh_original(self, ...)
    end

    local show_original = HUDNameLabel.show

    function HUDNameLabel:show(...)
        self:wh_colorize()
        return show_original(self, ...)
    end
elseif string.lower(RequiredScript) == "lib/managers/trademanager" then
    Hooks:PostHook(TradeManager, "on_player_criminal_death", "WolfgangHUD_TradeManager_on_player_criminal_death", function(self, criminal_name)
        local crim_data = managers.criminals:character_data_by_name(criminal_name)
        local panel = crim_data and managers.hud and managers.hud._teammate_panels[crim_data.panel_id]

        -- own death: the custody screen has its own timer, the own panel is being rebuilt then
        if panel and panel.wh_set_respawn_timer and criminal_name ~= managers.criminals:local_character_name() then
            panel:wh_set_respawn_timer(criminal_name)
        end
    end)
end
