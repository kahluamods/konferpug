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

kpg.iitems = {}
local sp = kpg.iitems

-- Items we want to ignore
sp["43228"] = true -- Stone Keepers Shard
sp["49426"] = true -- Emblem of Frost
sp["47241"] = true -- Emblem of Triumph
sp["45624"] = true -- Emblem of Conquest
sp["40753"] = true -- Emblem of Valor
sp["40752"] = true -- Emblem of Heroism
sp["29434"] = true -- Badge of Justice
sp["34664"] = true -- Sunmote
sp["30311"] = true -- KT's Warp Slicer
sp["30313"] = true -- KT's Staff of Disintegration
sp["30314"] = true -- KT's Phaseshift Bulwark
sp["30312"] = true -- KT's Infinity Blade
sp["30316"] = true -- KT's Devastation
sp["30317"] = true -- KT's Cosmic Infuser
sp["30318"] = true -- KT's Netherstrand Longbow
sp["30319"] = true -- KT's Nether Spike
sp["30320"] = true -- KT's Bundle of Spikes

