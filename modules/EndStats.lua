-- End of a mission: one line per player with all session statistics.
--
-- The game only names the best and worst player per category, and only the
-- host ever sees everyone's numbers (NetworkPeer:statistics()). So every
-- WolfgangHUD sends its own exact numbers to the other WolfgangHUDs
-- (WolfgangHUD.Sync), whatever its own mode is. Players without WolfgangHUD
-- are filled in from the host's statistics, if we are the host. A host with
-- WolfgangHUD also relays what it knows about the others (with or without
-- WolfgangHUD) to the WolfgangHUD clients, so they have those players too. Last resort is our own count of the
-- kills we saw, marked as an estimate.
--
-- Priority of the numbers of a player: its own WolfgangHUD > the host's view
-- (the game's own statistics if we are the host, the relay otherwise) > estimate.
--
-- Modes: 1 = off, 2 = shown to ourselves only, 3 = posted to chat for everyone.
-- Only one player posts to chat: everyone set to do so waits by peer id (the
-- host first), announces it over Sync right before posting, and whoever hears
-- that first stays quiet - those set to "only me" too, the chat has it then.

if string.lower(RequiredScript) == "lib/managers/statisticsmanager" then

	WolfgangHUD.EndStats = WolfgangHUD.EndStats or {}
	local EndStats = WolfgangHUD.EndStats

	EndStats.MODE_OFF = 1
	EndStats.MODE_LOCAL = 2
	EndStats.MODE_CHAT = 3

	EndStats.DELAY = 1.5 -- the chat is not ready in the first frame of the end screen
	EndStats.DELAY_PER_PEER = 0.5
	EndStats.POLL = 0.5
	EndStats.MAX_WAIT = 8 -- seconds to wait for the numbers of the other WolfgangHUDs

	EndStats.CALL_ID = "wolfganghud_end_stats"
	EndStats.EVENT_DATA = "end_stats_data" -- our own exact numbers
	EndStats.RELAY_MAX_WAIT = 5 -- the host does not wait for the slowest client longer than this
	EndStats.RELAY_CALL_ID = "wolfganghud_end_stats_relay"
	EndStats.EVENT_RELAY = "end_stats_relay" -- the host's numbers of the players without WolfgangHUD
	EndStats.EVENT_POSTED = "end_stats_posted" -- we post the stats to chat

	function EndStats:mode()
		return WolfgangHUD:getSetting({"MENU", "END_STATS"}, EndStats.MODE_LOCAL)
	end

	EndStats._observed = EndStats._observed or {} -- peer_id -> kills we saw it make this mission

	function EndStats:reset_observed()
		self._observed = {}
	end

	function EndStats:observe_kill(peer_id, is_special, headshot)
		if not peer_id then
			return
		end
		local seen = self._observed[peer_id]
		if not seen then
			seen = {kills = 0, specials_kills = 0, head_shots = 0}
			self._observed[peer_id] = seen
		end
		seen.kills = seen.kills + 1
		seen.specials_kills = seen.specials_kills + (is_special and 1 or 0)
		seen.head_shots = seen.head_shots + (headshot and 1 or 0)
	end

	function EndStats:reset()
		DelayedCalls:Remove(self.CALL_ID)
		DelayedCalls:Remove(self.RELAY_CALL_ID)
		self._stats = {}
		self._relayed = {}
		self._relay = nil
		self._posted_by_other = false
		self._reported = false
		self._start_t = nil
	end

	-- Same numbers StatisticsManager:send_statistics() gives the host
	function EndStats:own_stats(statistics)
		local revives = 0
		for _, count in pairs(statistics:session_teammates_revived() or {}) do
			revives = revives + count
		end
		return {
			kills = statistics:session_total_kills(),
			specials_kills = statistics:session_total_specials_kills(),
			head_shots = statistics:session_total_head_shots(),
			accuracy = math.min(statistics:session_hit_accuracy(), 1000),
			downs = statistics:session_downed(),
			revives = revives,
		}
	end

	function EndStats:line(stats)
		if not stats then
			return "n/a"
		end
		local function num(value)
			return value and tostring(value) or "?"
		end
		return string.format("Kills %s | Spec %s | HS %s | Acc %s | Downs %s | Revives %s%s",
			num(stats.kills), num(stats.specials_kills), num(stats.head_shots),
			stats.accuracy and (stats.accuracy .. "%") or "?", num(stats.downs), num(stats.revives),
			stats.estimated and " (est.)" or "")
	end

	-- Numbers that came from the player itself or from the host
	function EndStats:exact_of(peer)
		return self._stats[peer:id()] or self._relayed[peer:id()] or peer:statistics()
	end

	-- Exact numbers first, what we saw of the player otherwise
	function EndStats:stats_of(peer)
		local exact = self:exact_of(peer)
		if exact then
			return exact
		end
		local seen = self._observed[peer:id()] or {kills = 0, specials_kills = 0, head_shots = 0}
		return {
			kills = seen.kills,
			specials_kills = seen.specials_kills,
			head_shots = seen.head_shots,
			estimated = true,
		}
	end

	local function clean(data)
		return {
			kills = tonumber(data.kills),
			specials_kills = tonumber(data.specials_kills),
			head_shots = tonumber(data.head_shots),
			accuracy = tonumber(data.accuracy),
			downs = tonumber(data.downs),
			revives = tonumber(data.revives),
		}
	end

	-- The host's view of the other players, once it has it (or gave up waiting). Those with
	-- WolfgangHUD are included too, clients may not have reached them directly.
	function EndStats:try_relay()
		local session = managers.network and managers.network:session()
		if not session or not Network:is_server() or self._relay then
			return
		end

		local known = {}
		local complete = true
		for _, peer in pairs(session:all_peers()) do
			if peer ~= session:local_peer() then
				local stats = self._stats[peer:id()] or peer:statistics()
				if stats then
					known[tostring(peer:id())] = stats
				else
					complete = false
				end
			end
		end

		if not complete and Application:time() - self._start_t < self.RELAY_MAX_WAIT then
			DelayedCalls:Add(self.RELAY_CALL_ID, self.POLL, function()
				EndStats:try_relay()
			end)
			return
		end

		self._relay = {peers = known}
		WolfgangHUD.Sync:send_to_all_discovered_peers(self.EVENT_RELAY, self._relay)
	end

	function EndStats:start(statistics)
		local session = managers.network and managers.network:session()
		if not session then
			return
		end

		-- numbers of the others may have arrived before ours are due, keep them
		if self._start_t then
			self:reset()
		end
		self._start_t = Application:time()

		local mine = self:own_stats(statistics)
		self._stats[session:local_peer():id()] = mine
		WolfgangHUD.Sync:send_to_all_discovered_peers(self.EVENT_DATA, mine)

		-- chat candidates go by peer id, "only me" comes after all of them
		local rank = 0
		for _, peer in pairs(session:all_peers()) do
			if peer:id() < session:local_peer():id() then
				rank = rank + 1
			end
		end
		if self:mode() ~= self.MODE_CHAT then
			rank = rank + #WolfgangHUD.Sync.peers + 1
		end
		self:schedule(self.DELAY + rank * self.DELAY_PER_PEER)
		self:try_relay()
	end

	function EndStats:schedule(delay)
		DelayedCalls:Add(self.CALL_ID, delay, function()
			EndStats:try_report()
		end)
	end

	-- Waiting for: players with WolfgangHUD, everyone if we are the host, everyone if the host has WolfgangHUD
	function EndStats:missing_data(session)
		local host_relays = not Network:is_server() and WolfgangHUD.Sync.peers[session:server_peer():id()]
		for _, peer in pairs(session:all_peers()) do
			if not self:exact_of(peer) and (Network:is_server() or host_relays or WolfgangHUD.Sync.peers[peer:id()]) then
				return true
			end
		end
		return false
	end

	function EndStats:try_report()
		local session = managers.network and managers.network:session()
		local mode = self:mode()
		if not session or self._reported or self._posted_by_other or mode == self.MODE_OFF then
			return
		end

		if self:missing_data(session) and Application:time() - self._start_t < self.MAX_WAIT then
			self:schedule(self.POLL)
			return
		end

		self._reported = true

		local peers = {}
		for _, peer in pairs(session:all_peers()) do
			table.insert(peers, peer)
		end
		table.sort(peers, function(a, b)
			return a:id() < b:id()
		end)

		if mode == self.MODE_CHAT then
			WolfgangHUD.Sync:send_to_all_discovered_peers(self.EVENT_POSTED)
		end
		for _, peer in ipairs(peers) do
			local line = self:line(self:stats_of(peer))
			if mode == self.MODE_CHAT then
				-- as ourselves, for everyone
				managers.chat:send_message(ChatManager.GAME, session:local_peer():name(), peer:name() .. ": " .. line)
			else
				-- as the player itself, in the player's chat color
				managers.chat:receive_message_by_peer(ChatManager.GAME, peer, line)
			end
		end
	end

	WolfgangHUD.SyncListeners = WolfgangHUD.SyncListeners or {}
	WolfgangHUD.SyncDiscovered = WolfgangHUD.SyncDiscovered or {}

	WolfgangHUD.SyncListeners[EndStats.EVENT_DATA] = function(peer_id, data)
		if EndStats._stats then
			EndStats._stats[peer_id] = clean(data)
		end
	end

	WolfgangHUD.SyncListeners[EndStats.EVENT_RELAY] = function(peer_id, data)
		local session = managers.network and managers.network:session()
		-- only the host knows
		if not session or not EndStats._relayed or peer_id ~= session:server_peer():id() or type(data.peers) ~= "table" then
			return
		end
		for id, stats in pairs(data.peers) do
			id = tonumber(id)
			if id and type(stats) == "table" then
				EndStats._relayed[id] = clean(stats)
			end
		end
	end

	WolfgangHUD.SyncListeners[EndStats.EVENT_POSTED] = function(peer_id, data)
		EndStats._posted_by_other = true
	end

	-- A WolfgangHUD found while the numbers are due gets ours as well
	WolfgangHUD.SyncDiscovered.end_stats = function(peer_id)
		local session = managers.network and managers.network:session()
		local mine = session and EndStats._stats and EndStats._stats[session:local_peer():id()]
		if mine then
			WolfgangHUD.Sync:send_to_peer(peer_id, EndStats.EVENT_DATA, mine)
		end
		if EndStats._relay then
			WolfgangHUD.Sync:send_to_peer(peer_id, EndStats.EVENT_RELAY, EndStats._relay)
		end
	end

	EndStats:reset()

	local send_statistics_original = StatisticsManager.send_statistics
	function StatisticsManager:send_statistics(...)
		send_statistics_original(self, ...)
		WolfgangHUD.EndStats:start(self)
	end

	local clear_peer_statistics_original = StatisticsManager.clear_peer_statistics
	function StatisticsManager:clear_peer_statistics(...)
		WolfgangHUD.EndStats:reset()
		WolfgangHUD.EndStats:reset_observed()
		return clear_peer_statistics_original(self, ...)
	end

end
