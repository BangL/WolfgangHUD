if not _G.WolfgangHUD then
	_G.WolfgangHUD = {}
	WolfgangHUD.mod_path = ModPath
	WolfgangHUD.save_path = SavePath
	WolfgangHUD.settings_path = WolfgangHUD.save_path .. "WolfgangHUD.json"
	WolfgangHUD.tweak_file = "WolfgangHUDTweakData.lua"
	WolfgangHUD.identifier = string.match(WolfgangHUD.mod_path, "[\\/]([%w_-]+)[\\/]$") or "WolfgangHUD"

	WolfgangHUD.settings = {}
	WolfgangHUD.default_settings = {}
	WolfgangHUD.tweak_data = {}

	function WolfgangHUD:Reset()
		dofile(WolfgangHUD.mod_path .. "core/DefaultSettings.lua")	-- Default settings table in seperate file, in order to not bloat the Core file too much.
	end

	function WolfgangHUD:print_log(...)
		local LOG_MODES = self:getTweakEntry("LOG_MODE", "table", {})
		local params = {...}
		local msg_type, text = table.remove(params, #params), table.remove(params, 1)
		if msg_type and LOG_MODES and LOG_MODES[tostring(msg_type)] then
			if type(text) == "table" or type(text) == "userdata" then
				local function log_table(userdata, max_indent, indent) -- third param is for recursive calls only
					max_indent = max_indent or 1
					indent = indent or 0
					if indent == 0 then
						log("{") -- self bracket
					end
					local text = ""
					local spaces = string.rep(' ', (indent + 1) * 2) -- use 2 spaces per indent and indent self (+1)
					for id, data in pairs(type(userdata) == "userdata" and getmetatable(userdata) or userdata) do
						local name = type(id) == "number" and ("[" .. tostring(id) .. "]") or tostring(id)
						if type(data) == "table" then
							if id ~= "__index" and indent < max_indent then
								log(spaces .. name .. " = {")
								log_table(data, max_indent, indent + 1) -- call recursively, increase indent
								log(spaces .. "},")
							else
								log(spaces .. name .. " = {...},")
							end
						elseif type(data) == "function" then
							log(spaces .. "function " .. name .. "(...),")
						else
							log(spaces .. name .. " = " .. (type(data) == "string" and ('"' .. data .. '"') or tostring(data)) .. ",")
						end
					end
					if indent == 0 then
						log("}") -- self bracket
					end
				end
				if not text[1] or type(text[1]) ~= "string" then
					log(string.format("[WolfgangHUD] %s:", string.upper(msg_type)))
					log_table(text, params[1] or 1)
					return
				else
					text = string.format(unpack(text))
				end
			elseif type(text) == "function" then
				msg_type = "error"
				text = "Cannot log function... "
			elseif type(text) == "string" then
				text = string.format(text, unpack(params or {}))
			end
			text = string.format("[WolfgangHUD] %s: %s", string.upper(msg_type), text)
			log(text)
		end
	end

	function WolfgangHUD:Load()
		local corrupted = false
		local file = io.open(self.settings_path, "r")
		if file then
			local function parse_settings(table_dst, table_src, setting_path)
				for k, v in pairs(table_src) do
					if type(table_dst[k]) == type(v) then
						if type(v) == "table" then
							table.insert(setting_path, k)
							parse_settings(table_dst[k], v, setting_path)
							table.remove(setting_path, #setting_path)
						else
							table_dst[k] = v
						end
					else
						self:print_log("Error while loading, Setting types don't match (%s->%s)", self:SafeTableConcat(setting_path, "->") or "", k or "N/A", "error")
						corrupted = corrupted or true
					end
				end
			end

			local settings = json.decode(file:read("*all"))
			parse_settings(self.settings, settings, {})
			file:close()
		else
			self:print_log("Error while loading, settings file could not be opened (" .. self.settings_path .. ")", "error")
		end
		if corrupted then
			self:Save()
			self:print_log("Settings file appears to be corrupted, resaving...", "error")
		end
	end

	function WolfgangHUD:Save()
		if table.size(self.settings or {}) > 0 then
			local file = io.open(self.settings_path, "w+")
			if file then
				file:write(json.encode(self.settings))
				file:close()
			else
				self:print_log("Error while saving, settings file could not be opened (" .. self.settings_path .. ")", "error")
			end
		else
			self:print_log("Error while saving, settings table appears to be empty...", "error")
		end
	end

	function WolfgangHUD:DirectoryExists(path)
		if SystemFS and SystemFS.exists then
			return SystemFS:exists(path)
		elseif file and file.DirectoryExists then
			log("")	-- For some weird reason the function below always returns true if we don't log anything previously...
			return file.DirectoryExists(path)
		end
	end

	function WolfgangHUD:getVersion()
		local mod = BLT.Mods:GetMod(WolfgangHUD.identifier or "")
		return tostring(mod and mod:GetVersion() or "(n/a)")
	end

	function WolfgangHUD:SafeTableConcat(tbl, str)
		local res
		for i = 1, #tbl do
			local val = tbl[i] and tostring(tbl[i]) or "[nil]"
			res = res and res .. str .. val or val
		end
		return res
	end

	function WolfgangHUD:getSetting(id_table, default)
		if type(id_table) == "table" then
			local entry = self.settings
			for i = 1, #id_table do
				entry = entry[id_table[i]]
				if entry == nil then
					self:print_log("Requested setting doesn't exists!  (id='" .. self:SafeTableConcat(id_table, "->") .. "', type='" .. (default and type(default) or "n/a") .. "') ", "error")
					return default
				end
			end
			return entry
		end
		return default
	end

	function WolfgangHUD:setSetting(id_table, value)
		local entry = self.settings
		for i = 1, (#id_table-1) do
			entry = entry[id_table[i]]
			if entry == nil then
				return false
			end
		end

		if type(entry[id_table[#id_table]]) == type(value) then
			entry[id_table[#id_table]] = value
			return true
		end
	end

	function WolfgangHUD:getColorSetting(id_table, default, ...)
		local color_name = self:getSetting(id_table, default)
		return self:getColor(color_name, ...) or default and self:getColor(default, ...)
	end

	function WolfgangHUD:getColorID(name)
		if self.tweak_data and type(name) == "string" then
			local tbl = self:getTweakEntry("color_table", "table", {})
			if type(tbl) == "table" then
				for i, data in ipairs(tbl) do
					if name == data.name then
						return i
					end
				end
			end
		end
	end

	function WolfgangHUD:getColor(name, ...)
		if self.tweak_data and type(name) == "string" then
			local tbl = self:getTweakEntry("color_table", "table", {})
			if type(tbl) == "table" then
				for i, data in ipairs(tbl) do
					if name == data.name then
						return data.color and Color(data.color) or data.color_func and data.color_func(...) or nil
					end
				end
			end
		end
	end

	function WolfgangHUD:getTweakEntry(id, val_type, default)
		local value = self.tweak_data[id]
		if value ~= nil and (not val_type or type(value) == val_type) then
			return value
		else
			if default == nil then
				if val_type == "number" then -- Try to prevent crash by giving default value
					default = 1
				elseif val_type == "boolean" then
					default = false
				elseif val_type == "string" then
					default = ""
				elseif val_type == "table" then
					default = {}
				end
			end
			self.tweak_data[id] = default
			self:print_log("Requested tweak_entry doesn't exists!  (id='" .. id .. "', type='" .. tostring(val_type) .. "') ", "error")
			return default
		end
	end

	function WolfgangHUD:ShowHudElements()
		return not managers.raid_job:is_camp_loaded() or self:getSetting({"HUD", "SHOW_IN_CAMP"}, false)
	end

	function WolfgangHUD:character_color_id(unit, panel_id)
		local colorize_mode = self:getSetting({ "HUD", "COLORIZE_MODE" }, 1)

		if colorize_mode == 1 then
			-- in sync (like outlines)
			return managers.criminals:character_color_id_by_unit(unit)
		elseif colorize_mode == 2 then
			-- by panels (local)
			if not panel_id then
				local data = managers.criminals:character_data_by_unit(unit)
				panel_id = data.ai and 0 or (data.panel_id or HUDManager.PLAYER_PANEL)
			end
			return #tweak_data.chat_colors - panel_id
		end

		return nil
	end

	if not WolfgangHUD.tweak_path then		-- Populate tweak data
		local tweak_path = string.format("%s%s", WolfgangHUD.save_path, WolfgangHUD.tweak_file)
		if not io.file_is_readable(tweak_path) then
			tweak_path = string.format("%s%s", WolfgangHUD.mod_path, WolfgangHUD.tweak_file)
		end
		if io.file_is_readable(tweak_path) then
			dofile(tweak_path)
			WolfgangHUD.tweak_data = WolfgangHUDTweakData:new()
		else
			WolfgangHUD:print_log(string.format("Tweak Data file couldn't be found! (%s)", tweak_path), "error")
		end
		if WolfgangHUD.tweak_data and not WolfgangHUD.tweak_data.post_init then
			for _, data in ipairs(WolfgangHUD.tweak_data.color_table) do
				if data.name == "rainbow" then
					data.color_func = function(frequency)
						local r = Application:time() * 360 * (frequency or 1)
						local r, g, b = (1 + math.sin(r + 0)) / 2, (1 + math.sin(r + 120)) / 2, (1 + math.sin(r + 240)) / 2
						return Color(r, g, b)
					end
				end
			end
		end
	end

	--callback functions to apply changed settings on the fly
	if not WolfgangHUD.apply_settings_clbk then
		WolfgangHUD.apply_settings_clbk = {
			["HUDList"] = function(setting, value)
				if managers.hud and HUDListManager and setting then
					local list = tostring(setting[1])
					local category = tostring(setting[2])
					local option = tostring(setting[#setting])
					if list == "RIGHT_LIST" and category == "SHOW_PICKUP_CATEGORIES" then
						managers.hud:change_pickuplist_setting(option, WolfgangHUD:getColor(value) or value)
					else
						managers.hud:change_list_setting(option, WolfgangHUD:getColor(value) or value)
					end
				end
			end,
		}
	end

	-- chains a callback to a settings group, so modules can add their own without replacing others
	function WolfgangHUD:add_apply_clbk(script, clbk)
		local prev = self.apply_settings_clbk[script]
		self.apply_settings_clbk[script] = prev and function(...)
			prev(...)
			clbk(...)
		end or clbk
	end

	WolfgangHUD:Reset()	-- Populate settings table
	WolfgangHUD:Load()	-- Load user settings

	-- Create Ingame Menus
	dofile(WolfgangHUD.mod_path .. "core/OptionMenus.lua")	-- Menu structure table in seperate file, in order to not bloat the Core file too much.
end
