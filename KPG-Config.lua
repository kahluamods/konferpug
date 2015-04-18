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
  error ("KahLua KonferSK: could not find KahLua Kore.", 2)
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
local class = kpg.class

--
-- This file contains all of the UI initialisation code for KahLua KonferPUG.
--

local ignore
local sorted = {}
local decayed_users = {}
local seluser

local function button_click (this)
  if (not seluser) then
    return
  end
  if (kpg.inraid and not kpg.isml) then
    return
  end
  local idx = seluser
  if (not decayed_users or not decayed_users[idx]) then
    return
  end
  local duser = decayed_users[idx]
  local ruser = kpg.frdb.decayed[duser.name]
  local maxes = { kpg.frdb.main_max, kpg.frdb.off_max }
  ruser.count[this.incidx] = ruser.count[this.incidx] + this.incdec

  if (ruser.count[this.incidx] < 0) then
    ruser.count[this.incidx] = 0
  elseif (ruser.count[this.incidx] > maxes[this.incidx]) then
    ruser.count[this.incidx] = maxes[this.incidx]
  end
  if (kpg.inraid and kpg.isml) then
    kpg.SendAM ("SETDC", "ALERT", duser.name, ruser.class, ruser.count[1], ruser.count[2])
  end
  if (ruser.count[1] == 0 and ruser.count[2] == 0) then
    kpg.frdb.decayed[duser.name] = nil
  end
  kpg:RefreshDecayedUsers ()
end

local function dlist_newitem (objp, num)
  local bname = "KPGDecayListButton" .. tostring(num)
  local rf = MakeFrame ("Button", bname, objp.content)
  local nfn = "GameFontNormalSmallLeft"
  local hfn = "GameFontHighlightSmallLeft"
  local htn = "Interface/QuestFrame/UI-QuestTitleHighlight"

  rf:SetWidth (400)
  rf:SetHeight (16)
  rf:SetHighlightTexture (htn, "ADD")

  local who = rf:CreateFontString (nil, "OVERLAY", nfn)
  who:ClearAllPoints ()
  who:SetPoint ("TOPLEFT", rf, "TOPLEFT", 4, -2)
  who:SetPoint ("BOTTOMLEFT", rf, "BOTTOMLEFT", 4, -2)
  who:SetWidth (100)
  who:SetJustifyH ("LEFT")
  who:SetJustifyV ("TOP")
  rf.who = who

  local mcount = rf:CreateFontString (nil, "OVERLAY", nfn)
  mcount:ClearAllPoints ()
  mcount:SetPoint ("TOPLEFT", who, "TOPRIGHT", 4, 0)
  mcount:SetPoint ("BOTTOMLEFT", who, "BOTTOMRIGHT", 4, 0)
  mcount:SetWidth (150)
  mcount:SetJustifyH ("LEFT")
  mcount:SetJustifyV ("TOP")
  rf.mcount = mcount

  local ocount = rf:CreateFontString (nil, "OVERLAY", nfn)
  ocount:ClearAllPoints ()
  ocount:SetPoint ("TOPLEFT", mcount, "TOPRIGHT", 16, 0)
  ocount:SetPoint ("BOTTOMLEFT", mcount, "BOTTOMRIGHT", 16, 0)
  ocount:SetWidth (150)
  ocount:SetJustifyH ("LEFT")
  ocount:SetJustifyV ("TOP")
  rf.ocount = ocount

  rf.SetText = function (self, wo, cnt)
    self.who:SetText (wo)
    self.mcount:SetText (strfmt ("Main Spec: %d (%d)", cnt[1], cnt[1] * kpg.frdb.main_decay))
    self.ocount:SetText (strfmt ("Off-spec: %d (%d)", cnt[2], cnt[2] * kpg.frdb.off_decay))
  end

  rf:SetScript ("OnClick", function (this, btn)
    local idx = this:GetID ()
    this:GetParent():GetParent():SetSelected (idx, false)
  end)

  return rf
end

local function dlist_setitem (objp, idx, slot, btn)
  local duser = decayed_users[idx]
  local usr = class (duser)

  btn:SetText (usr, duser.count)
  btn:SetID (idx)
  btn:Show ()
end

local function dlist_selectitem (objp, idx, slot, btn, onoff)
  if (onoff == true) then
    seluser = idx
    kpg.qf.dtopwin:Show ()
  else
    seluser = nil
    kpg.qf.dtopwin:Hide ()
  end
end

function kpg:InitialiseConfigGUI ()
  local arg
  local ypos = 0
  local cf = kpg.qf.lootopts

  arg = {
    x = 0, y = ypos,
    label = { text = L["Auto-open Loot Panel When Corpse Looted"] },
    tooltip = { title = "$$", text = L["TIP001"] },
  }
  cf.autoopen = KUI:CreateCheckBox (arg, cf)
  cf.autoopen:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.auto_open = val
  end)
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos, label = { text = L["Display Tooltips in Loot List"] },
    tooltip = { title = "$$", text = L["TIP002"] },
  }
  cf.tooltips = KUI:CreateCheckBox (arg, cf)
  cf.tooltips:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.tooltips = val
  end)
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos, label = { text = L["Announce Loot"] },
    tooltip = { title = "$$", text = L["TIP003"] },
  }
  cf.announce = KUI:CreateCheckBox (arg, cf)
  cf.announce:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.announce_loot = val
  end)

  arg = {
    x = 230, y = ypos, label = { text = L["Announce Winners in Raid"] },
    tooltip = { title = "$$", text = L["TIP007"] },
  }
  cf.winners = KUI:CreateCheckBox (arg, cf)
  cf.winners:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.announce_winners = val
  end)
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos, label = { text = L["Auto-assign Loot When Roll Ends"] },
    tooltip = { title = "$$", text = L["TIP008"] },
  }
  cf.autoloot = KUI:CreateCheckBox (arg, cf)
  cf.autoloot:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.auto_loot = val
  end)
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos,
    label = { text = L["Assign to Enchanter if no-one rolls"] },
    tooltip = { title = "$$", text = L["TIP009"] },
  }
  cf.disenchant = KUI:CreateCheckBox (arg, cf)
  cf.disenchant:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.disenchant = val
  end)
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos, label = { text = L["Enable Chat Message Filter"] },
    tooltip = { title = "$$", text = L["TIP004"] },
  }
  cf.chatfilter = KUI:CreateCheckBox (arg, cf)
  cf.chatfilter:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.chat_filter = val
    kpg:SendMessage ("KPG_CONFIG_ADMIN", kpg.isml)
  end)
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos, label = { text = L["Record Loot Assignment History"] },
  }
  cf.history = KUI:CreateCheckBox (arg, cf)
  cf.history:Catch ("OnValueChanged", function (this, evt, val, usr)
    if (usr and not val) then
      kpg.frdb.history = {}
      kpg:RefreshHistory ()
    end
    kpg.frdb.record_history = val
  end)
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos, label = { text = L["Enable Off-spec Rolls"] },
    tooltip = { title = "$$", text = L["TIP024"] },
  }
  cf.offspec = KUI:CreateCheckBox (arg, cf)
  cf.offspec:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.offspec_rolls = val
    if (val) then
      kpg.qf.offspec:Show (val)
    else
      kpg.qf.offspec:Hide (val)
    end
    kpg.qf.switch:SetShown (val)
    kpg.qf.offtext:SetShown (val)
    kpg.qf.osmin:SetEnabled (val)
    kpg.qf.osmax:SetEnabled (val)
  end)
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos, label = { text = L["Enable Countdown Timer"] },
    tooltip = { title = "$$", text = L["TIP036"] },
  }
  cf.entimer = KUI:CreateCheckBox (arg, cf)
  cf.entimer:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.use_timeout = val
    kpg.qf.extendopt:SetEnabled (val)
    kpg.qf.rollto:SetEnabled (val)
    kpg.qf.rollext:SetEnabled (val and kpg.frdb.use_extend)
    kpg.qf.pauseroll:SetShown (val)
    kpg.qf.announcecount:SetEnabled (val)
    kpg.qf.announcehow:SetEnabled (val and kpg.frdb.announce_countdown)
  end)

  arg = {
    x = 230, y = ypos, label = { text = L["Enable Countdown Extension"] },
    tooltip = { title = "$$", text = L["TIP037"] },
  }
  cf.enext = KUI:CreateCheckBox (arg, cf)
  cf.enext:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.use_extend = val
    kpg.qf.rollext:SetEnabled (val and kpg.frdb.use_timeout)
  end)
  kpg.qf.extendopt = cf.enext
  ypos = ypos - 24

  arg = {
    label = { text = L["Roll Timeout"] },
    x = 0, y = ypos, minval = 5, maxval = 60,
    tooltip = { title = "$$", text = L["TIP005"] },
  }
  cf.rolltimeout = KUI:CreateSlider (arg, cf)
  cf.rolltimeout:Catch ("OnValueChanged", function (this, evt, newv)
    kpg.frdb.roll_timeout = newv
  end)
  kpg.qf.rollto = cf.rolltimeout

  arg = {
    x = 230, y = ypos, minval = 5, maxval = 30,
    label = { text = L["Roll Timeout Extension"] },
    tooltip = { title = "$$", text = L["TIP006"] },
  }
  cf.rollextend = KUI:CreateSlider (arg, cf)
  cf.rollextend:Catch ("OnValueChanged", function (this, evt, newv)
    kpg.frdb.roll_extend = newv
  end)
  kpg.qf.rollext = cf.rollextend
  ypos = ypos - 48

  arg = {
    x = 0, y = ypos, label = { text = L["Announce Countdown"] },
    tooltip = { title = "$$", text = L["TIP022"] },
  }
  cf.countdown = KUI:CreateCheckBox (arg, cf)
  cf.countdown:Catch ("OnValueChanged", function (this, evt, newv)
    kpg.qf.lootopts.counthow:SetEnabled (newv and kpg.frdb.use_timeout)
    kpg.frdb.announce_countdown = newv
  end)
  kpg.qf.announcecount = cf.countdown

  arg = {
    x = 230, y = ypos, itemheight = 16, mode = "SINGLE", dwidth = 200,
    name = "KPGCountHowDropDown", enabled = false,
    items = {
      {
        text = L["Down from 5 second mark"], value = 1,
        tooltip = { title = "$$", text = L["TIP022.1"] }
      },
      {
        text = L["At 5 second mark"], value = 2,
        tooltip = { title = "$$", text = L["TIP022.2"] }
      },
      {
        text = L["At 5 and 10 second marks"], value = 3,
        tooltip = { title = "$$", text = L["TIP022.3"] }
      },
    },
  }
  cf.counthow = KUI:CreateDropDown (arg, cf)
  cf.counthow:Catch ("OnValueChanged", function (this, evt, newv)
    kpg.frdb.announce_how = newv
  end)
  kpg.qf.announcehow = cf.counthow
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos, label = { text = L["Main Spec Minimum"] },
    len = 4, numeric = true, initialvalue = tostring(kpg.frdb.main_spec_min),
    width = 32,
  }
  cf.msmin = KUI:CreateEditBox (arg, cf)
  cf.msmin:Catch ("OnValueChanged", function (this, evt, value)
    kpg.frdb.main_spec_min = tonumber (value)
  end)
  kpg.qf.msmin = cf.msmin

  arg = {
    x =  200, y = ypos, label = { text = L["Maximum"] },
    len = 4, numeric = true, initialvalue = tostring(kpg.frdb.main_spec_max),
    width = 32,
  }
  cf.msmax = KUI:CreateEditBox (arg, cf)
  cf.msmax:Catch ("OnValueChanged", function (this, evt, value)
    kpg.frdb.main_spec_max = tonumber (value)
  end)
  kpg.qf.msmax = cf.msmax
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos, label = { text = L["Off-spec Minimum"] },
    len = 4, numeric = true, initialvalue = tostring(kpg.frdb.off_spec_min),
    width = 32,
  }
  cf.osmin = KUI:CreateEditBox (arg, cf)
  cf.osmin:Catch ("OnValueChanged", function (this, evt, value)
    kpg.frdb.off_spec_min = tonumber (value)
  end)
  kpg.qf.osmin = cf.osmin

  arg = {
    x =  200, y = ypos, label = { text = L["Maximum"] },
    len = 4, numeric = true, initialvalue = tostring(kpg.frdb.off_spec_max),
    width = 32,
  }
  cf.osmax = KUI:CreateEditBox (arg, cf)
  cf.osmax:Catch ("OnValueChanged", function (this, evt, value)
    kpg.frdb.off_spec_max = tonumber (value)
  end)
  kpg.qf.osmax = cf.osmax
  ypos = ypos - 24

  -- Extra options tab
  cf = kpg.qf.extraopts
  ypos = 0

  arg = {
    x = 0, y = ypos, label = { text = L["Enable Roll Decay"] },
    tooltip = { title = "$$", text = L["TIP028"] }
  }
  cf.decay = KUI:CreateCheckBox (arg, cf)
  cf.decay:Catch ("OnValueChanged", function (this, evt, val)
    kpg.frdb.enable_decay = val
    kpg.qf.extraopts.maindec:SetEnabled (val)
    kpg.qf.extraopts.mainmax:SetEnabled (val)
    kpg.qf.extraopts.offdec:SetEnabled (val)
    kpg.qf.extraopts.offmax:SetEnabled (val)
    kpg.qf.decaytab:SetShown (val)
    if (not val) then
      kpg:ResetDecay ()
    end
  end)
  ypos = ypos - 24

  arg = {
    x = 4, y = ypos, label = { text = L["Main Spec Decay Amount"] },
    tooltip = { title = "$$", text = L["TIP029"] },
    enabled = false, len = 4, numeric = true, width = 32,
    initialvalue = tostring(kpg.frdb.main_decay),
  }
  cf.maindec = KUI:CreateEditBox (arg, cf)
  cf.maindec:Catch ("OnValueChanged", function (this, evt, newv)
    kpg.frdb.main_decay = tonumber (newv)
    kpg:RefreshDecayedUsers ()
  end)

  arg = {
    x = 230, y = ypos, name = "KPGMainMaxDecayDropDown",
    itemheight = 16, mode = "COMPACT", dwidth = 65,
    label = { text = L["Maximum Decay Count"], pos = "LEFT" },
    tooltip = { title = "$$", text = L["TIP030"] },
    enabled = false, items = {
      { text = "1", value = 1 },
      { text = "2", value = 2 },
      { text = "3", value = 3 },
      { text = "4", value = 4 },
      { text = "5", value = 5 },
      { text = "6", value = 6 },
      { text = "7", value = 7 },
      { text = "8", value = 8 },
      { text = "9", value = 9 },
      { text = "10", value = 10 },
    },
  }
  cf.mainmax = KUI:CreateDropDown (arg, cf)
  cf.mainmax:Catch ("OnValueChanged", function (this, evt, newv)
    kpg.frdb.main_max = newv
    kpg:RefreshDecayedUsers ()
  end)
  ypos = ypos - 30

  arg = {
    x = 4, y = ypos, label = { text = L["Off-spec Decay Amount"] },
    tooltip = { title = "$$", text = L["TIP029"] },
    enabled = false, len = 4, numeric = true, width = 32,
    initialvalue = tostring(kpg.frdb.main_decay),
  }
  cf.offdec = KUI:CreateEditBox (arg, cf)
  cf.offdec:Catch ("OnValueChanged", function (this, evt, newv)
    kpg.frdb.off_decay = tonumber (newv)
    kpg:RefreshDecayedUsers ()
  end)

  arg = {
    x = 230, y = ypos, name = "KPGOffMaxDecayDropDown",
    itemheight = 16, mode = "COMPACT", dwidth = 65,
    label = { text = L["Maximum Decay Count"], pos = "LEFT" },
    tooltip = { title = "$$", text = L["TIP030"] },
    enabled = false, items = {
      { text = "1", value = 1 },
      { text = "2", value = 2 },
      { text = "3", value = 3 },
      { text = "4", value = 4 },
      { text = "5", value = 5 },
      { text = "6", value = 6 },
      { text = "7", value = 7 },
      { text = "8", value = 8 },
      { text = "9", value = 9 },
      { text = "10", value = 10 },
    },
  }
  cf.offmax = KUI:CreateDropDown (arg, cf)
  cf.offmax:Catch ("OnValueChanged", function (this, evt, newv)
    kpg.frdb.off_max = newv
    kpg:RefreshDecayedUsers ()
  end)
  ypos = ypos - 30

  cf = kpg.qf.ignores
  cf.ilistframe = MakeFrame ("Frame", nil, cf)
  cf.ilistframe:SetWidth (370)
  cf.ilistframe:SetPoint ("TOPLEFT", cf, "TOPLEFT", 0, 0)
  cf.ilistframe:SetPoint ("BOTTOMLEFT", cf, "BOTTOMLEFT", 0, 0)

  arg = {
    name = "KPGIgnoreScrollIst",
    itemheight = 16,
    newitem = function (objp, num)
      return KUI.NewItemHelper (objp, num, "KPGIListButton", 350, 16,
        nil, nil, function (this, idx)
          kpg.qf.idelbtn:SetEnabled (true)
          ignore = sortedignores[idx]
        end)
      end,
    setitem = function (objp, idx, slot, btn)
      return KUI.SetItemHelper (objp, btn, idx,
        function (op, ix)
          return kpg.frdb.items[sortedignores[ix]]
        end)
      end,
    selectitem = function (objp, idx, slot, btn, onoff)
      return KUI.SelectItemHelper (objp, idx, slot, btn, onoff,
        function () return true end,
        function () if (kpg.qf.idelbtn) then
            kpg.qf.idelbtn:SetEnabled (true)
          end
        end,
        nil,
        function () if (kpg.qf.idelbtn) then
            kpg.qf.idelbtn:SetEnabled (false)
          end
        end)
      end,
    highlightitem = function (objp, idx, slot, btn, onoff)
      return KUI.HighlightItemHelper (objp, idx, slot, btn, onoff)
    end,
  }
  cf.ilist = KUI:CreateScrollList (arg, cf.ilistframe)
  kpg.qf.ignorelist = cf.ilist

  ypos = 0
  arg = {
    x = 375, y = ypos, text = L["Delete"], enabled = false,
    tooltip = { title = "$$", text = L["TIP021"] },
  }
  cf.idelbtn = KUI:CreateButton (arg, cf)
  kpg.qf.idelbtn = cf.idelbtn
  cf.idelbtn:Catch ("OnClick", function (this, evt)
    kpg.frdb.items[ignore] = nil
    ignore = nil
    kpg.qf.ignorelist:SetSelected (nil)
    kpg:RefreshIgnoredItems ()
  end)

  -- The Decay tab
  cf = kpg.qf.decay
  local tf = cf.hsplit.topframe
  local bf = cf.hsplit.bottomframe
  local tb = MakeFrame ("Frame", nil, kpg.qf.dtopbar)
  tb:ClearAllPoints ()
  tb:SetPoint ("TOPLEFT", kpg.qf.dtopbar, "TOPLEFT", 0, 0)
  tb:SetPoint ("BOTTOMRIGHT", kpg.qf.dtopbar, "BOTTOMRIGHT", 0, 0)
  tb:Hide ()

  kpg.qf.decays = tf
  kpg.qf.dbuttons = bf
  kpg.qf.dtopwin = tb

  arg = {
    x = 0, y = 0, text = "Main Spec +", width = 100,
    tooltip = { title = "$$", text = L["TIP034"] }
  }
  local inc = KUI:CreateButton (arg, tb)
  inc:ClearAllPoints ()
  inc:SetPoint ("TOPLEFT", tb, "TOPLEFT", 4, -4)
  inc:SetPoint ("BOTTOMLEFT", tb, "BOTTOMLEFT", 4, 0)
  inc:SetWidth (100)
  tb.maininc = inc
  tb.maininc.incdec = 1
  tb.maininc.incidx = 1
  tb.maininc:Catch ("OnClick", button_click)

  arg = {
    x = 0, y = 0, text = "Main Spec -", width = 100,
    tooltip = { title = "$$", text = L["TIP035"] }
  }
  local dec = KUI:CreateButton (arg, tb)
  dec:ClearAllPoints ()
  dec:SetPoint ("TOPLEFT", inc, "TOPRIGHT", 4, 0)
  dec:SetPoint ("BOTTOMLEFT", inc, "BOTTOMRIGHT", 4, 0)
  dec:SetWidth (100)
  tb.maindec = dec
  tb.maindec.incdec = -1
  tb.maindec.incidx = 1
  tb.maindec:Catch ("OnClick", button_click)

  arg = {
    x = 0, y = 0, text = "Off Spec +", width = 100,
    tooltip = { title = "$$", text = L["TIP034"] }
  }
  inc = KUI:CreateButton (arg, tb)
  inc:ClearAllPoints ()
  inc:SetPoint ("TOPLEFT", tb.maindec, "TOPRIGHT", 4, 0)
  inc:SetPoint ("BOTTOMLEFT", tb.maindec, "BOTTOMRIGHT", 4, 0)
  inc:SetWidth (100)
  tb.offinc = inc
  tb.offinc.incdec = 1
  tb.offinc.incidx = 2
  tb.offinc:Catch ("OnClick", button_click)

  arg = {
    x = 0, y = 0, text = "Off Spec -", width = 100,
    tooltip = { title = "$$", text = L["TIP035"] }
  }
  dec = KUI:CreateButton (arg, tb)
  dec:ClearAllPoints ()
  dec:SetPoint ("TOPLEFT", inc, "TOPRIGHT", 4, 0)
  dec:SetPoint ("BOTTOMLEFT", inc, "BOTTOMRIGHT", 4, 0)
  dec:SetWidth (100)
  tb.offdec = dec
  tb.offdec.incdec = -1
  tb.offdec.incidx = 2
  tb.offdec:Catch ("OnClick", button_click)

  arg = {
    x = 100, y = 0, width = 125,
    text = L["Broadcast"],
    tooltip = { title = "$$", text = L["TIP032"] },
  }
  bf.bcastbutton = KUI:CreateButton (arg, bf)
  bf.bcastbutton:Catch ("OnClick", function (this, evt)
    if (kpg.frdb.enable_decay and kpg.frdb.decayed) then
      kpg.SendRaidMsg (strfmt (L["%s: the following user(s) are roll-decayed:"], L["MODABBREV"]))
      for k,v in pairs (decayed_users) do
        kpg.BroadcastPlayer (v.name)
      end
    end
  end)

  arg = {
    x = 260, y = 0, width = 125,
    text = L["Reset"],
    tooltip = { title = "$$", text = L["TIP033"] },
  }
  bf.resetbutton = KUI:CreateButton (arg, bf)
  bf.resetbutton:Catch ("OnClick", function (this, evt)
    kpg:ResetDecay ()
  end)

  arg = {
    name = "KPGDecayScrollList",
    itemheight = 16,
    newitem = dlist_newitem,
    setitem = dlist_setitem,
    selectitem = dlist_selectitem,
    highlightitem = KUI.HighlightItemHelper,
  }
  tf.slist = KUI:CreateScrollList (arg, tf)
  kpg.qf.decayscroll = tf.slist

  kpg:RefreshIgnoredItems ()
end

function kpg:RefreshIgnoredItems ()
  sortedignores = {}
  for k,v in pairs (kpg.frdb.items) do
    tinsert (sortedignores, k)
  end
  tsort (sortedignores, function (a,b)
    local an = GetItemInfo (kpg.frdb.items[a])
    local bn = GetItemInfo (kpg.frdb.items[b])
    return an < bn
  end)
  kpg.qf.ignorelist.itemcount = #sortedignores
  kpg.qf.ignorelist:UpdateList ()
end

function kpg:RefreshDecayedUsers ()
  local curidx = seluser
  decayed_users = {}
  local ip

  if (kpg.inraid) then
    if (kpg.isml) then
      ip = kpg.frdb
    else
      ip = kpg.remcfg
    end
  else
    ip = kpg.frdb
  end

  if (ip and ip.decayed) then
    for k,v in pairs (ip.decayed) do
      if (v.count[1] > ip.main_max) then
        v.count[1] = ip.main_max
      end
      if (v.count[2] > ip.off_max) then
        v.count[2] = ip.off_max
      end
      tinsert (decayed_users, { name = k, class = v.class, count = v.count })
    end
    tsort (decayed_users, function (a,b)
      return a.name < b.name
    end)
    kpg.qf.decayscroll.itemcount = #decayed_users
    kpg.qf.decayscroll:UpdateList ()
    if (curidx and curidx <= kpg.qf.decayscroll.itemcount) then
      kpg.qf.decayscroll:SetSelected (curidx)
    end
  else
    kpg.qf.decayscroll:SetSelected (nil)
    kpg.qf.decayscroll.itemcount = 0
    kpg.qf.decayscroll:UpdateList ()
  end
end

function kpg:ResetDecay (iscmd)
  kpg.frdb.decayed = nil
  kpg:RefreshDecayedUsers ()
  if (kpg.isml and not iscmd) then
    kpg.SendAM ("RESTD", "ALERT")
  end
end

function kpg:AddDecayedUser (who, whoclass, ismain, iscmd)
  if (kpg.isml and iscmd) then
    return
  end

  if (kpg.isml and not kpg.frdb.enable_decay) then
    return
  end

  local idx = 1
  if (not ismain) then
    idx = 2
  end

  if (kpg.isml) then
    kpg.frdb.decayed = kpg.frdb.decayed or {}
    local maxes = { kpg.frdb.main_max, kpg.frdb.off_max }
    local dt = kpg.frdb.decayed

    if (not dt[who]) then
      dt[who] = { class = whoclass, count = { 0, 0} }
    end
    dt[who].count[idx] = dt[who].count[idx] + 1
    if (dt[who].count[idx] > maxes[idx]) then
      dt[who].count[idx] = maxes[idx]
    end
  end

  kpg:RefreshDecayedUsers ()
  if (kpg.inraid and kpg.isml and not iscmd) then
    kpg.SendAM ("SETDC", "ALERT", who, whoclass, kpg.frdb.decayed[who].count[1], kpg.frdb.decayed[who].count[2])
  end
end

function kpg:SendConfig ()
  if (not kpg.isml) then
    return
  end

  kpg.SendAM ("CONFIG", "ALERT",
    kpg.frdb.main_spec_min,
    kpg.frdb.main_spec_max,
    kpg.frdb.off_spec_min,
    kpg.frdb.off_spec_max,
    kpg.frdb.offspec_rolls,
    kpg.frdb.enable_decay,
    kpg.frdb.main_decay,
    kpg.frdb.main_max,
    kpg.frdb.off_decay,
    kpg.frdb.off_max,
    kpg.frdb.decayed)
end

