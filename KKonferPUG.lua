--[[
   KahLua KonferPUG - an open roll loot distribution helper for PUGs.
     WWW: http://kahluamod.com/kpug
     SVN: http://kahluamod.com/svn/konferpug
     IRC: #KahLua on irc.freenode.net
     E-mail: cruciformer@gmail.com
   Please refer to the file LICENSE.txt for the Apache License, Version 2.0.

   Copyright 2008-2017 James Kean Johnston. All rights reserved.

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

local MAJOR= "KKonferPUG"
local MINOR = tonumber ("@revision@")
local MINOR = 1 -- @debug-delete@
local K,KM = LibStub:GetLibrary("KKore")
local DB = LibStub:GetLibrary("KKoreDB")
local KUI = LibStub:GetLibrary("KKoreUI")

if (not K) then
  error ("KahLua KonferPUG: could not find KahLua Kore.", 2)
end

if (tonumber(KM) < 731) then
  error ("KahLua KonferPUG: outdated KahLua Kore. Please update all KahLua addons.")
end

if (not KUI) then
  error ("KahLua KonferPUG: could not find KahLua Kore UI library.", 2)
end

local L = K:GetI18NTable("KKonferPUG", false)

kpg = K:NewAddon(nil, MAJOR, MINOR, L["Open Roll loot distribution helper for PUGs."], L["MODNAME"], L["CMDNAME"], "kpg" )
if (not kpg) then
  error ("KahLua KonferPUG: addon creation failed.")
end

kpg.version = MINOR
kpg.protocol = 1        -- Protocol version
kpg.dbversion = 4
kpg.L = L
kpg.CHAT_MSG_PREFIX = "KPG"
kpg.initialised = false

kpg.KUI = KUI
local MakeFrame = KUI.MakeFrame

-- Local aliases for global or Lua library functions
local _G = _G
local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort
local setmetatable = setmetatable
local tconcat = table.concat
local tostring = tostring
local GetTime = GetTime
local min = math.min
local max = math.max
local strfmt = string.format
local strsub = string.sub
local strlen = string.len
local strfind = string.find
local strlower = string.lower
local gmatch = string.gmatch
local match = string.match
local xpcall, pcall = xpcall, pcall
local pairs, next, type = pairs, next, type
local select, assert, loadstring = select, assert, loadstring
local printf = K.printf

local admin_hooks_registered = nil
local ml_hooks_registered = nil
local chat_filters_installed = nil

kpg.LOOT_TAB = 1
kpg.HISTORY_TAB = 2
kpg.RAIDERS_TAB = 3
kpg.CONFIG_TAB = 4
kpg.DECAY_TAB = 5
kpg.MAIN_CONFIG_TAB = 1
kpg.EXTRAS_CONFIG_TAB = 2
kpg.LOOT_IGNORE_TAB = 3

local ucolor = K.ucolor
local ecolor = K.ecolor
local icolor = K.icolor

local function debug(lvl,...)
  K.debug(L["MODNAME"], lvl, ...)
end

local function err(msg, ...)
  local str = L["MODTITLE"] .. " " .. L["error: "] .. strfmt(msg, ...)
  K.printf (K.ecolor, "%s", str)
end

local function info(msg, ...)
  local str = L["MODTITLE"] .. ": " .. strfmt(msg, ...)
  K.printf (K.icolor, "%s", str)
end

kpg.debug = debug
kpg.err = err
kpg.info = info

_G["KKonfer"] = _G["KKonfer"] or {}
local KKonfer = _G["KKonfer"]
KKonfer["..."] = KKonfer["..."] or {}

local me = KKonfer["kpg"] or {}
KKonfer["kpg"] = me
me.modname = L["MODNAME"]
me.modtitle = L["MODTITLE"]
me.desc = L["Open Roll loot distribution helper for PUGs."]
me.cmdname = L["CMDNAME"]
me.version = MINOR
me.suspendcmd = L["CMD_SUSPEND"]
me.resumecmd = L["CMD_RESUME"]
me.IsSuspended = function () return kpg.suspended or false end
me.SetSuspended = function (onoff)
  kpg.suspended = onoff or nil
  kpg.frdb.suspended = kpg.suspended
  local ds = L["KONFER_SUSPENDED"]
  if (not kpg.suspended) then
    kpg:FullRefresh (true)
    ds = L["KONFER_ACTIVE"]
    kpg:CheckForOtherKonferMods ( strfmt ("%s (v%s) - %s", me.modtitle,
      me.version, me.desc))
  end
  K.printf (K.icolor, "%s: |cffffffff%s|r.", L["MODTITLE"], ds)
end
me.OpenOnLoot = function ()
  if (kpg.frdb and kpg.frdb.auto_open) then
    return true
  end
  return false
end
me.raid = true
me.party = true

local function create_konfer_dialogs ()
  local kchoice = KKonfer["..."]
  assert (kchoice)
  KKonfer["..."] = kchoice
  local ks = "|cffff2222<" .. K.KAHLUA ..">|r"

  local arg = {
    x = "CENTER", y = "MIDDLE", name = "KKonferModuleSelector",
    title = strfmt (L["KONFER_SEL_TITLE"], ks),
    canmove = true,
    canresize = false,
    escclose = true,
    xbutton = false,
    width = 450,
    height = 180,
    framelevel = 64,
    titlewidth = 300,
    border = true,
  }
  kchoice.seldialog = KUI:CreateDialogFrame (arg)

  arg = {
    x = "CENTER", y = 0, width = 400, height = 96, autosize = false,
    font = "GameFontNormal",
    text = strfmt (L["KONFER_SEL_HEADER"], ks),
  }
  kchoice.seldialog.header = KUI:CreateStringLabel (arg, kchoice.seldialog)

  arg = {
    name = "KKonferModSelDD",
    x = 35, y = -105, dwidth = 350, justifyh = "CENTER",
    mode = "SINGLE", itemheight = 16, items = KUI.emptydropdown,
  }
  kchoice.seldialog.seldd = KUI:CreateDropDown (arg, kchoice.seldialog)
  kchoice.seldialog.seldd:Catch ("OnValueChanged", function (this, evt, val, usr)
    if (not usr) then
      return
    end
    local kkonfer = _G["KKonfer"]
    assert (kkonfer)
    for k,v in pairs (kkonfer) do
      if (k ~= "..." and k ~= val) then
        v.SetSuspended (true)
      end
    end
    kkonfer[val].SetSuspended (false)
    kkonfer["..."].seldialog:Hide ()
  end)

  kchoice.seldialog.RefreshList = function (party, raid)
    local kkonfer = _G["KKonfer"] or {}
    local items = {}
    local kd = kkonfer["..."].seldialog.seldd

    tinsert (items, {
      text = L["KONFER_SEL_DDTITLE"], value = "", title = true,
    })
    for k,v in pairs (kkonfer) do
      if (k ~= "...") then
        if ((party and v.party) or (raid and v.raid)) then
          local item = {
            text = strfmt ("%s (v%s) - %s", v.modtitle, v.version,
              v.desc),
            value = k, checked = false,
          }
          tinsert (items, item)
        end
      end
    end
    kd:UpdateItems (items)
    kd:SetValue ("", true)
  end

  arg = {
    x = "CENTER", y = "MIDDLE", name = "KKonferModuleDisable",
    title = strfmt (L["KONFER_SEL_TITLE"], ks),
    canmove = true,
    canresize = false,
    escclose = false,
    xbutton = false,
    width = 450,
    height = 240,
    framelevel = 64,
    titlewidth = 300,
    border = true,
    okbutton = {},
    cancelbutton = {},
  }
  kchoice.actdialog = KUI:CreateDialogFrame (arg)
  kchoice.actdialog:Catch ("OnAccept", function (this, evt)
    for k,v in pairs (KKonfer) do
      if (k ~= "..." and k ~= this.mod) then
        v.SetSuspended (true)
      end
    end
  end)

  arg = {
    x = "CENTER", y = 0, autosize = false, border = true,
    width = 400, font = "GameFontHighlight", justifyh = "CENTER",
  }
  kchoice.actdialog.which = KUI:CreateStringLabel (arg, kchoice.actdialog)

  arg = {
    x = "CENTER", y = -20, width = 400, height = 112, autosize = false,
    font = "GameFontNormal",
    text = strfmt (L["KONFER_SUSPEND_OTHERS"], ks),
  }
  kchoice.actdialog.msg = KUI:CreateStringLabel (arg, kchoice.actdialog)
end

local function check_for_other_konfer (sel)
  local kchoice = KKonfer["..."]
  assert (kchoice)

  if (not sel and kchoice.selected and kchoice.selected ~= "kpg") then
    me.SetSuspended (true)
    return
  end

  local nactive = 0

  for k,v in pairs (KKonfer) do
    if (k ~= "...") then
      if (not v.IsSuspended ()) then
        if (v.raid and v.OpenOnLoot ()) then
          nactive = nactive + 1
        end
      end
    end
  end

  if (nactive <= 1) then
    return
  end

  --
  -- We have more than one KahLua Konfer module that is active for raids
  -- and set to auto-open on loot. We need to select which one is going to
  -- be the active one. Pop up the Konfer selection dialog.
  --
  if (not kchoice.seldialog) then
    create_konfer_dialogs ()
  end
  if (sel) then
    kchoice.actdialog.which:SetText (sel)
    kchoice.actdialog.mod = "kpg"
    kchoice.seldialog:Hide ()
    kchoice.actdialog:Show ()
  else
    kchoice.seldialog.RefreshList (me.party, me.raid)
    kchoice.actdialog:Hide ()
    kchoice.seldialog:Show ()
  end
end

function kpg:CheckForOtherKonferMods (nm)
  check_for_other_konfer (nm)
end

kpg.white = function (str)
  return "|cffffffff" .. str .. "|r"
end

kpg.class = function (str, class)
  local nm = str
  if (type(str) == "table") then
    nm = str.name
    class = str.class
  end
  if (kpg.inraid and not kpg.raid.raiders[nm]) then
    return K.ClassColorsEsc2[class or "??"] .. nm .. "|r"
  end
  return K.ClassColorsEsc[class or "??"] .. nm .. "|r"
end

local white = kpg.white
local class = kpg.class

kpg.rolenames = kpg.rolenames or {}
kpg.rolenames[0] = L["Not Set"]
kpg.rolenames[1] = L["Healer"]
kpg.rolenames[2] = L["Melee DPS"]
kpg.rolenames[3] = L["Ranged DPS"]
kpg.rolenames[4] = L["Spellcaster"]
kpg.rolenames[5] = L["Tank"]

function kpg:TimeStamp ()
  local _, mo, dy, yr = CalendarGetDate ()
  local hh, mm = GetGameTime ()
  return strfmt ("%04d%02d%02d%02d%02d", yr, mo, dy, hh, mm), yr, mo, dy, hh, mm
end

kpg.defaults = {
  auto_open = true,
  display_tooltips = true,
  announce_loot = true,
  auto_loot = true,
  disenchant = true,
  chat_filter = true,
  use_timeout = true,
  roll_timeout = 10,
  use_extend = true,
  roll_extend = 5,
  announce_winners = true,
  announce_countdown = true,
  announce_how = 2,
  offspec_rolls = true,
  record_history = true,
  main_spec_min = 1,
  main_spec_max = 100,
  off_spec_min = 101,
  off_spec_max = 200,
  enable_decay = false,
  main_decay = 10,
  main_max = 4,
  off_decay = 10,
  off_max = 4,
}

local function kpg_version ()
  printf (ucolor, L["%s<%s>%s %s (version %d) - %s"],
    "|cffff2222", K.KAHLUA, "|r", L["MODTITLE"], MINOR,
    L["Open Roll loot distribution helper for PUGs."])
end

local function kpg_usage ()
  kpg_version ()
  printf (ucolor, L["Usage: "] .. white(strfmt(L["/%s [command [arg [arg...]]]"], L["CMDNAME"])))
    printf (ucolor, white(strfmt("/%s %s", L["CMDNAME"], L["CMD_CONFIG"])))
    printf (ucolor, L["  Set up various options."])

    printf (ucolor, white(strfmt("/%s %s", L["CMDNAME"], L["CMD_LOOT"])))
    printf (ucolor, L["  Opens the loot management window."])

    printf (ucolor, white(strfmt("/%s %s", L["CMDNAME"], L["CMD_HISTORY"])))
    printf (ucolor, L["  Opens the loot history window."])

    printf (ucolor, white(strfmt("/%s %s", L["CMDNAME"], L["CMD_RAIDERS"])))
    printf (ucolor, L["  Opens the user list management window."])

    printf (ucolor, white(strfmt("/%s %s", L["CMDNAME"], L["CMD_DECAY"])))
    printf (ucolor, L["  Opens the decay list window."])

    printf (ucolor, white(strfmt("/%s %s", L["CMDNAME"], L["CMD_SUSPEND"])))
    printf (ucolor, strfmt (L["  Suspend %s (no auto-open on loot)."], L["MODTITLE"]))

    printf (ucolor, white(strfmt("/%s %s", L["CMDNAME"], L["CMD_RESUME"])))
    printf (ucolor, strfmt (L["  Resume normal %s operations."], L["MODTITLE"]))

    printf (ucolor,white(strfmt(L["/%s %s [itemid | itemlink]"], L["CMDNAME"], L["CMD_ADDLOOT"])))
    printf (ucolor,L["  Adds a new item to the loot list."])

    printf (ucolor,white(strfmt(L["/%s %s [itemid | itemlink]"], L["CMDNAME"], L["CMD_ADDIGNORE"])))
    printf (ucolor,L["  Adds a new item to the item ignore list."])

    printf (ucolor,white(strfmt(L["/%s %s name"], L["CMDNAME"], L["CMD_ADDDECAY"])))
    printf (ucolor,L["  Adds the specified player to the decay list with a decay count of 1."])
end

local function kpg_config(input)
  kpg.mainwin:Show ()
  kpg.mainwin:SetTab (kpg.CONFIG_TAB, kpg.MAIN_CONFIG_TAB)
end

local function kpg_main()
  kpg.mainwin:Show ()
  kpg.mainwin:SetTab (kpg.LOOT_TAB, nil)
end

local function kpg_raiders()
  kpg:RefreshRaiders ()
  kpg.mainwin:Show ()
  kpg.mainwin:SetTab (kpg.RAIDERS_TAB, nil)
end

local function kpg_history()
  kpg.mainwin:Show ()
  kpg.mainwin:SetTab (kpg.HISTORY_TAB, nil)
end

local function kpg_show()
  kpg.mainwin:Show ()
end

local function kpg_decay()
  if (not kpg.frdb.enable_decay) then
    return
  end
  kpg.mainwin:Show ()
  kpg.mainwin:SetTab (kpg.DECAY_TAB, nil)
end

local function kpg_addloot (input)
  if (not kpg.inraid or not kpg.isml) then
    err (L["can only add items when in a raid and you are the master looter."])
    return true
  end

  if (not input or input == "" or input == L["CMD_HELP"]) then
    err (L["Usage: "] ..  white (strfmt (L["/%s %s [itemid | itemlink]"], L["CMDNAME"], L["CMD_ADDLOOT"])))
    return true
  end

  local itemid, pos = K.GetArgs (input)
  if (itemid ~= "") then
    -- Convert to numeric itemid if an item link was specified
    local ii = tonumber (itemid)
    if (ii == nil) then
      itemid = string.match (itemid, "item:(%d+)")
    end
  end
  if ((not itemid) or (itemid == "") or (pos ~= 1e9) or (tonumber(itemid) == nil)) then
    err (L["Usage: "] ..  white (strfmt (L["/%s %s [itemid | itemlink]"], L["CMDNAME"], L["CMD_ADDLOOT"])))
    return true
  end

  local iname, ilink = GetItemInfo (tonumber(itemid))
  if (iname == nil or iname == "") then
    err (L["item %d is an invalid item."], itemid)
    return true
  end

  kpg:AddLoot (ilink)
end

local function kpg_addignore (input)
  if (not input or input == "" or input == L["CMD_HELP"]) then
    err (L["Usage: "] ..  white (strfmt (L["/%s %s [itemid | itemlink]"], L["CMDNAME"], L["CMD_ADDIGNORE"])))
    return true
  end

  local itemid, pos = K.GetArgs (input)
  if (itemid ~= "") then
    -- Convert to numeric itemid if an item link was specified
    local ii = tonumber (itemid)
    if (ii == nil) then
      itemid = string.match (itemid, "item:(%d+)")
    end
  end
  if ((not itemid) or (itemid == "") or (pos ~= 1e9) or (tonumber(itemid) == nil)) then
    err (L["Usage: "] ..  white (strfmt (L["/%s %s [itemid | itemlink]"], L["CMDNAME"], L["CMD_ADDIGNORE"])))
    return true
  end

  local iname, ilink = GetItemInfo (tonumber(itemid))
  if (iname == nil or iname == "") then
    err (L["item %d is an invalid item."], itemid)
    return true
  end

  kpg.frdb.items[itemid] = ilink
  kpg:RefreshIgnoredItems ()
end

local function kpg_adddecay (input)
  if (not kpg.inraid) then
    return
  end

  if (not input or input == "") then
    err (L["Usage: "] .. white (strfmt (L["/%s %s name"], L["CMDNAME"], L["CMD_ADDDECAY"])))
    return true
  end

  local who, pos = K.GetArgs (input)
  if ((not who) or (who == "") or (pos ~= 1e9)) then
    err (L["Usage: "] .. white (strfmt (L["/%s %s name"], L["CMDNAME"], L["CMD_ADDDECAY"])))
    return true
  end

  who = K.CapitaliseName (who)

  if (not kpg.raid.raiders[who]) then
    err (L["Player %q not found in the raid."], who)
    return
  end

  if (kpg.frdb.decayed and kpg.frdb.decayed[who]) then
    err (L["Player %q already in the decay list."], class (who, kpg.frdb.decayed[who].class))
    return
  end

  kpg:AddDecayedUser (who, kpg.raid.raiders[who].class)
end

local function kpg_test (input)
end

local function kpg_debug (input)
  input = input or "1"
  if (input == "") then
    input = "1"
  end
  local dl = tonumber (input)
  if (dl == nil) then
    dl = 0
  end
  K.debugging[L["MODNAME"]] = dl
end

local function kpg_resetpos (input)
  if (kpg.mainwin) then
    kpg.mainwin:SetPoint ("TOPLEFT", UIParent, "TOPLEFT", 100, -100)
  end
end

local function kpg_suspend (input)
  me.SetSuspended (true)
end

local function kpg_resume (input)
  me.SetSuspended (false)
end

local function kpg_versioncheck (input)
  kpg.vcreplies = {}
  kpg_version ()
  kpg.SendAM ("VCHEK")
end

local function kpg_status (input)
  local rs = ""
  if (kpg.raid) then
    rs=strfmt (" kpg.raid:yes kr.nraiders:%d kr.threshold:%s myid:%s numlooters=%s", kpg.raid.numraiders, tostring (kpg.raid.threshold), kpg.myraidid, tostring(kpg.numlooters))
    if (kpg.looters) then
      for k,v in pairs (kpg.looters) do
        rs = rs .. "\nlooter[%s]=%d (%s)", k, v.mlidx, v.uid and v.uid or "none"
      end
    end
  end
  printf ("init=%s susp=%s inraid:%s isml:%s isaorl:%s mlname=%q" .. rs, tostring(kpg.initialised), tostring(kpg.suspended), tostring(kpg.inraid), tostring (kpg.isml), tostring (kpg.isaorl), tostring(kpg.mlname))
end

K.debugging[L["MODNAME"]] = 9   -- @debug-delete@

local kcmdtab = {}
kcmdtab["debug"] = kpg_debug
kcmdtab["status"] = kpg_status
kcmdtab[L["CMD_RESETPOS"]] = kpg_resetpos
kcmdtab[L["CMD_VERSION"]] = kpg_version
kcmdtab[L["CMD_SHOW"]] = kpg_show
kcmdtab[L["CMD_RAIDERS"]] = kpg_raiders
kcmdtab[L["CMD_LOOT"]] = kpg_main
kcmdtab[L["CMD_CONFIG"]] = kpg_config
kcmdtab[L["CMD_SUSPEND"]] = kpg_suspend
kcmdtab[L["CMD_RESUME"]] = kpg_resume
kcmdtab[L["CMD_HISTORY"]] = kpg_history
kcmdtab[L["CMD_ADDLOOT"]] = kpg_addloot
kcmdtab[L["CMD_ADDIGNORE"]] = kpg_addignore
kcmdtab[L["CMD_ADDDECAY"]] = kpg_adddecay
kcmdtab[L["CMD_DECAY"]] = kpg_decay
kcmdtab[L["CMD_VERSIONCHECK"]] = kpg_versioncheck
kcmdtab["vc"] = kpg_versioncheck

kcmdtab["test"] = kpg_test

function kpg:OnSlashCommand (input)
  if (not input or input == "") then
    kpg_main()
    return
  end

  local cmd, pos = K.GetArgs (input)
  if (not cmd or cmd == "") then
    kpg_main()
    return
  end

  strlower(cmd)

  if (cmd == L["CMD_HELP"] or cmd == "?") then
    kpg_usage()
    return
  end

  if (not kcmdtab[cmd]) then
    err (L["%q is not a valid command. Type %s for help."], white (cmd), white (strfmt ("/%s %s", L["CMDNAME"], L["CMD_HELP"])))
    return
  end

  local arg
  if (pos == 1e9) then
    arg = ""
  else
    arg = strsub(input, pos)
  end

  kcmdtab[cmd](arg)
end

local function kpg_initialisation (self)
  if (kpg.initialised) then
    return
  end

  self.db = DB:New("KKonferPUGDB", nil, "Default")
  self.frdb = self.db.factionrealm
  if (not self.frdb.dbversion) then
    self.frdb.dbversion = kpg.dbversion
    for k,v in pairs (kpg.defaults) do
      if (self.frdb[k] == nil) then
        self.frdb[k] = v
      end
    end
  end
  self.frdb.users = self.frdb.users or {}
  self.frdb.items = self.frdb.items or {}
  self.frdb.history = self.frdb.history or {}
  self:UpdateDatabaseVersion ()
  self.lootitem = {}
  self.qf = {}
  self.suspended = self.frdb.suspended or nil
  kpg:InitialiseUI ()
  K.comm.RegisterComm (self, self.CHAT_MSG_PREFIX)
  self:SendMessage ("KPG_INITIALISED")
end

function kpg:OnLateInit ()
  kpg_initialisation (self)
  check_for_other_konfer ()
end

function kpg:FullRefresh ()
  kpg:UpdateAllConfigSettings ()
  kpg:RefreshRaid ()
  kpg:RefreshIgnoredItems ()
  kpg:RefreshDecayedUsers ()
end

function kpg:UpdateAllConfigSettings ()
  local cf = kpg.qf.lootopts

  cf.autoopen:SetChecked (kpg.frdb.auto_open)
  cf.tooltips:SetChecked (kpg.frdb.display_tooltips)
  cf.announce:SetChecked (kpg.frdb.announce_loot)
  cf.chatfilter:SetChecked (kpg.frdb.chat_filter)
  cf.autoloot:SetChecked (kpg.frdb.auto_loot)
  cf.disenchant:SetChecked (kpg.frdb.disenchant)
  cf.rolltimeout:SetValue (kpg.frdb.roll_timeout)
  cf.rollextend:SetValue (kpg.frdb.roll_extend)
  cf.winners:SetChecked (kpg.frdb.announce_winners)
  cf.countdown:SetChecked (kpg.frdb.announce_countdown)
  cf.counthow:SetValue (kpg.frdb.announce_how)
  cf.offspec:SetChecked (kpg.frdb.offspec_rolls)
  cf.history:SetChecked (kpg.frdb.record_history)
  cf.entimer:SetChecked (kpg.frdb.use_timeout)
  cf.enext:SetChecked (kpg.frdb.use_extend)
  cf.msmin:SetText (tostring (kpg.frdb.main_spec_min))
  cf.msmax:SetText (tostring (kpg.frdb.main_spec_max))
  cf.osmin:SetText (tostring (kpg.frdb.off_spec_min))
  cf.osmax:SetText (tostring (kpg.frdb.off_spec_max))

  cf = kpg.qf.extraopts
  cf.decay:SetChecked (kpg.frdb.enable_decay)
  cf.maindec:SetText (tostring(kpg.frdb.main_decay))
  cf.mainmax:SetValue (kpg.frdb.main_max)
  cf.offdec:SetText (tostring(kpg.frdb.off_decay))
  cf.offmax:SetValue (kpg.frdb.off_max)
end

--
-- Event handling stuff. A few are Kore messages we trap but most are the
-- events we care about and are local to Konfer. The only exception is the
-- raid tracking stuff that will need to change to hook Kahlua Killers
-- events when that mod is complete.
--
local function player_info_updated (evt, ...)
  RequestRaidInfo ()
end

function kpg:RefreshRaid ()
  if (not kpg.initialised) then
    return
  end
  local nraiders = GetNumGroupMembers ()
  local oldinraid = kpg.inraid
  kpg.inraid = nil
  if (nraiders > 0) then
    kpg.inraid = 1
  end
  if (IsInRaid ()) then
    kpg.inraid = 2
  end
  if (UnitInBattleground ("player")) then
    kpg.inraid = false
  end
  local sendmsg = false

  if (kpg.inraid ~= oldinraid) then
    if (kpg.inraid and kpg.inraid > 0) then
      kpg.raid = {}
      kpg.myraidid = 0
      kpg.isml = false
      kpg.mlname = nil
      kpg.isaorl = false
      sendmsg = true
      K:UpdatePlayerAndGuild ()
    else
      kpg.raid = nil
      kpg.myraidid = nil
      kpg.isml = nil
      kpg.mlname = nil
      kpg.isaorl = nil
      kpg.looters = nil
      kpg.numlooters = nil
      kpg:ResetBossLoot ()
      kpg:SendMessage ("KPG_LEFT_RAID")
      return
    end
  end

  if (kpg.inraid) then
    kpg.raid.party = {}
    for i = 1,8 do
      kpg.raid.party[i] = {}
    end
    kpg.raid.raiders = {}
    kpg.raid.numraiders = nraiders
    kpg.raid.threshold = GetLootThreshold ()
    kpg.myraidid = 0

    if (kpg.inraid == 2) then
      local lootm, _, mlrid = GetLootMethod ()
      for i = 1, 40 do
        local nm, rank, party, lvl, _, cls, _, ol = GetRaidRosterInfo (i)
        if (nm) then
          nm = K.CanonicalName (nm, nil)
          local isml = false
          if (i == mlrid) then
            isml = true
          end
          if (nm == K.player.player) then
            kpg.myraidid = i
            if (isml) then
              kpg.isml = true
            end
            if (rank > 0) then
              kpg.isaorl = true
            end
          end

          kpg.raid.raiders[nm] = {
            class = K.ClassIndex[cls],
            idx = i,
            party = party,
            isaorl = rank > 0,
            online = ol and true or false,
          }
          if (kpg.frdb.users[nm]) then
            kpg.raid.raiders[nm].uinfo = kpg.frdb.users[nm]
          end
          local ti = { name = nm }
          tinsert (kpg.raid.party[party], ti)
        end
      end
    elseif (kpg.inraid == 1) then
      kpg.raid.raiders[K.player.player] = {
        class = K.player.class,
        idx = 0,
        party = 1,
        online = true,
      }
      tinsert (kpg.raid.party[1], { name = K.player.player })
      for i = 1, MAX_PARTY_MEMBERS do
        local isp = UnitExists ("party"..i)
        if (isp) then
          local pnm = UnitName ("party"..i)
          local pcl = K.ClassIndex[select (2, UnitClass ("party"..i))] or nil
          local ol = UnitIsConnected ("party"..i)
          if (pcl) then
            kpg.raid.raiders[pnm] = {
              class = pcl,
              idx = i,
              party = 1,
              online = ol and true or false,
            }
            tinsert (kpg.raid.party[1], { name = pnm })
            if (kpg.frdb.users[pnm]) then
              kpg.raid.raiders[pnm].uinfo = kpg.frdb.users[pnm]
            end
          end
        end
      end
    end
  end

  kpg:RefreshRaiders ()
  if (sendmsg) then
    kpg:SendMessage ("KPG_JOINED_RAID", kpg.raid.numraiders, kpg.raid.numparty)
  end
  kpg:RefreshMasterLootInfo ()
end

--
-- Only get these values once
--
local disenchant_name = GetSpellInfo (13262)
local herbalism_name = GetSpellInfo (11993)
local mining_name = GetSpellInfo (32606)

local function unit_spellcast_succeeded (evt, caster, sname, rank, tgt)
  if ((caster == "player") and (sname == OPENING)) then
    kpg.chestname = tgt
    return
  end

  if ((caster == "player") and ((sname == disenchant_name) or
    (sname == herbalism_name) or (sname == mining_name))) then
    kpg.skiploot = true
  end
end

function kpg:AddItemToBossLoot (ilink, quant, lootslot)
  if (not kpg.bossloot) then
    kpg.bossloot = {}
  end

  local lootslot = lootslot or 0
  local itemid = string.match (ilink, "item:(%d+)")
  local ti = { itemid = itemid, ilink = ilink, slot = lootslot, quant = quant }
  tinsert (kpg.bossloot, ti)
end

function kpg:SetMLCandidates (slot)
  if (not kpg.inraid) then
    return
  end

  kpg.looters = {}
  kpg.numlooters = 0

  for i = 1, GetNumGroupMembers (LE_PARTY_CATEGORY_HOME) do
    local tlc = GetMasterLootCandidate (slot, i)
    if (tlc and tlc ~= "") then
      local lc = K.CanonicalName (tlc, nil)
      local ti = { mlidx = i }
      kpg.looters[lc] = ti
      kpg.numlooters = kpg.numlooters + 1
    end
  end
  kpg:UpdateCandidatesPopup ()
end

function kpg:RefreshBossLoot()
  if (kpg.suspended or (not kpg.inraid) or (not kpg.isml) or (not kpg.raid) or (not kpg.raid.masterloot)) then
    return
  end

  kpg.announcedloot = kpg.announcedloot or {}

  if (kpg.skiploot) then
    debug (3, "skiploot set, returning")
    kpg.skiploot = nil
    return
  end

  local lslot = GetNumLootItems ()
  debug (3, "GetNumLootItems() = %d", lslot)

  local ilist = {}
  kpg.bossloot = {}
  kpg.uguid = nil

  for i = 1,lslot do
    if (LootSlotHasItem (i)) then
      local icon, name, quant, qual, locked = GetLootSlotInfo (i)
      local ilink = GetLootSlotLink (i)
      local itemid
      local skipit = false

      kpg:SetMLCandidates (i)

      if (locked) then
        skipit = true
      else
        if ((ilink ~= nil) and (ilink ~= "")) then
          itemid = string.match (ilink, "item:(%d+)")
          if (kpg.frdb.items and kpg.frdb.items[itemid]) then
            skipit = true
          elseif (kpg.iitems[itemid]) then
            skipit = true
          end
        else
          skipit = true
        end
      end

      if (qual < kpg.raid.threshold) then
        skipit = true
      end

      debug (3, "RefreshBossLoot: i=%d/%d ilink=%q itemid=%s quant=%d qual=%d threshold=%d skipit=%s", i, lslot, tostring (ilink), tostring (itemid), quant, qual, kpg.raid.threshold, tostring (skipit))

      if (not skipit) then
        kpg:AddItemToBossLoot (ilink, quant, i)
        local tii = { ilink, quant }
        tinsert (ilist, tii)
      end
    end
  end

  if (not kpg.bossloot) then
    return
  end

  local uname = UnitName ("target")
  local uguid = UnitGUID ("target")
  local realguid = true
  if (not uname or uname == "") then
    if (kpg.chestname and kpg.chestname ~= "") then
      uname = kpg.chestname
    else
      uname = L["Chest"]
    end
  end
  if (not uguid or uguid == "") then
    uguid = 0
    if (kpg.chestname and kpg.chestname ~= "") then
      uguid = kpg.chestname
      realguid = false
    end
  end
  kpg.uguid = uguid

  kpg.qf.lootlist.itemcount = #kpg.bossloot
  kpg.qf.lootlist:UpdateList ()

  if (#kpg.bossloot > 0) then
    kpg:SendConfig ()
    kpg.SendAM ("OLOOT", "ALERT", uname, uguid, realguid, ilist)
    if (kpg.frdb.auto_open == true) then
      if (not kpg.mainwin:IsVisible ()) then
        kpg.autoshown = true
      end
      kpg.mainwin:Show ()
      kpg.mainwin:SetTab (kpg.LOOT_TAB, kpg.LOOT_ASSIGN_TAB)
    end

    if (kpg.frdb.announce_loot) then
      kpg.announcedloot = kpg.announcedloot or {}
      local sendfn = kpg.SendRaidMsg
      if (kpg.inraid == 1) then
        sendfn = kpg.SendPartyMsg
      end

      local dloot = true
      if (uguid ~= 0) then
        if (kpg.announcedloot[uguid]) then
          dloot = false
        end
        kpg.announcedloot[uguid] = true
      else
        kpg.lastannouncetime = kpg.lastannouncetime or time()
        local now = time()
        local elapsed = difftime (now, kpg.lastannounce)
        if (elapsed < 60) then
          dloot = false
        end
      end

      if (dloot == true) then
        sendfn (strfmt (L["%s: loot from %s: "], L["MODABBREV"], uname))
        for k,v in ipairs (kpg.bossloot) do
          sendfn (strfmt ("%s: %s", L["MODABBREV"], v.ilink))
        end
        kpg.lastannouncetime = time ()
      end
    end
  else
    kpg.bossloot = nil
  end
end

local function loot_closed (evt, ...)
  kpg:ResetBossLoot ()
  kpg.chestname = nil
  if (kpg.autoshown) then
    kpg.autoshown = nil
    kpg.mainwin:Hide ()
  end
  kpg.SendAM ("CLOOT")
end

local function party_loot_method_changed (evt, ...)
  kpg:RefreshMasterLootInfo ()
end

function kpg:RefreshMasterLootInfo ()
  local method, mlpi, mlri = GetLootMethod ()
  kpg.mlname = nil
  kpg.isml = nil
  if (kpg.inraid) then
    kpg.raid.masterloot = false
  end

  if (method == "master") then
    local mlname
    if (mlpi) then
      if (mlpi == 0) then
        mlname = K.player.player
      else
        mlname = UnitName ("party"..mlpi)
      end
    end
    if (mlri) then
      if (mlri == 0) then
        mlname = K.player.player
      else
        mlname = UnitName ("raid"..mlri)
      end
    end
    if (kpg.inraid) then
      kpg.raid.masterloot = true
      kpg.mlname = K.CanonicalName (mlname)
      if (kpg.mlname == K.player.player) then
        kpg.isml = true
      else
        kpg.isml = false
      end
      kpg:SendMessage ("KPG_MASTER_LOOTER", kpg.isml)
    end
  end
  kpg:SendMessage ("KPG_CONFIG_ADMIN", kpg.isml)
end

local titlematch = "^" .. L["MODTITLE"] .. ": "
local abbrevmatch = "^" .. L["MODABBREV"] .. ": "
local function reply_filter (self, evt, msg, snd, ...)
  local sender = K.CanonicalName (snd, nil)
  if (strmatch (msg, titlematch)) then
    if (evt == "CHAT_MSG_WHISPER_INFORM") then
      return true
    elseif (sender == K.player.player) then
      return true
    end
  end
  if (strmatch (msg, abbrevmatch)) then
    if (evt == "CHAT_MSG_WHISPER_INFORM") then
      return true
    elseif (sender == K.player.player) then
      return true
    end
  end
end

local function raid_roster_update (evt,...)
  kpg:RefreshRaid ()
end

kpg:RegisterMessage ("KPG_CONFIG_ADMIN", function (evt, onoff, ...)
  if (onoff and admin_hooks_registered ~= true) then
    admin_hooks_registered = true
    kpg:RegisterEvent ("UNIT_SPELLCAST_SUCCEEDED", unit_spellcast_succeeded)
    kpg:RegisterEvent ("PARTY_LOOT_METHOD_CHANGED", party_loot_method_changed)
  elseif (not onoff and admin_hooks_registered == true) then
    admin_hooks_registered = false
    kpg:UnregisterEvent ("UNIT_SPELLCAST_SUCCEEDED")
    kpg:UnregisterEvent ("PARTY_LOOT_METHOD_CHANGED")
    kpg:SendMessage ("KPG_MASTER_LOOTER", false)
  end

  if (onoff) then
    if (chat_filters_installed ~= true) then
      if (kpg.frdb.chat_filter) then
        chat_filters_installed = true
        ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", reply_filter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", reply_filter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", reply_filter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", reply_filter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", reply_filter)
      end
    end
  end

  if (not onoff or not kpg.frdb.chat_filter) then
    if (chat_filters_installed) then
      chat_filters_installed = false
      ChatFrame_RemoveMessageEventFilter ("CHAT_MSG_WHISPER_INFORM", reply_filter)
      ChatFrame_RemoveMessageEventFilter ("CHAT_MSG_RAID", reply_filter)
      ChatFrame_RemoveMessageEventFilter ("CHAT_MSG_RAID_LEADER", reply_filter)
      ChatFrame_RemoveMessageEventFilter ("CHAT_MSG_PARTY", reply_filter)
      ChatFrame_RemoveMessageEventFilter ("CHAT_MSG_PARTY_LEADER", reply_filter)
    end
  end
end)

kpg:RegisterMessage ("KPG_MASTER_LOOTER", function (evt, onoff, ...)
  if (onoff and ml_hooks_registered ~= true) then
    kpg:RegisterEvent ("LOOT_OPENED", function (evt, ...)
      kpg:RefreshBossLoot ()
    end)
    kpg:RegisterEvent ("LOOT_SLOT_CHANGED", function (evt, ...)
      kpg:RefreshBossLoot ()
    end)
    kpg:RegisterEvent ("LOOT_CLOSED", loot_closed)
    kpg:RegisterEvent ("OPEN_MASTER_LOOT_LIST", function (evt, ...)
      local l
      for l = 1, GetNumLootItems() do
        if (LootSlotHasItem (l)) then
          kpg:SetMLCandidates (l)
          return
        end
      end
    end)
    kpg:RegisterEvent ("UPDATE_MASTER_LOOT_LIST", function (evt, ...)
      local l
      for l = 1, GetNumLootItems() do
        if (LootSlotHasItem (l)) then
          kpg:SetMLCandidates (l)
          return
        end
      end
    end)
    ml_hooks_registered = true
  elseif (not onoff and ml_hooks_registered == true) then
    kpg:UnregisterEvent ("LOOT_OPENED")
    kpg:UnregisterEvent ("LOOT_CLOSED")
    kpg:UnregisterEvent ("OPEN_MASTER_LOOT_LIST")
    kpg:UnregisterEvent ("UPDATE_MASTER_LOOT_LIST")
    ml_hooks_registered = false
  end

  if (not onoff and kpg.inraid) then
    -- Hide the config and decay tabs
    kpg.qf.configtab:SetShown (false)
    kpg.qf.decaytab:SetShown (false)
  else
    kpg.qf.configtab:SetShown (true)
    kpg.qf.decaytab:SetShown (kpg.frdb.enable_decay)
  end
  kpg:RefreshDecayedUsers ()
end)

kpg:RegisterMessage ("KPG_INITIALISED", function (evt, ...)
  debug (5, "KPG_INITIALISED")
  kpg.initialised = true
  kpg:RegisterMessage ("PLAYER_INFO_UPDATED", player_info_updated)
  kpg:RegisterEvent ("GROUP_ROSTER_UPDATE", raid_roster_update)
  kpg:RegisterEvent ("PARTY_MEMBERS_CHANGED", raid_roster_update)
  kpg:FullRefresh ()
end)

kpg:RegisterMessage ("KPG_JOINED_RAID", function (evt, ...)
  if (kpg.isml) then
    kpg.qf.configtab:SetShown (true)
    kpg.qf.decaytab:SetShown (kpg.frdb.enable_decay)
  else
    kpg.qf.configtab:SetShown (false)
    kpg.qf.decaytab:SetShown (false)
  end
end)

kpg:RegisterMessage ("KPG_LEFT_RAID", function (evt, ...)
  kpg.qf.configtab:SetShown (true)
  kpg.qf.decaytab:SetShown (kpg.frdb.enable_decay)
end)

