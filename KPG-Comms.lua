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

local K = LibStub:GetLibrary("KKore")
local H = LibStub:GetLibrary("KKoreHash")
local DB = LibStub:GetLibrary("KKoreDB")
local KUIBase = LibStub:GetLibrary("KKoreUI")

if (not K) then
  error ("KahLua KonferPUG: could not find KahLua Kore.", 2)
end

if (not H) then
  error ("KahLua KonferPUG: could not find KahLua Kore Hash library.", 2)
end

local kpg = K:GetAddon ("KKonferPUG")
local L = kpg.L
local KUI = kpg.KUI
local MakeFrame = KUI.MakeFrame

-- Local aliases for global or Lua library functions
local _G = _G
local tinsert = table.insert
local tremove = table.remove
local setmetatable = setmetatable
local tconcat = table.concat
local tsort = table.sort
local tostring = tostring
local GetTime = GetTime
local min = math.min
local max = math.max
local strfmt = string.format
local strsub = string.sub
local strlen = string.len
local strfind = string.find
local strlower = string.lower
local gsub = string.gsub
local gmatch = string.gmatch
local xpcall, pcall = xpcall, pcall
local pairs, next, type = pairs, next, type
local select, assert, loadstring = select, assert, loadstring
local printf = K.printf
local strsplit = string.split
local bxor = bit.bxor

local ucolor = K.ucolor
local ecolor = K.ecolor
local icolor = K.icolor
local debug = kpg.debug
local info = kpg.info
local err = kpg.err
local white = kpg.white
local class = kpg.class

--[[
This file contains all of the functions for dealing with sending and
receiving of inter-mod communications. It is where the KonferPUG "protocol"
is implemented.
]]

local function getbool (str)
  if (str and str == "Y") then
    return true
  end
  return false
end

local ehandlers = {}

local function send_addon_msg (cmd, prio, dist, target, ...)
  local prio = prio or "BULK"
  local fs = strfmt ("%d:%s:", kpg.protocol, cmd)
  local crc = H:CRC32 (fs, nil, false)
  local ndata = K.Serialise (...)
  crc = H:CRC32 (ndata, crc, true)
  fs = fs .. K.hexstr (crc) .. ":" .. ndata

  debug (9, "sending: fs=%q dist=%q target=%q prio=%q", tostring(fs:gsub("\124", "\124\124")), tostring(dist), tostring(target), tostring(prio))
  K.comm.SendCommMessage (kpg.CHAT_MSG_PREFIX, fs, dist, target, prio)
end

function kpg.SendAM (cmd, prio, ...)
  if (not kpg.inraid) then
    return
  end
  send_addon_msg (cmd, prio, "RAID", nil, ...)
end

function kpg.SendWhisperAM (target, cmd, prio, ...)
  send_addon_msg (cmd, prio, "WHISPER", target, ...)
end

--
-- Main message receipt function. Checks the protocol, checksum and other
-- sundry stuff before invoking the handler function.
--
local oldwarn = true
local function old_warning_dialog ()
  if (not oldwarn) then
    return
  end
  oldwarn = false

  local arg = {
    name = "KPGOldProtoDialog",
    x = "CENTER", y = "MIDDLE", border = true, blackbg = true,
    okbutton = { text = K.OK_STR }, canmove = false, canresize = false,
    escclose = false, width = 450, height = 100, title = L["MODTITLE"],
  }
  local dlg = KUI:CreateDialogFrame (arg)
  dlg.OnAccept = function (this)
    this:Hide ()
  end
  dlg.OnCancel = function (this)
    this:Hide ()
  end

  arg = {
    x = 8, y = -10, width = 410, height = 64, autosize = false,
    color = { r = 1, g = 0, b = 0, a = 1},
    text = L["MODTITLE"] .. ": " .. strfmt (L["your version of %s is out of date. Please update it."], L["MODTITLE"]), font = "GameFontNormal",
    justifyv = "TOP",
  }
  dlg.str1 = KUI:CreateStringLabel (arg, dlg)

  if (kpg.mainwin and kpg.mainwin:IsShown ()) then
    kpg.mainwin:Hide ()
  end
  dlg:Show ()
end

local function commdispatch (sender, proto, cmd, res, ...)
  if (res) then
    if (not ehandlers[cmd]) then
      old_warning_dialog ()
      debug (1, "unknown command %q from %q (p=%d)", cmd, sender, proto)
      return
    else
      debug (8, "COMM(%s) received from %q (proto=%d)", cmd, sender, proto)

      --
      -- If we are not the master looter we ignore all incoming events,
      -- as KPUG only sends events from the ML to users, never the other
      -- way around. The sole exception to this is the VCACK reply to the
      -- version check.
      --
      if (not kpg.inraid or (kpg.isml and cmd ~= "VCACK")) then
        debug (8, "ignoring incoming event - not in raid or ML")
        return
      end

      ehandlers[cmd] (sender, proto, cmd, ...)
    end
  else
    debug (1, "failed to deserialise %q from %q (p=%d)", sender, cmd, proto)
  end
end

local userwarn = userwarn or {}

function kpg:OnCommReceived (prefix, msg, dist, sender)
  if (sender == K.player.player) then
    return -- Ignore our own messages
  end
  if (dist == "UNKNOWN" and (sender ~= nil and sender ~= "")) then
    return
  end

  debug (9, "received: prefix=%q msg=%q dist=%q sender=%q", tostring(prefix), tostring(msg), tostring(dist), tostring(sender))

  local iter = gmatch (msg, "([^:]+)()")
  local ps = iter()
  if (not ps) then
    debug (1, "bad msg %q received from %q", msg, sender)
    return
  end
  local proto = tonumber (ps, 16)
  if (proto > kpg.protocol) then
    old_warning_dialog ()
    return
  end

  local cmd = iter ()
  if (not cmd) then
    debug (1, "malformed msg %q received from %q", msg, sender)
    return
  end
  local msum, pos = iter ()
  if (not msum) then
    debug (1, "malformed msg %q received from %q", msg, sender)
    return
  end
  local data = string.sub (msg, pos+1)
  if (not data) then
    debug (1, "malformed msg %q received from %q", msg, sender)
    return
  end
  local crc = H:CRC32 (ps, nil, false)
  crc = H:CRC32 (":", crc, false)
  crc = H:CRC32 (cmd, crc, false)
  crc = H:CRC32 (":", crc, false)
  crc = H:CRC32 (data, crc, true)
  local mf = K.hexstr (crc)

  if (mf ~= msum) then
    if (not userwarn[sender]) then
      printf (ecolor, "WARNING: addon message from %q was fake!", sender)
      userwarn[sender] = true
    end
  end
  commdispatch (sender, proto, cmd, K.Deserialise (data))
end

--
-- Command: VCHEK
-- Purpose: Respond to sender with a version check
--
ehandlers.VCHEK = function (sender, proto, cmd, ...)
  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg.SendWhisperAM (sender, "VCACK", nil, kpg.version)
end

--
-- Command: VCACK version
-- Purpose: Sent back to us in response to a VCHEK command
--
ehandlers.VCACK = function (sender, proto, cmd, ver)
  if (not kpg.vcreplies[sender]) then
    kpg.vcreplies[sender] = true
    info (L["%s using version %s"], white (sender), white (ver))
  end
end

--
-- Command: CONFIG msmin msmax osmin osmax osrolls decay msval mscnt osval oscnt decaytbl
-- Purpose: Sent to the raid to let users know what the current config
--          parameters are. This is always sent prior to an OLOOT event.
--
ehandlers.CONFIG = function (sender, proto, cmd, ...)
  local msmin, msmax, osmin, osmax, osrolls, decay, msval, mscnt, osval, oscnt, decaytbl = ...

  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg.remcfg = {
    main_spec_min = msmin,
    main_spec_max = msmax,
    off_spec_min = osmin,
    off_spec_max = osmax,
    offspec_rolls = osrolls,
    enable_decay = decay,
    main_decay = msval,
    main_max = mscnt,
    off_decay = osval,
    off_max = oscnt,
    decayed = decaytbl,
  }
  kpg:RefreshDecayedUsers ()
end

--
-- Command: OLOOT uname uguid realguid lootidtable
-- Purpose: Sent when the master looter loots a corpse or chest. This is sent
--          each time they do so, whether its for the same mob/chest or not.
--          So, if the ML clicks away from a mob or closes loot due to combat
--          or whatever, a loot close event will be sent, and when they
--          reloot the mob/chest, this event will be sent again. It is always
--          a table with the full list of unresolved loot. Each element in the
--          table is the itemlink and quantity for the item in question.
--          The uname parameter is the name of the mob being looted, and the
--          uguid is the GUID of the unit being looted. This is set to the name
--          of the chest or container being opened if its not a real mob with
--          a GUID. In this case, realguid will be false, for real mobs with
--          GUID's it will be true.
--
local we_opened = nil

ehandlers.OLOOT = function (sender, proto, cmd, ...)
  local uname, uguid, realguid, loottbl = ...

  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg:ResetBossLoot ()
  kpg.bossloot = {}

  for k,v in ipairs (loottbl) do
    local ilink, quant = unpack(v)
    local itemid = string.match (ilink, "item:(%d+)")
    local ti = { itemid = itemid, ilink = ilink, slot = 0, quant = quant }
    tinsert (kpg.bossloot, ti)
  end

  kpg.qf.lootlist.itemcount = #kpg.bossloot
  kpg.qf.lootlist:UpdateList ()

  kpg.autolooted = kpg.autolooted or {}
  if (kpg.autolooted[uguid] == true) then
    return
  end
  if (uguid ~= "0") then
    kpg.autolooted[uguid] = true
  end

  if (kpg.suspended or not kpg.frdb.auto_open) then
    return
  end

  if (not kpg.mainwin:IsShown ()) then
    kpg.mainwin:Show ()
    kpg.mainwin:SetTab (kpg.LOOT_TAB, 0)
    we_opened = true
  end
end

--
-- Command: CLOOT
-- Purpose: Sent when the master looter stops looting a corpse or chest.
--          Close the main window when we receive this if we opened it during
--          OLOOT processing.
--
ehandlers.CLOOT = function (sender, proto, cmd, ...)
  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg:ResetBossLoot ()
  if (we_opened) then
    we_opened = nil
    kpg.mainwin:Hide ()
  end
end

--
-- Command: ALOOT itemlink
-- Purpose: Sent when the master looter adds an item to the loot list
--          manually. ITEMLINK is the item link of the item being added
--
ehandlers.ALOOT = function (sender, proto, cmd, ilink)
  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg:AddLoot (ilink, true)
end

--
-- Command: LISEL idx itemid
-- Purpose: Select loot item at index position IDX. The item should have
--          item id of ITEMID.
--
ehandlers.LISEL = function (sender, proto, cmd, ...)
  local idx, itemid = ...
  if (not kpg.bossloot) then
    return
  end
  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg:SelectLootItem (idx, itemid)
end

--
-- Command: BIREM itemidx
-- Purpose: Used to remove an item from the list of items. This is
--          sent out to the raid only so that people in the raid tracking the
--          loot process see when an item is manually removed from the list
--          by the ML pressing the "Remove" button. This is also sent whenever
--          an item is awarded to a user and removed off the corpse.
--
ehandlers.BIREM = function (sender, proto, cmd, ...)
  local itemidx = ...
  if (not kpg.bossloot) then
    return
  end
  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg:RemoveItemByIdx (itemidx)
end

--
-- Command: BICAN
-- Purpose: Used to signal a  roll was cancelled.
--
ehandlers.BICAN = function (sender, proto, cmd, ...)
  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg:ResetRollers ()
end

--
-- Command: BIDOP idx
-- Purpose: Opens rolling on the currently selected item. Recipients of this
--          message merely need to activate their "Roll" button in case the
--          user is interested in rolling on the item. This is always preceeded
--          by a BICAN message to clear the roll list just to be sure.
--          Gets passed the index number of the item being bid on, which is
--          currently ignored as the item will have been set by LISEL. We could
--          do an integrity check though. Also currently unused (for future
--          use) is a timeout which will start a bid timeout countdown on the
--          user's end.
--
ehandlers.BIDOP = function (sender, proto, cmd, ...)
  local idx = ...
  if (not kpg.bossloot) then
    return
  end

  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg.qf.mymainroll:SetEnabled (true)
  kpg.qf.mymainroll:SetShown (true)

  if (kpg.remcfg.offspec_rolls) then
    kpg.qf.myoffroll:SetEnabled (true)
    kpg.qf.myoffroll:SetShown (true)
  end
end

--
-- Command: BIDND
-- Purpose: Closes bidding on the current item. The recipients simply need to
--          disable the roll buttons.
--
ehandlers.BIDND = function (sender, proto, cmd, ...)
  if (not kpg.bossloot) then
    return
  end

  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg.qf.mymainroll:SetEnabled (false)
  kpg.qf.myoffroll:SetEnabled (false)
  kpg.qf.mymainroll:SetShown (false)
  kpg.qf.myoffroll:SetShown (false)
end

-- Set a user's decay values
ehandlers.SETDC = function (sender, proto, cmd, ...)
  local who, whoclass, mc, oc = ...

  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  if (not kpg.remcfg) then
    return
  end

  if (mc == 0 and oc == 0) then
    kpg.remcfg.decayed[who] = nil
  else
    kpg.remcfg.decayed = kpg.remcfg.decayed or {}
    kpg.remcfg.decayed[who] = {
      class = whoclass, count = { mc, oc }
    }
  end
  kpg:RefreshDecayedUsers ()
end

-- Reset decay
ehandlers.RESTD = function (sender, proto, cmd, ...)
  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  if (not kpg.remcfg) then
    return
  end
  kpg.remcfg.decayed = nil
  kpg:RefreshDecayedUsers ()
end

-- New roller
ehandlers.NEWRL = function (sender, proto, cmd, ...)
  local name, class, roll, minr, maxr, pct, rit = ...
  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  kpg.rollers = kpg.rollers or {}
  kpg.rollers[name] = {
    class = class,
    roll = roll,
    minr = minr,
    maxr = maxr,
    omin = minr,
    omax = maxr,
    oroll = roll,
    pct = pct,
    rit = rit,
  }
  kpg:RefreshRollers ()
end

-- Update roller
ehandlers.UPDRL = function (sender, proto, cmd, ...)
  local name, minr, maxr, roll, rit = ...
  if (sender ~= kpg.mlname or kpg.isml) then
    return
  end

  if (kpg.rollers and kpg.rollers[name]) then
    local rp = kpg.rollers[name]
    rp.minr = minr
    rp.maxr = maxr
    rp.roll = roll
    rp.rit = rit
    kpg:RefreshRollers ()
  end
end

-- Add loot award history item
ehandlers.AHIST = function (sender, proto, cmd, ...)
  local when, what, who, class, how = ...

  kpg:AddLootHistory (when, what, who, class, how, true)
end

