-- Chat: a text editor worth the name, a history to scroll through, "X is typing...", and
-- a chat that can be sized, colored and spaced to taste - all of it also while the game runs.
--
-- Input (vanilla knows backspace, delete, left, right only): Home / End, Shift selection,
-- Ctrl+Left/Right word jump, Ctrl+Backspace/Delete word delete, Ctrl+A / C / X / V, Insert
-- to paste, Numpad Enter to send. PD2 has the editing in InputUtils, RAID does not, so it is
-- rebuilt here from set_selection / selection only.
--
-- Scrollback: Page Up / Page Down / Up / Down while the chat has focus. Vanilla puts all
-- consecutive messages of a sender into one block and cuts that block at the height of the
-- panel, so older lines are lost and the block can never be scrolled. Here every message is
-- a segment of its own; one that continues the previous sender's talk hides its name, which
-- looks like vanilla.
--
-- Typing info: WolfgangHUDs tell each other while they type (WolfgangHUD.Sync).
--
-- Fields set on a HUDChat: _wh_main (the chat on the HUD, not the ready up screen), _wh_message_w,
-- _wh_scroll, _wh_anchor (fixed end of a selection), _wh_mods (modifier keys), _wh_typing_sent.
-- On a message block: _wh_own, _wh_continuation, _wh_fallback, _wh_bg_color.

if string.lower(RequiredScript) == "lib/managers/hud/hudchat" then

	WolfgangHUD.ChatTweaks = WolfgangHUD.ChatTweaks or {}
	local ChatTweaks = WolfgangHUD.ChatTweaks

	ChatTweaks.SCROLLBAR_OFF = 1
	ChatTweaks.SCROLLBAR_LEFT = 2
	ChatTweaks.SCROLLBAR_RIGHT = 3

	ChatTweaks.LINE_SCROLL = 40 -- px per Up / Down
	ChatTweaks.NAME_SHIFT = 10 -- the name spacing option shows 0..10, vanilla is 10
	ChatTweaks.SENDER_EXTRA_GAP = 5 -- additional gap above a message of another sender
	ChatTweaks.INNER_PAD = 5 -- room the text box of a line has above and below the glyphs; not part of a segment
	ChatTweaks.BACKGROUND_ALPHA = 0.25
	ChatTweaks.SELECTION_COLOR = Color(0.55, 0.25, 0.45, 0.75)
	ChatTweaks.NEVER = 1e6 -- seconds, "never" for the fade-out
	ChatTweaks.BUFFER_MIN = 20 -- messages of the chat manager's replay buffer, vanilla

	ChatTweaks.TYPING_SEND_INTERVAL = 2 -- seconds between two "typing" announcements
	ChatTweaks.TYPING_TIMEOUT = 4 -- how long a peer stays listed after its last announcement
	ChatTweaks.TYPING_REFRESH = 0.25
	ChatTweaks.TYPING_FONT_SIZE = tweak_data.gui.font_sizes.size_14
	ChatTweaks.EVENT_TYPING = "chat_typing"
	ChatTweaks.EVENT_TYPING_STOP = "chat_typing_stop"

	ChatTweaks.INPUT_BG_PIECES = {"wolfganghud_input_bg_left", "wolfganghud_input_bg_middle", "wolfganghud_input_bg_right"}
	ChatTweaks.SCROLL_TRACK = "wolfganghud_scroll_track"
	ChatTweaks.SCROLL_HANDLE = "wolfganghud_scroll_handle"

	local DEFAULT_WIDTH = HUDChat.W
	local DEFAULT_HEIGHT = HUDChat.H
	local default_message_w -- HUDChatMessage.W of vanilla, read when the first message arrives

	-- ============ settings ============

	local function setting(id, default)
		return WolfgangHUD:getSetting({"CHAT", id}, default)
	end

	function ChatTweaks:width()
		return setting("WIDTH", 450)
	end

	function ChatTweaks:height()
		return setting("HEIGHT", 450)
	end

	function ChatTweaks:kept()
		return setting("MESSAGES_KEPT", 40)
	end

	-- px between two messages of the same sender. The option shows it as is, vanilla is 15:
	-- a segment is the line without the room its text box has around the glyphs (INNER_PAD).
	function ChatTweaks:line_gap()
		return setting("MESSAGE_SPACING", 7)
	end

	-- The name moves down by this many px, which shrinks the gap to the text. It cannot go up,
	-- the block is the name's clip rectangle.
	function ChatTweaks:name_trim()
		return math.max(0, self.NAME_SHIFT - setting("NAME_SPACING", 4))
	end

	function ChatTweaks:typing_info()
		return setting("TYPING_INFO", true)
	end

	-- Names and text get the color of the HUD names, which needs the HUD's name colors on as well
	-- (the menu option is greyed out otherwise).
	function ChatTweaks:colorize()
		return WolfgangHUD:getSetting({"HUD", "COLORIZE_NAMES"}, true) and setting("COLORIZE", true)
	end

	-- Constants of HUDChat and ChatManager that vanilla reads whenever it needs them
	function ChatTweaks:apply_constants()
		local kept = self:kept()
		HUDChat.MESSAGES_KEPT = kept
		if ChatManager then
			-- the replay buffer fills a new HUD chat after a load
			ChatManager.MESSAGE_BUFFER_SIZE = math.max(kept, self.BUFFER_MIN)
		end

		-- seconds a new message stays on screen while the chat is not in use
		local delay = setting("HIDE_DELAY", 8)
		HUDChat.MESSAGE_MAX_SHOWTIME = delay > 0 and delay or self.NEVER
	end

	-- Runs a function that must not take the chat down with it
	local function guarded(what, func)
		local ok, err = pcall(func)
		if not ok then
			log("[WolfgangHUD ChatTweaks] " .. what .. ": " .. tostring(err))
		end
	end

	-- ============ keys, modifiers, text ============

	local IDS_BACKSPACE = Idstring("backspace")
	local IDS_DELETE = Idstring("delete")
	local IDS_INSERT = Idstring("insert")
	local IDS_LEFT = Idstring("left")
	local IDS_RIGHT = Idstring("right")
	local IDS_UP = Idstring("up")
	local IDS_DOWN = Idstring("down")
	local IDS_HOME = Idstring("home")
	local IDS_END = Idstring("end")
	local IDS_PAGE_UP = Idstring("page up")
	local IDS_PAGE_DOWN = Idstring("page down")
	local IDS_NUM_ENTER = Idstring("num enter")
	local IDS_A = Idstring("a")
	local IDS_C = Idstring("c")
	local IDS_V = Idstring("v")
	local IDS_X = Idstring("x")

	-- Idstrings are compared by value (==), as tables keyed by them do not find
	-- an equal Idstring created elsewhere (the key event brings its own)
	local function has(list, k)
		for _, key in ipairs(list) do
			if key == k then
				return true
			end
		end
		return false
	end

	-- keys the editor handles on its own
	local EDIT_KEYS = {IDS_BACKSPACE, IDS_DELETE, IDS_INSERT, IDS_LEFT, IDS_RIGHT, IDS_HOME, IDS_END}
	local SCROLL_KEYS = {IDS_UP, IDS_DOWN, IDS_PAGE_UP, IDS_PAGE_DOWN}
	local REPEATING_KEYS = {IDS_BACKSPACE, IDS_DELETE, IDS_LEFT, IDS_RIGHT, IDS_UP, IDS_DOWN, IDS_PAGE_UP, IDS_PAGE_DOWN}

	function ChatTweaks:handles(chat, k)
		return has(SCROLL_KEYS, k) or has(EDIT_KEYS, k) or self:ctrl(chat) and (k == IDS_A or k == IDS_C or k == IDS_V or k == IDS_X) or false
	end

	-- Modifier state: Input:keyboard():down() with Idstrings (like CoreInput.shift() / ctrl(),
	-- the string form never saw a modifier), and the chat's own key events as a fallback
	local MODIFIERS = {
		lshift = Idstring("left shift"),
		rshift = Idstring("right shift"),
		lctrl = Idstring("left ctrl"),
		rctrl = Idstring("right ctrl"),
	}

	function ChatTweaks:track_modifier(chat, k, pressed)
		for name, ids in pairs(MODIFIERS) do
			if ids == k then
				chat._wh_mods = chat._wh_mods or {}
				chat._wh_mods[name] = pressed
			end
		end
	end

	function ChatTweaks:shift(chat)
		local mods = chat._wh_mods or {}
		local keyboard = Input:keyboard()
		return keyboard:down(MODIFIERS.lshift) or keyboard:down(MODIFIERS.rshift) or mods.lshift or mods.rshift or false
	end

	function ChatTweaks:ctrl(chat)
		local mods = chat._wh_mods or {}
		local keyboard = Input:keyboard()
		return keyboard:down(MODIFIERS.lctrl) or keyboard:down(MODIFIERS.rctrl) or mods.lctrl or mods.rctrl or false
	end

	-- Characters of a UTF-8 string, plain Lua, so nothing depends on what the engine's utf8 library does
	local function chars(str)
		local list = {}
		for c in tostring(str or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
			list[#list + 1] = c
		end
		return list
	end

	-- caret positions run 0..#list, character i sits between caret i - 1 and i
	local function word_start(list, pos)
		local i = pos
		while i > 0 and list[i] == " " do
			i = i - 1
		end
		while i > 0 and list[i] ~= " " do
			i = i - 1
		end
		return i
	end

	local function word_end(list, pos)
		local len = #list
		local i = pos
		while i < len and list[i + 1] ~= " " do
			i = i + 1
		end
		while i < len and list[i + 1] == " " do
			i = i + 1
		end
		return i
	end

	function ChatTweaks:read_clipboard()
		local ok, clipboard = pcall(function()
			return Application:get_clipboard()
		end)
		if not ok then
			return ""
		end
		return (tostring(clipboard or ""):gsub("%c+", " "))
	end

	function ChatTweaks:write_clipboard(str)
		pcall(function()
			Application:set_clipboard(str)
		end)
	end

	-- ============ editing ============

	-- Moves the caret end of the selection; the other end (the anchor, chat._wh_anchor)
	-- stays when Shift is held.
	local function move_caret(chat, text, s, e, new_pos, extend)
		new_pos = math.clamp(new_pos, 0, utf8.len(text:text()))

		if extend then
			local anchor = chat._wh_anchor
			if s == e or anchor ~= s and anchor ~= e then
				anchor = s
			end
			chat._wh_anchor = anchor
			text:set_selection(math.min(anchor, new_pos), math.max(anchor, new_pos))
		else
			chat._wh_anchor = nil
			text:set_selection(new_pos, new_pos)
		end
	end

	-- the end of the selection that moves
	local function caret_pos(chat, s, e)
		if s ~= e and chat._wh_anchor == e then
			return s
		end
		return e
	end

	function ChatTweaks:edit_key(chat, k)
		local text = chat._input_text
		local list = chars(text:text())
		local len = #list
		local s, e = text:selection()
		local has_selection = s ~= e
		local extend = self:shift(chat)
		local word = self:ctrl(chat)

		if k == IDS_BACKSPACE or k == IDS_DELETE then
			if not has_selection then
				if k == IDS_BACKSPACE and s > 0 then
					text:set_selection(word and word_start(list, s) or s - 1, e)
				elseif k == IDS_DELETE and s < len then
					text:set_selection(s, word and word_end(list, e) or e + 1)
				end
			end
			text:replace_text("")
			chat._wh_anchor = nil
		elseif k == IDS_LEFT or k == IDS_RIGHT then
			local caret = caret_pos(chat, s, e)
			if k == IDS_LEFT then
				if has_selection and not extend then
					move_caret(chat, text, s, e, s, false) -- collapse to the left end
				else
					move_caret(chat, text, s, e, word and word_start(list, caret) or caret - 1, extend)
				end
			elseif has_selection and not extend then
				move_caret(chat, text, s, e, e, false) -- collapse to the right end
			else
				move_caret(chat, text, s, e, word and word_end(list, caret) or caret + 1, extend)
			end
		elseif k == IDS_HOME then
			move_caret(chat, text, s, e, 0, extend)
		elseif k == IDS_END then
			move_caret(chat, text, s, e, len, extend)
		elseif k == IDS_A then
			chat._wh_anchor = 0
			text:set_selection(0, len)
		elseif k == IDS_C or k == IDS_X then
			if has_selection then
				-- the engine may count some characters differently, so the range is clamped
				self:write_clipboard(table.concat(list, "", math.min(s + 1, len + 1), math.min(e, len)))
				if k == IDS_X then
					text:replace_text("")
					chat._wh_anchor = nil
				end
			end
		elseif k == IDS_INSERT or k == IDS_V then
			local clipboard = chars(self:read_clipboard())
			local room = HUDChat.MESSAGE_MAX_SIZE - (len - (e - s))
			if room > 0 and #clipboard > 0 then
				text:replace_text(table.concat(clipboard, "", 1, math.min(room, #clipboard)))
			end
			chat._wh_anchor = nil
		end

		chat:_layout_input_text()
		chat:update_caret()
	end

	-- ============ segments and scrollback ============

	-- where the segment starts in its block: below the name, or at the name
	function ChatTweaks:segment_top(message)
		return message._wh_continuation and (HUDChatMessage.NAME_H + self.INNER_PAD) or self:name_trim()
	end

	function ChatTweaks:segment_h(message)
		return message:h() - self.INNER_PAD - self:segment_top(message)
	end

	-- gap between a segment and the one above it
	function ChatTweaks:segment_gap(message)
		return self:line_gap() + (message._wh_continuation and 0 or self.SENDER_EXTRA_GAP)
	end

	function ChatTweaks:max_scroll(chat)
		local total = 0
		for i, message in ipairs(chat._messages) do
			total = total + self:segment_h(message) + (i > 1 and self:segment_gap(message) or 0)
		end
		return math.max(0, total - chat._message_panel:h())
	end

	function ChatTweaks:scroll(chat, delta)
		local scroll = math.clamp((chat._wh_scroll or 0) + delta, 0, self:max_scroll(chat))
		if scroll ~= chat._wh_scroll then
			chat._wh_scroll = scroll
			chat:_layout_message_panel()
		end
	end

	function ChatTweaks:scroll_key(chat, k)
		local page = chat._message_panel:h() * 0.8
		if k == IDS_UP then
			self:scroll(chat, self.LINE_SCROLL)
		elseif k == IDS_DOWN then
			self:scroll(chat, -self.LINE_SCROLL)
		elseif k == IDS_PAGE_UP then
			self:scroll(chat, page)
		elseif k == IDS_PAGE_DOWN then
			self:scroll(chat, -page)
		end
	end

	-- The first segment of the kept ones shows its name, whatever it continued
	function ChatTweaks:restore_first_name(chat)
		local first = chat._messages[1]
		if first and first._wh_continuation then
			first._wh_continuation = nil
			first._name:set_visible(true)
		end
	end

	-- ============ look of the messages ============

	-- Own messages are flush right in vanilla, everything else flush left
	function ChatTweaks:align_block(block)
		if block._wh_own == nil then
			block._wh_own = block._horizontal_text_align == "right"
		end
		local align = block._wh_own and not setting("OWN_LEFT", false) and "right" or "left"

		block._horizontal_text_align = align -- for the lines a block may still get
		block._name:set_align(align)
		for _, line in ipairs(block._messages) do
			line:set_align(align)
		end
	end

	-- The color the HUD gives the player's name, the chat color of the peer as fallback
	function ChatTweaks:peer_color(peer_id, fallback)
		local ok, color_id = pcall(function()
			local unit = managers.criminals:character_unit_by_peer_id(peer_id)
			return alive(unit) and WolfgangHUD:character_color_id(unit)
		end)
		return ok and color_id and tweak_data.chat_colors[color_id] or fallback
	end

	function ChatTweaks:color_block(block, fallback)
		local default = block._message_color
		local color = default

		local peer_id = block:peer_id()
		block._wh_fallback = fallback or block._wh_fallback
		local peer_color = peer_id and not block:system_message() and self:peer_color(peer_id, block._wh_fallback)
		block._wh_bg_color = peer_color or default -- for the colored background, whatever the text does

		if peer_color and self:colorize() then
			color = peer_color
		end

		block._name:set_color(color)
		for _, line in ipairs(block._messages) do
			line:set_color(color)
		end
	end

	-- Colored background behind a message: the area the segment really takes
	function ChatTweaks:update_block_background(block)
		local background = block._object:child("wolfganghud_bg")
		if not setting("COLORED_BG", false) then
			if background then
				background:set_visible(false)
			end
			return
		end

		if not background then
			-- the background is the only thing on layer 0, the text (message panel) and the name are above it
			background = block._object:rect({name = "wolfganghud_bg", layer = 0})
			block._message_panel:set_layer(1)
		end
		background:set_color((block._wh_bg_color or block._message_color):with_alpha(self.BACKGROUND_ALPHA))
		background:set_shape(0, self:segment_top(block), block._object:w(), self:segment_h(block))
		background:set_visible(true)
	end

	-- Slim bar next to the messages: where we are in the history, only if there is more to see
	function ChatTweaks:update_scrollbar(chat)
		local track = chat._object:child(self.SCROLL_TRACK)
		local handle = chat._object:child(self.SCROLL_HANDLE)
		if not track or not handle then
			return
		end

		local max = self:max_scroll(chat)
		local mode = setting("SCROLLBAR", self.SCROLLBAR_RIGHT)
		local show = max > 0 and mode ~= self.SCROLLBAR_OFF
		track:set_visible(show)
		handle:set_visible(show)
		if not show then
			return
		end

		local panel_h = chat._message_panel:h()
		local top = chat._message_panel:y()
		local handle_h = math.max(16, panel_h * panel_h / (panel_h + max))
		-- in the margin next to the messages, on the left or on the right
		local margin_x = mode == self.SCROLLBAR_LEFT and HUDChat.CHAT_BOX_PADDING / 2 or chat._object:w() - HUDChat.CHAT_BOX_PADDING / 2
		local x = margin_x - track:w() / 2
		track:set_shape(x, top, track:w(), panel_h)
		handle:set_shape(x, top + (panel_h - handle_h) * (1 - (chat._wh_scroll or 0) / max), handle:w(), handle_h)
	end

	function ChatTweaks:update_decorations(chat)
		for _, block in ipairs(chat._messages) do
			self:update_block_background(block)
		end
		self:update_scrollbar(chat)
	end

	-- ============ size of the chat ============

	-- The input box is a bitmap of fixed size, centered in the wider row. Rebuilt from
	-- two caps and a stretched slice of its middle, so the rounded corners stay round.
	function ChatTweaks:widen_input_background(chat)
		local panel = chat._input_text_panel
		local background = panel:child("input_text_background")
		local icon = tweak_data.gui.icons[HUDChat.INPUT_TEXT_BACKGROUND]
		if not background or not icon then
			return
		end

		local rect = icon.texture_rect
		local cap = math.floor(rect[4] / 2)
		local cap_w = cap * background:h() / rect[4]
		local y, h, layer = background:y(), background:h(), background:layer()
		local w = panel:w()
		local left, middle, right = self.INPUT_BG_PIECES[1], self.INPUT_BG_PIECES[2], self.INPUT_BG_PIECES[3]

		background:set_visible(false)

		local function piece(name, x, piece_w, texture_rect)
			panel:bitmap({
				name = name,
				texture = icon.texture,
				texture_rect = texture_rect,
				layer = layer,
				x = x,
				y = y,
				w = piece_w,
				h = h,
			})
		end

		piece(left, 0, cap_w, {rect[1], rect[2], cap, rect[4]})
		piece(middle, cap_w, w - cap_w * 2, {rect[1] + math.floor(rect[3] / 2), rect[2], 1, rect[4]})
		piece(right, w - cap_w, cap_w, {rect[1] + rect[3] - cap, rect[2], cap, rect[4]})
	end

	-- The background bitmap has the size of its texture, stretch it over the whole chat
	function ChatTweaks:fit_background(chat)
		local background = chat._object:child("background")
		if background then
			background:set_shape(0, 0, chat._object:w(), chat._object:h())
		end
	end

	-- "X is typing..." sits in the free strip under the input box
	function ChatTweaks:place_typing(chat)
		local typing = chat._object:child("wolfganghud_typing")
		if typing then
			typing:set_w(chat._object:w() - HUDChat.CHAT_BOX_PADDING * 2)
			typing:set_h(HUDChat.CHAT_BOX_PADDING)
			typing:set_x(HUDChat.CHAT_BOX_PADDING)
			typing:set_bottom(chat._object:h())
		end
	end

	-- Height of the HUD chat, the bottom edge stays where it is
	function ChatTweaks:apply_height(chat)
		local height = self:height()
		if chat._object:h() == height then
			return
		end

		local bottom = chat._object:bottom()
		chat._object:set_h(height)
		chat._object:set_bottom(bottom)
		chat._input_panel:set_bottom(height)
		chat._message_panel:set_h(height - chat._input_panel:h())
		chat._message_panel:set_y(0)

		self:fit_background(chat)
		self:place_typing(chat)
		chat._wh_scroll = 0
	end

	-- Width of the HUD chat: its panels, the input box, and the message blocks (the text rewraps)
	function ChatTweaks:apply_width(chat)
		local width = self:width()
		if chat._object:w() == width then
			return
		end

		local message_w = width - HUDChat.CHAT_BOX_PADDING * 2
		chat._wh_message_w = message_w

		chat._object:set_w(width)
		chat._input_panel:set_w(width)
		chat._input_text_panel:set_w(message_w)
		chat._message_panel:set_w(message_w)
		-- resizing the chat made the engine re-center the message panel (halign center)
		chat._message_panel:set_x(HUDChat.CHAT_BOX_PADDING)
		chat._input_text_panel:set_x(HUDChat.CHAT_BOX_PADDING)
		chat._input_text:set_w(chat._input_text_panel:w() - HUDChat.INPUT_TEXT_X - HUDChat.INPUT_TEXT_PADDING_RIGHT)
		chat:_layout_input_text()

		self:fit_background(chat)
		self:place_typing(chat)
		self:update_scrollbar(chat)

		-- input box: the original bitmap at the vanilla width, the three pieces otherwise
		for _, name in ipairs(self.INPUT_BG_PIECES) do
			local piece = chat._input_text_panel:child(name)
			if piece then
				chat._input_text_panel:remove(piece)
			end
		end
		if width ~= DEFAULT_WIDTH then
			self:widen_input_background(chat)
		else
			local background = chat._input_text_panel:child("input_text_background")
			if background then
				background:set_visible(true)
				background:set_center_x(chat._input_text_panel:w() / 2)
			end
		end

		for _, block in ipairs(chat._messages) do
			block._object:set_w(message_w)
			block._name:set_w(message_w)
			block._message_panel:set_w(message_w)
			for _, line in ipairs(block._messages) do
				line:set_w(message_w)
				local _, _, _, h = line:text_rect()
				line:set_h(h)
			end
			block:_size_panel()
		end

		chat:update_caret()
	end

	-- ============ typing info ============

	ChatTweaks.typing = ChatTweaks.typing or {} -- peer_id -> time of the last announcement

	function ChatTweaks:notify_typing(chat)
		local sync = WolfgangHUD.Sync
		if not sync or not self:typing_info() then
			return
		end

		local t = Application:time()
		if utf8.len(chat._input_text:text()) == 0 then
			if chat._wh_typing_sent then
				chat._wh_typing_sent = nil
				sync:send_to_all_discovered_peers(self.EVENT_TYPING_STOP)
			end
		elseif not chat._wh_typing_sent or t - chat._wh_typing_sent >= self.TYPING_SEND_INTERVAL then
			chat._wh_typing_sent = t
			sync:send_to_all_discovered_peers(self.EVENT_TYPING)
		end
	end

	function ChatTweaks:typing_text()
		local session = managers.network and managers.network:session()
		if not session then
			return ""
		end

		local t = Application:time()
		local names = {}
		for peer_id, last_t in pairs(self.typing) do
			local peer = session:peer(peer_id)
			if peer and t - last_t < self.TYPING_TIMEOUT then
				table.insert(names, tostring(peer:name()))
			else
				self.typing[peer_id] = nil
			end
		end
		if #names == 0 then
			return ""
		end

		table.sort(names)
		local id = #names > 1 and "wolfganghud_chat_typing_many" or "wolfganghud_chat_typing_one"
		return managers.localization:text(id, {NAME = table.concat(names, ", ")}) .. string.rep(".", math.floor(t * 2) % 3 + 1)
	end

	WolfgangHUD.SyncListeners = WolfgangHUD.SyncListeners or {}
	WolfgangHUD.SyncListeners[ChatTweaks.EVENT_TYPING] = function(peer_id)
		ChatTweaks.typing[peer_id] = Application:time()
	end
	WolfgangHUD.SyncListeners[ChatTweaks.EVENT_TYPING_STOP] = function(peer_id)
		ChatTweaks.typing[peer_id] = nil
	end

	local function animate_typing(text)
		while alive(text) do
			text:set_text(ChatTweaks:typing_info() and ChatTweaks:typing_text() or "")
			wait(ChatTweaks.TYPING_REFRESH)
		end
	end

	-- ============ changed settings, applied while the chat exists ============

	function ChatTweaks:chats()
		local list = {}
		if managers.hud and managers.hud._hud_chat then
			table.insert(list, managers.hud._hud_chat)
		end
		local ready_up = managers.menu_component and managers.menu_component._raid_ready_up_gui
		if ready_up and ready_up._chat then
			table.insert(list, ready_up._chat)
		end
		return list
	end

	function ChatTweaks:apply_settings()
		self:apply_constants()

		for _, chat in ipairs(self:chats()) do
			guarded("applying settings", function()
				-- fewer to keep than shown: the oldest go
				while #chat._messages > self:kept() do
					chat._messages[1]:destroy()
					table.remove(chat._messages, 1)
				end
				self:restore_first_name(chat)

				if chat._wh_main and alive(chat._object) then
					self:apply_width(chat)
					self:apply_height(chat)
				end

				for _, block in ipairs(chat._messages) do
					self:align_block(block)
					self:color_block(block)
				end
				chat:_layout_message_panel()
			end)
		end
	end

	if WolfgangHUD.apply_settings_clbk then
		WolfgangHUD.apply_settings_clbk["CHAT"] = function()
			ChatTweaks:apply_settings()
		end

		-- the colors follow the HUD's name colors
		local hud_clbk = WolfgangHUD.apply_settings_clbk["HUD"]
		WolfgangHUD.apply_settings_clbk["HUD"] = function(setting_path, ...)
			if hud_clbk then
				hud_clbk(setting_path, ...)
			end
			local option = setting_path and setting_path[#setting_path]
			if option == "COLORIZE_NAMES" or option == "COLORIZE_MODE" then
				ChatTweaks:apply_settings()
			end
		end
	end

	-- ============ HUDChat: creation ============

	-- In the strip under the input box, outside input_panel, which dims when unfocused
	local function create_typing_text(chat)
		local font_size = ChatTweaks.TYPING_FONT_SIZE
		local text = chat._object:text({
			name = "wolfganghud_typing",
			align = "left",
			vertical = "center",
			layer = 30,
			text = "",
			color = HUDChat.PEER_MESSAGE_COLOR,
			font = tweak_data.gui:get_font_path(tweak_data.gui.fonts.lato, font_size),
			font_size = font_size,
		})
		ChatTweaks:place_typing(chat)
		text:animate(animate_typing)
	end

	-- Placed and shown by update_scrollbar
	local function create_scrollbar(chat)
		local colors = {
			[ChatTweaks.SCROLL_TRACK] = Color.white:with_alpha(0.12),
			[ChatTweaks.SCROLL_HANDLE] = HUDChat.PEER_MESSAGE_COLOR:with_alpha(0.7),
		}
		for _, name in ipairs({ChatTweaks.SCROLL_TRACK, ChatTweaks.SCROLL_HANDLE}) do
			chat._object:rect({
				name = name,
				color = colors[name],
				layer = 25,
				visible = false,
				w = 3,
				h = 3,
			})
		end
	end

	local init_original = HUDChat.init
	function HUDChat:init(ws, panel, background, ...)
		ChatTweaks:apply_constants()

		-- the widened chat is the one on the HUD; the ready up screen (no background) keeps its layout
		local width = background and ChatTweaks:width() or DEFAULT_WIDTH
		local height = background and ChatTweaks:height() or DEFAULT_HEIGHT
		HUDChat.W = width
		HUDChat.H = height
		init_original(self, ws, panel, background, ...)
		HUDChat.W = DEFAULT_WIDTH
		HUDChat.H = DEFAULT_HEIGHT

		self._wh_message_w = width - HUDChat.CHAT_BOX_PADDING * 2
		self._wh_main = background and true or false

		if width ~= DEFAULT_WIDTH then
			ChatTweaks:widen_input_background(self)
		end
		ChatTweaks:fit_background(self)
		create_typing_text(self)
		create_scrollbar(self)
	end

	-- ============ HUDChat: keys and input ============

	local key_press_original = HUDChat.key_press
	function HUDChat:key_press(o, k)
		-- Numpad Enter sends what was typed, like Enter; with nothing typed it keeps its other jobs
		if k == IDS_NUM_ENTER and not self._skip_first and utf8.len(self._input_text:text()) > 0 then
			if type(self._enter_callback) ~= "number" then
				self._enter_callback()
			end
			return
		end

		ChatTweaks:track_modifier(self, k, true)
		if self._skip_first or not ChatTweaks:handles(self, k) then
			return key_press_original(self, o, k)
		end

		if not self._enter_text_set then
			self._input_panel:enter_text(callback(self, self, "enter_text"))
			self._enter_text_set = true
		end

		self._key_pressed = k
		self._input_text:stop()
		self._input_text:animate(callback(self, self, "update_key_down"), k)

		self:_wh_handle_key(k)
	end

	function HUDChat:_wh_handle_key(k)
		guarded("key", function()
			if has(SCROLL_KEYS, k) then
				ChatTweaks:scroll_key(self, k)
			else
				ChatTweaks:edit_key(self, k)
				ChatTweaks:notify_typing(self)
			end
		end)
	end

	local update_key_down_original = HUDChat.update_key_down
	function HUDChat:update_key_down(o, k)
		if not ChatTweaks:handles(self, k) then
			return update_key_down_original(self, o, k)
		end

		wait(0.6)

		while self._key_pressed == k and has(REPEATING_KEYS, k) and ChatTweaks:handles(self, k) do
			self:_wh_handle_key(k)
			wait(0.03)
		end
	end

	local key_release_original = HUDChat.key_release
	function HUDChat:key_release(o, k)
		ChatTweaks:track_modifier(self, k, false)
		return key_release_original(self, o, k)
	end

	local enter_text_original = HUDChat.enter_text
	function HUDChat:enter_text(o, s)
		-- Ctrl+<letter> arrives as a control character as well
		local byte = string.byte(s or "", 1)
		if byte and (byte < 32 or byte == 127) then
			return
		end

		enter_text_original(self, o, s)
		self._wh_anchor = nil
		ChatTweaks:notify_typing(self)
	end

	local update_caret_original = HUDChat.update_caret
	function HUDChat:update_caret(...)
		update_caret_original(self, ...)

		-- vanilla only draws a caret of fixed size; the selection gets a rect of its own, behind the text
		local highlight = self._input_text_panel:child("wolfganghud_selection")
		if not highlight then
			highlight = self._input_text_panel:rect({
				name = "wolfganghud_selection",
				color = ChatTweaks.SELECTION_COLOR,
				layer = self._input_text:layer() - 1,
				visible = false,
			})
		end

		local s, e = self._input_text:selection()
		if s ~= e and self._focus then
			local x, y, w, h = self._input_text:selection_rect()
			highlight:set_world_shape(x, y, w, h)
			highlight:set_visible(true)
		else
			highlight:set_visible(false)
		end
	end

	local loose_focus_original = HUDChat._loose_focus
	function HUDChat:_loose_focus(...)
		if self._focus and self._wh_typing_sent and WolfgangHUD.Sync then
			WolfgangHUD.Sync:send_to_all_discovered_peers(ChatTweaks.EVENT_TYPING_STOP)
		end
		self._wh_typing_sent = nil
		self._wh_anchor = nil
		self._wh_scroll = 0
		self._wh_mods = nil

		return loose_focus_original(self, ...)
	end

	-- ============ HUDChat: messages ============

	local receive_message_original = HUDChat.receive_message
	function HUDChat:receive_message(name, peer_id, message, color, icon, system_message, ...)
		-- whoever just sent something is not typing any more, and new messages show at the bottom
		if peer_id then
			ChatTweaks.typing[peer_id] = nil
		end
		self._wh_scroll = 0

		-- the message blocks follow the message panel of this chat
		default_message_w = default_message_w or HUDChatMessage.W
		HUDChatMessage.W = self._wh_message_w or default_message_w

		local previous = self._messages[#self._messages]
		local previous_texts = previous and #previous._messages or 0
		local continues = previous and (previous:peer_id() == peer_id or system_message and previous:system_message())

		local result = receive_message_original(self, name, peer_id, message, color, icon, system_message, ...)

		local last = self._messages[#self._messages]
		if last and (last ~= previous or #last._messages > previous_texts) then
			ChatTweaks:align_block(last)
			ChatTweaks:color_block(last, color)
		end
		if continues and last and last ~= previous then
			last._wh_continuation = true
			last._name:set_visible(false)
		end
		ChatTweaks:restore_first_name(self)
		self:_layout_message_panel()

		return result
	end

	-- every message is a segment of its own (see the header)
	function HUDChat:_message_in_same_thread()
		return false
	end

	-- Shows the part of the messages the scroll offset points at. The blocks are placed through
	-- their panel directly, HUDChatMessage:set_bottom() would shrink the ones sticking out at
	-- the top for good.
	function HUDChat:_layout_message_panel()
		local panel_h = self._message_panel:h()
		local bottom = panel_h + (self._wh_scroll or 0)

		for i = #self._messages, 1, -1 do
			local message = self._messages[i]
			local h = ChatTweaks:segment_h(message)

			-- a hidden name leaves empty room at the top of the panel, it overlaps the segment above
			message._name:set_y(ChatTweaks:name_trim())
			message._object:set_bottom(bottom + ChatTweaks.INNER_PAD)
			message._object:set_visible(bottom - h >= 0 and bottom <= panel_h)

			bottom = bottom - h - ChatTweaks:segment_gap(message)
		end

		self._message_panel:set_bottom(self._object:h() - self._input_panel:h())
		ChatTweaks:update_decorations(self)
	end

end
