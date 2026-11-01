if string.lower(RequiredScript) == "lib/managers/menu/raid_menu/readyupgui" then

	-- Wie JimHUD: Force-Start nur nach FORCE_READY_ACTIVE_T Sekunden oder wenn
	-- alle nicht bereiten Peers Steam-Freunde sind. Ready laesst sich in RAID
	-- nicht zuruecknehmen, daher ein eigener Button statt 3x Ready.
	local FORCE_READY_ACTIVE_T = 90

	local init_original = ReadyUpGui.init
	local layout_buttons_original = ReadyUpGui._layout_buttons
	local update_original = ReadyUpGui.update

	function ReadyUpGui:init(...)
		self._wh_open_t = Application:time()
		return init_original(self, ...)
	end

	function ReadyUpGui:_layout_buttons(...)
		layout_buttons_original(self, ...)

		if self._is_host and not self._is_single_player then
			self._wh_force_ready_button = self._root_panel:short_secondary_button({
				name = "force_ready_button",
				on_click_callback = callback(self, self, "_wh_on_force_ready_button"),
				text = utf8.to_upper(managers.localization:text("wolfganghud_force_ready_button")),
				visible = false,
				x = 1000,
				y = 848,
			})
			self._wh_force_ready_button:set_right(self._root_panel:right())
			self._wh_force_ready_button:disable()
			self._wh_force_ready_button:hide()
		end
	end

	function ReadyUpGui:_wh_unready_peers()
		local result = {}
		local suggested = managers.challenge_cards:get_suggested_cards() or {}
		for peer_id, peer in pairs(managers.network:session():all_peers()) do
			local card = suggested[peer_id]
			if not card or not card.locked_suggestion then
				result[peer_id] = peer
			end
		end
		return result
	end

	function ReadyUpGui:_wh_can_force_ready()
		if self._wh_open_t and Application:time() - self._wh_open_t > FORCE_READY_ACTIVE_T then
			return true
		end
		if not Steam:logged_on() then
			return false
		end
		local friends = Steam:friends() or {}
		for _, peer in pairs(self:_wh_unready_peers()) do
			local is_friend = false
			for _, friend in ipairs(friends) do
				if friend:id() == peer:user_id() then
					is_friend = true
					break
				end
			end
			if not is_friend then
				return false
			end
		end
		return true
	end

	function ReadyUpGui:_wh_on_force_ready_button()
		if not self._wh_force_ready_button:enabled() then
			return
		end

		local dialog_data = {
			title = utf8.to_upper(managers.localization:text("wolfganghud_force_ready_button")),
			text = utf8.to_upper(managers.localization:text("wolfganghud_force_ready_confirm")),
			focus_button = 2,
			button_list = {
				{
					text = utf8.to_upper(managers.localization:text("dialog_yes")),
					callback_func = callback(self, self, "_wh_force_ready_confirmed"),
				},
				{
					text = utf8.to_upper(managers.localization:text("dialog_no")),
					class = RaidGUIControlButtonShortSecondary,
					cancel_button = true,
				},
			},
		}
		managers.system_menu:show(dialog_data)
	end

	-- Der Host sperrt fuer alle Unbereiten eine Karte ("pass", falls keine
	-- vorgeschlagen) und synct das an die Peers, als haetten sie selbst gelockt.
	function ReadyUpGui:_wh_force_ready_confirmed()
		if not Network:is_server() or not self:_wh_can_force_ready() then
			return
		end

		local session = managers.network:session()
		local cards = managers.challenge_cards
		local suggested = cards:get_suggested_cards()
		if not suggested then
			return
		end

		local pass_key = ChallengeCardsManager.CARD_PASS_KEY_NAME
		for peer_id in pairs(self:_wh_unready_peers()) do
			local card = suggested[peer_id]
			if not card then
				card = tweak_data.challenge_cards:get_card_by_key_name(pass_key)
				suggested[peer_id] = card
				session:send_to_peers_synched("send_suggested_card_to_peers", pass_key, peer_id, nil)
			end
			card.locked_suggestion = true
			session:send_to_peers_synched("send_toggle_lock_suggested_card_to_peers", peer_id)
		end
	end

	function ReadyUpGui:update(...)
		update_original(self, ...)

		local button = self._wh_force_ready_button
		local object = button and button._object
		if object and (not object.alive or alive(object)) then
			local show = WolfgangHUD:getSetting({"HOST", "FORCE_READY"}, true)
				and self._ready
				and not managers.challenge_cards:did_everyone_locked_sugested_card()
				and self:_wh_can_force_ready()
			if show and not button:visible() then
				button:show()
				button:enable()
			elseif not show and button:visible() then
				button:disable()
				button:hide()
			end
		end
	end

end
