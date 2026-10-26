-- WolfgangHUD to WolfgangHUD sync. Once loaded, every WolfgangHUD asks all
-- players whether they run WolfgangHUD too (discover / confirm, in both
-- directions, so clients know each other as well), and events are only sent
-- to the players that answered.
--
-- Other modules hook in with WolfgangHUD.SyncListeners[event] = function(peer_id, data)
-- and WolfgangHUD.SyncDiscovered[name] = function(peer_id); both tables may be
-- filled before this file runs.
--
-- Wire format: one fixed message id and a JSON payload, the envelope
-- { e = event, d = data }, d being the event's own data table.
--
-- protocol_version goes along with discover / confirm. A player with another
-- version is not taken in, and events are only accepted from players that were
-- taken in. Raise it with every change of an event's name or data.

if string.lower(RequiredScript) == "lib/network/base/basenetworksession" and not WolfgangHUD.Sync then

	WolfgangHUD.Sync = {
		msg_id = "WolfgangHUD_Sync",
		protocol_version = 1,
		retry_max = 5,
		retry_delay = 5,
		peers = {false, false, false, false},
		events = {
			discover = "discover",
			confirm = "confirm",
		},
	}
	local Sync = WolfgangHUD.Sync

	WolfgangHUD.SyncListeners = WolfgangHUD.SyncListeners or {}
	WolfgangHUD.SyncDiscovered = WolfgangHUD.SyncDiscovered or {}

	-- LuaNetworking:TableToString() flattens everything through tostring() and
	-- cannot nest; json keeps types and structure. json.decode yields nothing
	-- usable on malformed input, so anything but a table becomes {}.
	function Sync.table_to_string(tbl)
		return json.encode(tbl or {}) or ""
	end

	function Sync.string_to_table(str)
		local tbl = json.decode(str or "")
		return type(tbl) == "table" and tbl or {}
	end

	function Sync:send_to_peer(peer_id, event, data)
		if peer_id and peer_id ~= LuaNetworking:LocalPeerID() and event then
			LuaNetworking:SendToPeer(peer_id, self.msg_id, self.table_to_string({
				e = event,
				d = type(data) == "table" and data or nil,
			}))
		end
	end

	function Sync:send_to_all_peers(event, data)
		for peer_id in ipairs(self.peers) do
			self:send_to_peer(peer_id, event, data)
		end
	end

	function Sync:send_to_all_discovered_peers(event, data)
		for peer_id, known in ipairs(self.peers) do
			if known then
				self:send_to_peer(peer_id, event, data)
			end
		end
	end

	function Sync:send_to_unknown_peers(event, data)
		for peer_id, known in ipairs(self.peers) do
			if not known then
				self:send_to_peer(peer_id, event, data)
			end
		end
	end

	-- discover goes out once on load, so a lost one would leave us deaf to that peer for the
	-- whole session: ask the peers that did not answer a few more times
	function Sync:retry_unknown_peers(attempt)
		attempt = attempt or 1
		if attempt > self.retry_max then
			return
		end
		DelayedCalls:Add("WolfgangHUD_Sync_retry", self.retry_delay, function()
			if LuaNetworking:IsMultiplayer() then
				self:send_to_unknown_peers(self.events.discover, {version = self.protocol_version})
				self:retry_unknown_peers(attempt + 1)
			end
		end)
	end

	function Sync:receive_message(peer_id, event, data)
		if not peer_id or not event then
			return
		end

		if event == self.events.discover or event == self.events.confirm then
			local version = tonumber(data.version)
			if version ~= self.protocol_version then
				log(string.format("[WolfgangHUD.Sync] peer %s uses sync protocol %s, we use %s, not syncing with it",
					tostring(peer_id), tostring(version), tostring(self.protocol_version)))
				return
			end
			if event == self.events.discover then
				self:send_to_peer(peer_id, self.events.confirm, {version = self.protocol_version})
			end
			self:on_peer_discovered(peer_id)
		elseif not self.peers[peer_id] then
			return -- only from players with a compatible WolfgangHUD
		else
			local listener = WolfgangHUD.SyncListeners[event]
			if listener then
				listener(peer_id, data)
			end
		end
	end

	function Sync:on_peer_discovered(peer_id)
		local first_time = not self.peers[peer_id]
		self.peers[peer_id] = true

		if first_time then
			for _, callback in pairs(WolfgangHUD.SyncDiscovered) do
				callback(peer_id)
			end
		end
	end

	Hooks:Add("NetworkReceivedData", "WolfgangHUD_Sync_NetworkReceivedData", function(sender, msg_id, payload)
		sender = tonumber(sender)
		-- every mod on the hidden chat channel ends up here, compare, never parse
		if not sender or msg_id ~= Sync.msg_id then
			return
		end
		local msg = Sync.string_to_table(payload)
		if type(msg.e) == "string" and msg.e ~= "" then
			Sync:receive_message(sender, msg.e, type(msg.d) == "table" and msg.d or {})
		end
	end)

	Hooks:Add("BaseNetworkSessionOnPeerRemoved", "WolfgangHUD_Sync_BaseNetworkSessionOnPeerRemoved", function(peer, peer_id, reason)
		Sync.peers[peer_id] = false
	end)

	-- Everyone asks everyone, whoever loads later asks the ones already in
	Hooks:Add("BaseNetworkSessionOnLoadComplete", "WolfgangHUD_Sync_BaseNetworkSessionOnLoadComplete", function(local_peer, id)
		if LuaNetworking:IsMultiplayer() then
			Sync:send_to_all_peers(Sync.events.discover, {version = Sync.protocol_version})
			Sync:retry_unknown_peers()
		end
	end)

end
