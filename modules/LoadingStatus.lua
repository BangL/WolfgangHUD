-- Show who the game is still waiting for, without saying so itself.
--
-- 1) Mission start / end (loading screen): WorldCollection moves on stage by
--    stage (prepare -> load -> load finished) only once every peer reported
--    the stage for the world (peer._synced_worlds[world_id][stage]).
-- 2) First load / joining a session (IngameWaitingForPlayersState): holds
--    the start back until the local world is created, every outfit is loaded
--    and, for the host, every peer finished file streaming.

WolfgangHUD.LoadingStatus = WolfgangHUD.LoadingStatus or {}
local LoadingStatus = WolfgangHUD.LoadingStatus

LoadingStatus.TEXT_NAME = "wolfganghud_waiting_text"
LoadingStatus.INTERVAL = 0.5 -- seconds between updates
LoadingStatus.DELAY = 2 -- only once the wait takes noticeably long

function LoadingStatus:enabled()
	return WolfgangHUD:getSetting({"MENU", "WAITING_INFO"}, true)
end

local function loc(id, params)
	return managers.localization:text(id, params)
end

local function create_text(panel, layer)
	local font_size = tweak_data.gui.font_sizes.size_24
	local text = panel:text({
		name = LoadingStatus.TEXT_NAME,
		align = "left",
		vertical = "bottom",
		layer = layer,
		visible = false,
		text = "",
		color = tweak_data.gui.colors.raid_dirty_white,
		font = tweak_data.gui:get_font_path(tweak_data.gui.fonts.din_compressed, font_size),
		font_size = font_size,
	})
	text:set_w(panel:w() / 2)
	text:set_left(50)
	text:set_bottom(panel:h() - 50)
	return text
end

if string.lower(RequiredScript) == "lib/states/ingamewaitingforplayers" then

	-- Same conditions as BaseNetworkSession:are_all_peer_assets_loaded() and :are_peers_done_streaming()
	function LoadingStatus:waiting_text_state(session)
		local lines = {}
		local local_peer = session:local_peer()

		if not managers.worldcollection:all_worlds_created() then
			table.insert(lines, loc("wolfganghud_waiting_world", {NAME = tostring(local_peer:name())}))
		end
		if not local_peer:is_outfit_loaded() then
			table.insert(lines, loc("wolfganghud_waiting_outfit", {NAME = tostring(local_peer:name())}))
		end
		for _, peer in pairs(session:peers()) do
			if peer:waiting_for_player_ready() then
				if not peer:is_outfit_loaded() then
					table.insert(lines, loc("wolfganghud_waiting_outfit", {NAME = tostring(peer:name())}))
				elseif not peer:is_streaming_complete() then
					table.insert(lines, loc("wolfganghud_waiting_streaming", {
						NAME = tostring(peer:name()),
						PERCENT = tostring(peer:streaming_status() or 0),
					}))
				end
			end
		end

		return #lines > 0 and utf8.to_upper(table.concat(lines, "\n")) or nil
	end

	function LoadingStatus:text_object(state)
		local panel = state._safe_panel
		if not alive(panel) then
			return
		end

		return panel:child(self.TEXT_NAME) or create_text(panel, tweak_data.gui.DEBRIEF_VIDEO_LAYER + 10)
	end

	local update_original = IngameWaitingForPlayersState.update
	function IngameWaitingForPlayersState:update(t, dt, ...)
		update_original(self, t, dt, ...)

		if (self._wolfganghud_waiting_t or 0) > t then
			return
		end
		self._wolfganghud_waiting_t = t + LoadingStatus.INTERVAL

		local session = managers.network and managers.network:session()
		local text = session and LoadingStatus:enabled() and LoadingStatus:waiting_text_state(session)
		self._wolfganghud_waiting_since = text and (self._wolfganghud_waiting_since or t) or nil

		local text_object = LoadingStatus:text_object(self)
		if text_object then
			local show = text and t - self._wolfganghud_waiting_since >= LoadingStatus.DELAY
			if show then
				text_object:set_text(text)
			end
			text_object:set_visible(show and true or false)
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudloadingscreen" then

	-- Stages in the order WorldCollection:update waits for them
	local STAGES = {
		{CoreWorldCollection.STAGE_PREPARE, "wolfganghud_waiting_prepare"},
		{CoreWorldCollection.STAGE_LOAD, "wolfganghud_waiting_load"},
		{CoreWorldCollection.STAGE_LOAD_FINISHED, "wolfganghud_waiting_finish"},
	}

	-- The newest world that is not created yet, that is the one being loaded
	local function pending_world_id()
		local pending
		for _, definition in pairs(managers.worldcollection._world_definitions) do
			if not definition.destroyed and not definition.is_created then
				pending = math.max(pending or 0, definition._world_id)
			end
		end
		return pending
	end

	function LoadingStatus:waiting_text_loading()
		local session = managers.network and managers.network:session()
		local world_id = session and pending_world_id()
		if not world_id then
			return
		end

		local peers = {session:local_peer()}
		for _, peer in pairs(session:peers()) do
			table.insert(peers, peer)
		end

		local lines = {}
		for _, peer in ipairs(peers) do
			local synced = peer._synced_worlds and peer._synced_worlds[world_id] or {}
			for _, stage in ipairs(STAGES) do
				if not synced[stage[1]] then
					table.insert(lines, loc(stage[2], {NAME = tostring(peer:name())}))
					break
				end
			end
		end

		return #lines > 0 and utf8.to_upper(table.concat(lines, "\n")) or nil
	end

	local function animate_text(text, screen)
		local since
		while alive(text) do
			local t = Application:time()
			local content = screen._state == "shown" and LoadingStatus:enabled() and LoadingStatus:waiting_text_loading()
			since = content and (since or t) or nil

			local show = content and t - since >= LoadingStatus.DELAY
			if show then
				text:set_text(content)
			end
			text:set_visible(show and true or false)

			wait(LoadingStatus.INTERVAL)
		end
	end

	local setup_original = HUDLoadingScreen.setup
	function HUDLoadingScreen:setup(...)
		setup_original(self, ...)

		local text = self._panel:child(LoadingStatus.TEXT_NAME) or create_text(self._panel, self._bg:layer() + 5)
		text:stop()
		text:animate(animate_text, self)
	end

	local clean_up_original = HUDLoadingScreen.clean_up
	function HUDLoadingScreen:clean_up(...)
		local text = alive(self._panel) and self._panel:child(LoadingStatus.TEXT_NAME)
		if text then
			text:stop()
			self._panel:remove(text)
		end

		return clean_up_original(self, ...)
	end

end
