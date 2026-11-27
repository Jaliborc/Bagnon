# Bagnon Gamepad (WoW Forever)

Controller support for Bagnon on WoW Forever (interface 16001). It is a separate addon: install
the `BagnonGamepad` folder next to `Bagnon` in `Interface/AddOns`. It needs the BagBrother fixes
on the `forever-gamepad` branch of the BagBrother fork (bank panels, combined bag, guild bank).

- The D-pad moves a highlight between item slots and header controls, wrapping within the row.
  A uses, X picks up / places, Y splits a stack, LB/RB switch Bagnon windows. LT/RT switch to the
  vendor, bank, mail or trade window like Forever's own windows.
- Forever's gold arrow and held-item icon follow the selection.
- Buying a bank slot and putting a held item into a bag go through Blizzard's own buttons with
  secure overlays, so the controller UI is not tainted.
- Bagnon's options open through `Settings.OpenToCategory`, so the game opens the panel itself.
  On Bagnon's options pages the D-pad moves its own selection, because Forever's pointer gets
  stuck on addon widgets: A clicks, left/right changes sliders, drop-downs open the picker, and
  the category list is clicked through a secure button.
- The character selector opens a picker (locations, characters, guilds) instead of Blizzard's
  drop-down menu, which would taint the controller UI.
- Money: in the guild bank window A deposits and X withdraws; A on your own gold sets the gold of
  a mail being written or deposits at the guild bank. The D-pad sets the amount. Trade gold can't
  be set by addons (the game forbids it) and stays keyboard and mouse.
- The small windows (split stack, picker, money) use the window's Bagnon skin.
- In combat the controller bindings are released; the bags keep working with the mouse.
- Debug log (Bagnon options > Controller, or `/bagnonpad log`), saved to `BagnonGamepadLog`:
  blocked and forbidden calls with stacks, Lua errors, taint in Forever's controller tables, and a
  trace of Bagnon and Bagnon Gamepad activity with mouse and controller; an optional verbose mode
  adds per-call timing.
