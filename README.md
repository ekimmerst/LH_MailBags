# LH_MailBags

Version: 1.1.1

LH_MailBags opens your bags when you open the Blizzard mailbox in WoW Forever Beta (Interface 16001). It supports Baganator and the standard Blizzard bags, including combined bags. Closing bags when the mailbox closes is optional and enabled by default.

## Installation

1. Close WoW.
2. Place the `LH_MailBags` folder in your game's `Interface/AddOns` folder. The TOC must be at `Interface/AddOns/LH_MailBags/LH_MailBags.toc`, without an extra nested folder.
3. Restart WoW and enable **LH_MailBags** in the addon list.

Baganator is optional. Leave its required dependencies enabled if you use it. LH_MailBags has no libraries or separate configuration window.

## Commands and behavior

| Command | Effect |
| --- | --- |
| `/lh_mailbags close on` | Close bags when the mailbox closes (default). |
| `/lh_mailbags close off` | Keep bags open after the mailbox closes. |
| `/lh_mailbags status` | Show client/build/interface details, API availability, bag view and the saved setting. |
| `/lh_mailbags` | Show help. |

Changes apply the next time the mailbox closes, without a reload. With closing enabled, bags that were already open before visiting the mailbox also close. With closing disabled, carried bags reopen after leaving the mailbox, even if you closed them manually during the visit. This also compensates for Blizzard automatically closing bags; a brief one-frame flicker is possible.

Already open bags are not toggled closed when the mailbox opens. The bank is not opened. The addon does not open mail, collect attachments or send messages.

The `closeOnHide` setting is saved account-wide in `LH_MailBagsDB`. If no valid saved value exists, the `DEFAULT_CLOSE_ON_HIDE` constant in `LH_MailBags.lua` supplies the default.

## Upgrading from MiniMailBags

Replace the old folder with **LH_MailBags** and restart WoW. Do not enable MiniMailBags or the earlier ForeverMailBags alongside LH_MailBags. Commands now use `/lh_mailbags`; the former `/mmb` and `/fmb` commands are no longer registered.

To retain your setting, close WoW and back up `WTF/Account/<account>/SavedVariables/MiniMailBags.lua`. Copy it to `LH_MailBags.lua` in the same SavedVariables folder, then change `MiniMailBagsDB` to `LH_MailBagsDB` inside the copy. Migrate before first using the renamed addon; do not overwrite an existing `LH_MailBags.lua` containing settings you want to keep. Without migration, closing bags is enabled by default. Use `/lh_mailbags close off` if you prefer to keep them open.

## Baganator support

When Baganator is loaded, the addon uses `Baganator.CallbackRegistry:TriggerEvent("BagShow")` and `"BagHide"` to control its selected bag view. Showing the view refreshes the current character's inventory and does not toggle an already open view closed. Baganator's own mailbox automation can remain enabled.

Without Baganator, the addon opens the backpack and carried bags through `OpenBag()` and closes them through `CloseAllBags()`. It respects Blizzard's combined-bag setting. If Baganator is loaded but its callback interface is missing, the addon reports the missing API instead of opening a separate Blizzard view.

The mailbox is discovered on addon loading and login. `OnShow` and `OnHide` hooks follow the visible Blizzard mail window. Actions run through `C_Timer.After(0, ...)` after synchronous Blizzard/Baganator handling; a sequence number discards stale actions during rapid opening and closing. Blizzard functions are not replaced.

## Previous compatibility checks

The original 1.1.0 documentation recorded the following checks on October 17, 2026:

- Local WoW Forever Beta installation: version 1.60.1.70450, Interface 16001.
- Baganator 837 integration inspected in `Core/Initialize.lua`, `ViewManagement/Initialize.lua` and `ItemViewCommon/OpenClose.lua`.
- Eighteen Lua simulations passed, covering Baganator show/hide, keeping bags open, existing open views, missing callbacks, partially open Blizzard bags, both closing modes, delayed loading, rapid transitions, saved values, missing APIs and a simplified combined-bag model.
- No in-game test was performed. The referenced public UI source was older than the local build, and the exact UI files for build 70450 were not extracted.

These are historical checks, not new validation of version 1.1.1. API availability shown by `/lh_mailbags status` confirms that required functions exist; it does not confirm successful operation in game. Other bag replacements have not been specifically integrated.

Original reference links:

- [Forever client API reference, build 70170](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/README.md)
- [Blizzard bag functions at the inspected revision](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua)
- [Blizzard mailbox at the same revision](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua)

## In-game checks

1. Run `/lh_mailbags status`. Before the first mailbox visit, `MailFrame: not loaded yet` is normal. With Baganator enabled, the bag view should be Baganator and the API should be available.
2. Close all bags, then open the mailbox. Bags should appear. Close the mailbox using its close button, Escape and walking away; with `close on`, bags should close.
3. Repeat with bags already open. Opening the mailbox must not toggle them closed. Without Baganator, also try partially open bags and combined bags.
4. Set `/lh_mailbags close off` and repeat. Bags should remain open afterward. Check rapid opening and closing as well.
5. Use `/reload`, then restart WoW, and check the saved setting with `/lh_mailbags status`.

For errors, enable `/console scriptErrors 1`, reload, and record the first error and status output. Disable error popups again with `/console scriptErrors 0`. After a beta update, check the current interface number with `/dump select(4, GetBuildInfo())` before changing TOC metadata.

## Uninstallation

With WoW closed, remove `LH_MailBags` from `Interface/AddOns`. Optionally remove its `LH_MailBags.lua` and `LH_MailBags.lua.bak` settings files from `WTF/Account/<account>/SavedVariables`.

## Changelog

### 1.1.1 - 2026-10-21

- Renamed MiniMailBags to LH_MailBags, including its folder, Lua/TOC files, metadata, chat prefix and saved-variable table.
- Replaced the old chat commands with `/lh_mailbags`.
- Translated the documentation, comments and chat messages into English.
- Added instructions for transferring the account-wide setting.

## Required core addon

Install and enable **LH_Tweaks** alongside this addon. LH_Tweaks is the shared LiteHawk configuration host and must load first. CurseForge releases must list LH_Tweaks as a required dependency so the client installs it automatically.
