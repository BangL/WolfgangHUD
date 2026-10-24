local _get_marked_row_skill_button_original = WeaponSelectionGui._get_marked_row_skill_button

-- Vanilla only counts ACTIVE/SELECTED buttons as the currently applied tier of a row. Active skills whose
-- gun part is hidden get STATE_INVISIBLE instead, so hovering a tier and leaving it again restored a
-- lower tier than the applied one, which made the stat preview show bogus negative values.
function WeaponSelectionGui:_get_marked_row_skill_button(i_skill, ...)
    if not WolfgangHUD:getSetting({ "MENU", "FIX_SKILL_PREVIEW" }, true) then
        return _get_marked_row_skill_button_original(self, i_skill, ...)
    end

    local weapon_skills_row = self._weapon_skills:get_rows()[i_skill]
    local skill_buttons = weapon_skills_row and weapon_skills_row:get_skill_buttons()
    local max_skill_value = 0
    local weapon_skill_button

    for _, skill_button in pairs(skill_buttons or {}) do
        local button_state = skill_button:get_state()
        local counts = button_state == RaidGUIControlButtonWeaponSkill.STATE_INVISIBLE
            or (skill_button:visible() and (button_state == RaidGUIControlButtonWeaponSkill.STATE_ACTIVE or button_state == RaidGUIControlButtonWeaponSkill.STATE_SELECTED))
        local value = skill_button:get_data().value.value

        if counts and max_skill_value < value then
            max_skill_value = value
            weapon_skill_button = skill_button
        end
    end

    return weapon_skill_button
end
