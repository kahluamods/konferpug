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
local LibDeformat = LibStub:GetLibrary ("LibDeformat-3.0")

if (not K) then
  error ("KahLua KonferSK: could not find KahLua Kore.", 2)
end

if (not LibDeformat) then
  error ("KahLua KonferSK: could not find LibDeformat.", 2)
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
-- This file contains the code for managing the raiders tab, where users can
-- see who the current raiders are, and set notes for them or mark them as
-- an enchanter or set other arbitrary notes for them.
--

local selraider
local selidx
local uinfo = {}
local initdone = false

local function setup_uinfo ()
  uinfo = {}
  if (not selraider) then
    return
  end

  local ui = kpg.frdb.users[selraider]
  if (ui) then
    uinfo.enchanter = ui.e
    uinfo.role1 = ui.rl1
    uinfo.role2 = ui.rl2
    uinfo.rating = ui.rt
    uinfo.comment = ui.c
    uinfo.class = ui.cl
  end
  uinfo.name = selraider
  uinfo.class = kpg.sortedraiders[selidx].class
end

local function users_selectitem (objp, idx, slot, btn, onoff)
  if (onoff) then
    selraider = kpg.sortedraiders[idx].name
    selidx = idx
    setup_uinfo ()
    local uo = kpg.qf.useropts
    uo.enchanter:SetChecked (uinfo.enchanter or false)
    uo.role1:SetValue (uinfo.role1 or 0)
    uo.role2:SetValue (uinfo.role2 or 0)
    uo.rating:SetValue (uinfo.rating or 0)
    uo.comment:SetText (uinfo.comment or "")
    uo.enchanter:SetEnabled (true)
    uo.role1:SetEnabled (true)
    uo.role2:SetEnabled (true)
    uo.rating:SetEnabled (true)
    uo.comment:SetEnabled (true)
    kpg.qf.updatebtn:SetEnabled (true)
    kpg.qf.deletebtn:SetEnabled (true)
  else
    selraider = nil
    selidx = nil
    if (initdone) then
      local kids = { kpg.qf.useropts:GetChildren () }
      for k,v in pairs (kids) do
        if (v.SetEnabled) then
          v:SetEnabled (false)
        end
      end
    end
  end
end

local function create_role_dd (name, text, x, y, parent, w)
  local arg = {
    name = name, mode = "SINGLE", itemheight = 16,
    x = x, y = y, dwidth = w or 150,
    label =  { text = text, pos = "LEFT" },
    items = {
      { text = kpg.rolenames[0], value = 0 },
      { text = kpg.rolenames[1], value = 1 },
      { text = kpg.rolenames[2], value = 2 },
      { text = kpg.rolenames[3], value = 3 },
      { text = kpg.rolenames[4], value = 4 },
      { text = kpg.rolenames[5], value = 5 },
    },
    tooltip = { title = "$$", text = L["TIP017"] },
    enabled = false,
  }
  return KUI:CreateDropDown (arg, parent)
end

function kpg:InitialiseRaidersGUI ()
  local ypos = 0
  local cf = kpg.qf.raiders

  --
  -- The left-hand panel is a scrolling list of all of the raiders this user
  -- has either saved info for, or are currently in the raid. The right hand
  -- side is where they set per-user attributes.
  --
  local ls = cf.vsplit.leftframe
  local rs = cf.vsplit.rightframe

  local function raiders_och (this, btn, down)
    local ix = this:GetID ()
    this:GetParent():GetParent():SetSelected (ix, false, true)
    if (btn == "RightButton") then
      FriendsFrame_ShowDropdown (selraider, 1)
    end
    return true
  end

  local arg = {
    name = "KPGUsersScrollList",
    itemheight = 16,
    newitem = function (objp, num)
        return KUI.NewItemHelper (objp, num, "KPGUsersButton", 155, 16,
          nil, raiders_och, nil, function (rf, op, nm)
              rf:RegisterForClicks ("LeftButtonUp", "RightButtonUp")
            end)
      end,
    setitem = function (objp, idx, slot, btn)
        return KUI.SetItemHelper (objp, btn, idx,
          function (op, ix)
            local un = kpg.sortedraiders[ix].name
            local uc = kpg.sortedraiders[ix].class
            local gn = ""
            if (kpg.inraid and kpg.raid.raiders[un]) then
              gn = " [" .. kpg.raid.raiders[un].party .. "]"
            end
            return class (un, uc) .. gn
          end)
      end,
    selectitem = users_selectitem,
    highlightitem = KUI.HighlightItemHelper,
  }
  ls.slist = KUI:CreateScrollList (arg, ls)
  kpg.qf.userlist = ls.slist

  kpg.qf.useropts = rs
  arg = {
    x = 0, y = ypos, label = { text = L["User is an Enchanter"] },
    tooltip = { title = "$$", text = L["TIP016"] },
    enabled = false,
  }
  rs.enchanter = KUI:CreateCheckBox (arg, rs)
  rs.enchanter:Catch ("OnValueChanged", function (this, evt, newv, user)
    uinfo.enchanter = newv
  end)
  ypos = ypos - 24

  rs.role1 = create_role_dd ("KPGUserRole1", L["User Role 1"], 0, ypos, rs)
  rs.role1:Catch ("OnValueChanged", function (this, evt, newv, user)
    uinfo.role1 = newv
  end)
  ypos = ypos - 32

  rs.role2 = create_role_dd ("KPGUserRole2", L["User Role 2"], 0, ypos, rs)
  rs.role2:Catch ("OnValueChanged", function (this, evt, newv, user)
    uinfo.role2 = newv
  end)
  ypos = ypos - 32

  arg = {
    name = "KPGUserRating", mode = "SINGLE", itemheight = 16,
    x = 0, y = ypos, dwidth = 150,
    label = { text = L["Rating"], pos = "LEFT" },
    items = {
      { text = L["Not Set"], value = 0 },
      { text = L["Noob"], value = 1 },
      { text = L["Poor"], value = 2 },
      { text = L["Average"], value = 3 },
      { text = L["Good"], value = 4 },
      { text = L["Pro"], value = 5 },
    },
    tooltip = { title = "$$", text = L["TIP018"] },
    enabled = false,
  }
  rs.rating = KUI:CreateDropDown (arg, rs)
  rs.rating:Catch ("OnValueChanged", function (this, evt, newv, user)
    uinfo.rating = newv
  end)
  ypos = ypos - 32

  arg = {
    x = 0, y = ypos, width = 200, len = 64,
    label = { text = L["Comments"], pos = "LEFT" }, 
    enabled = false,
  }
  rs.comment = KUI:CreateEditBox (arg, rs)
  rs.comment:Catch ("OnValueChanged", function (this, evt, newv, user)
    uinfo.comment = newv
  end)
  ypos = ypos - 24

  arg = {
    x = 0, y = ypos, text = L["Update"], enabled = true,
    tooltip = { title = "$$", text = L["TIP019"] },
  }
  rs.updatebtn = KUI:CreateButton (arg, rs)
  kpg.qf.updatebtn = rs.updatebtn
  rs.updatebtn:Catch ("OnClick", function (this, evt)
    local ui = kpg.frdb.users
    ui[uinfo.name] = {
      cl = uinfo.class,
      e = uinfo.enchanter,
      rl1 = uinfo.role1,
      rl2 = uinfo.role2,
      rt = uinfo.rating,
      c = uinfo.comment,
    }
    if (kpg.inraid) then
      if (kpg.raid and kpg.raid.raiders[uinfo.name]) then
        kpg.raid.raiders[uinfo.name].uinfo = kpg.frdb.users[uinfo.name]
      end
    end
    rs.comment:ClearFocus ()
  end)

  arg = {
    x = 150, y = ypos, text = L["Delete"], enabled = false,
    tooltip = { title = "$$", text = L["TIP020"] },
  }
  rs.deletebtn = KUI:CreateButton (arg, rs)
  kpg.qf.deletebtn = rs.deletebtn
  rs.deletebtn:Catch ("OnClick", function (this, evt)
    if (not selraider) then
      return
    end
    kpg.frdb.users[selraider] = nil
    kpg:RefreshRaiders ()
  end)

  initdone = true
  kpg:RefreshRaid ()
end

function kpg:RefreshRaiders ()
  kpg.sortedraiders = {}
  local oldraider = selraider or ""
  local oldidx = 0
  local udb = kpg.frdb.users
  selraider = nil
  selidx = nil

  for k,v in pairs (udb) do
    local ent = { name = k, class = v.cl, saved = true }
    if (kpg.inraid and kpg.raid.raiders[k]) then
      ent.inraid = true
    else
      ent.inraid = false
    end
    tinsert (kpg.sortedraiders, ent)
  end
  if (kpg.inraid) then
    for k,v in pairs (kpg.raid.raiders) do
      local ent = { name = k, class = v.class, saved = false, inraid = true }
      if (not udb[k]) then
        tinsert (kpg.sortedraiders, ent)
      end
    end
  end
  tsort (kpg.sortedraiders, function (a, b)
    if (kpg.inraid) then
      if (a.inraid and not b.inraid) then
        return true
      end
      if (b.inraid and not a.inraid) then
        return false
      end
    end
    return a.name < b.name
  end)

  for k,v in ipairs (kpg.sortedraiders) do
    if (v.name == oldraider) then
      oldidx = k
      break
    end
  end

  if (oldidx == 0) then
    oldidx = 1
  end

  kpg.qf.userlist.itemcount = #kpg.sortedraiders
  kpg.qf.userlist:UpdateList ()
  if (kpg.qf.userlist.itemcount > 1) then
    selraider = kpg.sortedraiders[oldidx].name
    selidx = oldidx
    setup_uinfo ()
    kpg.qf.userlist:SetSelected (oldidx)
  else
    kpg.qf.userlist:SetSelected (nil)
  end
end

