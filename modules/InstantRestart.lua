if string.lower(RequiredScript) == "lib/managers/votemanager" then

	local restart_counter_original = VoteManager._restart_counter
	local default_delay

	function VoteManager:_restart_counter(...)
		default_delay = default_delay or tweak_data.voting.restart_delay
		local instant = Network:is_server() and WolfgangHUD:getSetting({"HOST", "INSTANT_RESTART"}, true)
		tweak_data.voting.restart_delay = instant and 0 or default_delay
		return restart_counter_original(self, ...)
	end

end
