--[[
item reader, player reader, and monster reader code copyright soleil rojas (soly)
xpbar code copyright phil smith (tornupgaming)
kill counter code copyright stephen c. wills (staphen)
modifications copyright catherine sciuridae (neonluna)
]]

local utility = require('custom hud.utility')

local _bankpointer = 0x00a95de0 + 0x18

local itemoffset={weapon=0x00,armor=0x04,mag=0x10,tool=0x0c,unit=0x08}
local resultoffset={weapon=44,armor=32,mag=28,tool=24,unit=20}
local bosshpoffset = {[45]=0x6b4, [73]=0x704}
local bosshpmaxoffset = {[45]=0x6b0, [73]=0x700}
local maskhpoffset = {[45]=0x6b8, [73]=0x708}
local shellhpoffset = {[45]=0x39c, [73]=0x7ac}

local armortypes = {"frame", "barrier", "unit"}
local itemtypes = {"weapon", "armor", "mag", "tool", "meseta"}
local attributelist = {"native", "a. beast", "machine", "dark", "hit"}
local techtypes = {[9]="s", [10]="d", [11]="j", [12]="z"}

local _hp = 0x334
local _itemkillcount = 0xe8
local _monsterunitxtid = 0x378
local _myplayerindex = 0x00a9c4f4
local _playerarray = 0x00a94254
local _room = 0x28
local _toolquantity = 0x104
local _weapongrind = 0x1f5
-- local _evp = 0x2d0

local activegamedata = {} -- indicates which data are in use
local sessionstartxp
local pmtaddress = nil
local psodata = {}
-- psodata.menustates = {'main menu open', 'lower screen menu open', 'full screen menu open', 'any menu open'}

local function inittechdata()
	return {multiplier=0, name="none", level=0, timeleft=0, totaltime=0, timefloat=0}
end -- local function inittechdata

local gamedata = {
	currentlocation='',
	level=0,
	thislevelxp=0,
	tonextlevel=0,
	levelprogress=0,
	levelprogressfloat=0,
	meseta=0,
	totaltime=0,
	sessiontime=0,
	elapsedtime=0,
	sessionxp=0,
	sessionxprate=0,
	dungeontime=0,
	dungeonxprate=0,
	inventoryspaceused=0,
	bankspaceused=0,
	flooritems={},
	inventory={},
	bank={},
	bankmeseta = 0,
	party={},
	monsterlist={},
	playerhp=0,
	playerhpmax=0,
	playerfrozen=false,
	playerconfused=false,
	playerparalyzed=false,
	playerdeftech=inittechdata(),
	playeratktech=inittechdata(),
	playertp=0,
	playertpmax=0,
	playerinvulnerabilitytime=0,
	menustate={},
}

local lasttime = os.time()
local lastlocation

local function getself()
	return pso.read_u32(_playerarray + pso.read_u32(_myplayerindex) * 4)
end

local function loadpmtaddress()
	pmtaddress = pso.read_u32(0x00a8dc94)
	return pmtaddress ~= 0
end

local function initsessiontime()
	lasttime = os.time()
	gamedata.elapsedtime = 0
	gamedata.dungeontime = 0
	gamedata.sessionxp = 0
	gamedata.sessionxprate = 0 -- per
	gamedata.dungeonxprate = 0 -- second
	local player = getself()
	if player ~= 0 then
		sessionstartxp = pso.read_u32(player + 0xe48)
	end
end -- local function initsessiontime
initsessiontime()

local function getunitxtitemaddress(type, group, index)
	if not pmtaddress then return nil end
	local groupoffset = 0
	if type == "weapon" or type == "tool" then
		groupoffset = group * 8
	elseif type == "armor" then
		if group == 3 then
			type = "unit"
		else
			groupoffset = (group - 1) * 8
		end
	elseif type == "mag" then
		index = group
	elseif type == "meseta" then
		return 0
	end
	-- print(type)
	local itemaddr = pso.read_u32(pmtaddress + itemoffset[type])
	-- print(itemaddr)
	if itemaddr == 0 then return nil end
	local groupaddr = itemaddr + groupoffset
	-- print(groupaddr)
	local count = pso.read_u32(groupaddr)
	-- print(count)
	itemaddr = pso.read_u32(groupaddr + 4)
	-- print(itemaddr)
	if index < count and itemaddr ~= 0 then
		return itemaddr + (index * resultoffset[type])
	else
		return nil
	end
end -- getunitxtitemaddress = function

local function readfromunitxt(group, index)
	local address = pso.read_u32(0x00a9cd50)
	if address == 0 then return nil end
	address = pso.read_u32(address + group * 4)
	if address == 0 then return nil end
	address = pso.read_u32(address + index * 4)
	if address == 0 then return nil end
	return pso.read_wstr(address, 256)
end

local function readitemdata(itemaddr, location)
	item = {} -- all item types: type, name, equipped* (*inventory only)
	local offset = 0
	if location ~= "bank" then offset = 0xf2 end
	item.type = itemtypes[pso.read_u8(itemaddr + offset) + 1]
	local group = pso.read_u8(itemaddr + offset + 1)
	local index = pso.read_u8(itemaddr + offset + 2)
	
	if location == "inventory" then
		item.equipped = bit.band(pso.read_u8(itemaddr + 0x190), 1) == 1
	end
	local unitxtaddr = getunitxtitemaddress(item.type, group, index)
	
	item.name = "???"
	if not unitxtaddr then
		return nil
	elseif item.type == "meseta" then
		item.name = "meseta"
	else
		local id = pso.read_i32(unitxtaddr)
		if id ~= -1 then item.name = readfromunitxt(1, id) end
	end
	
	if item.type == "weapon" then
		-- weapon: grind, wrapped, untekked, killcount, issrank, attributes -or- srank name, special
		local grindoffset, specialoffset, statsoffset
		if location == "bank" then
			grindoffset, specialoffset, statsoffset = 3, 4, 6
		else
			grindoffset = _weapongrind
			specialoffset = 0x1f6
			statsoffset = 0x1c8
		end
		
		item.grind = pso.read_u8(itemaddr + _weapongrind)
		
		local wrappedoruntekked = pso.read_u8(itemaddr + specialoffset)
		if wrappedoruntekked > 0xbf then
			item.wrapped = true
			item.untekked = true
		elseif wrappedoruntekked > 0x7f then
			item.untekked = true
		elseif wrappedoruntekked > 0x3f then
			item.wrapped = true
		end -- if wrappedoruntekked > 0xbf
		
		if group == 0x33 or group == 0xab then
			item.killcount = pso.read_u16(itemaddr + _itemkillcount)
		end
		
		item.issrank = (group >= 0x70 and group < 0x89) or (group >=0xa5 and group < 0xaa)
		if item.issrank then
			local result = ""
			local temp = 0
			for i = 0,4,2 do
				local addr = itemaddr + statsoffset + i
				local n = bit.lshift(pso.read_u8(addr), 8) + pso.read_u8(addr + 1) - 0x8000
				if i ~= 0 then
					temp = math.floor(n / 0x400) + 0x40
					if temp > 0x40 and temp < 0x60 then
						result = result .. string.char(temp)
					end
				end
				temp = math.floor((n % 0x400) / 0x20) + 0x40
				if temp > 0x40 and temp < 0x60 then
					result = result .. string.char(temp)
				end
				temp = (n % 0x20) + 0x40
				if temp > 0x40 and temp < 0x60 then
					result = result .. string.char(temp)
				end
			end -- for i=0,4,2
			item.srankname = result
			item.special = index
			
		else -- not srank
			item.special = pso.read_u8(itemaddr + specialoffset) % 64
			if item.special == 0 then
				item.special = "none"
			else
				item.special = readfromunitxt(1, pso.read_u32(0x005e4cbb) + item.special)
			end -- if item.special == 0
			for attrname in ipairs(attributelist) do
				item[attrname] = 0
			end
			for i = 0,4,2 do
				local attraddr = itemaddr + statsoffset + i -- attributeaddress
				local attrindex = pso.read_u8(attraddr) + 1
				if attrindex < 6 then -- maybe this 6 should be a 7
					local attrvalue = pso.read_u8(attraddr + 1)
					local attrname = attributelist[attrindex]
					if attrvalue > 127 then attrvalue = attrvalue - 256 end
					item[attrname] = attrvalue
				end
			end
		end -- else -- not srank
	
	elseif item.type == "armor" then
		if group == 1 then -- frame: slots, defense/max, evade/max
			item.type = "frame"
			local slotsoffset, defoffset, evadeoffset
			if location == "bank" then
				slotsoffset, defoffset, evadeoffset = 5, 6, 8
			else
				slotsoffset = 0x1b8
				defoffset = 0x1b9
				evadeoffset = 0x1ba
			end
			item.slots = pso.read_u8(itemaddr + slotsoffset)
			item.defense = pso.read_u8(itemaddr + defoffset)
			item.defensemax = pso.read_u8(unitxtaddr + 26)
			item.evade = pso.read_u8(itemaddr + evadeoffset)
			item.evademax = pso.read_u8(unitxtaddr + 27)
			
		elseif group == 2 then -- barrier: defense/max, evade/max
			item.type = "barrier"
			local defoffset, evadeoffset
			if location == "bank" then
				defoffset, evadeoffset = 6, 8
			else
				defoffset = 0x1e4
				evadeoffset = 0x1e5
			end
			item.defense = pso.read_u8(itemaddr + defoffset)
			item.defensemax = pso.read_u8(unitxtaddr + 26)
			item.evade = pso.read_u8(itemaddr + evadeoffset)
			item.evademax = pso.read_u8(unitxtaddr + 27)
			
		elseif group == 3 then -- unit: mod + or -
			item.type = "unit"
			local modoffset
			if location == "bank" then
				modoffset = 6
			else
				modoffset = 0x1dc
			end
			item.unitmod = pso.read_u8(itemaddr + modoffset)
			if item.unitmod > 127 then item.unitmod = item.unitmod - 256 end
			if item.unitmod < -2 then
				item.unitmod = -2
			elseif item.unitmod > 2 then
				item.unitmod = 2
			end
			-- item.unitmod2 = pso.read_u8(itemaddr + modoffset + 1)
			if index == 0x4d or index == 0x4f then
				item.killcount = pso.read_u16(itemaddr + _itemkillcount)
			end
			
		end -- armor subtype switch
	elseif item.type == "mag" then
		-- mag: def.%, pow.%, dex.%, mind.%, sync, iq, color, timer* (*inventory only), pbs
		local statsaddr, syncoffset, iqoffset, coloroffset, pbpresenceoffset, pblistoffset
		if location == "bank" then
			item.timer = 210
			statsaddr = itemaddr + 4
			syncoffset, iqoffset, coloroffset = 16, 17, 19
			pbpresenceoffset, pblistoffset = 18, 3
		else
			item.timer = pso.read_f32(itemaddr + 0x1b4) / 30
			statsaddr = itemaddr + 0x1c0
			syncoffset = 0x1be
			iqoffset = 0x1bc
			coloroffset = 0x1ca
			pbpresenceoffset = 0x1c8
			pblistoffset = 0x1c9
		end
		item.def = (bit.lshift(pso.read_u8(statsaddr + 1), 8) + pso.read_u8(statsaddr)) / 100
		item.pow = (bit.lshift(pso.read_u8(statsaddr + 3), 8) + pso.read_u8(statsaddr + 2)) / 100
		item.dex = (bit.lshift(pso.read_u8(statsaddr + 5), 8) + pso.read_u8(statsaddr + 4)) / 100
		item.mind = (bit.lshift(pso.read_u8(statsaddr + 7), 8) + pso.read_u8(statsaddr + 6)) / 100
		item.sync = pso.read_u8(itemaddr + syncoffset)
		item.iq = pso.read_u8(itemaddr + iqoffset)
		item.color = pso.read_u8(itemaddr + coloroffset)
		local pblist = pso.read_u8(itemaddr + pblistoffset)
		local pbpresence = pso.read_u8(itemaddr + pbpresenceoffset)
		item.pb = {}
		local takenpbs = {}
		local pbindex
		if bit.band(pbpresence, 1) ~= 0 then
			pbindex = bit.band(pblist, 7)
			item.pb[2] = readfromunitxt(9, pbindex)
			takenpbs[pbindex + 1] = true
		end
		if bit.band(pbpresence, 2) ~= 0 then
			pbindex = bit.rshift(bit.band(pblist, 56), 3)
			item.pb[3] = readfromunitxt(9, pbindex)
			takenpbs[pbindex + 1] = true
		end
		if bit.band(pbpresence, 4) ~= 0 then
			pbindex = bit.rshift(bit.band(pblist, 0xc0), 6)
			for i = 1,6 do
				if not takenpbs[i] then
					if pbindex == 0 then
						item.pb[1] = readfromunitxt(9, i - 1)
					else
						pbindex = pbindex - 1
					end
				end
			end
		end
	elseif item.type == "tool" then
		if group == 2 then -- technique disk: tech learned, level
			item.type = "technique disk"
			local technameoffset
			if location == "bank" then
				technameoffset = 4
			else
				technameoffset = 0x108
			end
			item.name = readfromunitxt(5, pso.read_u8(itemaddr + technameoffset))
			item.techniquelevel = index + 1
		else -- consumable item: quantity
			if location == "bank" then
				item.quantity = pso.read_u8(itemaddr + 20)
			else
				item.quantity = bit.bxor(pso.read_u32(itemaddr + _toolquantity), itemaddr + _toolquantity)
			end
		end
	elseif item.type == "meseta" then
		-- meseta: quantity
		item.name = "meseta"
		item.quantity = 0
		for i = 0,3 do
			item.quantity = item.quantity + bit.lshift(pso.read_u8(itemaddr + 0x100 + i), i * 8)
		end
	end -- item.type switch
	return item
end -- local function readitemdata

local function readbuffdata(playeraddr, offset)
	offset = offset or 0
	local techdata = {}
	local techtype = pso.read_u32(playeraddr + 0x274 + offset)
	if techtype == 0 then
		techdata = inittechdata()
	else
		techdata.name = techtypes[techtype]
		techdata.multiplier = pso.read_f32(playeraddr + 0x278 + offset)
		techdata.level = (math.abs(techdata.multiplier) - 0.087) * 77
		techdata.timeleft = pso.read_u32(playeraddr + 0x27c + offset) / 30
		techdata.totaltime = (techdata.level + 3) * 10
	end
	return techdata
end

local function readplayermonsterdata(playeraddr)
	local player = {}
	player.hp = pso.read_u16(playeraddr + _hp)
	player.hpmax = pso.read_u16(playeraddr + 0x2bc)
	local status = pso.read_u32(playeraddr + 0x268)
	player.statusfrozen = status == 0x02
	player.statusconfused = status == 0x12
	player.statusparalyzed = pso.read_u32(playeraddr + 0x25c) == 0x10
	player.deftech = readbuffdata(playeraddr, 12)
	player.atktech = readbuffdata(playeraddr)
	return player
end

function psodata.retrievepsodata()
	if not psodata.screenwidth or psodata.screenwidth == 0 then
		psodata.screenwidth = pso.read_u16(0x00a46c48)
		psodata.screenheight = pso.read_u16(0x00a46c4a)
	end
	local frametime = os.time() - lasttime
	gamedata.totaltime = gamedata.totaltime + frametime
	
	loadpmtaddress()
	local playeraddr = getself()
	if playeraddr ~= 0 then
		-- for _, state in ipairs(gamedata.menustate) do
			-- gamedata.menustate[state] = nil
		-- end
		if pso.read_u32(0x009ff3d4) ~= 1 then -- any menu open
			gamedata.menustate['anymenu'] = true
			gamedata.menustate['lowermenu'] = true -- pretty much every menu uses the lower part of the screen
			if pso.read_u32(0x00a97f44) == 1 then
				gamedata.menustate['mainmenu'] = true
				gamedata.menustate['fullmenu'] = nil
			elseif (pso.read_u32(0x00a48a9c) == 1) or ((psodata.currentlocation() == 'lobby') and (pso.read_u32(0x00aab218) ~= 0))then -- shops and stuff, also lobby counter
				gamedata.menustate['fullmenu'] = true
				gamedata.menustate['mainmenu'] = true
			else
				gamedata.menustate['fullmenu'] = nil
				gamedata.menustate['mainmenu'] = nil
			end
		else
			gamedata.menustate['fullmenu'] = nil
			gamedata.menustate['mainmenu'] = nil
			if pso.read_u32(0x00a97f44) == 2 then -- team chat
				gamedata.menustate['lowermenu'] = true
				gamedata.menustate['anymenu'] = true
			else
				gamedata.menustate['lowermenu'] = nil
				gamedata.menustate['anymenu'] = nil
			end
		end
	
		-- 0x00a97f44 main menu (== 1) and team chat (== 2)
		-- 0x00a48a9c bank, quest counter, shops, tekker, clinic (== 1)
		-- 0x009ff3d4 almost any menu (~= 1)
		
		-- print(gamedata.menustate)
		
		if activegamedata.xp then
			local pltaddress = pso.read_u32(0x00a94878)
			gamedata.level = pso.read_u32(playeraddr + 0xe44) + 1
			if pltaddress ~= 0 then
				if gamedata.level < 200 then
					local class = pso.read_u32(pso.read_u32(pltaddress) + 4 * pso.read_u8(playeraddr + 0x961))
					local totalxp = pso.read_u32(playeraddr + 0xe48)
					local thisleveltotalxp = pso.read_u32(class + 0x0c * (gamedata.level - 1) + 0x08)
					local nextleveltotalxp = pso.read_u32(class + 0x0c * gamedata.level + 0x08)
					gamedata.thislevelxp = nextleveltotalxp - thisleveltotalxp
						-- xp to level up from beginning of current level
						
					gamedata.levelprogress = totalxp - thisleveltotalxp
						-- character's xp past beginning of current level
						
					-- gamedata.tonextlevel = gamedata.thislevelxp - gamedata.levelprogress
					-- gamedata.levelprogressfloat = gamedata.levelprogress / gamedata.thislevelxp
				else -- player is level 200
					gamedata.thislevelxp = 0
					gamedata.levelprogress = 0
					gamedata.tonextlevel = 0
					gamedata.levelprogressfloat = 1
				end -- if gamedata.level < 200
			end -- if pltaddress ~= 0
		end -- if activegamedata.xp
		
		if activegamedata.ata then gamedata.ata = pso.read_u16(playeraddr + 0x2d4) end
		
		if activegamedata.player then
			local tempplayer = readplayermonsterdata(playeraddr)
			gamedata.playerhp = tempplayer.hp
			gamedata.playerhpmax = tempplayer.hpmax
			gamedata.playerfrozen = tempplayer.statusfrozen
			gamedata.playerconfused = tempplayer.statusconfused
			gamedata.playerparalyzed = tempplayer.statusparalyzed
			gamedata.playerdeftech = tempplayer.deftech
			gamedata.playeratktech = tempplayer.atktech
			gamedata.playertp = pso.read_u16(playeraddr + 0x336)
			gamedata.playertpmax = pso.read_u16(playeraddr + 0x2be)
			gamedata.playerinvulnerabilitytime = pso.read_u32(playeraddr + 0x720) / 30
		end -- if activegamedata.player
		
		if activegamedata.party then
			gamedata.party = {}
			for i = 0, 11 do
				local partymemberaddr = pso.read_u32(_playerarray + i * 4)
				if partymemberaddr ~= 0 and partymemberaddr ~= playeraddr then
					local partymemberdata = readplayermonsterdata(partymemberaddr)
					partymemberdata.tp = pso.read_u16(partymemberaddr + 0x336)
					partymemberdata.tpmax = pso.read_u16(partymemberaddr + 0x2be)
					partymemberdata.invulnerabilitytime = pso.read_u32(partymemberaddr + 0x720) / 30
					local partymembername = pso.read_wstr(partymemberaddr + 0x428, 12)
					if string.sub(partymembername, 1, 1) == "\t" then
						partymembername = string.sub(partymembername, 3)
					end -- if string.sub(partymembername, 1, 1) == "\t"
					partymemberdata.name = string.gsub(partymembername, "%%", "%%%%")
					table.insert(gamedata.party, partymemberdata)
				end -- if partymemberaddr ~= 0 and partymemberaddr ~= playeraddr
			end -- for i = 0, 11
		end -- if activegamedata.party
		
		if activegamedata.meseta then gamedata.meseta = pso.read_u32(playeraddr + 0xe4c) end
		
		local _lobby, _pioneer2 = 0xf, 0
		if activegamedata.sessiontime then
			local location = pso.read_u32(0x00aafc9c + 0x04)
			if location == _lobby then
				gamedata.currentlocation = 'lobby'
			elseif location == _pioneer2 then
				gamedata.currentlocation = 'pioneer 2'
			else
				gamedata.currentlocation = 'field'
			end
			if location ~= _lobby then
				if location == lastlocation then
					gamedata.elapsedtime = gamedata.elapsedtime + frametime
					gamedata.sessionxp = pso.read_u32(playeraddr + 0xe48) - sessionstartxp
					-- gamedata.sessionxprate = gamedata.sessionxp / gamedata.elapsedtime
					if location ~= _pioneer2 then
						gamedata.dungeontime = gamedata.dungeontime + frametime
						-- gamedata.dungeonxprate = gamedata.sessionxp / gamedata.dungeontime
					end -- if location ~= _pioneer2
				else -- location ~= lastlocation
					if lastlocation == _lobby then
						initsessiontime()
						sessionstartxp = pso.read_u32(playeraddr + 0xe48)
						-- lastlocation = location
						-- lasttime = now
					end -- if location == lastlocation
				end -- if location == lastlocation
			end -- if location ~= _lobby
			lastlocation = location
		end -- if activegamedata.sessiontime
		
		if activegamedata.flooritems or activegamedata.inventory then
			if activegamedata.flooritems then
				gamedata.flooritems = {}
			end
			if activegamedata.inventory then
				gamedata.inventory = {}
			end
			local playerindex = pso.read_u32(_myplayerindex)
			local itemarray = pso.read_u32(0x00a8d81c)
			local inventoryindex, floorindex = 0, 0
			local itemaddr
			for i = 1, pso.read_u32(0x00a8d820) do
				itemaddr = pso.read_u32(itemarray + 4 * (i - 1))
				if itemaddr ~= 0 then
					local owner = pso.read_i8(itemaddr + 0xe4)
					if owner == -1 and activegamedata.flooritems then
						floorindex = floorindex + 1
						local item = readitemdata(itemaddr, "floor")
						item.index = floorindex
						table.insert(gamedata.flooritems, item)
					elseif owner == playerindex and activegamedata.inventory then
						inventoryindex = inventoryindex + 1
						local item = readitemdata(itemaddr, "inventory")
						-- if gamedata.elapsedtime < 2 then
							-- print(item.name)
						-- end
						-- if item then
							item.index = inventoryindex
							table.insert(gamedata.inventory, item)
						-- end -- if item
					end -- check: inventory item or floor item
				end -- if itemaddr ~= 0
			end -- iterate through items array
			gamedata.inventoryspaceused = inventoryindex
		end -- if activegamedata.flooritems or activegamedata.inventory
		
		if activegamedata.bank then
			gamedata.bank = {}
			local bankaddress = pso.read_i32(_bankpointer)
			if bankaddress ~= 0 then
				bankaddress = bankaddress + 0x021c
				gamedata.bankspaceused = pso.read_u8(bankaddress)
				gamedata.bankmeseta = pso.read_i32(bankaddress + 4)
				for i = 1, gamedata.bankspaceused do
					local item = readitemdata(bankaddress + i * 24 - 16, "bank")
					if item then
						item.bankindex = i
						table.insert(gamedata.bank, item)
					end -- if item
				end -- iterate through bank items
			end -- if bankaddress ~= 0
		end -- if activegamedata.bank
		
		if activegamedata.monsterlist then
			gamedata.monsterlist = {}
			-- local monsteraddrlist = {}
			local namegroup = 2
			if pso.read_u32(0x00a9cd68) == 3 then
				namegroup = 4
			end
			local playerroom1 = pso.read_u16(playeraddr + _room)
			local playerroom2 = pso.read_u16(playeraddr + 0x2e)
			-- local playerx = pso.read_f32(playeraddr + 0x38)
			-- local playery = pso.read_f32(playeraddr + 0x3c)
			local playercount = pso.read_u32(0x00aae168)
			local entitycount = pso.read_u32(0x00aae164) - 1
			for i = 0, entitycount do
				local thismonster = {}
				local monsteraddr = pso.read_u32(0x00aad720 + 4 * (playercount + i))
				-- thismonster.hp = pso.read_u16(monsteraddr + _hp)
				if monsteraddr ~= 0 then
					local monsterid = pso.read_u32(monsteraddr + _monsterunitxtid)
					if monsterid == 45 or monsterid == 73 then
						thismonster.name = readfromunitxt(namegroup, pso.read_u32(monsteraddr + _monsterunitxtid))
						thismonster.hp = pso.read_u32(monsteraddr + bosshpoffset[monsterid])
						thismonster.hpmax = pso.read_u32(monsteraddr + bosshpmaxoffset[monsterid])
						local maxdataptr = pso.read_u32(0x00a43cc8)
						if maxdataptr ~= 0 then -- still has armor layer
							if i == 0 then -- this is the head
								thismonster.ap = pso.read_u32(monsteraddr + maskhpoffset[monsterid])
								thismonster.apmax = pso.read_u32(monsteraddr + 0x20)
							else -- this is a body segment
								thismonster.ap = pso.read_u32(monsteraddr + shellhpoffset[monsterid])
								thismonster.apmax = pso.read_u32(monsteraddr + 0x1c)
							end -- if i == 0
						end -- maxdataptr ~= 0
					else
						-- table.insert(monsteraddrlist, monsteraddr)
						local monsterroom = pso.read_u16(monsteraddr + _room)
						-- print(pso.read_u16(monsteraddr + _hp))
						-- print(monsterroom .. " == " .. playerroom1 .. " or " .. playerroom2)
						-- print((monsterroom == playerroom1 or monsterroom == playerroom2) and pso.read_u16(monsteraddr + _hp) > 0)
						if (monsterroom == playerroom1 or monsterroom == playerroom2) and pso.read_u16(monsteraddr + _hp) > 0 then
							-- print("live monster!")
							thismonster = readplayermonsterdata(monsteraddr)
							thismonster.name = readfromunitxt(namegroup, pso.read_u32(monsteraddr + _monsterunitxtid))
							table.insert(gamedata.monsterlist, thismonster)
						end -- if monster in same room and alive
					end -- if monsterid == 45 or monsterid == 73
				end -- if monsteraddr ~= 0
			end -- iterate through monster list
		-- print("my addon monster addresses:")
		-- for i, ma in ipairs(monsteraddrlist) do print(i .. " " .. ma) end
		end -- if activegamedata.monsterlist
		
	else
		gamedata.currentlocation = 'login'
	end -- check: player data present or not
	lasttime = os.time()
end -- local function retrievepsodata

-- psodata.get = function(key) return gamedata[key] end
function psodata.currentlocation()
	return gamedata.currentlocation
end

function psodata.setactive(datagroup) activegamedata[datagroup] = true end

function psodata.activedatareset() activegamedata = {} end

do -- define psodata getter functions

	local sf = {} -- string functions
	local nf = {} -- number functions
	local lf = {} -- list functions
	local bf = {} -- boolean functions
	local pf = {} -- progress functions

	sf['player current hp'] = function() return gamedata.playerhp end
	sf['player maximum hp'] = function() return gamedata.playerhpmax end
	sf['player current tp'] = function() return gamedata.playertp end
	sf['player maximum tp'] = function() return gamedata.playertpmax end
	sf['invulnerability time'] = function() return gamedata.playerinvulnerabilitytime end
	sf['player level'] = function() return gamedata.level end
	sf['level base xp'] = function() return gamedata.thislevelxp end
	sf['xp this level'] = function() return gamedata.levelprogress end
	sf['player ata'] = function() return gamedata.ata end
	sf['pack meseta'] = function() return gamedata.meseta end
	sf['session time elapsed'] = function() return gamedata.elapsedtime end
	sf['session xp accumulated'] = function() return gamedata.sessionxp end
	sf['session time in dungeon'] = function() return gamedata.dungeontime end
	sf['pack slots used'] = function() return gamedata.inventoryspaceused end
	sf['pack slots free'] = function() return 30 - gamedata.inventoryspaceused end
	sf['bank slots used'] = function() return gamedata.bankspaceused end
	sf['bank slots free'] = function() return 200 - gamedata.bankspaceused end
	sf['bank meseta'] = function() return gamedata.bankmeseta end
	sf['hp: current/maximum'] = function() return gamedata.playerhp .. '/' .. gamedata.playerhpmax end
	sf['tp: current/maximum'] = function() return gamedata.playertp .. '/' .. gamedata.playertpmax end
	sf['xp progress/needed'] = function() return gamedata.levelprogress .. '/' .. gamedata.thislevelxp end
	sf['xp to next level'] = function() return gamedata.thislevelxp - gamedata.levelprogress end
	sf['xp/second this session'] = function() return gamedata.sessionxp / gamedata.elapsedtime end
	sf['kxp/hour this session'] = function() return gamedata.sessionxp / gamedata.elapsedtime * 3.6 end
	sf['xp/second in dungeon'] = function() return gamedata.sessionxp / gamedata.dungeontime end
	sf['kxp/hour in dungeon'] = function() return gamedata.sessionxp / gamedata.dungeontime * 3.6 end
	sf['pack space: used/total'] = function() return gamedata.inventoryspaceused .. '/30' end
	sf['bank space: used/total'] = function() return gamedata.bankspaceused .. '/200' end

	sf['inventory items'] = function() return gamedata.inventory end
	sf['floor items'] = function() return gamedata.flooritems end
	sf['bank items'] = function() return gamedata.bank end
	sf['party members'] = function() return gamedata.party end
	sf['monsters in current room'] = function() return gamedata.monsterlist end

	-- bf['player status: frozen'] = function() return gamedata.playerfrozen end
	-- bf['player status: confused'] = function() return gamedata.playerconfused end
	-- bf['player status: paralyzed'] = function() return gamedata.playerparalyzed end

	sf['player hp'] = function() return
		{gamedata.playerhp, gamedata.playerhpmax} end
	sf['player tp'] = function() return
		{gamedata.playertp, gamedata.playertpmax} end
	sf['xp progress'] = function() return
		{gamedata.levelprogress, gamedata.thislevelxp} end
	sf['pack space'] = function() return
		{gamedata.inventoryspaceused, 30} end
	sf['bank space'] = function() return
		{gamedata.bankspaceused, 200} end
	sf['player deband/zalure timer'] = function() return
		{gamedata.playerdeftech.timeleft,
		gamedata.playerdeftech.totaltime} end
	sf['player shifta/jellen timer'] = function() return
		{gamedata.playeratktech.timeleft,
		gamedata.playeratktech.totaltime} end

	sf['player s/d/j/z timer'] = function()
		deffloat = gamedata.playerdeftech.timeleft / gamedata.playerdeftech.totaltime
		atkfloat = gamedata.playeratktech.timeleft / gamedata.playeratktech.totaltime
		if (deffloat == 0) or (deffloat > atkfloat) then
			return {gamedata.playeratktech.timeleft,
				gamedata.playeratktech.totaltime}
		else
			return {gamedata.playerdeftech.timeleft, 
				gamedata.playerdeftech.totaltime}
		end
	end
	
	-- local timeuntilchange(time1, time2)
		-- if (time1 == 0) or ((time2 < time1) and (time2 ~= 0)) then
			-- return time2
		-- else
			-- return time1
		-- end
	-- end
	
	-- sf['s/d/j/z time left'] = function()
		-- return timeuntilchange
			-- { gamedata.playerdeftech.timeleft,
			-- gamedata.playeratktech.timeleft }
	-- end
	
	-- sf['s/d/j/z starting time'] = function()
		-- return timeuntilchange
			-- { gamedata.playerdeftech.totaltime,
			-- gamedata.playeratktech.totaltime }
	-- end
	
	psodata.combolist =
		{
		['string'] =
			{
			'player current hp',
			'player maximum hp',
			'player current tp',
			'player maximum tp',
			'invulnerability time',
			'player level',
			'level base xp',
			'xp this level',
			'player ata',
			'pack meseta',
			'session time elapsed',
			'session xp accumulated',
			'session time in dungeon',
			'pack slots used',
			'pack slots free',
			'bank slots used',
			'bank slots free',
			'bank meseta',
			'hp: current/maximum',
			'tp: current/maximum',
			'xp: progress/needed',
			'xp to next level',
			'xp/second this session',
			'xp/second in dungeon',
			'pack space: used/total',
			'bank space: used/total',
			},
		['number'] =
			{
			'player current hp',
			'player maximum hp',
			'player current tp',
			'player maximum tp',
			'invulnerability time',
			'player level',
			'level base xp',
			'xp progress',
			'player ata',
			'pack meseta',
			'session time elapsed',
			'session xp accumulated',
			'session time in dungeon',
			'pack slots used',
			'pack slots free',
			'bank slots used',
			'bank slots free',
			'bank meseta',
			'xp to next level',
			'xp/second this session',
			'xp/second in dungeon',
			},
		['progress'] =
			{
			'player hp',
			'player tp',
			'player deband/zalure timer',
			'player shifta/jellen timer',
			'player s/d/j/z timer',
			'xp progress',
			},
		['list'] =
			{
			'inventory items',
			'floor items',
			'bank items',
			'party members',
			'monsters in current room',
			},
		}
	
	for _, list in pairs(psodata.combolist) do
		utility.addcombolist(list)
	end
	
	psodata.get = sf
	
	psodata.listfields = {}
	psodata.listsubfields = {}
	psodata.listsubfields['inventory items'] =
		{
		['weapon'] =
			{
			['string'] = {'index', 'type', 'equipped', 'name', 'grind', 'wrapped', 'killcount', 'untekked', 'issrank', 'srankname', 'special', 'native', 'a. beast', 'machine', 'dark', 'hit'},
			['number'] = {'index', 'grind', 'killcount', 'native', 'a. beast', 'machine', 'dark', 'hit'},
			['progress'] = {},
			},
		['frame'] =
			{
			['string'] = {'index', 'type', 'equipped', 'name', 'wrapped', 'slots', 'defense', 'defensemax', 'evade', 'evademax'},
			['number'] = {'index', 'slots', 'defense', 'defensemax', 'evade', 'evademax'},
			['progress'] = {},
			},
		['barrier'] =
			{
			['string'] = {'index', 'type', 'equipped', 'name', 'wrapped', 'defense', 'defensemax', 'evade', 'evademax'},
			['number'] = {'index', 'defense', 'defensemax', 'evade', 'evademax'},
			['progress'] = {},
			},
		['unit'] =
			{
			['string']= {'index', 'type', 'equipped', 'name', 'wrapped', 'killcount', 'unitmod'},
			['number'] = {'index', 'killcount', 'unitmod'},
			['progress'] = {},
			},
		['mag'] =
			{
			['string'] = {'index', 'type', 'equipped', 'name', 'wrapped', 'def', 'pow', 'dex', 'mind', 'sync', 'iq', 'color', 'pb', 'timer'},
			['number']= {'index', 'def', 'pow', 'dex', 'mind', 'sync', 'iq', 'timer'},
			['progress'] = {},
			},
		['technique disk'] =
			{
			['string'] = {'index', 'type', 'name', 'wrapped', 'techniquelevel'},
			['number'] = {'index', 'techniquelevel'},
			['progress'] = {},
			},
		['tool'] =
			{
			['string'] = {'index', 'type', 'name', 'wrapped', 'quantity'},
			['number'] = {'index', 'quantity'},
			['progress'] = {},
			},
		['meseta'] =
			{
			['string'] = {'index', 'type', 'name', 'wrapped', 'quantity'},
			['number'] = {'index', 'quantity'},
			['progress'] = {},
			},
		} -- psodata.listsubfields['inventory items'] = {...}
	psodata.listsubfields['floor items'] =
		{
		['weapon'] =
			{
			['string'] = {'index', 'type', 'name', 'grind', 'wrapped', 'killcount', 'untekked', 'issrank', 'srankname', 'special', 'native', 'a. beast', 'machine', 'dark', 'hit'},
			['number'] = {'index', 'grind', 'killcount', 'native', 'a. beast', 'machine', 'dark', 'hit'},
			['progress'] = {},
			},
		['frame'] =
			{
			['string'] = {'index', 'type', 'name', 'wrapped', 'slots', 'defense', 'defensemax', 'evade', 'evademax'},
			['number'] = {'index', 'slots', 'defense', 'defensemax', 'evade', 'evademax'},
			['progress'] = {},
			},
		['barrier'] =
			{
			['string'] = {'index', 'type', 'name', 'wrapped', 'defense', 'defensemax', 'evade', 'evademax'},
			['number'] = {'index', 'defense', 'defensemax', 'evade', 'evademax'},
			['progress'] = {},
			},
		['unit'] =
			{
			['string'] = {'index', 'type', 'name', 'wrapped', 'killcount', 'unitmod'},
			['number'] = {'index', 'killcount', 'unitmod'},
			['progress'] = {},
			},
		['mag'] =
			{
			['string'] = {'index', 'type', 'name', 'wrapped', 'def', 'pow', 'dex', 'mind', 'sync', 'iq', 'color', 'pb', 'timer'},
			['number']= {'index', 'def', 'pow', 'dex', 'mind', 'sync', 'iq', 'timer'},
			['progress'] = {},
			},
		['technique disk'] =
			{
			['string'] = {'index', 'type', 'name', 'wrapped', 'techniquelevel'},
			['number'] = {'index', 'techniquelevel'},
			['progress'] = {},
			},
		['tool'] =
			{
			['string'] = {'index', 'type', 'name', 'wrapped', 'quantity'},
			['number'] = {'index', 'quantity'},
			['progress'] = {},
			},
		['meseta'] =
			{
			['string'] = {'index', 'type', 'name', 'wrapped', 'quantity'},
			['number'] = {'index', 'quantity'},
			['progress'] = {},
			},
		}
	psodata.listfields['party members'] =
		{
		['string'] = {'hp', 'hpmax', 'statusfrozen', 'statusconfused', 'statusparalyzed', 'deftech', 'atktech', 'tp', 'tpmax', 'invulnerabilitytime', 'name'},
		['number'] = {'hp', 'hpmax', 'tp', 'tpmax', 'invulnerabilitytime'},
		}
	psodata.listfields['monsters in current room'] =
		{
		['string'] = {'hp', 'hpmax', 'statusfrozen', 'statusconfused', 'statusparalyzed', 'deftech', 'atktech', 'name'},
		['number'] = {'hp', 'hpmax'},
		}

	for _, list in pairs(psodata.listsubfields) do
		for _, sublist in pairs(list) do
			for index, value in pairs(sublist) do
				sublist[value] = index
			end
		end
	end
	psodata.listsubfields['bank items'] = psodata.listsubfields['floor items']

	for _, list in pairs(psodata.listfields) do
		for index, value in pairs(list) do
			list[value] = index
		end
	end
	

end

function psodata.getdata(fieldname) return gamedata[fieldname] end

function psodata.getgamewindowsize()
	return pso.read_u16(0x00a46c48), pso.read_u16(0x00a46c4a)
end

return psodata
