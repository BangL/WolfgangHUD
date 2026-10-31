v2.45.0:
- Downs: red icon at the last life, toughness state is synced

v2.44.0:
- Downs: remaining downs of other players are shown
- Chat: mouse pointer with wheel scroll, copy and links
- Wider overhead name labels (long names were cut off)
- Fixes: missing world definition, emptied greed caches as drop-in, corrupted settings file, HUDList color maps and counts, reload bar duration

v2.43.1:
- HUDList / Ping: alive() guards (crash on exit)

v2.43.0:
- Options menu rework (profiles-style menus, descriptions); requires base 2.2.0

v2.42.3:
- HUDList: counts stg44, commander_backup and the missing mp38/kar98 enemy types

v2.42.2:
- GameInfo: pickups of destroyed units are dropped (stale greed item count)

v2.42.1:
- forest_bunker: fixed the id of the unreachable small loot

v2.42.0:
- options are applied directly, without a restart
- changed defaults (chat, waypoints, toasts, revive block)

v2.41.0:
- option to skip the title screen
- InstantRestart: the delay is set when the vote starts instead of patching tweak_data
- HUDList: loot behind doors that stay closed is ignored (Tiger Trap)
- EndStats: the host relays the numbers of all players, not only those without WolfgangHUD
- Sync: retry discover for peers that did not answer

v2.40.0:
- Weapon menu: stat diff vs the equipped weapon, upgrade preview fix

v2.39.1:
- auto updates will be pulled directly from git, instead of mws

v2.39.0
- Fix: crash on game exit, caused by the HUDList pickup display

v2.38.1
- Chat: the background now stretches to the chat's size
- Chat: "X is typing..." moved below the input box
- End stats: players without WolfgangHUD are no longer missing for clients. A host with WolfgangHUD relays what it knows about them to the other WolfgangHUD clients
- End stats: if no exact numbers are available, kills, specials and headshots you saw yourself are shown, marked "(est.)"
- End stats: unknown values are shown as "?" instead of 0

v2.38.0
- added chat improvements:
  - extended text input: home/end, shift selection, ctrl+left/right word jump, ctrl+backspace/delete word delete, ctrl+a/c/x/v, insert to paste, numpad enter sends
  - scroll back through the chat (page up/down, arrow keys), more messages kept (option), optional scroll bar (off/left/right)
  - "x is typing..." indicator (for players using WolfgangHUD)
  - colorize chat names and text like the hud names, optional colored message background
  - options for chat width, chat height, message spacing, name spacing, fade-out time (0 = never) and own messages on the left
- added end stats: kills, specials, headshots, accuracy, downs and revives for every player when a mission ends. shown only to you or posted to the chat (only one player posts)
- added loading status: shows who the mission start/end is still waiting for on the loading screen (and when joining a game)
- added WolfgangHUD <-> WolfgangHUD sync (used for the typing indicator and the end stats)

v2.37.0
- fixed waypoints for some items not showing up (crowbars etc)
- fixed mem leak regarding waypoints
- better saving of changed game settings
- fixed german and spanish translations

v2.36.0
- updated for blt2.0

v2.35.1
- added menu icon for blt 1.3

v2.35.0
- added option to not use press2hold when driving.
- the custom waypoints core code got split into [WaypointsLib](https://modworkshop.net/mod/52686) to make it possible to develop standalone mods using that feature.

v2.34.4
- fix accuracy panel positioning for pd2 hud layout

v2.34.3
- fixed auto reload settings logic
- show stealthable icons in free play menu

v2.34.2
- u25.1 fixup

v2.34.1
- crash hotfix

v2.34.0
- loot count fixes now work with blitz operations

v2.33.4
- qol: allow turret use in camp without double-tap
- fix: interaction timer bar created an orange box after exiting vehicles, when interaction bars disabled
- fix: progress bar description param pass for u25
- cleanup: removed obsolete OperationDaysAsMissions exception for stealhable icons

v2.33.3
- updated loot count blacklists
- fix crash when changing team ai count

v2.33.2
- crash fix with interaction timer

v2.33.1
- crash fixes for u25
- removed 'straight to main menu' feature, as its causing too much trouble. left 'skip intro' in tho.

v2.33.0
- re-added waypoints for non-lootable carryables (like flak shells etc.)
- removed enigma machine waypoint
- added new small loot type 'press_take_loot_tight' (a.k.a documents)
- added waypoints and counter for the Full Stop explosives and conspiracy boards
- retriggering res-changed on options reset (seems to work now)
- removed dead code for waypoint arrows

v2.32.2:
- removed concealment / detection risk from weapon selection, as it got streamlined with U24 (all weapons will result in a detection risk of 3 now)

v2.32.1:
- added U24 icon to offline mode servers entry

v2.32.0:
- added client ping display
- using sblt asset loading

v2.31.1:
- hotfix bug where show ring was inverted :D

v2.31.0:
- added option to hide the suspicion hud background ring
- dropped RaidBLT support! (please switch to RAID-SuperBLT)

v2.30.5:
- improved how game settings are updated (difficulty/permission etc)
- added more ignored loots in operations

v2.30.4:
- sblt fixup
- ignored some more unreachable loot in clear skies

v2.30.3:
- fixed aligments of event hud elements (candy, buffs) in pd2 layout
- added direct SBLT compat, instead of indirectly through BeardLib

v2.30.2:
- added BeardLib compatibility, in preperation for SBLT

v2.30.1:
- fixed empty greed caches being shown, as drop-in
- ignored some unreachable loots in rhinegold 3 and 4

v2.29:
- vanilla hud layout: aligning notification with hudlist now, to prevent overlapping.

v2.28:
- fixed outlaw raid icon (hudlist & waypoint) for u22.2

v2.27:
- pd2style: made notification position static, so it wont overlap with carry any longer
- hudlist: streamlined font
- hudlist: removed flak shells and german_spy icons
- hudlist: added army crates to mission pickups
- show more baggable loot types, better baggable loot icons
- fixed accuracy panel positioning
- marked Countdown and Blinding Heimdall as not stealthable, marked Odin's Fall as completely stealthable
- safer game settings code
- fixed kelly composite loot, ignored some unreachable pickups in extraction and clear skies 2,5,6

v2.26:
- fixed crash when trying to increase bots while peers are present

v2.25:
- fixed alignment of the menu 'menu'
- no longer moving the player list around

v2.24:
- better main menu settings alignment of the players list

v2.23:
- fixed crashes when trying to change game settings while being client (on the mission table)
- fixed ai count changer, while having clients in lobby

v2.22:
- simplified max revive check
- removed obsolete no-ads feature
- GameSettings: apply difficulty changes directly

v2.21:
- removed redundant 'join online' menu entry (you can still add 'servers' to offline camp)
- fixed detection of having 4 revives
- code for stealthable icons reworked

v2.19:
- fixed detection of the motion-dot setting (for hiding it when interacting)
- fixed possible crash with zoom-based-sensitivity
- backported baggable loot icon from pre-u22
- fixed spectator teammate name alignment (when in custody, using the pd2 style)

v2.18:
- fixed crash when cancelling interactions

v2.17:
- removed "no debriefings" (base game already has this option now, since u22)
- removed "transparent pause menu" in favour of related U22 changes
- fixed alignment of the new bars that show picked up items in notifications, when using the pd2 hud layout

v2.16:
- added null checks to prevent crashes with the transparent pause menu feature

v2.15:
- basic fixes for U22

v2.13:
- fixed a bug introduced in 2.11, where revive packs became unusable when tried tp pickup at full health, with the "allow interacting with revive packs when full health but revives below max" option.
- added russian translation by "Hater"

v2.12:
- fix: hudlist now also respects the "hide ui stuff in camp" setting
- fix: interaction lock "progress" mode
- added option: convert weapon ui sizes to meters
- colorize mode is now also applied to outlines

v2.11:
- fix: showing correct gold amounts in Kelly now.
- fix: removed gold rush from partially stealthable list (what was i thinking?)
- hudlist/waypoints: removed "last orders" mines (useless)
- hudlist: combat pickups option converted to multi-select with the option to only show revive-packs (enabled by default)
- hopefully better Colorization Mode naming
- more Custom Waypoints settings
- added revive packs to custom waypoints
- added interaction tweaks:
  - disallow interacting with turrets in stealth (double-tap)
  - allow interacting with revive packs when full health but revives below max
  - disallow interacting with revive packs when revives not below max

v2.09:
- hidden weapon stats rework (added aim-zoom and alert size)
- saving and reapplying all the lobby settings after restarts, also made all those apply instantly, when selected. (difficulty, allow drop-in, permission, etc)
- added permission/drop-in options to the main pause menu when hosting. applies instantly.
- fixed a bug where the game stayed in single-player mode (sp-pause, challenge cards blocked) when joining via the main menu join-online-injection
- added "host" colorization mode, which makes own name labels (and dmg popus in color mode "all") always green, even if client. disabled by default (idea by shinrax, painful implementation by me).

v2.08:
- fixed flak ui bottom alignment in pd2 hud layout
- added complete spanish translation, by SHAD2421
- added missing german translations for latest features

v2.07:
- fixed weapon concealment value not being shown until clicked

v2.06:
- interaction timer: added option to offset centered, moved down a bit by default.
- added option to hide motion dot when shown, disabled by default.
- added option to show weapon concealment in weapons menu. enabled by default.
- added option to show player detection risk in weapons menu. enabled by default.

v2.05:
- hud suspicion: added option to show the pd2 style 'detected' text (default: disabled)
- fixed meta data for the new stealthable icons, reviewed by "Hater"
- fixed bottom alignment for all notification types, when in pd2 layout

v2.04:
- added stealthable mission icons
- added option to change bot amounts

v2.02:
- fixed vanilla teammate panel

v2.01:
- added options to colorize names
- added option to put levels before names
- now aligns killcounters with name, when level is before names
- fixed several alignments in new pd2 layout
- simplified tweak data file

v1.99:
- added pd2 hud layout
- added option to disable toast sound (mission reminder)
- revised gasmasks icon, swapped with flamer icon

v1.98:
- revised config defaults
- auto-reload single-shot weapons
- completed german translation

v1.97:
- added chinese translation by FR0Z3_N3.Borealis

v1.96:
- changed document icons in strongpoint (white/grey symbol) for better distinguishing between outlaw docs (still golden symbol)
- greed caches will now be removed from hudlist/waypoints if looted empty

v1.95:
- added new loot types to hudlist
- renamed portables > heavy objects in options menu
- fixed bot kill counter alignment
- added personal suspicion hud from pd2 & packported numeric option from wolfhud
- general fixes

v1.94:
- added german translation by Shinrax
- fixed damage popup values by Neslon-Poggers

v1.93:
- fixed "straight to main menu" (i hope)
- added option to show actual dogtag counts (enabled by default)
- added version to main menu
- small fix for properly handling changed debriefing default of v1.92

v1.92:
- disabled "straight to main menu" again (no idea yet)
- added option to "streamline" main menu button sizes and their fonts sizes
- added option to add "server" (radio) to the main menu
- config-defaults: re-enabled debriefing videos

v1.91:
- potentially fixed "straight to main menu" (it did not)

v1.9:
- fixed loot/dogtag indicators/counters
- null pointer prevention in kill counter code

v1.8:
- disabled "straight to main menu" for now (U21 broke it, need to wait for lua decomp to fix it)

v1.7:
- added "Custom Waypoints" feature

v1.6:
- updated for Raid-BLT v1.37
- added "Damage popups" feature
- added "FOV based sensivity" feature

v1.5:
- fixed some interaction code (v1.4) regarding vehicles etc.
- added counters for all kinds of loot, pickups and equipment, and even enemy flares

v1.4:
- added "Interaction Lock" features + Interaction timer, Reload, Melee charge etc.

v1.3:
- added "Realistic Reload" feature (turned off by default)
- added "No Debriefing" feature
- completely reworked options menu.. its more like the vanilla menus now

v1.2:
- added "Floating Health Bars" feature
- fixed multi-choice options (like colors) not being set correctly, when changed in menu

v1.1:
- added "Ready on numpad enter" feature
- removed useless "Shoot through bots" feature
- disabled "Auto Apply Weapon Skills" for now, (its too experimental and leads to crashes for now, needs further testing.)
