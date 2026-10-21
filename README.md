# LH_MailBags

Version: 1.2.1

LH_MailBags opens your bags when you open the Blizzard mailbox in WoW Forever Beta (Interface 16001). It supports Baganator and the standard Blizzard bags, including combined bags. Closing bags when the mailbox closes is optional and enabled by default.

## Installation

1. Close WoW.
2. Place the `LH_MailBags` folder in your game's `Interface/AddOns` folder. The TOC must be at `Interface/AddOns/LH_MailBags/LH_MailBags.toc`, without an extra nested folder.
3. Restart WoW and enable **LH MailBags**, grouped under **LH Tweaks**, in the addon list. LH_Tweaks must also be installed and enabled.

Baganator is optional. Leave its required dependencies enabled if you use it. Keep Settings.lua and the Media folder when installing. Fully restart WoW after upgrading to 1.2.0 because the TOC loads a new file and adds grouping/icon metadata.

## Graphical settings

Open WoW Settings > AddOns > LH Tweaks > LH MailBags, or type `/lh_mailbags`. The native page contains:

- **Enable mailbox bag automation:** Enable or disable LH_MailBags' opening and closing actions. Enabled by default. Disabling cancels queued actions and leaves current bags alone. Enabling while the mailbox is open opens carried bags.
- **Close bags with the mailbox:** Close bags after the mailbox closes, or keep/reopen them when unchecked. This control is available while automation is enabled; disabling automation preserves its saved value.

Both settings are saved account-wide in the existing `LH_MailBagsDB` table. Blizzard's Defaults for this category restores both settings to enabled. Other LH modules' settings are unaffected. The shared LH icon and native AddOn grouping match the other companion addons.

## Commands and behavior

| Command | Effect |
| --- | --- |
| `/lh_mailbags on` | Enable bag automation (default). Open bags if the mailbox is currently visible. |
| `/lh_mailbags off` | Disable LH_MailBags actions and cancel pending actions. Leave current bags alone. |
| `/lh_mailbags close on` | Close bags when the mailbox closes (default). |
| `/lh_mailbags close off` | Keep bags open after the mailbox closes. |
| `/lh_mailbags` | Open the native LH Tweaks > LH MailBags options page. |
| `/lh_mailbags help` | Show command help. |

Changes to the close preference apply the next time the mailbox closes, without a reload. While automation is enabled, bags that were already open before visiting the mailbox also close when the close preference is enabled. With that preference disabled, carried bags reopen after leaving the mailbox, even if you closed them manually during the visit. This also compensates for Blizzard automatically closing bags; a brief one-frame flicker is possible. With the main switch disabled, LH_MailBags performs neither action; Blizzard and other addons retain their own behavior.

Already open bags are not toggled closed when the mailbox opens. The bank is not opened. The addon does not open mail, collect attachments or send messages.

The existing `closeOnHide` setting is preserved when upgrading, and the new `enabled` flag defaults to true. Native controls and chat commands use the same values. Closing defaults to true when no valid saved preference exists.

## Upgrading from MiniMailBags

Replace the old folder with **LH_MailBags** and restart WoW. Do not enable MiniMailBags or the earlier ForeverMailBags alongside LH_MailBags. Commands now use `/lh_mailbags`; the former `/mmb` and `/fmb` commands are no longer registered.

To retain your setting, close WoW and back up `WTF/Account/<account>/SavedVariables/MiniMailBags.lua`. Copy it to `LH_MailBags.lua` in the same SavedVariables folder, then change `MiniMailBagsDB` to `LH_MailBagsDB` inside the copy. Migrate before first using the renamed addon; do not overwrite an existing `LH_MailBags.lua` containing settings you want to keep. Without migration, closing bags is enabled by default. Use `/lh_mailbags close off` if you prefer to keep them open.

## Baganator support

When Baganator is loaded, the addon uses `Baganator.CallbackRegistry:TriggerEvent("BagShow")` and `"BagHide"` to control its selected bag view. Showing the view refreshes the current character's inventory and does not toggle an already open view closed. Baganator's own mailbox automation can remain enabled.

This integration is implemented directly in LH_MailBags.lua. LH_MailBags does not load or require a separate integration library, LibStub or Syndicator. Baganator's own use of Syndicator belongs to Baganator and is independent of this mailbox integration.

Without Baganator, the addon opens the backpack and carried bags through `OpenBag()` and closes them through `CloseAllBags()`. It respects Blizzard's combined-bag setting. If Baganator is loaded but its callback interface is missing, the addon reports the missing API instead of opening a separate Blizzard view.

The mailbox is discovered on addon loading and login. `OnShow` and `OnHide` hooks follow the visible Blizzard mail window. Actions run through `C_Timer.After(0, ...)` after synchronous Blizzard/Baganator handling; a sequence number discards stale actions during rapid opening and closing. Blizzard functions are not replaced.

## Previous compatibility checks

Version 1.2.1: the Blizzard and Baganator simulations pass with the diagnostic button and command removed. The native page is checked to contain only its section heading and the two checkboxes. All bag behavior, saved preferences and queued-action cancellation regression checks still pass. `git diff --check` passed. On October 21, 2026, the user confirmed that the preceding 1.2.0 integration works in game; the 1.2.1 UI cleanup remains pending in game.

Version 1.2.0: `.settings-test.py` passed Lua 5.1 simulations for both Blizzard bags and Baganator, native module registration, both controls and defaults, saved preferences, command/UI synchronization, deferred show/hide actions, cancellation of pending opens/closes, toggling with the mailbox open, rapid transitions, late mailbox loading, hook deduplication, status output and one-time missing-API warnings. Shared icons were verified byte-for-byte against LH_Tweaks, and `git diff --check` passed. Native rendering and real bag integration remain pending in game. Run `python LH_MailBags/.settings-test.py` from the AddOns folder with Lupa available in `LH_Tweaks/.test-runtime`.

The original 1.1.0 documentation recorded the following checks on October 17, 2026:

- Local WoW Forever Beta installation: version 1.60.1.70450, Interface 16001.
- Baganator 837 integration inspected in `Core/Initialize.lua`, `ViewManagement/Initialize.lua` and `ItemViewCommon/OpenClose.lua`.
- Eighteen Lua simulations passed, covering Baganator show/hide, keeping bags open, existing open views, missing callbacks, partially open Blizzard bags, both closing modes, delayed loading, rapid transitions, saved values, missing APIs and a simplified combined-bag model.
- No in-game test was performed. The referenced public UI source was older than the local build, and the exact UI files for build 70450 were not extracted.

These are historical checks, not new validation of version 1.1.1. Other bag replacements have not been specifically integrated. The diagnostic command and native status button from earlier versions were removed in 1.2.1.

Original reference links:

- [Forever client API reference, build 70170](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/README.md)
- [Blizzard bag functions at the inspected revision](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua)
- [Blizzard mailbox at the same revision](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua)

## In-game checks

1. Open `/lh_mailbags` and enable mailbox bag automation. With Baganator enabled, its bag view should be used; otherwise the standard Blizzard bags should open.
2. Close all bags, then open the mailbox. Bags should appear. Close the mailbox using its close button, Escape and walking away; with `close on`, bags should close.
3. Repeat with bags already open. Opening the mailbox must not toggle them closed. Without Baganator, also try partially open bags and combined bags.
4. Set `/lh_mailbags close off` and repeat. Bags should remain open afterward. Check rapid opening and closing as well.
5. Use `/reload`, then restart WoW, and check both saved settings on the options page.
6. Open `/lh_mailbags` and exercise both checkboxes. Disable automation with the mailbox open and verify that closing it triggers no LH_MailBags action. Reenable it with an open mailbox and verify that bags open. Check saved settings and native Defaults.

For errors, enable `/console scriptErrors 1`, reload, and record the first error. Disable error popups again with `/console scriptErrors 0`. After a beta update, check the current interface number with `/dump select(4, GetBuildInfo())` before changing TOC metadata.

## Uninstallation

With WoW closed, remove `LH_MailBags` from `Interface/AddOns`. Optionally remove its `LH_MailBags.lua` and `LH_MailBags.lua.bak` settings files from `WTF/Account/<account>/SavedVariables`.

## Changelog

### 1.2.1 - 2026-10-21

- Removed the Inspect client and bag integration / Print status control and the diagnostic status command. Retained the one-time warning when a required bag API is missing.
- Documented that Baganator support is already implemented directly in LH_MailBags, with no integration-library addon dependency.

### 1.2.0 - 2026-10-21

- Added native LH MailBags settings under LH Tweaks with a main activation switch, the existing close preference and a status button.
- Added the account-wide `enabled` flag, defaulting to true while retaining existing `closeOnHide` values. Disabling cancels pending actions and suppresses LH_MailBags behavior; enabling with an open mailbox opens bags.
- Added `/lh_mailbags on|off`; the command without arguments now opens the native settings page. Existing close and status commands remain available.
- Added native AddOn list grouping and the shared gold LH icon. Media/Icon.png and Media/Icon.tga are exact copies of LH_Tweaks' artwork, using Spoken's chamfered gold frame as the reference. There is no runtime Spoken dependency.

### 1.1.1 - 2026-10-21

- Renamed MiniMailBags to LH_MailBags, including its folder, Lua/TOC files, metadata, chat prefix and saved-variable table.
- Replaced the old chat commands with `/lh_mailbags`.
- Translated the documentation, comments and chat messages into English.
- Added instructions for transferring the account-wide setting.

## Required core addon

Install and enable **LH_Tweaks** alongside this addon. LH_Tweaks is the shared LiteHawk configuration host and must load first. CurseForge releases must list LH_Tweaks as a required dependency so the client installs it automatically.
