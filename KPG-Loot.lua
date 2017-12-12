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
local LibDeformat = LibStub:GetLibrary ("LibDeformat-3.0")

if (not K) then
  error ("KahLua KonferPUG: could not find KahLua Kore.", 2)
end

if (not LibDeformat) then
  error ("KahLua KonferPUG: could not find LibDeformat.", 2)
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
local xpcall, pcall = xpcall, pcall
local pairs, next, type = pairs, next, type
local select, assert, loadstring = select, assert, loadstring
local printf = K.printf

local ucolor = K.ucolor
local ecolor = K.ecolor
local icolor = K.icolor
local debug = kpg.debug
local info = kpg.info
local err = kpg.err
local white = kpg.white
local class = kpg.class

--
-- This file contains all of the UI handling code for the loot panel,
-- as well as all loot manipulation functions.
--

local initdone = false
local timerbarwidth = 0
local assignpopup

local function main_spec (player)
  local ip

  if (kpg.isml) then
    ip = kpg.frdb
  else
    ip = kpg.remcfg
  end

  local mn = ip.main_spec_min
  local mx = ip.main_spec_max

  if (ip.enable_decay and player and ip.decayed and ip.main_decay > 0) then
    local ared = 0
    if (ip.decayed[player]) then
      ared = ip.decayed[player].count[1] * ip.main_decay
    end
    if (ared < mx) then
      mx = mx - ared
    end
  end

  if (mn == 1 and mx == 100) then
    return "/roll", 1, 100
  else
    return strfmt ("/roll %d-%d", mn, mx), mn, mx
  end
end

local function off_spec (player)
  local ip

  if (kpg.isml) then
    ip = kpg.frdb
  else
    ip = kpg.remcfg
  end

  local mn = ip.off_spec_min
  local mx = ip.off_spec_max

  if (ip.enable_decay and player and ip.decayed and ip.off_decay > 0) then
    local ared = 0
    if (ip.decayed[player]) then
      ared = ip.decayed[player].count[2] * ip.off_decay
    end
    if (ared < mx) then
      mx = mx - ared
    end
  end

  if (mn == 1 and mx == 100) then
    return "/roll", 1, 100
  else
    return strfmt ("/roll %d-%d", mn, mx), mn, mx
  end
end

function kpg.BroadcastPlayer (player)
  local _, mn, mx = main_spec (player)
  local _, on, ox = off_spec (player)

  if (kpg.frdb.offspec_rolls) then
    kpg.SendRaidMsg (strfmt ("%s: %s %d-%d (main) %d-%d (off)", L["MODABBREV"], player, mn, mx, on, ox))
  else
    kpg.SendRaidMsg (strfmt ("%s: %s %d-%d", L["MODABBREV"], player, mn, mx))
  end
end

local function reset_roll_buttons ()
  local en = false
  if (kpg.selectedloot and kpg.isml) then
    en = true
  end
  kpg.qf.startroll:SetEnabled (en)
  kpg.qf.pauseroll:SetEnabled (false)
  kpg.qf.remove:SetEnabled (en)
  kpg.qf.startroll:SetText (L["Start Roll"])
  kpg.qf.remove:SetText (L["Remove Item"])
  kpg.qf.pauseroll:SetText (L["Pause Roll"])
  kpg.qf.mymainroll:SetShown (false)
  kpg.qf.myoffroll:SetShown (false)
  kpg.qf.mymainroll:SetEnabled (false)
  kpg.qf.myoffroll:SetEnabled (false)
end

local function active_roll_buttons ()
  kpg.qf.startroll:SetEnabled (true)
  kpg.qf.pauseroll:SetEnabled (true)
  kpg.qf.remove:SetEnabled (true)
  kpg.qf.startroll:SetText (L["End Roll"])
  kpg.qf.remove:SetText (K.CANCEL_STR)
  kpg.qf.mymainroll:SetShown (true)
  kpg.qf.myoffroll:SetShown (true)
  kpg.qf.mymainroll:SetEnabled (true)
  kpg.qf.myoffroll:SetEnabled (true)
end

local function set_autoloot_win (name, class, ilink)
  kpg.qf.autoassign_item:SetText (ilink)
  kpg.qf.confirmframe.slot = kpg.bossloot[kpg.selectedloot].slot
  kpg.qf.confirmframe.idx = kpg.selectedloot
  kpg.qf.confirmframe.target = nil
  if (kpg.qf.confirmframe.slot ~= 0) then
    if (kpg.numlooters and kpg.numlooters > 0 and kpg.looters[name]) then
      kpg.qf.confirmframe.target = kpg.looters[name].mlidx
    end
  end
  kpg.qf.confirmframe.denched = false
  kpg.qf.confirmframe.who = name
  kpg.qf.confirmframe.class = class
  kpg.qf.confirmframe.ilink = ilink
  kpg.qf.lootlist:SetSelected (nil)
  reset_roll_buttons ()
  kpg.qf.lootframe:Hide ()
  kpg.qf.confirmframe:Show ()
end

local function possible_de ()
  if (not kpg.frdb.disenchant) then
    return false
  end

  for k,v in pairs (kpg.raid.raiders) do
    if (v.online and v.uinfo and v.uinfo.e) then
      local rs = ""
      if (kpg.lootitem.loot.slot == 0 or not kpg.numlooters or not kpg.looters[k]) then
        rs = "\n\n" .. white (L["Note: player will need to pick item up manually."])
      end
      local cname = class (k, v.class)
      kpg.qf.autoassign_msg:SetText (strfmt (L["AUTODENCHNR"], cname, cname) .. rs)
      set_autoloot_win (k, v.class, kpg.lootitem.loot.ilink)
      kpg.qf.confirmframe.denched = true
      return true
    end
  end
  return false
end

local function real_roll_end ()
  if (kpg.isml) then
    kpg.SendAM ("BIDND", "ALERT")
  end
  kpg.qf.timerframe:SetScript ("OnUpdate", nil)
  kpg.qf.timerframe:Hide ()
  kpg.rolling = 0
  local topmain = {}
  local topalts = {}
  local nummain = 0
  local numalts = 0
  for i = 1, #kpg.lootroll.mainspec do
    local nm = kpg.lootroll.mainspec[i]
    local ru = kpg.rollers[nm]
    tinsert (topmain, class (nm, ru.class) .. " [" .. ru.roll .. "]")
    nummain = nummain + 1
    if (nummain == 5) then
      break
    end
  end
  for i = 1, #kpg.lootroll.offspec do
    local nm = kpg.lootroll.offspec[i]
    local ru = kpg.rollers[nm]
    tinsert (topalts, class (nm, ru.class) .. " [" .. ru.roll .. "]")
    numalts = numalts + 1
    if (numalts == 5) then
      break
    end
  end

  if (nummain > 0 ) then
    info (L["top main spec rollers: %s"], tconcat (topmain, ", "))
  end
  if (numalts > 0 ) then
    info (L["top off-spec rollers: %s"], tconcat (topalts, ", "))
  end
  topmain = nil
  topalts = nil

  local wlist = nil
  local tiemin, tiemax, tiefunc
  local ismain = true
  local histstr = "M"
  if (nummain > 0) then
    wlist = kpg.lootroll.mainspec
    tiemin = kpg.frdb.main_spec_min
    tiemax = kpg.frdb.main_spec_max
    tiefunc = main_spec
  elseif (numalts > 0) then
    wlist = kpg.lootroll.offspec
    tiemin = kpg.frdb.off_spec_min
    tiemax = kpg.frdb.off_spec_max
    tiefunc = off_spec
    ismain = false
    histstr = "O"
  end

  if (wlist) then
    local winner = wlist[1]
    -- Deal with ties here.
    local nwinners = 1
    local winners = {}
    local winnames = {}
    winners[winner] = kpg.rollers[winner].class
    tinsert (winnames, winner)
    local winroll = kpg.rollers[winner].roll
    for i = 2, #wlist do
      local nm = wlist[i]
      local ru = kpg.rollers[nm]
      if (ru.roll == winroll) then
        winners[nm] = ru.class
        tinsert (winnames, nm)
        nwinners = nwinners + 1
      end
    end

    if (nwinners > 1) then
      kpg.SendRaidMsg (strfmt (L["%s: the following users tied with %d: %s. Roll again."], L["MODABBREV"], winroll, tconcat (winnames, ", ")))
      winnames = nil
      kpg.SendAM ("BICAN", "ALERT")
      kpg.rollers = {}
      kpg.lootroll.mainspec = {}
      kpg.lootroll.offspec = {}
      kpg.lootroll.restrict = winners
      kpg.lootroll.endtime = GetTime () + kpg.frdb.roll_timeout + 1
      kpg.lootroll.lastwarn = nil
      kpg.lootroll.mark5 = nil
      kpg.lootroll.mark10 = nil
      kpg.lootroll.tiemin = tiemin
      kpg.lootroll.tiemax = tiemax
      kpg.lootroll.tiefunction = tiefunc
      kpg.rolling = 1
      active_roll_buttons ()
      kpg.qf.timerframe:Show ()
      kpg.qf.timerframe:SetScript ("OnUpdate", rolltimer_onupdate)
      return
    end

    local rid = kpg.raid.raiders[winner]
    local winclass = rid.class
    local party = rid.party
    local ilink = kpg.lootitem.loot.ilink

    local ts = strfmt (L["%s: %s (group %d) won %s. Grats!"], L["MODABBREV"], winner, party, ilink)
    if (kpg.frdb.announce_winners) then
      kpg.SendRaidMsg (ts)
    end
    if (kpg.frdb.chat_filter) then
      printf (icolor, "%s", ts)
    end

    ts = kpg:TimeStamp ()
    kpg:AddLootHistory (ts, ilink, winner, winclass, histstr)
    if (not kpg.openroll) then
      kpg:AddDecayedUser (winner, winclass, ismain, false)
    end
    kpg.rolling = nil

    if (kpg.lootitem.loot.slot ~= 0 and kpg.frdb.auto_loot and kpg.numlooters and kpg.numlooters > 0) then
      local cname = class (winner, winclass)
      kpg.qf.autoassign_msg:SetText (strfmt (L["AUTOLOOT"], cname, cname, cname))
      set_autoloot_win (winner, winclass, ilink)
      return
    else
      if (kpg.isml) then
        kpg.SendAM ("BIREM", "ALERT", kpg.selectedloot)
      end
      kpg:RemoveItemByIdx (kpg.selectedloot)
    end
  else -- No winner because no-one rolled
    info (strfmt (L["no-one rolled for %s."], kpg.lootitem.loot.ilink))
    if (not possible_de ()) then
      --
      -- No-one rolled and they didn't assign it to a dencher. We don't
      -- really know what they are going to do with it, so we can not
      -- record a loot history event. Yes it would be possible to trap
      -- the loot assignment message in case they manually assign the item,
      -- but that is highly unreliable as it wont be displayed if the
      -- recipient is out of range. No-one ever said this was a perfect
      -- system.
      --
      if (kpg.isml) then
        kpg.SendAM ("BIREM", "ALERT", kpg.selectedloot)
      end
      kpg:RemoveItemByIdx (kpg.selectedloot)
    end
  end

  kpg.rolling = nil
  kpg.qf.lootlist:SetSelected (nil)
  kpg.qf.timerframe:Hide () -- Calls cleanup in OnHide handler
end

--
-- Start the roll process or end the current roll if one is active.
--
local function start_or_end_roll ()
  if (kpg.rolling) then
    -- End the current roll
    kpg.rolling = 1
    kpg.lootroll.endtime = GetTime () - 1
    if (not kpg.frdb.use_timeout) then
      real_roll_end ()
    end
  else
    local oroll = IsShiftKeyDown ()
    -- Start a new roll. First lets check to make sure that the main spec
    -- maximum and minimum values are sane.
    if (kpg.frdb.main_spec_min > kpg.frdb.main_spec_max) then
      err (L["invalid main spec roll range (%d > %d)."], kpg.frdb.main_spec_min, kpg.frdb.main_spec_max)
      return
    end
    if (kpg.frdb.offspec_rolls) then
      if (kpg.frdb.off_spec_min > kpg.frdb.off_spec_max) then
        err (L["invalid off-spec roll range (%d > %d)."], kpg.frdb.off_spec_min, kpg.frdb.off_spec_max)
        return
      end
      if (kpg.frdb.off_spec_min == kpg.frdb.main_spec_min and kpg.frdb.off_spec_max == kpg.frdb.main_spec_max) then
        err (L["main spec and off-spec roll ranges cannot be the same."])
        return
      end
    end

    if (kpg.isml) then
      kpg.SendAM ("BIDOP", "ALERT", kpg.selectedloot)
    end
    kpg.rolling = 1
    kpg.openroll = oroll
    kpg.qf.spark.StartRoll ()
    if (kpg.frdb.use_timeout and not oroll) then
      kpg.SendRaidWarning (strfmt (L["Roll for %s within %d seconds."], kpg.lootitem.loot.ilink, kpg.frdb.roll_timeout))
    else
      kpg.SendRaidWarning (strfmt (L["Roll for %s."], kpg.lootitem.loot.ilink))
    end
    kpg.usagedisplayed = kpg.usagedisplayed or {}
    if (not oroll and not kpg.usagedisplayed[kpg.uguid]) then
      if (kpg.frdb.offspec_rolls) then
        kpg.SendRaidMsg (strfmt (L['%s: type %q for main spec, %q for off-spec or "/roll 1-1" to cancel a roll.'], L["MODABBREV"], main_spec (), off_spec ()))
      else
        kpg.SendRaidMsg (strfmt (L['%s: type %q for main spec or "/roll 1-1" to cancel a roll.'], L["MODABBREV"], main_spec ()))
      end
      kpg.usagedisplayed[kpg.uguid] = true
    end
  end
end

local function pause_resume_roll ()
  if (kpg.rolling) then
    if (kpg.rolling == 1) then
      local rem = floor (kpg.lootroll.endtime - GetTime()) + 1
      kpg.qf.pauseroll:SetText (L["Resume"])
      kpg.rolling = 2
      if (rem < 6) then
        if (kpg.frdb.use_extend) then
          rem = kpg.frdb.roll_extend + 1
        else
          rem = 6
        end
      end
      kpg.lootroll.resume = rem
    else
      local etime = GetTime() + kpg.lootroll.resume
      kpg.lootroll.endtime = etime
      kpg.lootroll.lastwarn = nil
      kpg.lootroll.mark5 = nil
      kpg.lootroll.resume = nil
      kpg.qf.pauseroll:SetText (L["Pause Roll"])
      kpg.rolling = 1
    end
  end
end

local function auto_loot_ok (skipgive)
  local li = kpg.qf.confirmframe
  if (not skipgive) then
    if (li.slot ~= 0 and li.target) then
      GiveMasterLoot (li.slot, li.target)
    end
  end
  if (li.denched) then
    kpg:AddLootHistory (kpg:TimeStamp (), li.ilink, li.who, li.class, "D")
  end
  if (kpg.isml) then
    kpg.SendAM ("BIREM", "ALERT", kpg.qf.confirmframe.idx)
  end
  kpg:RemoveItemByIdx (kpg.qf.confirmframe.idx)
  kpg.qf.confirmframe:Hide ()
  kpg.qf.lootframe:Show ()
  reset_roll_buttons ()
end

--
-- Called when a user presses 'Cancel' in the autoloot panel.
--
local function auto_loot_cancel ()
  auto_loot_ok (true)
end

--
-- OnUpdate script handler for the open roll timer bar. This needs to examine
-- the remaining time, move the bar and set its color accordingly (it changes
-- from green to red gradually as the timeout gets closer and closer) and
-- deals with the timer expiring.
--
local function rolltimer_onupdate()
  if (not kpg.lootroll) then
    kpg.qf.timerframe:SetScript ("OnUpdate", nil)
    return
  end
  if (kpg.rolling == 2) then
    -- We're paused
    return
  end
  local now = GetTime ()
  if (now > kpg.lootroll.endtime) then
    real_roll_end ()
    return
  end

  local remt = kpg.lootroll.endtime - now
  local warnt = floor(remt)
  local pct = remt / (kpg.frdb.roll_timeout + 1)
  kpg.qf.timerbar:SetStatusBarColor (1-pct, pct, 0)
  kpg.qf.timerbar:SetValue (pct)
  kpg.qf.timertext:SetText (strfmt (L["Roll closing in %s"], ("%.1f)"):format (remt)))
  kpg.qf.timerspark:ClearAllPoints ()
  kpg.qf.timerspark:SetPoint ("CENTER", kpg.qf.timerbar, "LEFT", pct * timerbarwidth, 0)

  if (warnt == 10 and kpg.frdb.announce_countdown and kpg.frdb.announce_how == 3) then
    if (not kpg.lootroll.lastwarn or warnt ~= kpg.lootroll.lastwarn) then
      kpg.lootroll.lastwarn = warnt
      kpg.SendRaidMsg (strfmt (L["%s: roll closing in: %d"], L["MODABBREV"], warnt))
    end
    return
  end

  if (warnt < 5) then
    if (not kpg.lootroll.lastwarn or warnt ~= kpg.lootroll.lastwarn) then
      kpg.lootroll.lastwarn = warnt
      if (kpg.frdb.announce_countdown) then
        if (kpg.frdb.announce_how == 1 or (kpg.frdb.announce_how > 1 and not kpg.lootroll.mark5)) then
          kpg.SendRaidMsg (strfmt (L["%s: roll closing in: %d"], L["MODABBREV"], warnt+1))
          kpg.lootroll.mark5 = true
        end
      end
    end
  end
end

local function rollers_sort_func (a, b)
  if (kpg.rollers[a].roll > kpg.rollers[b].roll) then
    return true
  end
  return false
end

--
-- This is called when a valid player has typed /roll. 
--
local function invalid_roll (player)
  if (kpg.openroll) then
    kpg.SendWhisper (strfmt (L['%s: invalid roll. Use %q for main spec or "/roll 1-1" to cancel a roll.'], L["MODTITLE"], "/roll"), player)
    return
  end
  if (kpg.frdb.offspec_rolls) then
    kpg.SendWhisper (strfmt (L['%s: invalid roll. Use %q for main spec, %q for off-spec or "/roll 1-1" to cancel a roll.'], L["MODTITLE"], main_spec (player), off_spec (player)), player)
  else
    kpg.SendWhisper (strfmt (L['%s: invalid roll. Use %q for main spec or "/roll 1-1" to cancel a roll.'], L["MODTITLE"], main_spec (player)), player)
  end
end

function kpg:RefreshRollers ()
  kpg.lootroll = kpg.lootroll or {}

  --
  -- Create the sorted list of rollers
  --
  kpg.lootroll.mainspec = {}
  kpg.lootroll.offspec = {}
  for k,v in pairs (kpg.rollers) do
    if (v.rit == 1) then
      tinsert (kpg.lootroll.mainspec, k)
    elseif (v.rit == 2) then
      tinsert (kpg.lootroll.offspec, k)
    end
  end
  tsort (kpg.lootroll.mainspec, rollers_sort_func)
  tsort (kpg.lootroll.offspec, rollers_sort_func)

  --
  -- Update the rollers lists
  --
  kpg.qf.mainspec.itemcount = #kpg.lootroll.mainspec
  kpg.qf.offspec.itemcount = #kpg.lootroll.offspec
  kpg.qf.mainspec:SetSelected (nil)
  kpg.qf.offspec:SetSelected (nil)
  kpg.qf.mainspec:UpdateList ()
  kpg.qf.offspec:UpdateList ()
end

local function player_rolled (player, roll, minr, maxr)
  if (not kpg.rolling) then
    return
  end
  local mn, mx = kpg.frdb.main_spec_min, kpg.frdb.main_spec_max
  local om, ox = kpg.frdb.off_spec_min, kpg.frdb.off_spec_max
  local rp = kpg.rollers[player]
  local rmx = mx
  local rox = ox

  if (kpg.frdb.enable_decay and kpg.frdb.decayed) then
    local ared = 0
    if (kpg.frdb.decayed[player] and kpg.frdb.main_decay > 0) then
      ared = kpg.frdb.decayed[player].count[1] * kpg.frdb.main_decay
    end
    if (ared < mx) then
      mx = mx - ared
    end
    ared = 0
    if (kpg.frdb.decayed[player] and kpg.frdb.off_decay > 0) then
      ared = kpg.frdb.decayed[player].count[2] * kpg.frdb.off_decay
    end
    if (ared < ox) then
      ox = ox - ared
    end
  end

  if (kpg.openroll) then
    mn = 1
    mx = 100
    om = 1
    ox = 100
    rmx = 100
    rox = 100
  end

  if (rp) then
    --
    -- If they had rolled before but were using a different min and max,
    -- recheck things, as they may be correcting a main spec versus offspec
    -- roll.
    --
    if ((rp.minr == minr) and (rp.maxr == maxr)) then
      kpg.SendWhisper (strfmt (L["%s: you already rolled %d. New roll ignored."], L["MODTITLE"], kpg.rollers[player].roll), player)
      return
    end

    --
    -- They must be switching specs or rolling 1-1. If they are switching
    -- specs we need to calculate the percentage that they were in the
    -- original range, and set them to the same percentage in the other
    -- range. However, if there is an even difference between the two, we
    -- simply subtract / add.
    --
    if (minr == mn and maxr == mx) then
      rp.rit = 1
      if (minr == rp.omin and maxr == rp.omax) then
        rp.roll = rp.oroll
      else
        rp.roll = tonumber (strfmt ("%d", (kpg.frdb.main_spec_min - 1) + (((mx - kpg.frdb.main_spec_min) + 1) * (rp.pct/100))))
      end
    elseif (minr == om and maxr == ox) then
      rp.rit = 2
      if (minr == rp.omin and maxr == rp.omax) then
        rp.roll = rp.oroll
      else
        rp.roll = tonumber (strfmt ("%d", (kpg.frdb.off_spec_min - 1) + (((ox - kpg.frdb.off_spec_min) + 1) * (rp.pct/100))))
      end
    elseif (minr == 1 and maxr == 1) then
      rp.rit = 0
    else
      invalid_roll (player)
      return
    end
    rp.minr = minr
    rp.maxr = maxr
    kpg.SendAM ("UPDRL", "ALERT", player, minr, maxr, rp.roll, rp.rit)
  else
    --
    -- This is a new roll for this user.
    --
    local ok = false
    local pct
    if (minr == mn and maxr == mx) then
      local df = (mx - mn) + 1
      local dfs = (roll - kpg.frdb.main_spec_min) + 1
      pct = (dfs / df) * 100
      ok = true
    elseif (minr == om and maxr == ox) then
      local df = (ox - om) + 1
      local dfs = (roll - kpg.frdb.off_spec_min) + 1
      pct = (dfs / df) * 100
      ok = true
    elseif (minr == 1 and maxr == 1) then
      return
    end
    if (not ok) then
      invalid_roll (player)
      return
    end

    local class
    if (kpg.lootroll.restrict) then
      if (not kpg.lootroll.restrict[player]) then
        kpg.SendWhisper (strfmt (L["%s: sorry you are not allowed to roll right now."], L["MODTITLE"]), player)
        return
      end
      if (minr ~= kpg.lootroll.tiemin or maxr ~= kpg.lootroll.tiemax) then
        kpg.SendWhisper (strfmt (L['%s: invalid roll. Use %q or "/roll 1-1" to cancel a roll.'], L["MODTITLE"], kpg.lootroll.tiefunction ()), player)
        return
      end

      class = kpg.lootroll.restrict[player]
    else
      --
      -- Check to see if they are eligible for loot. We may have a case here
      -- where no-one is marked as a master loot candidate because the
      -- raid leader had loot set incorrectly, and subsequently changed it
      -- to master looting. In this case we don't want to block the user
      -- from rolling.
      --
      if (kpg.numlooters and kpg.numlooters > 0 and not kpg.looters[player]) then
        kpg.SendWhisper (strfmt (L["%s: you are not eligible to receive this item - roll ignored."], L["MODTITLE"]), player)
        return
      end

      class = kpg.raid.raiders[player].class
    end

    kpg.rollers[player] = {}
    rp = kpg.rollers[player]
    rp.pct = pct
    rp.roll = roll
    rp.minr = minr
    rp.maxr = maxr
    rp.class = class
    rp.omin = minr
    rp.omax = maxr
    rp.oroll = roll
    local rit = 0
    if (minr == mn and maxr == mx) then
      rit = 1
    elseif (minr == om and maxr == ox) then
      rit = 2
    end
    rp.rit = rit
    kpg.SendAM ("NEWRL", "ALERT", player, class, roll, minr, maxr, rp.pct, rit)
  end

  kpg:RefreshRollers ()

  --
  -- If this roll arrived within 5 seconds of the timeout reset the timeout
  -- back up to 5 seconds.
  --
  if (kpg.frdb.use_extend) then
    local now = GetTime ()
    local rem = floor (kpg.lootroll.endtime - now) + 1
    if (rem < 6) then
      kpg.lootroll.endtime = now + kpg.frdb.roll_extend + 1
      kpg.lootroll.lastwarn = nil
      kpg.lootroll.mark5 = nil
    end
  end
end

--
-- Either remove an item or cancel a bid / roll.
--
local function remove_or_cancel ()
  if (kpg.rolling) then
    kpg.SendRaidWarning (strfmt (L["Roll for %s cancelled!"], kpg.lootitem.loot.ilink))
    kpg:SelectLootItem (kpg.selectedloot, kpg.lootitem.itemid)
    kpg.rolling = nil
    kpg.qf.timerframe:Hide ()
    kpg.qf.timerframe:SetScript ("OnUpdate", nil)
    if (kpg.isml) then
      kpg.SendAM ("BICAN", "ALERT")
    end
    kpg:ResetRollers ()
    return
  end

  if (kpg.isml) then
    kpg.SendAM ("BIREM", "ALERT", kpg.selectedloot)
  end
  if (kpg.selectedloot) then
    kpg:RemoveItemByIdx (kpg.selectedloot)
  end
end

local function llist_newitem (objp, num)
  local bname = "KPGLListButton" .. tostring(num)
  local rf = MakeFrame ("Button", bname, objp.content)
  local nfn = "GameFontNormalSmallLeft"
  local htn = "Interface/QuestFrame/UI-QuestTitleHighlight"

  rf:SetWidth (350)
  rf:SetHeight (16)
  rf:SetHighlightTexture (htn, "ADD")
  rf:RegisterForClicks ("LeftButtonUp", "RightButtonUp")

  local text = rf:CreateFontString (nil, "ARTWORK", nfn)
  text:ClearAllPoints ()
  text:SetPoint ("TOPLEFT", rf, "TOPLEFT", 8, -2)
  text:SetPoint ("BOTTOMRIGHT", rf, "BOTTOMRIGHT", -8, 2)
  text:SetJustifyH ("LEFT")
  text:SetJustifyV ("TOP")
  rf.text = text

  rf:SetScript ("OnEnter", function (this, evt, ...)
    if (kpg.frdb.display_tooltips) then
      local idx = this:GetID ()
      GameTooltip:SetOwner (this, "ANCHOR_BOTTOMLEFT", 0, 16)
      GameTooltip:SetHyperlink (kpg.bossloot[idx].ilink)
      GameTooltip:Show ()
    end
  end)
  rf:SetScript ("OnLeave", function (this, evt, ...)
    GameTooltip:Hide ()
  end)

  rf.SetText = function (self, txt)
    self.text:SetText (txt)
  end

  rf:SetScript ("OnClick", function (this, button, down)
    local idx = this:GetID ()
    if (IsModifiedClick ("CHATLINK")) then
      ChatEdit_InsertLink ( kpg.bossloot[idx].ilink)
      return
    end
    if (not kpg.isml) then
      return
    end
    --
    -- If we have a current bid or roll in progress, ignore this attempt to
    -- change the item. If they want to cancel a bid or roll they can now
    -- press Cancel and that will take care of things.
    --
    if (kpg.rolling) then
      return
    end

    local loot = kpg.bossloot[idx]
    local itemid = loot.itemid
    local slot = loot.slot
    if (slot ~= 0) then
      kpg:SetMLCandidates (slot)
    end
    kpg:SelectLootItem (idx, itemid)
    kpg.SendAM ("LISEL", "ALERT", idx, itemid)
    assignpopup:Close ()
    if (button == "RightButton") then
      --
      -- Pop up the loot assignment menu at the cursor position.
      --
      local gx, gy = GetCursorPosition ()
      local uis = UIParent:GetEffectiveScale ()
      gx = gx / uis
      gy = gy / uis
      assignpopup:SetPoint ("TOPLEFT", UIParent, "BOTTOMLEFT", gx, gy)
      assignpopup:Show ()
    else
      reset_roll_buttons ()
    end
  end)

  return rf
end

local function llist_setitem (objp, idx, slot, btn)
  btn:SetText (kpg.bossloot[idx].ilink)
  btn:SetID (idx)
  btn:Show ()
end

local function llist_selectitem (objp, idx, slot, btn, onoff)
  if (onoff) then
    kpg:SelectLootItem (idx)
  else
    kpg.selectedloot = nil
    kpg.lootitem = nil
    if (initdone) then
      reset_roll_buttons ()
    end
  end
end

local function xlist_newitem (objp, num, nm, wan, owan)
  local bname = nm .. tostring(num)
  local rf = MakeFrame ("Button", bname, objp.content)
  local nfn = "GameFontNormalSmallLeft"
  local htn = "Interface/QuestFrame/UI-QuestTitleHighlight"
  rf.wan = wan
  rf.owan = owan

  rf:SetWidth (155)
  rf:SetHeight (16)
  rf:SetHighlightTexture (htn, "ADD")

  local text = rf:CreateFontString (nil, "ARTWORK", nfn)
  text:ClearAllPoints ()
  text:SetPoint ("TOPLEFT", rf, "TOPLEFT", 4, -2)
  text:SetPoint ("BOTTOMRIGHT", rf, "BOTTOMRIGHT", -36, 2)
  text:SetJustifyH ("LEFT")
  text:SetJustifyV ("TOP")
  rf.who = text

  local how = rf:CreateFontString (nil, "ARTWORK", nfn)
  how:ClearAllPoints ()
  how:SetPoint ("TOPRIGHT", rf, "TOPRIGHT", -2, -2)
  how:SetPoint ("BOTTOMLEFT", text, "BOTTOMRIGHT", 4, 0)
  how:SetJustifyH ("RIGHT")
  how:SetJustifyV ("TOP")
  rf.how = how

  rf.SetText = function (self, usr, cls, roll)
    self.who:SetText (class (usr, cls))
    self.how:SetText (strfmt ("%d", roll))
  end

  rf:SetScript ("OnClick", function (this, button, down)
    if (not kpg.isml) then
      return
    end
    local idx = this:GetID ()
    kpg.qf[this.owan]:SetSelected (nil)
    kpg.rollerlist = this.wan
    kpg.selectedroller = kpg.lootroll[this.wan][idx]
    kpg.qf[this.wan]:SetSelected (idx)
  end)

  return rf
end

local function rlist_setitem (objp, idx, slot, btn)
  local rp = kpg.lootroll[btn.wan][idx]
  btn:SetText (rp, kpg.rollers[rp].class, kpg.rollers[rp].roll)
  btn:SetID (idx)
  btn:Show ()
end

local function rlist_selectitem (objp, idx, slot, btn, onoff)
  if (onoff) then
    if (not kpg.selectedroller) then
      return
    end
    kpg.qf.switch:SetEnabled (true)
    kpg.qf.remroll:SetEnabled (true)
  else
    kpg.selectedroller = nil
    kpg.rollerlist = nil
    if (initdone) then
      kpg.qf.switch:SetEnabled (false)
      kpg.qf.remroll:SetEnabled (false)
    end
  end
end

local function mlist_newitem (objp, num)
  return xlist_newitem (objp, num, "KPGMainListBtn", "mainspec", "offspec")
end

local function olist_newitem (objp, num)
  return xlist_newitem (objp, num, "KPGOffListBtn", "offspec", "mainspec")
end

function kpg:InitialiseLootGUI ()
  local arg

  local ypos = 0

  local cf = kpg.mainwin.tabs[kpg.LOOT_TAB].content
  local ts = cf.hsplit.topframe
  local bs = cf.hsplit.bottomframe

  arg = {
    inset = 2, height = 32,
    name = "KPGLootBSplit", topanchor = true,
  }
  bs.hsplit = KUI:CreateHSplit (arg, bs)
  local bt = bs.hsplit.topframe
  local bb = bs.hsplit.bottomframe
  kpg.qf.spark = bt
  kpg.qf.rollers = bb

  --
  -- The top frame serves two purposes. The first is to have the full loot
  -- list and the buttons that control the looting process. However, when
  -- a roll is done and a winner determined, if the user has auto-looting
  -- enabled, this top window is temporarily hidden and replaced with the
  -- loot assignment confirmation page. This will inform the ML of the item
  -- that was rolled for and who the winner was. This gives them the
  -- opportunity to confirm the auto-assignment before giving it to the
  -- user. So we create a frame that covers the entire top frame that will
  -- contain the confirmation widgets. We must take care to redisplay the
  -- main loot frame when KPG is hidden and then shown.
  --
  ts.confirmframe = MakeFrame ("Frame", nil, ts)
  ts.confirmframe:SetAllPoints (ts)
  ts.confirmframe:Hide ()
  ts.lootframe = MakeFrame ("Frame", nil, ts)
  ts.lootframe:SetAllPoints (ts)
  kpg.qf.confirmframe = ts.confirmframe
  kpg.qf.lootframe = ts.lootframe

  --
  -- The top panel will contain the scrollable loot list and the roll
  -- control buttons. We need to create the frame for this scroll list.
  --
  ts.llistframe = MakeFrame ("Frame", nil, ts.lootframe)
  ts.llistframe:SetWidth (370)
  ts.llistframe:SetPoint ("TOPLEFT", ts.lootframe, "TOPLEFT", 0, 0)
  ts.llistframe:SetPoint ("BOTTOMLEFT", ts.lootframe, "BOTTOMLEFT", 0, 0)

  arg = {
    name = "KPGLootScrollList",
    itemheight = 16,
    newitem = llist_newitem,
    setitem = llist_setitem,
    selectitem = llist_selectitem,
    highlightitem = function (objp, idx, slot, btn, onoff)
      return KUI.HighlightItemHelper (objp, idx, slot, btn, onoff)
    end,
  }
  ts.llist = KUI:CreateScrollList (arg, ts.llistframe)
  kpg.qf.lootlist = ts.llist

  local bdrop = {
    bgFile = KUI.TEXTURE_PATH .. "TDF-Fill",
    tile = true,
    tileSize = 32,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  }
  ts.llist:SetBackdrop (bdrop)

  arg = {
    x = 375, y = ypos, text = L["Start Roll"],
    tooltip = { title = "$$", text = L["TIP010"] },
    enabled = false,
  }
  ts.startroll = KUI:CreateButton (arg, ts.lootframe)
  ypos = ypos - 24
  ts.startroll:Catch ("OnClick", function (this, evt)
    start_or_end_roll ()
  end)
  kpg.qf.startroll = ts.startroll

  arg = {
    x = 375, y = ypos, text = L["Pause Roll"],
    tooltip = { title = "$$", text = L["TIP011"] },
    enabled = false,
  }
  ts.pauseroll = KUI:CreateButton (arg, ts.lootframe)
  ypos = ypos - 24
  ts.pauseroll:Catch ("OnClick", function (this, evt)
    pause_resume_roll ()
  end)
  kpg.qf.pauseroll = ts.pauseroll

  arg = {
    x = 375, y = ypos, text = L["Remove Item"],
    tooltip = { title = "$$", text = L["TIP012"] },
    enabled = false,
  }
  ts.remove = KUI:CreateButton (arg, ts.lootframe)
  ypos = ypos - 24
  ts.remove:Catch ("OnClick", function (this, evt)
    remove_or_cancel ()
  end)
  kpg.qf.remove = ts.remove

  --
  -- Stuff for the auto-loot confirmation frame
  --
  arg = {
    x = "CENTER", y = 0, height = 24, width = 350, autosize = false,
    font = "GameFontNormal", text = "",
    color = {r = 1, g = 1, b = 1, a = 1 }, border = true,
    justifyh = "CENTER",
  }
  ts.confirmframe.item = KUI:CreateStringLabel (arg, ts.confirmframe)
  kpg.qf.autoassign_item = ts.confirmframe.item

  arg = {
    x = 0, y = 0, width = 1, height = 1, autosize = false,
    color = {r = 1, g = 0, b = 0, a = 1 }, text = "",
    font = "GameFontNormal", justifyv = "TOP",
  }
  ts.confirmframe.str = KUI:CreateStringLabel (arg, ts.confirmframe)
  ts.confirmframe.str:ClearAllPoints ()
  ts.confirmframe.str:SetPoint ("TOPLEFT", ts.confirmframe, "TOPLEFT", 4, -30)
  ts.confirmframe.str:SetPoint ("BOTTOMRIGHT", ts.confirmframe, "BOTTOMRIGHT", -4, 28)
  ts.confirmframe.str.label:SetPoint ("TOPLEFT", ts.confirmframe.str, "TOPLEFT", 0, 0)
  ts.confirmframe.str.label:SetPoint ("BOTTOMRIGHT", ts.confirmframe.str, "BOTTOMRIGHT", 0, 0)
  kpg.qf.autoassign_msg = ts.confirmframe.str

  arg = {
    x = 140, y = -104, width = 90, text = K.OK_STR,
  }
  ts.confirmframe.ok = KUI:CreateButton (arg, ts.confirmframe)
  ts.confirmframe.ok:Catch ("OnClick", function (this, evt, ...)
    auto_loot_ok ()
  end)

  arg = {
    x = 250, y = -104, width = 90, text = K.CANCEL_STR,
  }
  ts.confirmframe.cancel = KUI:CreateButton (arg, ts.confirmframe)
  ts.confirmframe.cancel:Catch ("OnClick", function (this, evt, ...)
    auto_loot_cancel ()
  end)

  --
  -- The rollers frame. We need to create a frame for the scroll list, and
  -- then the buttons along the side.
  --
  ypos = 0
  arg = {
    x = 0, y = ypos, text = L["[Main Spec]"], autosize = false,
    width = 160, font = "GameFontNormal",
  }
  bb.str1 = KUI:CreateStringLabel (arg, bb)
  arg.x = 190
  arg.text = L["[Off-spec]"]
  bb.str2 = KUI:CreateStringLabel (arg, bb)
  kpg.qf.offtext = bb.str2

  bb.mainspec = MakeFrame ("Frame", nil, bb)
  bb.mainspec:SetWidth (175)
  bb.mainspec:SetPoint ("TOPLEFT", bb, "TOPLEFT", 0, -20)
  bb.mainspec:SetPoint ("BOTTOMLEFT", bb, "BOTTOMLEFT", 0, 0)
  kpg.qf.mainspec = bb.mainspec
  bb.offspec = MakeFrame ("Frame", nil, bb)
  bb.offspec:SetWidth (175)
  bb.offspec:SetPoint ("TOPLEFT", bb.mainspec, "TOPRIGHT", 15, 0)
  bb.offspec:SetPoint ("BOTTOMLEFT", bb.mainspec, "BOTTOMRIGHT", 10, 0)
  kpg.qf.offspec = bb.offspec

  arg = {
    name = "KPGMainScrollList",
    itemheight = 16,
    newitem = mlist_newitem,
    setitem = rlist_setitem,
    selectitem = rlist_selectitem,
    highlightitem = function (objp, idx, slot, btn, onoff)
      return KUI.HighlightItemHelper (objp, idx, slot, btn, onoff)
    end,
  }
  bb.mlist = KUI:CreateScrollList (arg, bb.mainspec)
  kpg.qf.mainspec = bb.mlist

  arg.name = "KPGOffScrollList"
  arg.newitem = olist_newitem
  bb.olist = KUI:CreateScrollList (arg, bb.offspec)
  kpg.qf.offspec = bb.olist

  arg = {
    x = 375, y = ypos, text = L["Remove"],
    tooltip = { title = "$$", text = L["TIP014"] },
    enabled = false,
  }
  bb.remroll = KUI:CreateButton (arg, bb)
  bb.remroll:Catch ("OnClick", function (this, evt)
    local rp = kpg.rollers[kpg.selectedroller]
    player_rolled (kpg.selectedroller, 0, 1, 1)
  end)
  kpg.qf.remroll = bb.remroll
  ypos = ypos - 24

  arg = {
    x = 375, y = ypos, text = L["Switch Spec"],
    tooltip = { title = "$$", text = L["TIP015"] },
    enabled = false,
  }
  bb.switch = KUI:CreateButton (arg, bb)
  bb.switch:Catch ("OnClick", function (this, evt)
    local rp = kpg.rollers[kpg.selectedroller]
    local mn, mx = kpg.frdb.main_spec_min, kpg.frdb.main_spec_max
    local om, ox = kpg.frdb.off_spec_min, kpg.frdb.off_spec_max

    if (kpg.frdb.enable_decay and kpg.frdb.decayed) then
      local ared = 0
      if (kpg.frdb.decayed[kpg.selectedroller]) then
        ared = kpg.frdb.decayed[kpg.selectedroller].count[1] * kpg.frdb.main_decay
        if (ared < mx) then
          mx = mx - ared
        end
        ared = kpg.frdb.decayed[kpg.selectedroller].count[2] * kpg.frdb.off_decay
        if (ared < ox) then
          ox = ox - ared
        end
      end
    end

    if (rp.minr == mn and rp.maxr == mx) then
      player_rolled (kpg.selectedroller, 0, om, ox)
    elseif (rp.minr == om and rp.maxr == ox) then
      player_rolled (kpg.selectedroller, 0, mn, mx)
    end
  end)
  kpg.qf.switch = bb.switch
  ypos = ypos - 48

  arg = {
    x = 375, y = ypos, text = L["Main Spec Roll"],
    enabled = false
  }
  bb.mymainroll = KUI:CreateButton (arg, bb)
  bb.mymainroll:Catch ("OnClick", function (this, evt)
    local _, mn, mx = main_spec (K.player.player)
    RandomRoll (mn, mx)
    if (kpg.isml) then
      kpg.qf.myoffroll:SetEnabled (false)
      kpg.qf.mymainroll:SetEnabled (false)
    end
  end)
  kpg.qf.mymainroll = bb.mymainroll
  ypos = ypos - 24

  arg = {
    x = 375, y = ypos, text = L["Off-spec Roll"],
    enabled = false
  }
  bb.myoffroll = KUI:CreateButton (arg, bb)
  bb.myoffroll:Catch ("OnClick", function (this, evt)
    local _, mn, mx = off_spec (K.player.player)
    RandomRoll (mn, mx)
    if (kpg.isml) then
      kpg.qf.myoffroll:SetEnabled (false)
      kpg.qf.mymainroll:SetEnabled (false)
    end
  end)
  kpg.qf.myoffroll = bb.myoffroll
  ypos = ypos - 32

  bb.mymainroll:SetShown (false)
  bb.myoffroll:SetShown (false)

  bt.timerbarframe = MakeFrame ("Frame", "KPGLootRollTimerFrame", bt)
  kpg.qf.timerframe = bt.timerbarframe
  bt.timerbarframe:ClearAllPoints ()
  bt.timerbarframe:SetPoint ("TOPLEFT", bt, "TOPLEFT", 0, 0)
  bt.timerbarframe:SetPoint ("BOTTOMRIGHT", bt, "BOTTOMRIGHT", 0, 0)
  bt.timerbarframe:SetBackdrop ( {
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    })
  bt.timerbarframe:SetBackdropBorderColor (0.4, 0.4, 0.4)
  bt.timerbarframe:SetBackdropColor (0, 0, 0, 0)
  bt.timerbarframe:Hide ()

  bt.timerbar = MakeFrame ("StatusBar", nil, bt.timerbarframe)
  bt.timerbar:ClearAllPoints ()
  bt.timerbar:SetPoint ("TOPLEFT", bt.timerbarframe, "TOPLEFT", 8, -8)
  bt.timerbar:SetPoint ("BOTTOMRIGHT", bt.timerbarframe, "BOTTOMRIGHT", -8, 8)
  bt.timerbar:SetStatusBarTexture ("Interface/TargetingFrame/UI-StatusBar")
  bt.timerbar:SetStatusBarColor (0, 1, 0)
  bt.timerbar:SetMinMaxValues (0, 1)
  kpg.qf.timerbar = bt.timerbar

  bt.timertext = bt.timerbar:CreateFontString (nil, "OVERLAY", "GameFontNormal")
  bt.timertext:ClearAllPoints ()
  bt.timertext:SetPoint ("TOPLEFT", bt.timerbar, "TOPLEFT", 0, 0)
  bt.timertext:SetPoint ("BOTTOMRIGHT", bt.timerbar, "BOTTOMRIGHT", 0, 0)
  bt.timertext:SetTextColor (1,1,1,1)
  bt.timertext:SetJustifyH ("CENTER")
  bt.timertext:SetJustifyV ("MIDDLE")
  kpg.qf.timertext = bt.timertext

  bt.timerspark = bt.timerbar:CreateTexture (nil, "OVERLAY")
  bt.timerspark:SetTexture ("Interface/CastingBar/UI-CastingBar-Spark")
  bt.timerspark:SetBlendMode ("ADD")
  bt.timerspark:SetWidth (20)
  bt.timerspark:SetHeight (44)
  kpg.qf.timerspark = bt.timerspark

  local function bt_onevent (this, evt, arg1, ...)
    if (evt == "CHAT_MSG_SYSTEM") then
      local plr, roll, minr, maxr = LibDeformat.Deformat (arg1, RANDOM_ROLL_RESULT)
      if (plr and (not strfind (plr, "-", 1, true))) then
        local ds = plr .. "-"
        local ss, se
        for k, v in pairs (kpg.raid.raiders) do
          ss, se = strfind (k, ds, 1, true)
          if (ss == 1) then
            plr = k
            break
          end
        end
      end
      local player = K.CanonicalName (plr, nil)
      if (player and (not kpg.raid.raiders[player])) then
        player = nil
      end
      if (player and roll and minr and maxr) then
        player_rolled (player, roll, minr, maxr)
      end
    end
  end

  bt.StartRoll = function ()
    --
    -- We want to disable other roll trackers. This is the place to do it.
    -- Currently I only know about LootHog. Add others here.
    --
    kpg.lootroll = {}
    if (loothog_settings) then
      if (loothog_settings["enable"]) then
        if (loothog_turnoff) then
          kpg.lootroll.lhdisabled = true
          loothog_turnoff()
        end
      end
    end

    kpg.lootroll.endtime = GetTime () + kpg.frdb.roll_timeout + 1
    kpg.rollers = {}
    kpg.lootroll.mainspec = {}
    kpg.lootroll.offspec = {}
    if (kpg.frdb.use_timeout) then
      bt.timerbarframe:Show ()
      timerbarwidth = kpg.qf.timerbar:GetWidth ()
      bt.timerbarframe:SetScript ("OnUpdate", rolltimer_onupdate)
    end
    active_roll_buttons ()
    bt:RegisterEvent ("CHAT_MSG_SYSTEM")
    bt:SetScript ("OnEvent", bt_onevent)
  end

  local function bt_onhide ()
    if (kpg.rolling == 0 or not kpg.rolling) then
      kpg:CleanupLootRoll ()
    elseif (kpg.rolling == 1) then
      pause_resume_roll ()
    elseif (kpg.rolling == 2) then
      kpg.rolling = 3
    end
  end

  local function bt_onshow ()
    if (kpg.rolling == 2) then
      pause_resume_roll ()
    elseif (kpg.rolling == 3) then
      kpg.rolling = 2
    end
  end
  bt:SetScript ("OnHide", bt_onhide)
  bt:SetScript ("OnShow", bt_onshow)

  --
  -- Set up the popup menu that will be displayed if the user right-clicks
  -- an item in the loot list.
  --
  arg = {
    name = "KPGLootAssignPopup", items = KUI.emptydropdown,
    canmove = false, canresize = true, border = "THIN",
    itemheight = 16, height = 176, minheight = 80, minwidth = 80,
    escclose = true, mode = "COMPACT", timeout = 3,
    func = function (tbf, cr)
      if (not cr) then
        local loot = kpg.bossloot[kpg.selectedloot]
        local lidx = loot.slot
        local gidx = tbf.value
        assignpopup:Close ()
        GiveMasterLoot (lidx, gidx)
        if (kpg.isml) then
          kpg.SendAM ("BIREM", "ALERT", kpg.selectedloot)
        end
        kpg:RemoveItemByIdx (kpg.selectedloot)
      end
    end,
  }
  assignpopup = KUI:CreatePopupMenu (arg, UIParent)

  initdone = true
  kpg:ResetBossLoot ()
end

function kpg:ResetRollers ()
  kpg.rollers = nil
  reset_roll_buttons ()
  kpg.qf.mainspec:SetSelected (nil)
  kpg.qf.offspec:SetSelected (nil)
  if (kpg.lootroll) then
    kpg.lootroll.mainspec = {}
    kpg.lootroll.offspec = {}
  end
  kpg.qf.mainspec.itemcount = 0
  kpg.qf.offspec.itemcount = 0
  kpg.qf.mainspec:UpdateList ()
  kpg.qf.offspec:UpdateList ()
end

function kpg:ResetBossLoot ()
  kpg.qf.lootlist:SetSelected (nil)
  kpg.selectedloot = nil
  kpg.qf.lootlist.itemcount = 0
  kpg.qf.lootlist:UpdateList ()
  kpg:ResetRollers ()
  kpg.bossloot = nil
  kpg.lootitem = nil
  reset_roll_buttons ()
  assignpopup:Close ()
  kpg.qf.timerframe:Hide ()
  kpg.qf.timerframe:SetScript ("OnUpdate", nil)
  kpg.qf.confirmframe:Hide ()
  kpg.qf.lootframe:Show ()
end

function kpg:SelectLootItem (idx, itemid)
  kpg.selectedloot = idx
  kpg.qf.lootlist:SetSelected (idx)
  kpg.lootitem = { idx = idx, itemid = itemid }
  kpg.lootitem.loot = kpg.bossloot[idx]

  if (kpg.isml == true) then
    reset_roll_buttons ()
  end
end

function kpg:RemoveItemByIdx (idx)
  if (idx == kpg.selectedloot) then
    kpg.qf.lootlist:SetSelected (nil)
  end
  tremove (kpg.bossloot, idx)
  kpg.qf.lootlist.itemcount = #kpg.bossloot
  kpg.qf.lootlist:UpdateList ()
  kpg:ResetRollers ()
end

function kpg:AddLoot (ilink, nocmd)
  if (not kpg.isml) then
    return
  end

  local added = false
  if (kpg.bossloot) then
    added = true
  end
  kpg:AddItemToBossLoot (ilink, 1)
  kpg.qf.lootlist.itemcount = #kpg.bossloot
  kpg.qf.lootlist:UpdateList ()

  if (not added) then
    if (not nocmd) then
      kpg:SendConfig ()
      kpg.SendAM ("OLOOT", "ALERT", K.player.player, "0", false, {{ ilink, 1}})
      if (not kpg.mainwin:IsVisible ()) then
        kpg.autoshown = true
      end
      kpg.mainwin:Show ()
      kpg.mainwin:SetTab (kpg.LOOT_TAB)
    end
  else
    if (not nocmd) then
      kpg.SendAM ("ALOOT", "ALERT", ilink)
    end
  end
  if (not kpg.uguid) then
    kpg.uguid = 0
  end
end

function kpg:CleanupLootRoll ()
  kpg.qf.spark:UnregisterEvent ("CHAT_MSG_SYSTEM")
  kpg.qf.spark:SetScript ("OnEvent", nil)
  kpg.qf.spark.timerbarframe:SetScript ("OnUpdate", nil)
  if (kpg.lootroll and kpg.lootroll.lhdisabled) then
    loothog_turnoff()
  end
  kpg.rolling = nil
  kpg.lootroll = nil
  kpg:ResetRollers ()
  kpg.qf.lootlist:SetSelected (nil)
  kpg.selectedloot = nil
end

function kpg:UpdateCandidatesPopup ()
  local items = {}

  for k,v in pairs (kpg.looters) do
    tinsert (items, { text = k, value = v.mlidx, notcheckable = true })
  end
  tsort (items, function (a,b) return a.text < b.text end)

  for k,v in pairs (items) do
    v.text = class(v.text, kpg.raid.raiders[v.text].class)
  end

  tinsert (items, 1, { text = GIVE_LOOT, value = 0, title = true, })
  assignpopup:UpdateItems (items)
end
