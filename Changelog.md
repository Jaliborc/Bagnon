### 11.2.11
* All: Modified BagBrother's item storage format, prioritizing future-proofing it for Blizzard changes on retail.
  * This fixes the recent issues with keystone tooltips.
  * Removed some unecessary data introduced recently by Blizzard.
* Retail: The deposit button toggle button now appears in the settings as intended once again.
* All: Improved the efficiency of tooltip count generation.

### 11.2.10
* Retail: Right-click behaviour at the bank is no longer changed if the bank frame is disabled.
* Retail: Fixed layout positioning issues introduced by the last patch.
* Mists: Updated TOC number.

### 11.2.9
* All: Client-sorting can now sort in reverse!
  * Added option for reverse sorting, both for client-sorting and server-sorting (Blizzard hid this option for no clear reason).
* Fixed issues reported with the new taint-free frame display system:
  * Mists, Retail: Adressed issue that caused the default blizzard code to lag in specific game interactions.
  * Classic, Mists: The default blizzard bags now scale with the UI scaling setting appropriately.

### 11.2.8
* Entirely retooled Bagnon's internal frame display logic, which required an update since the Dragonflight UI rework. You might some notice some differences:
  * The system now runs entirely-taint free, potentially making "Action Blocked" errors less likely to occur.
  * The display events settings now apply to a broader range of NPCs (ex: disabling display at the bank will also disable it at the warbound bank chest).
  * Fixed issues with disabling display events (ex: inability to not show the inventory at the mailbox if the user choses), which could not be fixed in the old system.

### 11.2.7
* Retail: Shift-right click will now fallback to a normal right click when warband bank is not available.
* Classic: Hotfixed error message introduced last version.
* Classic: Improved calculation of keyring size.

### 11.2.6
* Classic: Forcefully disabled right-click item banking features (which only activated on retail anyway), to test potential causes for combat taint blocks.

### 11.2.5
* Retail: Fixed error message that would appear on startup, introduced by last build (ups).
* All: Added slash command which can be used to reset the addon settings and clear the cache.

### 11.2.4
* Classic: Fixed error that would appear when unlocking the keyring on a character for the first time.

### 11.2.3
* All: Now uses the first available filter on login when the "All" tab is disabled.
* Retail: Bank deposit button now appears and behaves as expected again.
* Retail: Bank server-side sorting now behaves as expected again.
* Retail: Money is once again showed correctly within each frame.

### 11.2.2
* Retail: Now gracefully handles Blizzard having deleted a font from the game.

### 11.2.1
* Classic, Mists: fixed issue with right-clicking items introduced in the last update.

## 11.2
* Retail: Updated for patch 11.2.
* Retail: You can once again buy bank bag slots within the addon, without being blocked by the game.
* Mists: Color settings for bag types such as inscription or jewelcrafting are now available.

### 11.1.28
* Moved back to a full addon-based event handling, as Blizzard's event registry is prone to event loss (thank you to the dev community for all the suggestions).

### 11.1.27
* The filters editor help button now directs to a new instructional video (https://youtu.be/sie39ZW8uZo).
* Hotfixed an issue in blizzard's event code.

### 11.1.26
* Fixed issue with item pre-click logic on Mists servers.
* Fixed issue in the guild bank causing the latest transactions in the log to be hidden.
* The guild bank logs are now scrollable.

### 11.1.25
* Bagnon Config now loads apropriately in Mists of Pandaria servers.

### 11.1.24
* Now supports Mists of Pandaria servers.
  * PLease do not submit bugs related to void storage. The blizzard beta servers are acting very weird on the storage, addons or not.
* Updated chinese localization.
* Fixed bug in character favoriting system.

### 11.1.23
* Fixed bug preventing startup of the databroker plugin.
* Guilds are now also stacked into a scrollable submenu when too many are listed (why are some of you on 50 different guilds? explain yourselves!)
* Tagged recently added features with a "NEW" stamp. 

### 11.1.22
* Characters from the current server group are now sorted before others by default.
* Offline view menu rework:
  * You can now favorite characters. Favorited characters take priority over all others.
  * If too many characters are present, additional characters will be shown in a scrollable overflow menu.
  * Design now adapts to each server type.
* Money tooltip now only shows the top 8 characters, and truncates the remainder into a single entry.
* The filters menu now becomes scrollable if many filters are available.
* Now defaults pet rarity to common in offline view if rarity is missing (to prevent bugs).

### 11.1.21
* Fixed bug preventing custom search filters from filtering.
* Added more mechanisms for automatic wipeout of invalid settings/cache structures.
* No longer warns of detected new version on login if the user as since updated.

### 11.1.20
* Updated with workaround to serious flaw within Blizzard's EventRegistry, causing frames to stop updating.

### 11.1.19
* Retail: offline view now shows all warband characters, not just characters in your server group!
* Can now gracefully handle errors in skins.
* Now prevents error caused by bad code in Outfitter Retrofit.
* Fixed error message on startup that would appear if you had disabled item or currency tooltip counts. 
* Added a mechanism to fix old corrupted settings one user reported.

### 11.1.18
* All Bagnon modules are now grouped under BagBrother.
* Fixed visual bug when right-clicking on the Sidebar or the "Bags" button.
* Fixed a bug with moving items while a dynamic ruleset is active.
* New BagBrother icon (by Maxime Playoust, based on Blackmane's work).
* TOC update.

### 11.1.17
* Fixed a bug with bank search.
* Reversed the algorithmic change to frame positioning made last version. The old algorithm turned out superior.
* Tagging release.

### 11.1.16 (beta)
* All: Settings upgrade system can now report errors, while still not interrupting addon loading.
* All: Re-added the missing english localization for slash commands help menu (since when has it been missing?!)
* All: Search custom filters now 100% accurately match using the search bar.
* All: Minor final changes to prepare for Bagnonium release.
* Retail: Updated description to match the new addon list formatting.

### 11.1.15 (beta)
* Large internal restructuring of systems, including new item layout algorithm, to accomodate Bagnonium upcoming release.
* Upgraded to WildAddon-1.1.
* Minor optimizations wherever possible, thanks to the upgrades.
* Version warnings now ignore beta/alpha builds.
* Fixed issue with changing the display event settings.
* Fixed issue with "Bag Break" settings upgrade.
* You can now type uppercase characters in the search bar.

### 11.1.14
* Disabled "Thin" skin (the template it used was removed by Blizzard).
* Minor template changes as part of Bagnonium development.

### 11.1.13
* Updated to new version of the search engine, featuring improvements in logical operators and updates to keywords (like boe, bop, etc).
* Added missing sound design to the side filters.

### 11.1.12
* Fixed typo that could prevent inventory items from being cached.

### 11.1.11
* Fixed issue that could cause duplicate upgrade icons.
* Updated settings upgrade system.

### 11.1.10
* Retail, Classic: Added support to undocumented Blizzard API change.
* Added "Help" button to the filter editor.

### 11.1.9
* Added new "margin" property to skins, allowing for better placement of the side tabs across different skins.
* The "Slot Options" panel now appears again as intended.

### 11.1.8
* Fixed bug with "ignored slot" display.
* Fixed issue with displaying bank bags while the bank frame is disabled.
* Fixed layout issue that could happen when swaping two bags of the same size.

### 11.1.7
* Further fixes into the settings upgrade internal system introduced in 11.1.5.
* Settings upgrade is now done in a "try-catch" manner, making sure the addon will run even if the upgrade fails.

### 11.1.6
* Classic: Fixed bug preventing sorting from starting on the inventory.
* All: Fixed function related with bag display that forgot to update.
* All: Items will now always properly display the locked symbols while in "sorting configuration mode", even if changing characters or moving bags.
* All: Filter editor is now placed appropriately if shown from the inventory.

### 11.1.5
* The side filters now indicate they can be configured with a right-click.
* Sorting no longer starts if the user is viewing offline content.
* Some settings are now always saved per-character/guild:
  * Shown/hidden bags.
  * Locked item slots.
* Note: Bagnon will convert your character's cached data to a new format to support the new per-character settings. In case you lose cached information in the conversion process, visit characters/banks again and it will resolve itself.

### 11.1.4
* Improved compatibility with plugins made for earlier versions of Bagnon.
* Reinstated the old "right-click bags to toggle bank" behaviour, as "focus trade/normal" functionality is no longer needed with the filters update.
* Fixed edge-case issues with updating items when a side tab is selected.
* Improved performance of some side tabs.

### 11.1.3
* Tagging release, with all the new features developed in the beta included moving foward.

### 11.1.2 (beta)
* New features:
  * You can now share and import custom filters.
	* Added the ability to create and edit "Search" filters, on top of the existing "Macro" filters.
	* Filters can be used on all the frames on all game servers, not just Retail.
* Other improvements:
	* Filter configuration is now part of Bagnon_Config, for better loading performance.
  * Frames now take into account their filters when resizing.
  * Updated frame layout logic to ensure money, currency, etc are always at the bottom of the frame.
  * Fixed other edge-case issues with the frame layout logic.
  * The bank deposit button is now enabled by default (was always the intended behaviour).

### 11.1.1 (beta)
* Continuation of the 11.0.27 beta, with the updates from 11.0.28 and 11.1.
* More progress on the bank side filters:
	* The filters in the configuration menu now display icons and are sorted alphabetically.
	* Added "Normal Bags" and "Trade Bags" filters. Updated the icons of some of the existing filters.
  * Fixed bugs when opening the bank, including one that made chat unresponsive.
  * Overall made the Bagnon.Rules API more robust and object-oriented.

## 11.1
* Retail: Updated for the "Undermined" game patch.

### 11.0.28
* All: Added check at startup that upgrades outdated "Bag Break" settings, which could lead to only the first bag being shown.
* Retail: Increased the default number of columns of the bank frame.
* Classic: TOC update.

### 11.0.27 (beta)
* All: Bank is now load on demand (reduces login time).
* Retail: Big progress on the bank side filters:
	* The filters are now configurable - you can toggle and reorder them.
	* You can create and edit your own filters ingame, much alike action bar macros.
	* Expanded on the list of default provided filters. The goal is to eventually match Combuctor.
	* Improved the look and feel of existing filters.
	* Note: sharing/importing filters is not yet implemented.

### 11.0.26
* Retail: Added support for the upcoming addon list native grouping capabilities.

### 11.0.25
* Fixed issue with saving some specific currencies on retail (with help of Mctalian).
  
### 11.0.24
* Reverted to 11.0.21 and updated TOC.

### 11.0.23 (beta)
* Version for Retail only.
* Disabled the example filters for now, to not confuse casual users while the feature is in development.
* Bank is now load on demand.
* Updated TOC.

### 11.0.22 (beta)
* Made progress in development of new item filtering features. Testing of current state would be very welcome!

### 11.0.21
* Retail: Client sorting now supports warband bank.
* All: Added FAQ question on how to quickly deposit items in the warband bank.

### 11.0.20
* Retail: Tooltip item counts now displays the amount of items in the warband bank.
* Retail: No longer caches account-shared currencies, which was unecessary.

### 11.0.19
* Retail: Account-shared currencies do not show currency counters. Conversely, transferable currencies now show account totals on top of per-character amounts.

### 11.0.18
* Retail: The temporary side filters appear again as intended.
* Retail, Cata: Improved uncollected appearance detection.
* Classic, Cata: Fixed issue with tooltip searching for item propriety detection.

### 11.0.17
* All: Implemented sound design missing in UI elements.
* Retail: Shift-right clicking while at the bank will now deposit items in the warband bags.
* Retail: Fixed issue with "Bag Break by Type" that caused warband bags to be separated in some conditions.
	* Thank you to DeVeteran for the large gold donation that made debugging this issue possible.
* Cata, Retail: Fixed an error that would appear when shift-clicking empty slots in the guild bank.
* All: Sorting will now immediately stop if the player leaves the bank, void storage, etc...
* All: Fixed a bug introduced in the last beta that caused frames to behave as if cached when first open.
* All: Fixed a bug introduced in the last beta, which affected Void Storage and Guild Bank.

### 11.0.16
* All: Settings for server sorting are now saved per-frame.
* All: Popup dialogs now play sound effects, appropriate to each dialog.
* All: Minor improvement to sorting options menu.
* Retail: Clicking the deposit button will no longer throw an audio line on characters without a reagent bank.

### 11.0.15
* Retail: Fixed bug with enabling/disabling frames in settings.
* Retail: Updated bank settings to include the new "Deposit Items" button.

### 11.0.14
* All: Fixes two bugs from occurring in inventory and bank.
* Cata, Retail: Fixed a major bug with void storage startup and guild log selection.

### 11.0.13 (beta)
* Retail: Added new deposit items button in the bank.
* All: Changed some internal infrastructure that affects many aspects of the addon, hence the beta for testing.

### 11.0.12
* All: Fixed longstanding bug that sometimes caused offline viewing items to display tinted colors.
* All: Fixed error message that could appear when opening the bank for the first time.
* Retail: Added a subtle default color-tint to warband item slots (configurable).

### 11.0.11
* All: Re-introduced the LibItemCache library as part of the legacy code section to support plugins that still rely on it.

### 11.0.10
* Retail: Warband tabs now have their own slot type.
* Retail: "Break by Type" now separates normal and warband slots, even of the reagent bank is hidden.

### 11.0.9
* All: New version detection now handled by StaleCheck-1.0. 

### 11.0.8
* Retail: Added tabs to focus between player and account bags.
	* This is still a work in progress!
	* These current tabs are provided as a temporary solution until I am ready for a proper release of a tab system (I have been experimenting with systems and designs internally for Bagnonium).
	* Neither the current look nor funtionality of the tabs are final.
	* When a proper system is released, it will be optional and highly configurable - think Combuctor, but smarter.
* All: Fixed error message that could appear at startup on fresh new installs.

### 11.0.7
* Retail: Can once again configure server sorting by right-clicking the bags.
* Retail: Now marks uncollected appearances with unique art, not just purely cosmetic items.

### 11.0.6
* Retail: Can now cache and offline display the Warband bank bags.
* Retail: Can now more accurately detect whether one is able to withdraw/deposit Warband money.
* Retail: Can now tell personal bank bags are offline when using the remote warband bank spell.
* Retail: Fixed issues with display of reagent bank purchase status, both online and offline.

### 11.0.5
* All: Fixed error message that sometimes appeared during search or sorting.

## 11.0.4
* Retail: Added support for Warband Money deposit/withdrawal.
* Retail: Online tooltip count now properly includes the reagent bank.
* Classic: Fixed error message at startup (did nothing bad, but still).

### 11.0.3
* Retail: Started adding support for Warband Bank.
	* This is a work in progress, thought it was important to get a working version in your hands early.
	* The current state is in no way representative of the intended final vision.
	* Editing the bank tabs within Bagnon IS supported! 
	* Local-side sorting is NOT supported yet.
* Retail: Improved server sorting implementation and added warband support.
* All: Added bag break spacing option.
* All: Bag break "By Type" is now the default setting.

### 11.0.2
* Retail: Updated for WoW patch 11.0.2.
* Classic, Cata: Verified support.
* All: Updated TaintLess.

### 11.0.1
* Retail: Polished compatibility with The War Within.

## 11.0.0
* Retail: Now compatible with The War Within!
* Retail: Warband bank support still in the works.

### 10.2.31
* All: The new item glow should no longer appear when using appearance-chaning addons (ex: Masque).

### 10.2.30
* All: Update detection now takes into account reports by other players, which should drastically reduce the need for version broadcast.
* Dragonflight: Updated toc.

### 10.2.29
* All: Updated Portuguese, Spanish and Mandarin localizations.

### 10.2.28
* Cata: Now displays item and currency tooltips properly.
* Cata: Updated popups to support the worsened API, fixing multiple bugs.

### 10.2.26
* Ready for Cataclysm!
* All: Fixed debug code mistakenly left during development that increased version checking rate unecessarily.

### 10.2.25
* All: Added OnePixel skin proposed by the community to the built-in list (optimized and improved).
* All: Fixed issue with some skins preventing clear background colors from being applied.

### 10.2.24
* All: Currenty Tracker can now enter multiline mode to fix niche issue that ocurred when tracking an extremely large amount of currencies.

### 10.2.23
* All: Fixed issue with party version broadcast detected by the community.

### 10.2.22
* All: Fixed issue with ColorPicker detected by the community.

### 10.2.21
* Wrath: Potential bugfix for the guild tab editing functionality.

### 10.2.20
* Retail: Multiple guild bank improvements.
	* You can now edit guild bank tabs icons and names without having to turn Bagnon off.
	* Unlike in the stock UI, you can also edit tab descriptions from the same edit menu. 
	* Redesigned guild bank tabs tooltips - more informative and better readability.
	* Removed the tab info button from the guild bank, as it is now redundant due to the aforementioned changes.
	* Made workaround of a bug in Blizzard API that reports the incorrect number of remaining withdrawals for guild bank tabs.
	* Fixed issue that would cause guild bank not to show up if opened while any but the first tab was selected.  
* Wrath: These changes have not been tested on Classic servers, as I currently don't have access to a guild bank there.

### 10.2.19
* Wrath, Retail: Guild tabs now show their description/notes on mouse-over.
* Wrath, Retail: Guild leaders can now buy new guild tabs.
* All: Updated TOC numbers.

### 10.2.18
* Updated portuguese localization.
* Small tweak to Slot Settings for clarity.
* Retail: Updated Color Picker to support changed API (while retaining classic support)

### 10.2.17
* Fixed issue with the "Character Specific Settings" button.
* Added optional parameters to the skin API to more easily control fonts.

### 10.2.16
* Fixed bug introduced last build that disabled closing bags on ESC.
* Retail: now displays caged battle pets and keystones properly while offline (wasn't supported since the new core).

### 10.2.15
* Updated "guild bank and vault"-only tooltips to the new design.
* Added new optional parameters to the skin API with commonly useful frame modifications.
* Miscellaneous  code improvements and fixes.
* Overall update to the wiki.

### 10.2.14 (beta)
* Reorganized the menu buttons and what actions their perform given the recently added functionalities.
	** IMPORTANT! Some shortcuts, such as opening the bank with right-click, are no longer where they used to be! Please pay attention to the new tooltips.
	** Temporarily highlighted important recent changes and functionalities in the tooltips.
* Comprehensive revamp of tooltip design, including tooltip item counts.

### 10.2.13
* Fixed issue with initializing the sorting configuration mode on some systems.

### 10.2.12
* Hotfixed issue with settings upgrade in previous version.

### 10.2.11
* Added new Skin API and serveral built-in skins.
* Users can now tell who is sending them version update alerts.
* Fixed bug that caused sometimes dropdown menus to have full-screen backdrops.
* Fixed bug causing an error on startup to some users.
* Fixed bug with setting profiles.

### 10.2.10
* New Trade-Skills/Reagents button.
* DataBroker display area now supports _OnDragStart/OnReceiveDrag_ events.
* Increased out-of-version warning cooldown. Can now detect invalid versions as well.
* Fixed issue that caused the sort button to remain highlighted if pressed in an offline panel.
* Retail: Fixed bug with reagent bank purchase dialog (caused by typo in Blizzard code).
* Fixed bug that caused the Bag Break setting to reset to None.
* Fixed bug with linking items in chat from offline windows.

### 10.2.9
* This version is not yet feature-complete for Retail servers and thus only has Classic builds.
* New Feature: You may now lock specific item slots to be ignored during sorting!
* Happy new year!

### 10.2.8
* This version is not yet feature-complete for Retail servers and thus only has Classic builds.
* All: Made the buttons for forgetting character data more interactive and obvious.
* All: Added the new sorting configuration menu with upcoming options.
* All: Updated option headers and added a new question to the FAQ.
* Retail: Local sorting now compatible with inventory and bank.
* Retail: Fixed compartment being sillily attributed to Scrap.

### 10.2.7
* Added ability to break bags by type (credit goes to Alban / Xin4rius).
* Fixed concurrency issue introduced last version that could cause options not to appear.

### 10.2.6
* Retail: Added support to the new native Addon Compartment functionality.
* All: Fixed bug that caused new item highlight not to reset on mousehover.

### 10.2.5
* Now detects and warns user if the addon is out of date.

### 10.2.4
* Help menu improvements:
	* Classic: Made sure help redirects behave the same as in retail.
	* All: Fixed positioning of "Join Us"
	* Added new Q&A about toggling frames.
* Updated spanish locales.
* New terms that were hard-coded are now localizable.
* Fixed missing icon bug.

### 10.2.3
* New Help menu!
* Upgraded to Sushi-3.2:
	* Popup rework, with bugfixes and improved design.
	* Fixed dropdown issue that could create lag, improved design.
	* Function-chaining now possible.
	* Other minor optimizations.

### 10.2.2
* All: Due to a technical difficulty, **10.2** and **10.2.1** were never actually released without my knowledge.
* All: Fixed issue with build system dependency making builds less optimized than they should have been.
* Retail: Updated for new C_AddOns API with backwards support.

### 10.2.1
* All: Currency and sorting now more gracefully handle failed server requests.
* All: Custom Bagnon keybindings now appear in their own category.

## 10.2
* Retail: TOC update.

### 10.1.15
* All: Bagnon sort now clears the cursor before moving items, to prevent issues from the player grabbing an item or something else mid-sort.
* Wrath: TOC update.

### 10.1.14
* All: Fixed local sorting stacking issue.
* All: Fixed offline inventory and bank search.

### 10.1.13
* All: Offline viewing browser design.
	* New dropdown menu.
	* Right-clicking the bag toggle now opens bank.
* Classic: Fixed error message when right-clicking bags.
* All: Fixed issue that caused items to stay darkened after a cooldown.
* All: Default bank bag artwork changed.

### 10.1.12
* All: Fixed issue causing the wrong gender to be shown in the icons of some offline characters.
* All: Fixed bug that caused guild to always be shown as horde.

### 10.1.11
* All: Fixed bugs when shift-clicking items in guild bank or void storage.
* All: Fixed silly bug in French locales.
* Classic: Fixed issue that caused upgrade arrows sometimes not to show up (requires Pawn).

### 10.1.10
* All: Fixed bug with Flash Find.
* All: Redesigned the flash animation itself of Flash Find. Also reduced overall flashing speed to avoid creating negative effects on people vulnerable to intense flashing.
* All: Fixed issue caused by server sending currency update events with missing arguments.
* All: Updated French locales (by edalongeville).

### 10.1.9
* Wrath: Fixed issue with caching the bank on Wrath servers (thank you to wishes90 for finding the cause).
* All: Fixed bug with currency caching for offline viewing.
* All: Overall update to localizations.
* All: Added Dutch locales.

### 10.1.8
* All: New Feature! You can now offline view tracked currencies and amounts throughout characters in tooltips.
* All: Fixed bug that would cause item tooltips to not enable in the settings without a reload.

### 10.1.7
* All: Potentially fixed issue with offline viewing entity sorting that was causing errors at startup to some users.

### 10.1.6
* Vanilla & Wrath: Fixed issues with loading config in modern option panels.

### 10.1.4
* Sorting now running on the new core, which concludes the transition to this new more efficient system.
* Improvements to local sorting:
	* Equipment saved as part of sets is still sorted before the rest of the equipment, but now right before it, without other categories of items inbetween.
	* Fixed issue making sorting not target just the selected guild bank tab.

### 10.1.3
* All: Implemented new recommended style for plugins in the addon list, to help telling plugins from core bagnon modules apart.

### 10.1.2
* Classic: Fixed bug preventing sorting.
* Classic: Fixed bug preventing from opening the bags shelf.
* Dragonflight: Tooltip for empty reagent bag slot now displays properly.
* All: Bag buttons now desaturate when locked as expected.

### 10.1.1
* Dragonflight: Added support for the new addon logos API and multiple-TOC format (no Compartiment support yet).
* Classic and Wrath: Bagnon modules for features that don't exist in classic versions of the game no longer appear in the addon list.
* Wrath: Updated TaintLess (previous version was causing issues on this version of the game).
* All: There is an hidden easter egg included in this version, which will be removed in the close future. So if you want to hunt, hunt it now!

## 10.1
* Dragonflight: Updated for Embers of Neltharion.
* Dragonflight: Can now do search by item level and required level using math operators again.
* Guild and Vault: Fixed issue with their keybindings.
* Still in the process of finishing integration with new core, had to release earlier than desired due to new patch.
* Reverted local sorting to pre-alpha version, as it wasn't ready for release.
* Fixed bug that prevented new players from using the addon.
* Improved behaviour of the sorting button highlight.

### 10.0.19 (closed alpha)
* Vault: Fixed long time unreported issue that the frame would start behaving erratically if closed mid transfer.
* Vault: Fixed issue that would cause vault items to be in the wrong position until one was interacted with.
* Bank and Vault: Fixed issue preventing items from being cached.

### 10.0.18 (closed alpha)
* Reversed mistake made last version that caused new taint.
* _Fallback Hidden Bags_ option now appears to work flawlessly.

### 10.0.17 (closed alpha)
* Testing build featuring the nearly completed new core, which should feature better performance and easier development moving forward.
* Tooltip counts now solely use the new data retrieval API. It should offer significant performance improvement to players with many characters.
* Guild bank sort button now properly highlights when sorting is in process.
* Fixed structural issue that could cause guilds be assigned to the wrong server and cause a multitude of issues.
* Fixed error when trying to open guild bank if not in one.
* Fixed multiple minor void storage and guild bank bugs.
* Reduced taint.

### 10.0.16
* Wrath: Hotfix for blizzard server bugs introduced with Secrets of Ulduar.
* All: New item glow no longer appears on all items for 1 frame the first time the inventory is open.

### 10.0.15
* All: Minor change that might reduce taint.

### 10.0.14
* Retail: Fixed issue preventing disabling backgrounds. Additionally, you can now pick between 3 different designs.
* Fixed issue preventing searching by expansion.
* Fixed issue with changing settings while Scrap is running.
* Fixed issue with color settings.
* Fixed bug in Sushi.Choice.

### 10.0.13
* Fixed unwanted behavior of new item flash.

### 10.0.12
* Dragonflight: Circumvented issue with Dragonflight client that was preventing items from being clicked.
* Updated vault and guild bank search to the new search engine.

### 10.0.11
* Fixed the conflict causing bad performance due to Blizzard's new tooltip hooking API.
* Colorization of quest items while offline is now more consistent with online viewing.
* You can now search items by soulbound status.
* Dragonflight: You can now search items for all manner of stats, Properties, expansion they were released on, etc...
* Technical Details
	* Started core redesign by merging Wildpants with BagBrother.
	* Upgraded to the new LibItemSearch-1.3.
	* Updated C_Everywhere with backwards TooltipInfo support.

### 10.0.10
* Minor item display bugfixes.
* Embedded TaintLess.

### 10.0.9
* Dragonflight: Dragon Isle reagents now show quality icons.
* Refactor and optimization of tooltip and item border display.

### 10.0.8
* Fixed bug introduced last version that screwed up guild and vault tooltips.
* Item tooltip now updates properly when new server data is received.
* Dragonflight: Fixed bug preventing guildbank from being cached.

### 10.0.7
* All: Fixed bug introduced last version that was slowly deleting offline caches. Offline viewing functions again after visiting bank once.
* WoLK, Classic: enchanting now should display item counts properly?
* All: Item tooltips now longer refresh "OnUpdate".
* All: Russian localization updated.

### 10.0.6
* Dragonflight: added guild bank, void storage and bag flags support.
* Dragonflight: caged pet tooltips currently don't show counts.

### 10.0.5 (beta)
* All: New sorting button icon (by Dethmold).
* All: Moving forward will have to depend on BagBrother, makes more sense implementation-wise.
* Dragonflight: Fixed issue with tooltip counts on merchant tooltips.
* Dragonflight: Reagent bags now properly use the reagent slot color.

### 10.0.4 (beta)
* Dragonflight: Main features supported, without removing backwards support. Currently not implemented: the new reagent bag, bag sorting types, guild bank and void storage.

### 10.0.3
* All: Updated Chinese locals
* Dragonflight: Updated for new bag slot IDs
* Dragonflight: Fixed bag slot sorting flag bug

### 10.0.3
* Wrath: Fixed issue with honor points.
* All: Fixed issue if item slot coloring is turned off.

### 10.0.2
* New official logos and presentation, art by Daniel Troko.
* Added support for new item border types (cosmetics, conduits,...).
* Tightened currency display + bugfix.
* Improved Pawn support.
* Tagging release.

### 10.0.1 (beta)
* Fixed some bugs with vault and guild bank.
* Fixed issue with databroker positioning in vault.
* Fixed some technical issues with the configuration menu.

## 10 (beta)
* Near full Dragonflight support (except configuration).
* Largely improved auto frame display features. Auto display settings have been reset to default values.
* Updated Portuguese config locales (by... just me, actually).

### 9.2.4 (beta)
* Basic Drangonflight support:
  * No configuration, guild or vault yet.
  * There are some known issues with the bank.
* Currency tracker:
  * Now supports all game versions, including Dragonflight and Wrath of the Lich King
  * Redesigned to match the layout [chosen by the community](https://www.patreon.com/posts/71748089).
  * Each currency in the tracker can now be interacted with separately.
* Removed behavior that made all slots of guild bank glow when move-hovering a guild bank tab.
* Improved tooltips behavior while interacting with items.

### 9.2.3 (beta)
* All: Added built-in currency tracker demo with basic functionality. [Please vote which design you ](https://www.patreon.com/posts/71748089) prefer.
* All: Changed some default settings to better accommodate modern monitors and currency display.
* All: Fixed minor bug in databroker display.

### 9.2.2
* Classic: Fixed bug introduced last version that only affected classic era servers.

### 9.2.1
* Updated for Wrath of the Lich King

## 9.2
* All: Reverted authenticator slot changes from last version. Behaviour didn't match expected, our apologies.
* TBC: Fixed bug preventing splitting stacks on guild bank.
* Retail: Tagged for 9.2.

### 9.1.6
* All: Fixed issue with authenticator extra slots.
* Retail: Fixed issue with viewing Vulpera's inventory offline.

### 9.1.5
* All: Updated italian locales.
* TBC: Fixed startup issue introduced in the latest patch.

### 9.1.4
* Retail: Updated for Shadowlands 9.1.5.
* All: Removed use of deprecated client APIs.

### 9.1.3
* TBC: Fixed keyring sorting issue.
* All: Further improvement to avoid "Item Cannot go into that Container" errors.

### 9.1.2
* All: Improved handling of simultaneous different bag types during sort to avoid "Item Cannot go into that Container" errors.
* All: Changed default engineering bag color to set it further apart from others.

### 9.1.1
* TBC: Fixed profession items sorting issue.
* TBC: Replaced guild bank icon that isn't available in these servers.
* All: Changed default mining bag color to set it further apart from others.

## 9.1
* Retail: updated for Chains of Domination.

### 9.0.7
* TBC: now compatible.
* All Classic: fixed keyring sorting issue (thanks to jazminite).

### 9.0.6
* Retail: can now sort guild bank tabs.
* Retail: improved search on unorthodox items (ex: pets).
* Retail: added command-line only option to disable server side sorting for inventory (not release quality).

### 9.0.5
* You can now search items by uncollected appearances.
* Equipment set items will be sorted separately from normal equipment.

### 9.0.4
* Now works with latest version of Pawn addon.

### 9.0.3
* Fixed issue with tooltips in profession window.

### 9.0.2
* Retail: fixed issue with junk icons.
* Fixed issue hiding item slots introduced in Shadowlands.
* Fixed visual update issue with bank slots after purchase.

### 9.0.1
* Fixed issue introduced in classic servers.

## 9
* Updated for Shadowlands.

### 8.3.9
* Improved backpack server update performance.

### 8.3.8
* Fixed issue with handling bank events introduced last version.

### 8.3.7
* Improved efficiency in server event handling.
* Fixed issue in new sorting algorithm.

### 8.3.6
* All: sorting efficiency improved (with help by Pierre Sassoulas).
* Retail: corrupted item overlay support (by mCzolko).

### 8.3.5
* All: frame title now disappears during search for increased visibility.
* Retail: fixed search issue with champion/follower equipment.

### 8.3.4
* Retail: fixed issue with some allied race icons.

### 8.3.3
* Retail: fixed tooltip issues with caged pets and keystones.

### 8.3.2
* Retail: fixed multiple loading issues with guild bank.
* All: updated Italian localization (thanks to kikuchi).

### 8.3.1
* Retail: added recent races.
* Retail: fixed issue making dropdowns unclickable.
* Updated Chinese localization (by Adavak).
* Updated Korean localization (by chkid).

## 8.3
* Updated for Visions of Nzoth.
* Made showing a coin icon on poor items optional.
* Removed some forgotten debug code.

### 8.2.29
* Can now change the transparency of frames as before.
* Now, if no plugins like `Bagnon Scrap` are installed, marks sellable gray items with the default junk coin icon.

### 8.2.28
* Now void storage and guild bank properly support _Flash Find_.

### 8.2.27
* Retail: fixed multiple bugs with void storage.
* Classic: hopefully improved key sorting behaviour.

### 8.2.26
* Fixed bug with data-broker display region.
* Added some backwards compatibility for out of date plugins.

### 8.2.25
* Frames now behave properly when pressing `ESC` key.
* Fixed equipment tooltip compare issue.
* Fixed bank main bag tooltip issue.
* Fixed bug with slash command opening interface options.
* Fixed multiple issues with interface options sliders.

### 8.2.24
* Fixed issue on classic characters without keyring.

### 8.2.23
* Fixed mouse-over bug on retail servers.

### 8.2.22
* Fixed display issue with spacing option slider.
* Fixed `UpdateTooltip` error when mouse-hovering items.
* Fixed keyring empty slot count.
* Fixed startup issue on retail.

### 8.2.21
* Added missing appearance options to Frame Settings.
* Tagging release.

### 8.2.20 (beta)
* Fixed all issues with clicking items introduced since 8.2.17.

### 8.2.19 (beta)
* Fixed "blocked action" error when clicking items.
* Inventory now closes when the escape key is pressed, as intended.
* Fixed issue in retail PTR servers.
* Updated classic TOC number.

### 8.2.18 (beta)
* Added keyring.

### 8.2.17 (beta)
* Visible changes
  * New owner selection menu.
  * New frame selection menu.
  * New icons in interface options.
  * Upgraded interface options color picker design.
  * Fixed issue with reappearing inactive widgets on scrollable menus.
* Internal changes
  * Upgraded to Poncho-2.0 and Sushi-3.1.
  * Reorganization of components shared functionality using Poncho-2.0 new features.
  * Massive cleaning and standardizing of code into Ace-like modules using WildAddon-1.0.
  * Moved internally used timer API to new library DelayMutex-1.0.
  * No longer using taintable dropdown or static popup implementations.

### 8.2.16
* Sorting now even faster in most situations.

### 8.2.15
* Sorting now much faster in most situations.

### 8.2.14
* Fixed 2 sorting bugs, causing sorting to stop or enter a loop on very specific conditions on classic servers.
* Fixed issue with some container tooltips.

### 8.2.13
* Fixed issue with Spanish, French, Italian, Portuguese and Russian localization.
* Updated Chinese localization.
* Retail:
  * Fixed issue depositing items in the reagent bank.
  * Fixed rare issue sorting the reagent bank.

### 8.2.12
* Sorting:
  * Button tooltip now shows updated instructions.
  * Now properly sorts void storage items in retail (guild bank will be next).
  * No longer tries to start if in combat, dead, or holding something in the cursor.
  * Automatically stops when entering combat.
  * Fixed issue with enchanting reagents.
* Tooltip Counts:
  * Now properly count items in the 1st bank slot.
* Localization:
  * Changed how tooltip instructions are internally generated.

### 8.2.11 (beta)
* Sorting:
  * Improved sorting criteria.
  * Fixed issue with the bank slot.
  * Fixed issue with some quest items.
  * Sorting button now highlights until the process is done.
* Fixed small visual issue with character select button.
* Internally changed how some tasks are scheduled with new delay API.

### 8.2.10 (beta)
* Can now sort items, even if the server doesn't support it:
  * Bags and bank in classic.
  * Void storage in retail.
* Changed sort button icon.

### 8.2.9
* Fixed issue with button generation on classic servers, preventing frames from being disabled.

### 8.2.8
* Fixed issue with missing texture.
* Finished internal file organization change (make sure to update addon while wow isn't running).

### 8.2.7
* Fixed ordering issue with patron panel.
* Started internal file organization change (make sure to update addon while wow isn't running).

### 8.2.6
* Now character select button shows 3D portrait for current character. Racial and gender based icons remain the same for cached characters.

### 8.2.5
* Fixed bug with herb pouches in classic servers (thank you Denzer - Mirage EU).
* Ammo pouches now colored the same as quivers.
* Added option to color soul bags.

### 8.2.4
* Added option for quiver coloring.
* Fixed issue with loading void storage offline before visiting vendor.
* Fixed error with gem socketing auto display option on classic.

### 8.2.3
* Tagging release.
* Fixed bug in 1st bank slot.

### 8.2.2 (beta)
* Now properly disables vault and guild configuration on classic servers.
* Updated Ace libraries.
* Smarter server type handling.

### 8.2.1 (beta)
* Now compatible with World of Warcraft classic servers.
  * Does not support keyring yet (don't have a character with a key).
* Now using the icons from character creation for player icons.

## 8.2
* Updated for Rise of Aszhara.
* Fixed issue with opening bags in combat.
* Currently "act as standard panel" mode is not implemented. Still trying to figure out if it is possible to do so patch 8.2 onwards.

### 8.1.9
* Fixed issue causing items to not appropriately show their greyed out locked status.

### 8.1.8
* Fixed issue with automatic bank sorting introduced by latest game patch.

### 8.1.7
* Updated for World of Warcraft 8.1.5 patch.

### 8.1.6
* Fixed root cause of "numbered string" internal bug.

### 8.1.5
* Fixed issue with character specific settings.

### 8.1.4
* Hotfix

### 8.1.3
* Fixed another tooltip issue that didn't went trough last version

### 8.1.2
* Fixed issue with non connected reals introduced in 8.1.1
* Fixed issue with splitting item stacks in the guild bank
* Now shows item count tooltips for singleton characters in a server

### 8.1.1
* Now handles server names differently, which should fix server specific issues.
  * You might need to re-login on some characters for their data to show.
* Updated French and Russian localization.
* Fixed issue with bag toggle button.

## 8.1
* Fixed issue preventing Void Storage from working and that could also cause minor guild bank issues.
* Updated for World of Warcraft patch 8.1.

### 8.0.7
* Guild Bank:
  * Fixed bug causing only up to 4 tabs being shown.
  * Fixed issues with non-viewable tabs.
  * Largely improved tab withdraw counter placement and behavior.
  * Redesigned and improved tab tooltips.
  * Tab permissions are now displayed even when not selected (requires caching).

### 8.0.6
* Reversed internal modification that created more issues than it fixed.

### 8.0.5
* Fixed issue with auto display events.
* Added display event for scrapping machines.

### 8.0.4
* Added portrait icons for the remaining 4 allied races. Improved Nightborne and Goblin icons.
* Items now display the azerite and artifact alternative border artwork.
* Can now search for "azerite", "artifact" and "unusable" items. Keywords translated for the different locales.
* Redesigned color options panel.

### 8.0.3
* Added patron list in the configuration options. See patreon.com/jaliborc to learn how to join the list.

### 8.0.2
* Fixed issue with double clicking the title bar.
* Fixed issue with Void Storage.

### 8.0.1
* Reduced tooltip count memory usage by about 80%.
* Fixed issue with updating inventory and bank frames.
* Fixed issue with properly marking the bank frame as "live" (not cached).
* Fixed issue with Aggra server.

## 8
* Updated for Battle for Azeroth.

### 7.3.11 (beta)
* Now handles server names with spaces properly.

### 7.3.10 (beta)
* Now handles the first 4 released allied races properly.

### 7.3.9 (beta)
* Fixed issue on realms that are not connected to other realms.

### 7.3.8 (beta)
* Fixed issue on realms with hyphens on their names that caused other characters not to be browsable.

### 7.3.7 (beta)
* Fixed multiple issues with character specific settings.
* Reset the character specific settings that were screwed up by the previous version.

### 7.3.6 (beta)
* Fixed a bug in the owner list that appeared when _Bagnon_GuildBank_ was disabled.

### 7.3.5 (beta)
* Fixed issue with deleting owner information.
* The money total tooltip now displays player icons just alike the tooltip counts.

### 7.3.4 (beta)
* Fixed an issue when depositing items in the bank.
* Fixed an issue with the _owner_ icon generator.
* Added back _:GetItem_ API function of item buttons for legacy purposes (plugin support).

### 7.3.3 (beta)
* Another major internal update! Completly reworked the internal system for representing item data.
  * The previous system, although more memory efficient, suffered from many problems. It would easly break with updates of the game. It required constant re-specification, making developing and maintaining plugins for other developers much harder.
  * More importantly, the previous system was designed before the advent of Guild Banks. These were considered a set of bags controlled by the player character, which led to a whole set of issues. In the new system, this is no longer the case.
* Visible changes:
  * Guilds are now considered independent entities from player characters, and the Guild Bank is owned by the Guild.
  * Due to the above, issues from having multiple characters on the same guild are now fixed.
  * Guilds your characters belong to are now listed in the _onwer_ selection dropdown. Selecting them will open the Guild Bank of that Guild.
  * Choosing to open the Guild Bank of a player behaves the same as selecting his/hers Guild in the _owner_ selection dropdown.
  * Tooltip counts now display icons for each _owner_, just as in the selection dropdown.

### 7.3.2
* Fixed an issue with the tooltip displaying characters' money.
* The money tooltip now uses the standard money icons (except in colorblind mode).

### 7.3.1
* Fixed sound issues with Guild Bank and void storage frames
* Minor internal optimizations

## 7.3
* Updated for Shadow of Argus

### 7.2.7
* Added option to disable tooltip counts just for Guild Banks
* Frames are no longer click-through
* Internal changes to prevent future issues with internal library (AceEvent)

### 7.2.6
* Updated internal library (AceEvent) that reportedly was causing problems and preventing the program to load for users running other specific addons.

### 7.2.5
* Pressing enter now properly closes the search bars.

### 7.2.4
* Fixed issue causing the search not to start when double clicking the frame titles.
* Hopefully fixed issue causing multiple tries being sometimes required to open/close frames.
* The Frame Layer setting is now working as properly.

### 7.2.3
* Fixed bug preventing separate reagent Bank option from working.
* Pressing escape on a search editbox now properly disables item searching.
* Added a localized thousands separator to money display (large gold amounts are now easier to read).

### 7.2.2
* Guild Bank now fully functional again.
* Clicking on the money display while viewing another character will no longer pick money from your current one.
* Fixed visual issue with right-clicking title to toggle search frame.
* Fixed visual bugs with the money display and character icon when switching characters.
* Fixed long-standing display issue on Guild tabs with unlimited withrawals

### 7.2.1 (beta)
* Void Storage now fully functional again. Next update will bring the Guild Bank back.
* Minor quality of life improvements to some UI elements hitboxes.

## 7.2 (beta)
* Updated for WoW patch 7.2
* Major internal update! The large majority of Bagnon now runs on the same code as Combuctor
  * Added an API for registering item rulesets. Has no visible effect yet.
* Fixed issue with some UI elements in the Bank frame
* New "options" slashcommand

### 7.1.1
* Fixed issue displaying Void Storage tooltips.
* Fixed issue with new build pipeline versioning system.

## 7.1 (beta)
* Updated for WoW patch 7.1.
* Now displays upgrade icons.
* Removed some unused library files from build.

### 7.0.4
* Fixed issue with server names with spaces.
* Fixed issue causing compare tooltips to anchor on the wrong side of the main one.
* Minor bugfix.

### 7.0.3
* Fixed issue with containers inside containers.
* Fixed issue with displaying information about characters on the same server.

### 7.0.2
* Tagging as release.
* Hopefully fixed issue with Guild Bank tabs in Legion (can't test yet).
* Fixed issue with character and realm detection.
* Russian localization updated (thanks to DogmaTX)

### 7.0.1 (beta)
* Hopefully fixed issue with server names like Azjol-Nerub

## 7 (beta)
* Updated for Legion

### 6.2.7
* Fixed bug that caused errors when searching items with a few special characters.
* Added korean localization.
* Minor hotfix.

### 6.2.6
* Fixed bug when moving empty bag to inventory.

### 6.2.5
* Bagnon will now fill existing item stacks in the Bank bags before filling an empty slot in the reagent Bank.
* Localization updates. Thank you Phanx!
* Can now search for "naval" items.

### 6.2.4
* Hotfix.

### 6.2.3
* Workaround issue introduced by Blizzard preventing tooltip counts from displaying on tradeskill windows
* Fixed global leakage
* Minor bugfix

### 6.2.2
* Fixed rare frame display bug

### 6.2.1
* Fixed bug with display blizzard frames option

## 6.2
* Updated for Fury of Hellfire

### 6.1.7
* Fixed issue causing money display to not update when switching characters.
* Improved class color readability in tooltips and menus.
* Fixed minor bug in the Guild log frames.
* Major item draw performance improvement.
* When enabling character specific settings, they are initialized as a copy of the current global settings.

### 6.1.6 (beta)
* Now frame settings can be saved per character or shared between characters, depending on the user preferences.
  * You can choose wether to use the global settings on each different character. Look at the frame settings panel.
  * By default, new characters will use the global options.
  * Characters upgrading from previous versions will have specific settings.
* Fixed item quality search.

### 6.1.5
* Void Storage:
  * Fixed issue affecting some users that caused the frame to require being open twice to appear.
  * Fixed issue causing frame to appear empty on first appearance.
  * Fixed issue preventing control click items to preview them.
* Flipped clean up button behaviour back to what it was before patch 6.1.
* Updated chinese locales.

### 6.1.4
* Fixed issue with the "Display Blizzard Bags" feature.
* Last version appears to be a success. Applied same process to Vault and Guild Bank.
* Fixed an interference issue between Bank, Guild Bank and Vault frames.
* Display options that have no effect in specific frames are no longer displayed.

### 6.1.3
* Attempt to fix the "unresponsive Bank" issue that affects some users.

### 6.1.2
* Fixed issue with Guild Bank repostioning.
* Fixed issue with slot color.

### 6.1.1
* Added option to change frames strata.
* GuildBank and voidstorage are now properly shown in row order.
* Blizzard frames for disabled bags option is now functional.
* Added keybindings and slashcommands for all windows.
* Multiple bugfixes.

## 6.1 (beta)
* This is an experimental version. Use at your own risk. If you find a bug and report it, **please indicate that you are using this version**.
* More major bugfixes.
* Added option to have the reagent Bank separated from the normal Bank bags.
* Bagnon databroker plugin now displays number of free slots in inventory.
* You may now set the transparency of the frames background and borders.

### 6.0.21 (beta)
* This is an experimental version. Use at your own risk. If you find a bug and report it, **please indicate that you are using this version**.
* Fixed major bugs reported so far.
* Added "Reverse Bag Order" option.

### 6.0.20 (beta)
* This is an experimental version. Use at your own risk. If you find a bug and report it, **please indicate that you are using this version**.
* Complete rewrite:
  * While Bagnon might look the same, the great majority of the code has been written from scratch.
  * These changes should provide better performance and make future development and debugging much faster.
  * "Script ran for too Long" errors should become much less frequent.
  * This also increases the amount of code shared between Bagnon and Combuctor, allowing for updates to be easly ported between both addons.
  * Note that there might be bugs on features that were previously working. This will be handled during the next days, as bug reports are received.
* The option menus have been redesigned.
* When offline viewing other character items, frames will now layout the items according to the corresponding character settings.
* Now typing "follower" will browse for follower items on english clients.
* The "use blizzard frames for disabled bags" feature has not been reimplemented in this version. It should be reimplemeted next version.

### 6.0.19
* Swaped behaviour of sort button on Bank.

### 6.0.18
* Fixed issue preventing proper stack splitting on right click.

### 6.0.17
* Minor bug fix.

### 6.0.16
* Fixed issue causing window to behave strangely when clicking on the "loot won" frame.
* Localization update.

### 6.0.15
* Fixed issues with item coloring (ex: highlight item sets not working properly).
* No longer displays warning messages when depositing non-reagents in the Bank or when the reagent Bank is full.
* No longer causes cursor flickering at vendors.
* Small changes to prevent tainting issues and extremely rare loading error occurrences.

### 6.0.14
* Fixed issue preventing character data from being deleted.
* Fixed issue preventing proper searches in Korean clients and possibly other localizations.
* The player dropdown list now displays all your connected realm characters.
  * The new class and race introduced in 6.0.10 should help to keep the list manageable for players with many characters.
  * Tooltips still only display players from the same faction (to keep tooltip sizes manageable) as only BOA accounts are sharable between these characters.
* Fixed issue preventing some servers to be visible in others.

### 6.0.13
* Fixed issue causing Guild Bank tabs sometimes to stay invisible.

### 6.0.12
* Guild Bank hotfix.

### 6.0.11
* Now supports all the Blizzard item sorting features, such as:
  * Ignoring bags for auto sort.
  * Setting bags to a specific type of loot.
* The sort confirmation dialog was removed.
  * To avoid unwanted sorts, the Bank frame now performs a bulk deposit on left click, and a sort on right click.
  * You may also set bags to be ignored for sorting.
* Bags now display the number of empy slots available.
* More minor bugfixes.

### 6.0.10
* Reagents now take priority in going to the reagent Bank before other bag slots when depositing.
* Fixed issue that could be fired when configuring other addons.
* Now the player dropdown list displays class colors and race icons. This should make it much easier to find players in long lists.

### 6.0.9
* Now new item glow flashes for a limited period of time.
  * It remains with a bolder glow than regular items until the bag is closed or the item moused over.
* Now only characters from the same faction as yours will be displayed in the character list.
  * You must login again in your characters so that BagBrother can learn their factions!

### 6.0.8
* Reverse slot ordering option is now working properly.
  * Tip: you can use this option if you prefer to sort items to the bottom of the window instead of the top.
* To avoid sorting bags by accident, now auto sort displays a confirmation dialog before sorting.

### 6.0.7
* Items are no longer marked as new after the bag is closed.
* Made items in void storage movable.
* Tooltips now properly display in the void storage.
* Items in the Bank reagents slot are now properly accounted on item tooltips.

### 6.0.6
* Fixed Guild Bank issues, including long-standing log frame problems.

### 6.0.5
* Fixed issue with Bagnon Facade

### 6.0.4
* Fixed bug causing tooltips not to appear on the reagents Bank slot.
* Fixed issue preventing Bank slots from being purchased.
* Fixed errors with player listing.

### 6.0.3
* Tagging release version.

### 6.0.2 (beta)
* Money frame cannot be disabled in void storage (needed for transfering)

### 6.0.1 (beta)
* Item Sorting:
  * The long awaited feature is finally here! Now there is a new button at the inventory and Bank windows where you can click to automatically sort your items.
  * The button can be disabled at the interface options. But why would you?
* Reagent Bank:
  * You can now right-click on the new sort button do deposit all reagents.
  * Now properly displays whether the reagent Bank has been unlocked when offline browsing.
* Void Storage:
  * Now supports the new void tab!
  * Fixed several issues with the withdraw and deposit interfaces.

## 6 (beta)
* Updated for Warlords of Draenor.
* Now supports the new reagent Bank, which appears as a new bag in the Bank window.
  * To deposit all reagents, click on the reagent Bank icon.
* Now flashes new items, much alike Diablo 3 style.

### 5.4.15
* Fixed issue causing errors when opening the Guild Bank for the first time.

### 5.4.14
* Hopefully solved tainting issues when opening the inventory for the first time in combat.

### 5.4.13 (beta)
* Now can change Guild Bank tabs while in offline mode.
* Guild Bank items now show tooltips in offline mode.

### 5.4.12 (beta)
* Many offline Guild Bank issues solved.

### 5.4.11 (beta)
* Guild Bank bugfixes.

### 5.4.10 (beta)
* Added experimental offline Guild Bank support!

### 5.4.9
* Solved issue affecting some clients with specific system settings.

### 5.4.8
* Solved bug with the layer slider in the Frame Options.
* Solved bugs with connected realms support.

### 5.4.7 (beta)
* Solved several bugs in the Interface Options.

### 5.4.6 (beta)
* Solved bug with money frame.

### 5.4.5 (beta)
* Removed unecessary test files.

### 5.4.4 (beta)
* Now supports connected realms!
* Fixed some issues when using operators with the text search.

### 5.4.3
* Fixed issue causing caged pets quality to not always be properly identified.

### 5.4.2
* Fixed issue causing flash find to not work on all items.

### 5.4.1
* Fixed bug with Guild Bank and void storage.

## 5.4
* Updated for Siege of Ogrimmar.
* Added support for the new in-game store features.

### 5.3.6
* Hotfix of issue on upload system.

### 5.3.5
* Flash Find is back, behaving exacty as on previous patches! Yet, it now uses a different animation system, as the previous one could lead to taints in combat.
* Alt-clicking an item link in the chat now automatically opens the inventory and searches for the selected item.

### 5.3.4
* Updated LibCustomSearch.

### 5.3.3
* Fixed issue with the settings version upgrade system.

### 5.3.2
* Flash Find now behaves like standard text search. Search bars react accordingly.
* Now using LibItemSearch-1.2.
* Fixed bug causing error message on rare login situations.

## 5.3
* Updated for patch Escalation!

### 5.2.5
* Fixed issue causing some cached item icons to not be properly displayed.

### 5.2.4
* Closing the Bank window now properly releases the Banker.

### 5.2.3
* Fixed an issue causing caged pets to not be properly displayed in offline mode.
* Added caged pet tooltip support for the Guild Bank.

### 5.2.2
* Updated chinese translations.

### 5.2.1
* Added option to color items belonging to equipment sets. Packed with ItemRack and Wardrobe support!
  * Idea and initial prototype by Omee - Proudmoore (US).
* Upgraded item search engine.
* Updated italian translations.

## 5.2
* Updated for patch 5.2: The Thunder King

### 5.1.3
* Added italian translations.

### 5.1.2
* Reduced chance of tainting issues with popup dialogs.
* Fixed bug with option to close inventory when leaving vendor.

### 5.1.1
* Added support for cooking bags.

### 5.1.0
* Updated for patch 5.1: Landfall!
* The realm money tooltip now displays class colors.

### 5.0.9
* Quick hotfix.

### 5.0.8
* Bagnon is now fully localized in French (by Noaah) and Russian (by Vgorishny).

### 5.0.7
* Small bug fix.

### 5.0.6
* Fixed bug causing item icons to not always display.

### 5.0.5
* Offline view of caged pets is now supported.
* For now, disabled support for Armory and Baggins caching systems. Very few players use them, were costly yo maintain, and made bug reports harder to decipher.

### 5.0.4
* Fixed bug causing Guild money display to behave incorrectly for users with no withdraw limit.

### 5.0.3
* Fixed bug causing void storage purchase dialog to sometimes show up when vewing void storage offline.
* Fixed error causing "Failed to load void storage items." message to show up.
* Fixed bug causing tooltips to now show for cached void storage items.

### 5.0.2
* Tagging as release.

### 5.0.1 (beta)
* Updated for compatibility with latest Scrap version.

## 5 (beta)
* Updated and tested for Mists of Pandaria.
* Added monk class and pandaren race.
* Bug fixes and internal improvements.

### 4.3.25
* Now it is possible to drag items into the void storage for deposit
* Now tooltip counts track items deposited in the void storage
* Now tooltip counts can be enabled with BagBrother disabled.
* Added option to show inventory while socketing items.

### 4.3.24
* Small bug fix

### 4.3.23
* Chinese translations update

### 4.3.22
* Hacky hotfix of bug caused by unknown reasons

### 4.3.21
* Fixed bug when depositing money on Guild Bank

### 4.3.20
* Added binding to toggle Void Storage
* Fixed bug causing GuildBank money frame to be unresponsive to clicks

### 4.3.19
* VoidStorage and GuildBank hotfixes
* Tagging as release

### 4.3.18 (beta)
* Guild Bank and Void Storage now displays items in the same order as in the default interface
* German and Portuguese localizations update
* Void Storage bugfixes
* Money frame tooltip redesigned

### 4.3.17 (beta)
* Fixed a bug causing weird behavior when the void storage was configured while transferring items.
* Fixed bugs related with the order of items being deposited/withdrawn
* Many GuildBank hotfixes

### 4.3.16 (beta)
* After asking the mafia for money, Bagnon was able to buy a Void Storage support for itself, packed up with offline viewing capabilities.
* Many tweaks and improvements were made to bring you this piece of joy and get the mafia approval.

### 4.3.15 (beta)
* Hotfix

### 4.3.14 (beta)
* Fixed bug causing "quest bangs" to show up at the Guild Bank items
* Fixed bug causing default Guild Bank to show up

### 4.3.13 (beta)
* Prevention of code taint

### 4.3.12 (beta)
* Locked Guild Bank tabs behavior improvements
* Chinese localization update
* Delicious tweaks and goodies

### 4.3.11
* Fixed bug causing tooltip searches to not work properly
* Enabled search tags that were disabled for unknown reasons.

### 4.3.10
* BagBrother no longer disables itself when BagSync or Armory are enabled (could confuse users)

### 4.3.9
* Added Guild Bank german and portuguese translations
* Small money tooltip bug prevention
* Fixed bug causing logs to appear and overlap items on odd situations

### 4.3.8
* German translations updated (thanks to Reinhard Griedelbach)
* Tooltip item count now also displays the sum of all characters on the server
* Tooltip item count syntax improved

### 4.3.7
* Added support for viewing and editing Guild Bank tab information

### 4.3.6
* The ability to hide individual bag slots can now be toggled at the General Options and is disabled by default

### 4.3.5
* Fixed a bug with Flash Find
* Flash Find now also works for cached items

### 4.3.4
* More bug fixing
* Tagging as release

### 4.3.3
* Updated LibItemCache - fixes a bug causing money to not be correctly tracked with BagSync.

### 4.3.2
* Critical bug fix

### 4.3.1
* Updated for WoW 4.3
* Finalized portuguese translations

### 4.2.14
* Fixed a bug causing Bagnon to request already bought bag slots to be purchased over and over
* Fixed bug causing bag slot icons to not show for the first time on cached players
* Fixed bug causing bag items to be incorrectly counted on item tooltips

### 4.2.13
* Jaliborc: Now when opening the Bank window by right clicking in the "bag toggle" button at the inventory one, the selected player will be the same on both
* Jaliborc: Windows no longer change position when viewing other characters items
* Jaliborc: Should have fixed a bug causing BagBrother to loose Bank data on some situations
* Jaliborc: Fixed a bug causing the items in the Guild Bank to show the cool-down of the items in your bags
* Jaliborc: No more "Jaliborc:" tag from now on. If no tag is here, it means it was me.

### 4.2.12
* Jaliborc: Several bug fixes
* Jaliborc: Guild Bank now should work like a charm
* Thank you to thelucid for borrowing me his Guild Bank

### 4.2.11
* Jaliborc: Several bug fixes
* Jaliborc: Started to implement portuguese translations
* Jaliborc: Tweaked Guild Bank log position in the window

### 4.2.10
* Jaliborc: Bagnon_Forever has been replaced by BagBrother, an item cache which will be shared with Combuctor
* Jaliborc: Now comes bundled with LibItemCache, a library that adds support for other item caches, such as BagSync and Armory
* Jaliborc: With the new cache approach, Bagnon_Tooltips is no more. Now you can toggle the feature at the Interface Options.
* Jaliborc: The character selector now changes depending on the selected character and has much better icons
* Jaliborc: BagnonFacade now should work properly with the Guild Bank
* Jaliborc: The tooltip item count is now colored by class
* Jaliborc: Updated LibIemCache, providing many improvements in the search syntax

### 4.2.9
* Jaliborc: Fixed a bug with the Traditional Chinese translations

### 4.2.8
* Jaliborc: Tackle boxes can now be colored separately
* Jaliborc: Updated Traditional Chinese translations (thank you Seraveegd@鬼霧峰)

### 4.2.7
* Jaliborc: Buttonfacade support has been removed and is now available as a separate plug-in - [[http://wow.curse.com/downloads/wow-addons/details/bagnon-facade.aspx|Bagnon Facade]]
* Jaliborc: Each type of trade bag can now be colored separately
* Jaliborc: Reduced download size by about 70%

### 4.2.6a
* Jaliborc: Zip file appears to have been corrupted by unknown reason. New attempt to upload.

### 4.2.6
* Jaliborc: Fixed a bug causing ButtonFacade settings to not be properly loaded

### 4.2.5
* Jaliborc: Fixed bug when clicking the money frame
* Jaliborc: Hearthstones should not have tooltip counts... again
* Jaliborc: Fixed undead portrait.. again
* Jaliborc: Fixed a bug causing Bagnon_Forever data to reset when updating

### 4.2.4
* Jaliborc: Fixed a bug causing some options to not show up in the config menu
* Jaliborc: The bags toggle button now shows the Bank window on right-click

### 4.2.3
* Jaliborc: ButtonFacade support improvements and bugfixing

### 4.2.2
* Jaliborc: Added ButtonFacade support

### 4.2.1
* Tuller: Fixed a bug causing the lock checkbox to not show up in the config menu

## 4.2
* Jaliborc: Removed keyring code, since the keyring is gone with WoW 4.2
* Jaliborc: Implemented options for hiding frames when entering combat/entering a vehicle.

### 4.1.1
* Tuller: Fixed missing undead portraits.

## 4.1
* Tuller: Hearthstones should now no longer have tooltip counts.

### 2.19.2
* Tuller: Updated TOC reference to LibItemSearch to make it load on demand properly

### 2.19.1
* Tuller: Updated LibItemSearch to fix searching for bind on account items

## 2.19
* Jaliborc: Added unsuable item highlighting as an option.

## 2.18
* Tuller: Updated TOC for 4.1

## 2.17
* Jaliborc: Added log views to the GuildBank
* Tuller: Fixed tackle box highlighting
* Tuller: Added some basic compatibility code for 4.1

### 2.16.1
* Added Bagnon_GuildBank back, in a disabled state
* Fixed the quest item issue in the Guild Bank module
* Adjusted the money frame default for the Guild Bank from disabled to enabled
* Adjusted the text for the auto vendor display option to better reflect what it actually does
* Fixed tackle box coloring
* Removed some lingering ammo/soul shard detection code

## 2.16
* 4.0.6 fixes

### 2.15.2
* Altered portrait display so that it should now work for Worgen/Goblins

### 2.15.1
* Added flash find options
* Removed ammo + shard color options, since they have no use anymore.

## 2.15
* Added FlashBind - Alt-Click a link or item to highlight it in your inventory (thanks Rueben)

### 2.14.0b
* Added back missing Bagnon_Forever + Tooltips

## 2.14
* First Cataclysm beta

### 2.13.3
* Updated localization

### 2.13.2b
* Bagnon for WoW 3.3.3, without the Guild Bank

### 2.13.2
* Fixed a typo that resulted in a redbox error when hovering over the Guild Bank money frame.

### 2.13.1
* Maybe if I enable right clicks on the Guild Bank money frame, you'll be able to withdraw via right click :P

## 2.13
* Implemented support for Blizzard's quest item highlighting in WoW 3.3.3

### 2.12.6
* Updated LibItemSearch, adding wardrobe support.
* Added a potential bugfix for the nil frame settings issue.

### 2.12.5b
* Added missing externals.

### 2.12.5
* Put a fix in for the withdraw bug.

### 2.12.4
* Initial Guild Bank support implemented.  Things not supported at the moment: Guild master management & offline viewing.

### 2.12.3
* Removed Bagnon_GuildBank.  I did not intend on including it quite yet, but my build process did :P

### 2.12.2
* Updated TOC for 3.3

### 2.12.1
* Added comparison operators to item level and quality searches (you can now do things like q>=rare, q!=0, etc)
* Added itemlevel searching: ilvl<op><number> (ex, ilvl>200 or ilvl:200)

## 2.12
* Added new options for item slot colors and item border brightness

## 2.11
* Added a new option to automatically display your inventory when opening the player frame
* Added a new frame specific option: Enable bag break layout
* Fixed a bug causing quest item highlighting to not work properly for non English locales

## 2.10
* Added support for equipment set searching via s:<setName>
* Made it easier for me to define new typed searches via Bagnon.ItemSearch.RegisterTypedSearch(typedSearchObj)

### 2.9.3
* Updated for 3.2
* Disabled search text syncing to prevent issues with Chinese clients

### 2.9.2
* Fixed a bug causing the options menu to show up when displaying the world map

### 2.9.1
* Added a new modifier to search by name:  n:search.  For example, typing "n:pants" will find all items named "pants"
* A search without modifiers, ex "gem" will now perform a smart search, like in 1.x versions of Bagnon.  For example, typing "gem" will now find items of type "gem" as  well as items named "gem"

## 2.9.0
* Added a keyring bag back to the inventory's bag frame.  Its hidden by default.
* Keyring slots are now colored
* Made text searching global
* Made the text search box close when the enter key is pressed
* The searching with uppercase text bug should now be fixed.

### 2.8.1
* Localization bugfix

## 2.8
* Added a new option to disable the options toggle button
* Adjusted a few default settings for the automatic display of the inventory frame
* Adjusted priority of quest highlighting so that Uncommon+ items are not marked as quest items
* Updated localization

## 2.7
* Added new frame strata options: MEDIUMLOW, MEDIUMHIGH.  These are equivalent to Low + Toplevel and Medium + Toplevel
* Added new option: Display Blizzard bag frames for disabled bags.
* Added the ability to right click the title frame to display the options menu.

### 2.6.3
* Fixed a bug causing it to not be possible to disable auto display settings
* Fixed a bug causing it to not be possible to search on other characters/your Bank when not at the Bank
* Fixed a bug with hiding the default Bank frame
* Made the general options panel a sub panel of the main Bagnon panel. This should hopefully make it easier to spot when configuring frames.

### 2.6.2
* Added a bugfix to the default settings clearing code

### 2.6.1
* Miscellaneous bug fixes
* Updated localization

### 2.6.0
* Added a new options panel to configure automatic display settings for the inventory frame
* More performance optimizations to the item frame
* More bug fixes to the item frame

### 2.5.2
* Added an assertion to catch the nil slot issue, if it exists.
* Fixed a bug with item frame event registering causing items to appear to not move, etc
* Updated localization

### 2.5.1
* Added some bugfixes to item event handling
* Added some bugfixes to broker tooltip handling
* Updated localization

## 2.5
* Moved item slot event handling to the item frame.
* Fixed a display issue with the player selector for undead characters
* Added in settings to disable the inventory, Bank and keyring frames
* Fixed some bugs related to saving and loading default settings
* Updated localization

### 2.4.1
* Fixed a redbox error from hiding a frame when viewing another character

## 2.4
* Fixed a bug with frame/border coloring
* The player filter will now reset to the current player when a frame is closed
* Made reverse bag slot ordering a per frame setting, instead of a global one
* Added per frame option: Enable bag frame (disabled for the keyring for semi obvious reasons)
* Added per frame option: Enable money frame
* Added per frame option: Enable databroker frame
* Added per frame option: Enable search frame toggle button

### 2.3.1
* Implemented a fix that should resolve the wacky frame position thing
* Implemented a fix that should resolve the "for limit must be a number" bug
* Updated localization
* Added per frame option: Frame Layer - Controls frames appearing above or below other frames.

## 2.3
* Rewrote saved settings back end to make it easier for me to adjust defaults.  Your settings have been reset.
* Frame settings are now saved on per character basis
* Global settings (stuff on the main options panel) are saved globally.
* Adjusted a few default settings (frame border color, frame position)

### 2.2.1
* Updated localization
* Added option: highlight item slots by bag type
* Fixed a frame display bug when closing frames via pressing escape
* You can now double click to search once again.

## 2.2
* Added option: show empty item slot textures
* Added option: highlight items by quality
* Added option: highlight quest items
* Added option: reverse item slot ordering
* Added option: lock frame positions
* Added a databroker launcher for Bagnon
* Fixed a few bugs related to the databroker plugin

## 2.1
* Started implementaton of the new options menu. Added options for color, border color, columns, spacing, opacity, and scale.
* Added new slash command, /bgn options
* Added a button to all frames as a shortcut to the options menu
* I'm calling this version a beta, since I want more feedback.

### 2.0.3
* Reimplemented slash commands: /bgn|/bagnon Bank, /bgn bags, /bgn keys, and /bgn version

### 2.0.2
* Fixed Bank frame tool tips
* Fixed quality display for certain items
* Removed a file that was not being called anymore.

### 2.0.1
* Fixed Bank frame closing
* Fixed an error when hovering over a Bank item when at the Bank
* Fixed an error when clicking on a databroker object with no click event
* Added sounds when opening/closing frames.
