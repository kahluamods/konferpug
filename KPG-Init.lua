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

--
-- This file contains all of the UI initialisation code for KahLua KonferPUG.
--

local maintitle = "|cffff2222<" .. K.KAHLUA .. ">|r " .. L["MODTITLE"]

local mainwin = {
  x = "CENTER", y = "MIDDLE",
  name = "KKonferPUG",
  title = maintitle,
  canresize = "HEIGHT",
  canmove = true,
  escclose = true,
  xbutton = true,
  width = 512,
  height = 450,
  minwidth = 512,
  minheight = 450,
  framelevel = 32,
  tabs = {
    loot = {
      text = L["Loot"],
      id = tostring (kpg.LOOT_TAB),
      title = maintitle .. " - " .. L["Assign Loot"],
      hsplit = { height = 128, topanchor = true, },
    },
    history = {
      text = L["History"],
      id = tostring (kpg.HISTORY_TAB),
      title = maintitle .. " - " .. L["Loot History"],
      hsplit = { height = 24, },
    },
    raiders = {
      text = L["Raiders"],
      id = tostring (kpg.RAIDERS_TAB),
      title = maintitle .. " - " .. L["Raider Attributes"],
      vsplit = { width = 180 },
    },
    config = {
      text = L["Config"],
      id = tostring (kpg.CONFIG_TAB),
      title = maintitle .. " - " .. L["Configure Options"],
      tabs = {
        main = {
          text = L["Config"], id = tostring (kpg.MAIN_CONFIG_TAB),
        },
        decay = {
          text = L["Extras"], id = tostring(kpg.EXTRAS_CONFIG_TAB),
        },
        ignores = {
          text = L["Ignored Items"], id = tostring (kpg.LOOT_IGNORE_TAB),
        }
      },
    },
    decay = {
      text = L["Decay"],
      id = tostring(kpg.DECAY_TAB),
      title = maintitle .. " - " .. L["Decay"],
      hsplit = { height = 24 }, enabled = false,
    }
  }
}

kpg.mainwin = KUI:CreateTabbedDialog (mainwin)

function kpg:InitialiseUI()
  if (kpg.initialised) then
    return
  end

  kpg.qf.lootopts = kpg.mainwin.tabs[kpg.CONFIG_TAB].tabs[kpg.MAIN_CONFIG_TAB].content
  kpg.qf.ignores = kpg.mainwin.tabs[kpg.CONFIG_TAB].tabs[kpg.LOOT_IGNORE_TAB].content
  kpg.qf.raiders = kpg.mainwin.tabs[kpg.RAIDERS_TAB].content
  kpg.qf.decay = kpg.mainwin.tabs[kpg.DECAY_TAB].content
  kpg.qf.dtopbar = kpg.mainwin.tabs[kpg.DECAY_TAB].topbar
  kpg.qf.extraopts = kpg.mainwin.tabs[kpg.CONFIG_TAB].tabs[kpg.EXTRAS_CONFIG_TAB].content

  kpg.qf.loottab = kpg.mainwin.tabs[kpg.LOOT_TAB].tbutton
  kpg.qf.historytab = kpg.mainwin.tabs[kpg.HISTORY_TAB].tbutton
  kpg.qf.raiderstab = kpg.mainwin.tabs[kpg.RAIDERS_TAB].tbutton
  kpg.qf.configtab = kpg.mainwin.tabs[kpg.CONFIG_TAB].tbutton
  kpg.qf.decaytab = kpg.mainwin.tabs[kpg.DECAY_TAB].tbutton

  kpg:InitialiseLootGUI ()
  kpg:InitialiseHistoryGUI ()
  kpg:InitialiseRaidersGUI ()
  kpg:InitialiseConfigGUI ()

  kpg:UpdateAllConfigSettings ()

  kpg.initialised = true
  K:UpdatePlayerAndGuild ()
  kpg.mainwin.OnShow = function (this, evt)
    K:UpdatePlayerAndGuild ()
    kpg.mainwin.OnShow = function (this, evt)
      kpg:CleanupLootRoll ()
    end
  end
end

