if string.lower(RequiredScript) == "lib/tweak_data/timespeedeffecttweakdata" then

	local init_original = TimeSpeedEffectTweakData.init

	local FORCE_ENABLE = {
		mission_effects = true,
	}

	-- original values of the effects we disabled, to bring them back when the option is switched off
	local backup = setmetatable({}, { __mode = "k" })

	function TimeSpeedEffectTweakData:wg_set_disabled(disabled)
		local function walk(table)
			for name, data in pairs(table) do
				if not FORCE_ENABLE[name] and type(data) == "table" then
					if data.speed and data.sustain then
						if disabled and not backup[data] then
							backup[data] = {
								speed = data.speed,
								fade_in_delay = data.fade_in_delay,
								fade_in = data.fade_in,
								sustain = data.sustain,
								fade_out = data.fade_out,
							}
							data.speed = 1
							data.fade_in_delay = 0
							data.fade_in = 0
							data.sustain = 0
							data.fade_out = 0
						elseif not disabled and backup[data] then
							for k, v in pairs(backup[data]) do
								data[k] = v
							end
							backup[data] = nil
						end
					else
						walk(data)
					end
				end
			end
		end
		walk(self)
	end

	function TimeSpeedEffectTweakData:init(...)
		init_original(self, ...)
		if WolfgangHUD:getSetting({"GAMEPLAY", "NO_SLOWMOTION"}, true) then
			self:wg_set_disabled(true)
		end
	end

	WolfgangHUD:add_apply_clbk("GAMEPLAY", function(setting, value)
		if setting and setting[1] == "NO_SLOWMOTION" and tweak_data and tweak_data.timespeed then
			tweak_data.timespeed:wg_set_disabled(value)
		end
	end)

end
