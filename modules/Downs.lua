-- Remaining downs (revives) of the other players, shown as the vanilla downs icon on
-- their panels. Bots have no downs (TeamAIDamage has no lives), so no icon for them.
--
-- Vanilla only knows the local player's downs (PlayerDamage._revives). Players with
-- WolfgangHUD send theirs (exact). For everyone else the downs are counted whenever
-- their panel goes into bleedout, which is wrong for anyone who joined after those
-- downs happened: so whoever was there longer hands the counted values over to the
-- newcomer.
--
-- Entries are keyed by peer id.

-- the state is shared by all hooked scripts, whichever of them loads first creates it
if not WolfgangHUD.Downs then

	WolfgangHUD.Downs = {
		EVENT_OWN = "downs",
		EVENT_COUNTED = "downs_counted",
		pending = {}, -- [peer_id] = true while that peer is taking a health_big
		data = {}, -- [key] = {r = remaining, m = max, exact = true if sent by the player itself}
		age_t = Application:time(),
	}
	local Downs = WolfgangHUD.Downs

	-- what everyone has: the base lives and the challenge cards, which are the same for all
	-- players. Skills (revenant_additional_life) are not known for the others.
	function Downs:default_max()
		local max = tweak_data.player.class_defaults.default.damage.BASE_LIVES
		local buff = managers.buff_effect
		if buff and buff:is_effect_active(BuffEffectManager.EFFECT_MODIFY_LIVES) then
			max = max + (buff:get_effect_value(BuffEffectManager.EFFECT_MODIFY_LIVES) or 0)
		end
		return math.max(max, 0)
	end

	-- the entry of a key, created at the maximum if we know nothing yet
	function Downs:entry(key)
		local entry = self.data[key]
		if not entry then
			entry = {m = self:default_max()}
			entry.r = entry.m
			self.data[key] = entry
		end
		return entry
	end

	function Downs:own_max()
		local unit = managers.player and managers.player:player_unit()
		local damage = alive(unit) and unit:character_damage()
		return damage and damage.get_max_revives and damage:get_max_revives() or self:default_max()
	end

	function Downs:refresh_panels()
		for _, panel in pairs(managers.hud and managers.hud._peer_teammate_panels or {}) do
			panel:update_downs()
		end
	end

	-- only the counted values (and the dead ones): the ones sent by the players themselves
	-- are renewed by them
	function Downs:reset()
		for key, entry in pairs(self.data) do
			if not entry.exact or entry.dead then
				self.data[key] = nil
			end
		end
		self:refresh_panels()
	end

	-- the local player's own value, goes out on every change and to every newly met player
	function Downs:send_own(peer_id)
		if not LuaNetworking:IsMultiplayer() then
			return
		end
		local unit = managers.player and managers.player:player_unit()
		local damage = alive(unit) and unit:character_damage()
		if not damage or not damage.get_revives then
			return
		end
		-- t: the toughness skill is ready (the game colors the own icon gold then), nothing else tells the others
		local panel = managers.hud and managers.hud._teammate_panels[HUDManager.PLAYER_PANEL]
		local data = {r = damage:get_revives(), m = self:own_max(), t = panel and panel._downs_icon_color and 1 or 0}
		if peer_id then
			WolfgangHUD.Sync:send_to_peer(peer_id, self.EVENT_OWN, data)
		else
			WolfgangHUD.Sync:send_to_all_discovered_peers(self.EVENT_OWN, data)
		end
	end

	-- what we counted ourselves for the ones that cannot tell (the drop-in sync)
	function Downs:send_counted(peer_id)
		local counted = {}
		for key, entry in pairs(self.data) do
			if not entry.exact then
				counted[tostring(key)] = {r = entry.r, m = entry.m, d = entry.dead or nil}
			end
		end
		if next(counted) then
			WolfgangHUD.Sync:send_to_peer(peer_id, self.EVENT_COUNTED, {age = Application:time() - self.age_t, counted = counted})
		end
	end

	-- the downs of a panel's owner went down by one: only counted for those that do not send
	function Downs:count_down(key)
		if not key then
			return
		end
		local entry = self:entry(key)
		if entry.exact then
			return
		end
		if entry.dead then
			-- going down means being alive: the panel was marked dead before the unit was there
			entry.dead = nil
			entry.r = entry.m
		end
		entry.r = math.max(entry.r - 1, 0)
		self:refresh_panels()
	end

	-- a health_big taken by someone: gives one down back (never above the max)
	function Downs:count_up(key)
		local entry = key and self.data[key]
		if entry and not entry.exact then
			entry.r = math.min(entry.r + 1, entry.m)
			self:refresh_panels()
		end
	end

	-- out of lives and in custody / dead; comes back with the maximum again (see set_teammate_nationality)
	function Downs:on_died(key)
		if not key then
			return
		end
		local entry = self:entry(key)
		entry.r = 0
		entry.dead = true
		self:refresh_panels()
	end

	function Downs:get(key)
		local entry = key and self.data[key]
		if entry then
			local remaining = math.max(entry.r, 0)
			-- counted: the maximum is a guess (the revenant skill adds a life nobody tells us about), so someone
			-- who is still around after the counted lives were used up has one more, the last one.
			-- (The values are the game's: they include that last life, the symbol shows one less: 4 -> "3",
			-- 5 with revenant -> "4", 1 -> "0" = last life, in red.)
			if not entry.exact and not entry.dead and remaining < 1 then
				remaining = 1
			end
			return remaining, entry.m, entry.t, entry.dead
		end
		local max = self:default_max()
		return max, max
	end

	WolfgangHUD.SyncListeners = WolfgangHUD.SyncListeners or {}
	WolfgangHUD.SyncDiscovered = WolfgangHUD.SyncDiscovered or {}

	WolfgangHUD.SyncListeners[Downs.EVENT_OWN] = function(peer_id, data)
		local r, m = tonumber(data.r), tonumber(data.m)
		if r then
			r = math.max(r, 0)
			Downs.data[peer_id] = {r = r, m = math.max(m or Downs:default_max(), r), exact = true, t = tonumber(data.t) == 1,
				dead = Downs.data[peer_id] and Downs.data[peer_id].dead and r == 0 or nil}
			Downs:refresh_panels()
		end
	end

	WolfgangHUD.SyncListeners[Downs.EVENT_COUNTED] = function(peer_id, data)
		-- only from someone who was here longer than us
		if (tonumber(data.age) or 0) <= Application:time() - Downs.age_t or type(data.counted) ~= "table" then
			return
		end
		local local_id = LuaNetworking:LocalPeerID()
		for key, entry in pairs(data.counted) do
			key = tonumber(key) or key
			local current = Downs.data[key]
			if key ~= local_id and not (current and current.exact) and tonumber(entry.r) then
				Downs.data[key] = {r = tonumber(entry.r), m = tonumber(entry.m) or Downs:default_max(), dead = entry.d or nil}
			end
		end
		Downs:refresh_panels()
	end

	WolfgangHUD.SyncDiscovered["Downs"] = function(peer_id)
		Downs:send_own(peer_id)
		Downs:send_counted(peer_id)
	end

	-- peer ids are handed out again: nothing of a former player may stay behind
	Hooks:Add("BaseNetworkSessionOnPeerRemoved", "WolfgangHUD_Downs_BaseNetworkSessionOnPeerRemoved", function(peer, peer_id, reason)
		Downs.data[peer_id] = nil
		Downs.pending[peer_id] = nil
		Downs:refresh_panels()
	end)

	-- a new session: the peers of the last one are gone, whether or not each removal was announced
	Hooks:Add("BaseNetworkSessionOnLoadComplete", "WolfgangHUD_Downs_BaseNetworkSessionOnLoadComplete", function(local_peer, id)
		Downs.data = {}
		Downs.pending = {}
		Downs.age_t = Application:time()
	end)

end

if string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then

	local set_player_downs_original = HUDManager.set_player_downs
	function HUDManager:set_player_downs(...)
		set_player_downs_original(self, ...)
		WolfgangHUD.Downs:send_own()
	end

	-- the toughness skill got ready / was used up
	local override_player_down_color_original = HUDManager.override_player_down_color
	function HUDManager:override_player_down_color(...)
		override_player_down_color_original(self, ...)
		WolfgangHUD.Downs:send_own()
	end

	local set_teammate_nationality_original = HUDManager.set_teammate_nationality
	function HUDManager:set_teammate_nationality(i, nationality, ...)
		local key = i ~= HUDManager.PLAYER_PANEL and self._teammate_panels[i] and self._teammate_panels[i]:peer_id()
		local entry = key and WolfgangHUD.Downs.data[key]
		if entry and entry.dead then
			-- a panel being (re)taken by someone who was dead: lives are back at the maximum
			WolfgangHUD.Downs.data[key] = nil
			WolfgangHUD.Downs:refresh_panels()
		end
		return set_teammate_nationality_original(self, i, nationality, ...)
	end

elseif string.lower(RequiredScript) == "lib/network/handlers/unitnetworkhandler" then

	-- Every player tells everyone when he starts / finishes / aborts an interaction, with the
	-- unit he interacts with: a finished health_big (restore_down) gives that player a down back.
	local sync_teammate_start_progress_original = UnitNetworkHandler.sync_teammate_start_progress
	function UnitNetworkHandler:sync_teammate_start_progress(timer, interact_unit, sender, ...)
		local peer = self._verify_sender(sender)
		if peer then
			local pickup = alive(interact_unit) and interact_unit:pickup()
			WolfgangHUD.Downs.pending[peer:id()] = pickup and pickup.get_restores_down and pickup:get_restores_down() or nil
		end
		return sync_teammate_start_progress_original(self, timer, interact_unit, sender, ...)
	end

	local sync_teammate_cancel_progress_original = UnitNetworkHandler.sync_teammate_cancel_progress
	function UnitNetworkHandler:sync_teammate_cancel_progress(sender, ...)
		local peer = self._verify_sender(sender)
		if peer then
			WolfgangHUD.Downs.pending[peer:id()] = nil
		end
		return sync_teammate_cancel_progress_original(self, sender, ...)
	end

	local sync_teammate_complete_progress_original = UnitNetworkHandler.sync_teammate_complete_progress
	function UnitNetworkHandler:sync_teammate_complete_progress(sender, ...)
		local peer = self._verify_sender(sender)
		if peer and WolfgangHUD.Downs.pending[peer:id()] then
			WolfgangHUD.Downs.pending[peer:id()] = nil
			WolfgangHUD.Downs:count_up(peer:id())
		end
		return sync_teammate_complete_progress_original(self, sender, ...)
	end

elseif string.lower(RequiredScript) == "lib/managers/raidjobmanager" then

	local on_mission_started_original = RaidJobManager.on_mission_started
	function RaidJobManager:on_mission_started(...)
		local result = on_mission_started_original(self, ...)
		WolfgangHUD.Downs:reset()
		return result
	end

	local on_restart_to_camp_original = RaidJobManager._on_restart_to_camp
	function RaidJobManager:_on_restart_to_camp(...)
		local result = on_restart_to_camp_original(self, ...)
		WolfgangHUD.Downs:reset()
		return result
	end

	local on_mission_ended_original = RaidJobManager.on_mission_ended
	function RaidJobManager:on_mission_ended(...)
		local result = on_mission_ended_original(self, ...)
		WolfgangHUD.Downs:reset()
		return result
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammatebase" then

	local on_died_original = HUDTeammateBase.on_died
	function HUDTeammateBase:on_died(...)
		WolfgangHUD.Downs:on_died(self:peer_id())
		return on_died_original(self, ...)
	end

	function HUDTeammateBase:_create_downs_indicator(bottom)
		local remaining = WolfgangHUD.Downs:default_max()
		local guis = tweak_data.gui:get_full_gui_data(HUDTeammatePeer.DOWN_ICON .. math.clamp(remaining, 1, 5))
		local indicator = self._left_panel:bitmap({
			name = "downs_indicator",
			alpha = 1,
			layer = 30,
			color = guis.color,
			texture = guis.texture,
			texture_rect = guis.texture_rect,
		})
		indicator:set_left(-2)
		indicator:set_bottom(bottom)
	end

	function HUDTeammateBase:update_downs()
		local indicator = alive(self._left_panel) and self._left_panel:child("downs_indicator")
		if not indicator then
			return
		end
		local remaining, _, toughness, dead = WolfgangHUD.Downs:get(self:peer_id())
		-- 0 is still alive (the last bleedout, the red icon), only in custody / dead there is nothing to show
		local visible = not dead and WolfgangHUD:getSetting(self._downs_setting, true)
		indicator:set_visible(visible)
		if visible then
			local guis = tweak_data.gui:get_full_gui_data(HUDTeammatePeer.DOWN_ICON .. math.clamp(remaining, 1, 5))
			indicator:set_image(guis.texture, unpack(guis.texture_rect))
			indicator:set_color(toughness and tweak_data.gui.colors.raid_gold or guis.color)
		end
	end

	-- one count per bleedout, the state may be announced more than once
	function HUDTeammateBase:count_down_once()
		if not self:has_active_state("downed") then
			WolfgangHUD.Downs:count_down(self:peer_id())
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammatepeer" then

	local init_original = HUDTeammatePeer.init
	function HUDTeammatePeer:init(...)
		init_original(self, ...)
		self._downs_setting = {"HUD", "PEER", "DOWNS", "SHOW"}
		local warcry_panel = self._left_panel:child("warcry_panel")
		local warcry_background = warcry_panel and warcry_panel:child("warcry_background")
		local bottom = warcry_background
			and warcry_panel:y() + warcry_background:y() + warcry_background:h() + 2
			or self._left_panel:h()
		self:_create_downs_indicator(bottom)
	end

	local go_into_bleedout_original = HUDTeammatePeer.go_into_bleedout
	function HUDTeammatePeer:go_into_bleedout(...)
		self:count_down_once()
		return go_into_bleedout_original(self, ...)
	end

end
