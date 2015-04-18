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

local kpg = K:GetAddon ("KKonferPUG")
local L = kpg.L

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
local gsub = string.gsub
local strlen = string.len
local strfind = string.find
local strlower = string.lower
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
local aclass = kpg.aclass

--
-- This file contains general purpose utility functions used throughout KPG.
--

function kpg.SendRaidMsg (text)
  if (kpg.inraid == 2) then
    SendChatMessage (text, "RAID")
  elseif (kpg.inraid == 1) then
    SendChatMessage (text, "PARTY")
  end
end

function kpg.SendRaidWarning (text)
  if (kpg.inraid == 2) then
    if (kpg.isaorl == true) then
      SendChatMessage (text, "RAID_WARNING")
    else
      SendChatMessage (text, "RAID")
    end
  elseif (kpg.inraid == 1) then
    SendChatMessage (text, "PARTY")
  end
end

function kpg.SendPartyMsg (text)
  SendChatMessage (text, "PARTY")
end

function kpg.SendWhisper (text, target)
  SendChatMessage (text, "WHISPER", nil, target)
end

function kpg:UpdateDatabaseVersion ()
  if (not kpg.frdb.dbversion) then
    return
  end

  local f = kpg.frdb
  if (f.dbversion == 1) then
    -- Version 2 added decay and slightly diffrent announce options
    f.version = nil
    if (f.only_5secs) then
      f.announce_how = 2
    else
      f.announce_how = 1
    end
    f.only_5secs = nil
    f.enable_decay = false
    f.main_only = false
    f.decay_amount = 10
    f.max_decay = 4
    f.dbversion = 2
  end

  if (f.dbversion == 2) then
    -- Version 3 made timeouts optional and allows the user to configure
    -- different decay amounts for mainspec and offspec
    f.use_timeout = true
    f.use_extend = true
    f.main_decay = f.decay_amount
    f.main_max = f.max_decay
    if (f.main_only) then
      f.off_decay = 0
      f.off_max = 1
    else
      f.off_decay = 10
      f.off_max = 4
    end
    f.decay_amount = nil
    f.max_decay = nil
    f.main_only = nil

    if (f.decayed) then
      for k,v in pairs(f.decayed) do
        local cc = v.count
        v.count = { cc, 0 }
      end
    end
    f.dbversion = 3
  end

  if (f.dbversion == 3) then
    -- Version 4 made all names canonical
    local tcn = {}
    for k,v in pairs(f.users) do
      local cn = K.CanonicalName (k, nil)
      tcn[cn] = v
    end
    f.users = tcn
  end

  f.dbversion = kpg.dbversion
end

