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

    function HUDTeammatePlayer:set_level(level, ...)
        set_level_original(self, level, ...)
        if WolfgangHUD:getSetting({ "HUD", "LEVELS_BEFORE_NAME" }, true) then
            self:wh_refresh_level(true)
        end
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
end
