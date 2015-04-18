--[[
   KahLua KonferPUG - an open roll loot distribution helper for PUGs.
     WWW: http://kahluamod.com/kpug
     SVN: http://kahluamod.com/svn/konferpug
     IRC: #KahLua on irc.freenode.net
     E-mail: cruciformer@gmail.com
   Please refer to the file LICENSE.txt for the Apache License, Version 2.0.

   Copyright 2008-2010 James Kean Johnston. All rights reserved.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
]]

local K = LibStub:GetLibrary("KKore")

if (not K) then
  error ("KahLua KonferPUG: could not find KahLua Kore.", 2)
end

local L = K:RegisterI18NTable("KKonferPUG", "enUS")
if (not L) then
  error ("KahLua KonferPUG: could not initialize I18N.", 2)
end

--
-- NOTE TO PEOPLE LOCALISING THIS FILE:
-- PLEASE BE SURE TO VIEW THE LOCALISATION INSTRUCTIONS FOUND AT
-- http://kahluamod.com/l10n BEFORE STARTING ANY TRANSLATIONS OF
-- THIS FILE. THANK YOU.
--

L["MODTITLE"] = "KonferPUG"
L["MODNAME"] = "konferpug"
L["MODABBREV"] = "KPUG"
L["CMDNAME"] = "kpug"
L["CMD_LOOT"] = "loot"
L["CMD_HISTORY"] = "history"
L["CMD_RAIDERS"] = "raiders"
L["CMD_CONFIG"] = "config"
L["CMD_HELP"] = "help"
L["CMD_VERSION"] = "version"
L["CMD_RESETPOS"] = "resetpos"
L["CMD_SUSPEND"] = "suspend"
L["CMD_RESUME"] = "resume"
L["CMD_ADDLOOT"] = "addloot"
L["CMD_ADDIGNORE"] = "addignore"
L["CMD_ADDDECAY"] = "adddecay"
L["CMD_EDITION"] = "edition"
L["CMD_SHOW"] = "show"
L["CMD_DECAY"] = "decay"
L["CMD_VERSIONCHECK"] = "versioncheck"

--
-- Main localisation strings start here
--

L["AUTOLOOT"] = "This item was won by %s. Press 'Ok' to automatically assign the item to %s. If you press 'Cancel' the item will still be removed from the loot list, and you will need to assign it to %s using the standard user interface."
L["AUTODENCHNR"] = "No-one rolled on the above item. Disenchanter %q is online and in the raid. Press 'Ok' to assign this item to %s. Press 'Cancel' if you want to assign the item manually (the item will be removed from the loot list but not from the corpse or chest)."

L["error: "] = true
L["Open Roll loot distribution helper for PUGs."] = true
L["%s<%s>%s %s (version %d) - %s"] = true
L["/%s [command [arg [arg...]]]"] = true
L["Usage: "] = true
L["  Opens the loot management window."] = true
L["  Opens the user list management window."] = true
L["  Opens the decay list window."] = true
L["  Opens the loot history window."] = true
L["  Suspend %s (no auto-open on loot)."] = true
L["  Resume normal %s operations."] = true
L["  Set up various options."] = true
L["/%s %s [itemid | itemlink]"] = true
L["/%s %s name"] = true
L["  Adds a new item to the loot list."] = true
L["  Adds a new item to the item ignore list."] = true
L["  Adds the specified player to the decay list with a decay count of 1."] = true
L["Player %q not found in the raid."] = true
L["Player %q already in the decay list."] = true
L["%q is not a valid command. Type %s for help."] = true
L["Auto-open Loot Panel When Corpse Looted"] = true
L["Display Tooltips in Loot List"] = true
L["Announce Loot"] = true
L["Enable Chat Message Filter"] = true
L["Roll Timeout"] = true
L["Roll Timeout Extension"] = true
L["Auto-assign Loot When Roll Ends"] = true
L["Assign to Enchanter if no-one rolls"] = true
L["Enable Off-spec Rolls"] = true
L["Loot"] = true
L["Assign Loot"] = true
L["History"] = true
L["Loot History"] = true
L["Raiders"] = true
L["Raider Attributes"] = true
L["Config"] = true
L["Ignored Items"] = true
L["Configure Options"] = true
L["can only add items when in a raid and you are the master looter."] = true
L["item %d is an invalid item."] = true
L["Announce Winners in Raid"] = true
L["Start Roll"] = true
L["End Roll"] = true
L["Pause Roll"] = true
L["Resume"] = true
L["Remove Item"] = true
L["Remove"] = true
L["Switch Spec"] = true
L["[Main Spec]"] = true
L["[Off-spec]"] = true
L["User Role 1"] = true
L["User Role 2"] = true
L["Not Set"] = true
L["Tank"] = true
L["Ranged DPS"] = true
L["Melee DPS"] = true
L["Healer"] = true
L["Spellcaster"] = true
L["User is an Enchanter"] = true
L["Rating"] = true
L["Pro"] = true
L["Good"] = true
L["Average"] = true
L["Poor"] = true
L["Noob"] = true
L["Comments"] = true
L["Update"] = true
L["Delete"] = true
L["Chest"] = true
L["%s: loot from %s: "] = true
L["Roll for %s cancelled!"] = true
L["Roll for %s within %d seconds."] = true
L["Roll for %s."] = true
L["Roll closing in %s"] = true
L["%s: roll closing in: %d"] = true
L["no-one rolled for %s."] = true
L["top main spec rollers: %s"] = true
L["top off-spec rollers: %s"] = true
L["%s: the following users tied with %d: %s. Roll again."] = true
L["%s: sorry you are not allowed to roll right now."] = true
L['%s: type %q for main spec, %q for off-spec or "/roll 1-1" to cancel a roll.'] = true
L['%s: type %q for main spec or "/roll 1-1" to cancel a roll.'] = true
L['%s: invalid roll. Use %q for main spec, %q for off-spec or "/roll 1-1" to cancel a roll.'] = true
L['%s: invalid roll. Use %q for main spec or "/roll 1-1" to cancel a roll.'] = true
L["Announce Countdown"] = true
L["%s: you are not eligible to receive this item - roll ignored."] = true
L["%s: you already rolled %d. New roll ignored."] = true
L["%s: %s (group %d) won %s. Grats!"] = true
L["Note: player will need to pick item up manually."] = true
L["Clear All"] = true
L["Clear all except last week"] = true
L["Clear all except last month"] = true
L["When"] = true
L["What"] = true
L["Who"] = true
L["How"] = true
L["Record Loot Assignment History"] = true
L["Disenchanted"] = true
L["Won Roll"] = true
L["Roll (Main)"] = true
L["Roll (Off)"] = true
L["Main Spec Minimum"] = true
L["Off-spec Minimum"] = true
L["Maximum"] = true
L["invalid main spec roll range (%d > %d)."] = true
L["invalid off-spec roll range (%d > %d)."] = true
L["main spec and off-spec roll ranges cannot be the same."] = true
L['%s: invalid roll. Use %q or "/roll 1-1" to cancel a roll.'] = true
L["Extras"] = true
L["Decay"] = true
L["Enable Roll Decay"] = true
L["Main Spec Decay Amount"] = true
L["Off-spec Decay Amount"] = true
L["Maximum Decay Count"] = true
L["Apply to Main Spec Only"] = true
L["Broadcast"] = true
L["Reset"] = true
L["Down from 5 second mark"] = true
L["At 5 second mark"] = true
L["At 5 and 10 second marks"] = true
L["%s: the following user(s) are roll-decayed:"] = true
L["%s:   %s by %d item(s) (%d)"] = true
L["Enable Countdown Timer"] = true
L["Enable Countdown Extension"] = true
L["Main Spec Roll"] = true
L["Off-spec Roll"] = true
L["your version of %s is out of date. Please update it."] = true
L["%s using version %s"] = true

L["TIP001"] = "Enable this option to have the KPUG loot distribution window open automatically when you loot a corpse that has items that match the master loot threshold."
L["TIP002"] = "Enable the display of the item tooltip when the mouse hovers over an item in the loot distribution list."
L["TIP003"] = "Announce the loot found on a corpse or in a chest in raid chat."
L["TIP004"] = "Enable this option to hide incoming bid whispers and most outgoing whispers and warnings. This reduces the chances you miss real whispers from users during the loot process."
L["TIP005"] = "Set how long to wait for incoming rolls before deciding on a winner. You can pause and finish a roll once it has been started."
L["TIP006"] = "Sets the number of seconds to extend the roll timer by when a roll is received within the last 5 seconds of the countdown."
L["TIP007"] = "Send a message to the raid when a winning bid has been received and the bids close."
L["TIP008"] = "Enable this option to have the loot automatically assigned to the highest roller when the roll timeout expires."
L["TIP009"] = "Enable this option to automatically assign the loot to an enchanter if no-one rolls on the item. You will need to define who is an enchanter in the Raiders tab."
L["TIP010"] = "Start the roll countdown timer during which time users who are interested in the loot can roll on it. A raid warning is issued telling users how to roll for off-spec, how to cancel a roll etc, and how long the countdown is.\n\nIf you have already started a roll then this button will end the roll and award the item to the current highest roller. Use this when you know there will be no more rolls for an item.\n\nIf you Shift-Click this button, it will start an 'Open Roll', where any user can roll, there are no off-spec rolls, and no decay."
L["TIP011"] = "Pause the current roll countdown to give users more time to make up their minds about whether or not they want the item."
L["TIP012"] = "Remove the highlighted item from the loot list. If you have already started the roll process this button will cancel the current roll and forget all current rolls."
L["TIP014"] = "Removes the currently highlighted roll from the roll list."
L["TIP015"] = "Switches the selected roll between main spec and off-spec. Usually done to correct a user's mistake, but they can do it themselves by re-rolling with the correct spec range (1-100 for main spec or 101-200 for off-spec)."
L["TIP016"] = "Mark the user as an enchanter. If no-one rolls on an item, it will be assigned to the first enchanter found in the raid, if any."
L["TIP017"] = "Select the role(s) that a user can fill. This is useful when you are looking for extra people to fill a PUG. Two roles can be defined for each user."
L["TIP018"] = "Rate the performance of this user. This is useful when a user performs particularly well or particularly poorly and you are looking for users to fill a PUG."
L["TIP019"] = "Press this to make these changes to the user attributes permanent. Until you press this no actual changes have been made to the user record."
L["TIP020"] = "Press this button to delete a saved user from the user database. If the user is currently in the raid they will still show up in the raiders list, but their saved information will be removed and when they leave the raid there will be no trace of them."
L["TIP021"] = "Press this button to delete the currently selected item from the ignore list. The next time the item is encountered in a loot list it will now be displayed."
L["TIP022"] = "Select this option to have the countdown to the roll timer expiring sent as warnings to the raid or party. If this is enabled, you can choose whether or not you want just the 5- seconds left warning or if it counts down each of the last 5 seconds."
L["TIP022.1"] = "Display a raid warning for the last 5 seconds of the roll timeout. If the roll timeout is extended due to a late roll, the countdown will be displayed again as soon as the timeout hits 5 seconds."
L["TIP022.2"] = "Display a raid warning as soon as the countdown reaches 5 seconds, but not for each second in the last 5 seconds. This is the default."
L["TIP022.3"] = "Display a raid warning when the countdown timer reaches the 10 second mark, and again when it reaches the 5 second mark. These warnings will be redisplayed if the roll timeout is extended due to a late roll."
L["TIP024"] = "Enable this to have the open roll manager differentiate between main spec (1-100) and off-spec (101-200) rolls. If this is disabled and a user attempts to '/roll 101-200' it will be ignored."
L["TIP025"] = "Clear all loot history. Note this only clears your own local history list, it does not affect the history for any other admins."
L["TIP026"] = "Clear all loot history except loot received in the last 7 days. Note this only clears your own local history list, it does not affect the history for any other admins."
L["TIP027"] = "Clear all loot history except loot received in the last month. Note this only clears your own local history list, it does not affect the history for any other admins."
L["TIP028"] = "Enable decaying rolls. When this is enabled, if a user wins a roll for an item, the maximum value they can roll is reduced by a specified amount. This ensures that no single user can win all (or too many) rolls in a raid. There are several options which control how the decay works that are all enabled when this option is enabled."
L["TIP029"] = "Set the amount that a users maximum roll value is reduced by each time they win a roll."
L["TIP030"] = "Set the maximum number of times a user will have their roll ceiling reduced. Typically 4 is used, and is the default."
L["TIP031"] = "When enabled, only apply roll decay to main spec rolls. When disabled, apply decay to both main spec and off-spec rolls."
L["TIP032"] = "Press this button to broadcast the list of all the users who have been decayed to the raid. This does not broadcast the items, it just broadcasts the decayed users and the amount they are decayed by."
L["TIP033"] = "Press this button to reset the decay data. Usually you do this at the start of a raid or when you start a new instance."
L["TIP034"] = "Increase the user's decay count by 1, up to the maximum decay count"
L["TIP035"] = "Decrease the user's decay count by 1. If this reaches 0, remove the user from the decay list."
L["TIP036"] = "Select this if you want to enable the roll countdown timer. If you prefer to manage how long rolls take manually, deselect this option."
L["TIP037"] = "Select this option if you want to enable the roll timeout extension feature. When enabled, if a new roll is received during the last 5 seconds of the countdown, the timer is extended by the number of seconds specified."

--
-- Shared Konfer dialog. These strings are used by all Konfer addons.
--
L["KONFER_SEL_TITLE"] = "Select Active %s Konfer Module"
L["KONFER_SEL_HEADER"] = "You have multiple %s Konfer modules installed, and more than one of them is active and set to auto-open when you loot a corpse or chest. This can cause conflicts and you need to select which one of the modules should be the active one. All others will be suspended."
L["KONFER_SEL_DDTITLE"] = "Select Module to Make Active"
L["KONFER_ACTIVE"] = "active"
L["KONFER_SUSPENDED"] = "suspended"
L["KONFER_SUSPEND_OTHERS"] = "You have just activated the %s Konfer module above, but other Konfer modules are also currently active. Having multiple Konfer modules active at the same time can cause problems, especially if more than one of them is set to auto-open on loot. It is suggested that you suspend all other Konfer modules. If you would like to do this and make the module above the only active one, press 'Ok' below. If you are certain you want to leave multiple Konfer modules running, press 'Cancel'."
