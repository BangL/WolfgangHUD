if string.lower(RequiredScript) == "lib/managers/hud/hudteammatepeer" then
    local init_original = HUDTeammatePeer.init

    HUDTeammatePeer.PING_FONT_SIZE = 20
    HUDTeammatePeer.PING_FONT = "din_compressed_outlined_20"

    function HUDTeammatePeer:init(...)
        init_original(self, ...)
        self._next_ping_update_t = 0
        self:_create_ping_info()
    end

    function HUDTeammatePeer:_create_ping_info()
        local ping_panel = self._right_panel:text({
            name = "ping_panel",
            vertical = "right",
            align = "right",
            halign = "right",
            horizontal = "bottom",
            valign = "bottom",
            text = "",
            layer = 1,
            visible = WolfgangHUD:getSetting({ "HUD", "PEER", "PING", "SHOW" }, true),
            color = Color.white,
            h = self.PING_FONT_SIZE,
            font_size = self.PING_FONT_SIZE,
            font = tweak_data.gui.fonts[self.PING_FONT]
        })
        ping_panel:set_bottom(self._right_panel:h())
    end

    function HUDTeammatePeer:update_ping_info(t, dt)
        local ping_panel = self._right_panel:child("ping_panel")
        if ping_panel then
            ping_panel:set_visible(WolfgangHUD:getSetting({ "HUD", "PEER", "PING", "SHOW" }, true))
        end
        if ping_panel and self:peer_id() and t > self._next_ping_update_t then
            local net_session = managers.network:session()
            local peer = net_session and net_session:peer(self:peer_id())
            local ping = peer and Network:qos(peer:rpc()).ping or "n/a"

            if type(ping) == "number" then
                ping_panel:set_text(string.format("%.0fms", ping))
                ping_panel:set_color(ping < 75 and Color('C2FC97') or ping < 150 and Color('CEA168') or
                    Color('E24E4E'))
            else
                ping_panel:set_text(ping)
                ping_panel:set_color(Color('E24E4E'))
            end

            self._next_ping_update_t = t + 1
        elseif not self:peer_id() and ping_panel then
            ping_panel:set_text("")
        end
    end
elseif string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then
    local update_original = HUDManager.update

    function HUDManager:update(t, dt, ...)
        for _, panel in ipairs(self._teammate_panels) do
            if panel.update_ping_info then
                panel:update_ping_info(t, dt, ...)
            end
        end
        return update_original(self, t, dt, ...)
    end
end
