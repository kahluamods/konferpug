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

if (not K) then
  error ("KahLua KonferPUG: could not find KahLua Kore.", 2)
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
-- This file contains all of the UI handling code for the history panel.
--

local initdone = false

local function hlist_newitem (objp, num)
  local bname = "KPGHistListButton" .. tostring(num)
  local rf = MakeFrame ("Button", bname, objp.content)
  local nfn = "GameFontNormalSmallLeft"
  local hfn = "GameFontHighlightSmallLeft"
  local htn = "Interface/QuestFrame/UI-QuestTitleHighlight"

  rf:SetWidth (470)
  rf:SetHeight (16)
  rf:SetHighlightTexture (htn, "ADD")

  local when = rf:CreateFontString (nil, "BORDER", nfn)
  when:ClearAllPoints ()
  when:SetPoint ("TOPLEFT", rf, "TOPLEFT", 0, -2)
  when:SetPoint ("BOTTOMLEFT", rf, "BOTTOMLEFT", 0, -2)
  when:SetWidth (70)
  when:SetJustifyH ("LEFT")
  when:SetJustifyV ("TOP")
  rf.when = when

  local what = rf:CreateFontString (nil, "BORDER", nfn)
  what:ClearAllPoints ()
  what:SetPoint ("TOPLEFT", when, "TOPRIGHT", 4, 0)
  what:SetPoint ("BOTTOMLEFT", when, "BOTTOMRIGHT", 4, 0)
  what:SetWidth (170)
  what:SetJustifyH ("LEFT")
  what:SetJustifyV ("TOP")
  rf.what = what

  local who = rf:CreateFontString (nil, "BORDER", nfn)
  who:ClearAllPoints ()
  who:SetPoint ("TOPLEFT", what, "TOPRIGHT", 4, 0)
  who:SetPoint ("BOTTOMLEFT", what, "BOTTOMRIGHT", 4, 0)
  who:SetWidth (100)
  who:SetJustifyH ("LEFT")
  who:SetJustifyV ("TOP")
  rf.who = who

  local how = rf:CreateFontString (nil, "BORDER", nfn)
  how:ClearAllPoints ()
  how:SetPoint ("TOPLEFT", who, "TOPRIGHT", 4, 0)
  how:SetPoint ("BOTTOMLEFT", who, "BOTTOMRIGHT", 4, 0)
  how:SetWidth (110)
  how:SetJustifyH ("LEFT")
  how:SetJustifyV ("TOP")
  rf.how = how

  rf.SetText = function (self, whn, wht, wo, ho)
    self.when:SetText (whn)
    self.what:SetText (wht)
    self.who:SetText (wo)
    self.how:SetText (ho)
    self.whatlink = wht
  end

  rf:SetScript ("OnEnter", function (this, evt, ...)
    if (this.whatlink) then
      GameTooltip:SetOwner (this, "ANCHOR_BOTTOMLEFT", 0, 18)
      GameTooltip:SetHyperlink (this.whatlink)
      GameTooltip:Show ()
    end
  end)

  rf:SetScript ("OnLeave", function (this, evt, ...)
    GameTooltip:Hide ()
  end)

  rf:SetScript ("OnClick", function (this)
    if (IsModifiedClick ("CHATLINK")) then
      ChatEdit_InsertLink (this.whatlink)
    end
  end)

  return rf
end

local function hlist_setitem (objp, idx, slot, btn)
  local hitem = kpg.frdb.history[idx]
  local when,what,who,how = strsplit ("\7", hitem)
  local usr = class (strsplit ("/", who))
  local hs = ""
  if (how == "D") then
    hs = L["Disenchanted"]
  elseif (how == "R") then
    hs = L["Won Roll"]
  elseif (how == "M") then
    hs = L["Roll (Main)"]
  elseif (how == "O") then
    hs = L["Roll (Off)"]
  end

  local ws = strsub (when, 5, 6) .."-" .. strsub (when, 7, 8) .. " " .. strsub (when, 9, 10) .. ":" .. strsub(when, 11,12)

  btn:SetText (ws, what, usr, hs)
  btn:SetID (idx)
  btn:Show ()
end

function kpg:InitialiseHistoryGUI ()
  local arg

  local ypos = 0

  local cf = kpg.mainwin.tabs[kpg.HISTORY_TAB].content
  local tf = cf.hsplit.topframe
  local bf = cf.hsplit.bottomframe

  --
  -- Do the buttons at the bottom first
  --
  arg = {
    x = 0, y = ypos, width = 85, text = L["Clear All"],
    tooltip = { title = "$$", text = L["TIP025"], },
  }
  bf.clearall = KUI:CreateButton (arg, bf)
  bf.clearall:Catch ("OnClick", function (this, evt, ...)
    kpg.frdb.history = {}
    kpg:RefreshHistory ()
  end)

  arg = {
    x = 85, y = ypos, width = 200, text = L["Clear all except last week"],
    tooltip = { title = "$$", text = L["TIP026"], },
  }
  bf.clearweek = KUI:CreateButton (arg, bf)
  bf.clearweek:Catch ("OnClick", function (this, evt, ...)
    local _, y, m, d = kpg:TimeStamp ()
    if (d >= 7) then
      d = d - 6
    else
      if (m == 1) then
        y = y - 1
        m = 12
      else
        m = m - 1
      end
      d = 23 + d
    end
    local ts = tonumber (strfmt ("%04d%02d%02d0101", y, m, d))
    local i = 1
    while (i <= #kpg.frdb.history) do
      if (tonumber (strsub (kpg.frdb.history[i], 1, 12)) < ts) then
        tremove (kpg.frdb.history, i)
      else
        i = i + 1
      end
    end
    kpg:RefreshHistory ()
  end)

  arg = {
    x = 280, y = ypos, width = 200, text = L["Clear all except last month"],
    tooltip = { title = "$$", text = L["TIP027"], },
  }
  bf.clearmonth = KUI:CreateButton (arg, bf)
  bf.clearmonth:Catch ("OnClick", function (this, evt, ...)
    local _, y, m, d = kpg:TimeStamp ()
    if (m == 1) then
      y = y - 1
      m = 12
    else
      m = m - 1
    end
    local ts = tonumber (strfmt ("%04d%02d%02d0101", y, m, d))
    local i = 1
    while (i <= #kpg.frdb.history) do
      if (tonumber (strsub (kpg.frdb.history[i], 1, 12)) < ts) then
        tremove (kpg.frdbtory, i)
      else
        i = i + 1
      end
    end
    kpg:RefreshHistory ()
  end)
  ypos = ypos - 24

  arg = {
    x = 0, y = 0, text = L["When"], font = "GameFontNormalSmall",
  }
  tf.str1 = KUI:CreateStringLabel (arg, tf)

  arg.x = 75
  arg.text = L["What"]
  tf.str2 = KUI:CreateStringLabel (arg, tf)

  arg.x = 248
  arg.text = L["Who"]
  tf.str3 = KUI:CreateStringLabel (arg, tf)

  arg.x = 350
  arg.text = L["How"]
  tf.str4 = KUI:CreateStringLabel (arg, tf)

  tf.sframe = MakeFrame ("Frame", nil, tf)
  tf.sframe:ClearAllPoints ()
  tf.sframe:SetPoint ("TOPLEFT", tf, "TOPLEFT", 0, -18)
  tf.sframe:SetPoint ("BOTTOMRIGHT", tf, "BOTTOMRIGHT", 0, 0)

  arg = {
    name = "KPGHistoryScrollList",
    itemheight = 16,
    newitem = hlist_newitem,
    setitem = hlist_setitem,
    selectitem = function (objp, idx, slot, btn, onoff) return end,
    highlightitem = KUI.HighlightItemHelper,
  }
  tf.slist = KUI:CreateScrollList (arg, tf.sframe)
  kpg.qf.histscroll = tf.slist

  initdone = true
  kpg:RefreshHistory ()
end

function kpg:RefreshHistory ()
  kpg.qf.histscroll.itemcount = 0
  if (kpg.frdb.history) then
    kpg.qf.histscroll.itemcount = #kpg.frdb.history
  end
  if (kpg.qf.histscroll.itemcount > 0) then
    -- Resort the list as we may have receieved new loot info
    tsort (kpg.frdb.history, function (a, b)
      return tonumber(strsub (a, 1, 12)) > tonumber(strsub (b, 1, 12))
    end)
  end
  kpg.qf.histscroll:UpdateList ()
  kpg.qf.histscroll:SetSelected (nil)
end

function kpg:AddLootHistory (when, what, who, class, how, iscmd)
  if (not kpg.frdb.record_history) then
    return
  end

  local ts = strfmt ("%s\7%s\7%s/%s\7%s", when, what, who, class, how)

  tinsert (kpg.frdb.history, ts)
  kpg:RefreshHistory ()

  if (not iscmd) then
    kpg.SendAM ("AHIST", "ALERT", when, what, who, class, how)
  end
end

