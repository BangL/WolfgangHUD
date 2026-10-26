if string.lower(RequiredScript) == "lib/setups/menusetup" then
    local init_game_original = MenuSetup.init_game

    function MenuSetup:init_game(...)
        local gsm = init_game_original(self, ...)
        if WolfgangHUD:getSetting({ "MENU", "SKIP_INTRO" }, false) then
            gsm:set_boot_intro_done(true)
            gsm:change_state_by_name("menu_titlescreen")
        end
        return gsm
    end

elseif string.lower(RequiredScript) == "lib/states/menutitlescreenstate" then
    -- simulate the "press any key" so the title screen proceeds on its own (sign-in/savegame loading still runs)
    local get_start_pressed_controller_index_original = MenuTitlescreenState.get_start_pressed_controller_index

    function MenuTitlescreenState:get_start_pressed_controller_index(...)
        if WolfgangHUD:getSetting({ "MENU", "SKIP_TITLESCREEN" }, false) and self._controller_list and not self._wgh_auto_pressed then
            for index, controller in ipairs(self._controller_list) do
                if controller._default_controller_id == "keyboard" then
                    self._wgh_auto_pressed = true
                    -- vanilla's real key press makes the hotswap controller disable itself; without that every later key press re-triggers hotswap (dialogs register the mouse twice -> crash)
                    for wrapper_index, hotswap_controller in pairs(managers.controller._hotswap_controllers or {}) do
                        if managers.controller._wrapper_class_map[wrapper_index].TYPE == "pc" then
                            hotswap_controller:disable()
                        end
                    end
                    return index
                end
            end
        end
        return get_start_pressed_controller_index_original(self, ...)
    end
end
