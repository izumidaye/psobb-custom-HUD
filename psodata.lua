--[[
Item Reader, Player Reader, and Monster Reader code copyright Soleil Rojas (Soly)
XpBar code copyright Phil Smith (Tornupgaming)
Kill Counter code copyright Stephen C. Wills (Staphen)
Modifications copyright Catherine Sciuridae (NeonLuna)
]]

local _bankPointer = 0x00A95DE0 + 0x18

local itemOffset={weapon=0x00,armor=0x04,mag=0x10,tool=0x0C,unit=0x08}
local resultOffset={weapon=44,armor=32,mag=28,tool=24,unit=20}
local bossHpOffset = {[45]=0x6B4, [73]=0x704}
local bossHpMaxOffset = {[45]=0x6B0, [73]=0x700}
local maskHpOffset = {[45]=0x6B8, [73]=0x708}
local shellHpOffset = {[45]=0x39C, [73]=0x7AC}

local armorTypes = {"frame", "barrier", "unit"}
local itemTypes = {"weapon", "armor", "mag", "tool", "meseta"}
local attributeList = {"Native", "A. Beast", "Machine", "Dark", "Hit"}
local techTypes = {[9]="S", [10]="D", [11]="J", [12]="Z"}

local _hp = 0x334
local _itemKillcount = 0xE8
local _monsterUnitxtId = 0x378
local _myPlayerIndex = 0x00A9C4F4
local _playerArray = 0x00A94254
local _room = 0x28
local _toolQuantity = 0x104
local _weaponGrind = 0x1F5
-- local _evp = 0x2D0

local ActiveGameData = {} -- indicates which data are in use
local sessionStartXp
local pmtAddress = nil
local psodata = {}
local GameData = {}
local lastTime, lastLocation

local function getSelf()
	return pso.read_u32(_playerArray + pso.read_u32(_myPlayerIndex) * 4)
end

local function loadPmtAddress()
	pmtAddress = pso.read_u32(0x00A8DC94)
	return pmtAddress ~= 0
end

local function initTechData()
	return {multiplier=0, name="none", level=0, timeLeft=0, totalTime=0, timeFloat=0}
end -- local function initTechData

local function initSessionTime()
	lastTime = os.time()
	GameData.elapsedTime = 0
	GameData.dungeonTime = 0
	GameData.sessionXp = 0
	GameData.sessionXpRate = 0 -- per
	GameData.dungeonXpRate = 0 -- second
	local player = getSelf()
	if player ~= 0 then
		sessionStartXp = pso.read_u32(player + 0xE48)
	end
end -- local function initSessionTime

local function getUnitxtItemAddress(type, group, index)
	if not pmtAddress then return nil end
	local groupOffset = 0
	if type == "weapon" or type == "tool" then
		groupOffset = group * 8
	elseif type == "armor" then
		if group == 3 then
			type = "unit"
		else
			groupOffset = (group - 1) * 8
		end
	elseif type == "mag" then
		index = group
	elseif type == "meseta" then
		return 0
	end
	-- print(type)
	local itemAddr = pso.read_u32(pmtAddress + itemOffset[type])
	-- print(itemAddr)
	if itemAddr == 0 then return nil end
	local groupAddr = itemAddr + groupOffset
	-- print(groupAddr)
	local count = pso.read_u32(groupAddr)
	-- print(count)
	itemAddr = pso.read_u32(groupAddr + 4)
	-- print(itemAddr)
	if index < count and itemAddr ~= 0 then
		return itemAddr + (index * resultOffset[type])
	else
		return nil
	end
end -- getUnitxtItemAddress = function

local function readFromUnitxt(group, index)
	local address = pso.read_u32(0x00A9CD50)
	if address == 0 then return nil end
	address = pso.read_u32(address + group * 4)
	if address == 0 then return nil end
	address = pso.read_u32(address + index * 4)
	if address == 0 then return nil end
	return pso.read_wstr(address, 256)
end

local function readItemData(itemAddr, location)
	item = {} -- all item types: type, name, equipped* (*inventory only)
	local offset = 0
	if location ~= "bank" then offset = 0xF2 end
	item.type = itemTypes[pso.read_u8(itemAddr + offset) + 1]
	local group = pso.read_u8(itemAddr + offset + 1)
	local index = pso.read_u8(itemAddr + offset + 2)
	
	if location == "inventory" then
		item.equipped = bit.band(pso.read_u8(itemAddr + 0x190), 1) == 1
	end
	local unitxtAddr = getUnitxtItemAddress(item.type, group, index)
	
	item.name = "???"
	if not unitxtAddr then
		return nil
	elseif item.type == "meseta" then
		item.name = "meseta"
	else
		local id = pso.read_i32(unitxtAddr)
		if id ~= -1 then item.name = readFromUnitxt(1, id) end
	end
	
	if item.type == "weapon" then
		-- weapon: grind, wrapped, untekked, killcount, isSrank, attributes -or- sRank name, special
		local grindOffset, specialOffset, statsOffset
		if location == "bank" then
			grindOffset, specialOffset, statsOffset = 3, 4, 6
		else
			grindOffset = _weaponGrind
			specialOffset = 0x1F6
			statsOffset = 0x1C8
		end
		
		item.grind = pso.read_u8(itemAddr + _weaponGrind)
		
		local wrappedOrUntekked = pso.read_u8(itemAddr + specialOffset)
		if wrappedOrUntekked > 0xBF then
			item.wrapped = true
			item.untekked = true
		elseif wrappedOrUntekked > 0x7F then
			item.untekked = true
		elseif wrappedOrUntekked > 0x3F then
			item.wrapped = true
		end -- if wrappedOrUntekked > 0xBF
		
		if group == 0x33 or group == 0xAB then
			item.killcount = pso.read_u16(itemAddr + _itemKillcount)
		end
		
		item.isSrank = (group >= 0x70 and group < 0x89) or (group >=0xA5 and group < 0xAA)
		if item.isSrank then
			local result = ""
			local temp = 0
			for i = 0,4,2 do
				local addr = itemAddr + statsOffset + i
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
			item.SrankName = result
			item.special = index
			
		else -- not Srank
			item.special = pso.read_u8(itemAddr + specialOffset) % 64
			if item.special == 0 then
				item.special = "None"
			else
				item.special = readFromUnitxt(1, pso.read_u32(0x005E4CBB) + item.special)
			end -- if item.special == 0
			for attrName in ipairs(attributeList) do
				item[attrName] = 0
			end
			for i = 0,4,2 do
				local attrAddr = itemAddr + statsOffset + i -- attributeAddress
				local attrIndex = pso.read_u8(attrAddr) + 1
				if attrIndex < 6 then -- maybe this 6 should be a 7
					local attrValue = pso.read_u8(attrAddr + 1)
					local attrName = attributeList[attrIndex]
					if attrValue > 127 then attrValue = attrValue - 256 end
					item[attrName] = attrValue
				end
			end
		end -- else -- not Srank
	
	elseif item.type == "armor" then
		if group == 1 then -- frame: slots, defense/max, evade/max
			item.type = "frame"
			local slotsOffset, defOffset, evadeOffset
			if location == "bank" then
				slotsOffset, defOffset, evadeOffset = 5, 6, 8
			else
				slotsOffset = 0x1B8
				defOffset = 0x1B9
				evadeOffset = 0x1BA
			end
			item.slots = pso.read_u8(itemAddr + slotsOffset)
			item.defense = pso.read_u8(itemAddr + defOffset)
			item.defenseMax = pso.read_u8(unitxtAddr + 26)
			item.evade = pso.read_u8(itemAddr + evadeOffset)
			item.evadeMax = pso.read_u8(unitxtAddr + 27)
			
		elseif group == 2 then -- barrier: defense/max, evade/max
			item.type = "barrier"
			local defOffset, evadeOffset
			if location == "bank" then
				defOffset, evadeOffset = 6, 8
			else
				defOffset = 0x1E4
				evadeOffset = 0x1E5
			end
			item.defense = pso.read_u8(itemAddr + defOffset)
			item.defenseMax = pso.read_u8(unitxtAddr + 26)
			item.evade = pso.read_u8(itemAddr + evadeOffset)
			item.evadeMax = pso.read_u8(unitxtAddr + 27)
			
		elseif group == 3 then -- unit: mod + or -
			item.type = "unit"
			local modOffset
			if location == "bank" then
				modOffset = 6
			else
				modOffset = 0x1DC
			end
			item.unitMod = pso.read_u8(itemAddr + modOffset)
			if item.unitMod > 127 then item.unitMod = item.unitMod - 256 end
			if item.unitMod < -2 then
				item.unitMod = -2
			elseif item.unitMod > 2 then
				item.unitMod = 2
			end
			-- item.unitMod2 = pso.read_u8(itemAddr + modOffset + 1)
			if index == 0x4D or index == 0x4F then
				item.killcount = pso.read_u16(itemAddr + _itemKillcount)
			end
			
		end -- armor subtype switch
	elseif item.type == "mag" then
		-- mag: def.%, pow.%, dex.%, mind.%, sync, iq, color, timer* (*inventory only), pbs
		local statsAddr, syncOffset, iqOffset, colorOffset, pbPresenceOffset, pbListOffset
		if location == "bank" then
			item.timer = 210
			statsAddr = itemAddr + 4
			syncOffset, iqOffset, colorOffset = 16, 17, 19
			pbPresenceOffset, pbListOffset = 18, 3
		else
			item.timer = pso.read_f32(itemAddr + 0x1B4) / 30
			statsAddr = itemAddr + 0x1C0
			syncOffset = 0x1BE
			iqOffset = 0x1BC
			colorOffset = 0x1CA
			pbPresenceOffset = 0x1C8
			pbListOffset = 0x1C9
		end
		item.def = (bit.lshift(pso.read_u8(statsAddr + 1), 8) + pso.read_u8(statsAddr)) / 100
		item.pow = (bit.lshift(pso.read_u8(statsAddr + 3), 8) + pso.read_u8(statsAddr + 2)) / 100
		item.dex = (bit.lshift(pso.read_u8(statsAddr + 5), 8) + pso.read_u8(statsAddr + 4)) / 100
		item.mind = (bit.lshift(pso.read_u8(statsAddr + 7), 8) + pso.read_u8(statsAddr + 6)) / 100
		item.sync = pso.read_u8(itemAddr + syncOffset)
		item.iq = pso.read_u8(itemAddr + iqOffset)
		item.color = pso.read_u8(itemAddr + colorOffset)
		local pbList = pso.read_u8(itemAddr + pbListOffset)
		local pbPresence = pso.read_u8(itemAddr + pbPresenceOffset)
		item.pb = {}
		local takenPbs = {}
		local pbIndex
		if bit.band(pbPresence, 1) ~= 0 then
			pbIndex = bit.band(pbList, 7)
			item.pb[2] = readFromUnitxt(9, pbIndex)
			takenPbs[pbIndex + 1] = true
		end
		if bit.band(pbPresence, 2) ~= 0 then
			pbIndex = bit.rshift(bit.band(pbList, 56), 3)
			item.pb[3] = readFromUnitxt(9, pbIndex)
			takenPbs[pbIndex + 1] = true
		end
		if bit.band(pbPresence, 4) ~= 0 then
			pbIndex = bit.rshift(bit.band(pbList, 0xC0), 6)
			for i = 1,6 do
				if not takenPbs[i] then
					if pbIndex == 0 then
						item.pb[1] = readFromUnitxt(9, i - 1)
					else
						pbIndex = pbIndex - 1
					end
				end
			end
		end
	elseif item.type == "tool" then
		if group == 2 then -- technique disk: tech learned, level
			item.type = "technique disk"
			local techNameOffset
			if location == "bank" then
				techNameOffset = 4
			else
				techNameOffset = 0x108
			end
			item.name = readFromUnitxt(5, pso.read_u8(itemAddr + techNameOffset))
			item.techniqueLevel = index + 1
		else -- consumable item: quantity
			if location == "bank" then
				item.quantity = pso.read_u8(itemAddr + 20)
			else
				item.quantity = bit.bxor(pso.read_u32(itemAddr + _toolQuantity), itemAddr + _toolQuantity)
			end
		end
	elseif item.type == "meseta" then
		-- meseta: quantity
		item.name = "meseta"
		item.quantity = 0
		for i = 0,3 do
			item.quantity = item.quantity + bit.lshift(pso.read_u8(itemAddr + 0x100 + i), i * 8)
		end
	end -- item.type switch
	return item
end -- local function readItemData

local function readBuffData(playerAddr, offset)
	offset = offset or 0
	local td = {} -- tech data
	local techType = pso.read_u32(playerAddr + 0x274 + offset)
	if techType == 0 then
		td = initTechData()
	else
		td.multiplier = pso.read_f32(playerAddr + 0x278 + offset)
		td.name = techTypes[techType]
		td.level = (math.abs(td.multiplier) - 0.087) * 77
		td.timeLeft = pso.read_u32(playerAddr + 0x27C + offset) / 30
		td.totalTime = (td.level + 3) * 10
	end
	return td
end

local function readPlayerMonsterData(playerAddr)
	local player = {}
	player.hp = pso.read_u16(playerAddr + _hp)
	player.hpMax = pso.read_u16(playerAddr + 0x2BC)
	local status = pso.read_u32(playerAddr + 0x268)
	player.statusFrozen = status == 0x02
	player.statusConfused = status == 0x12
	player.statusParalyzed = pso.read_u32(playerAddr + 0x25C) == 0x10
	player.defTech = readBuffData(playerAddr, 12)
	player.atkTech = readBuffData(playerAddr)
	return player
end

psodata.retrievePsoData = function()
	loadPmtAddress()
	local playerAddr = getSelf()
	if playerAddr ~= 0 then
		GameData.menuState = pso.read_u32(0x00A97F44)
		
		if ActiveGameData.xp then
			local pltAddress = pso.read_u32(0x00A94878)
			GameData.level = pso.read_u32(playerAddr + 0xE44) + 1
			if pltAddress ~= 0 then
				if GameData.level < 200 then
					local class = pso.read_u32(pso.read_u32(pltAddress) + 4 * pso.read_u8(playerAddr + 0x961))
					local totalXp = pso.read_u32(playerAddr + 0xE48)
					local thisLevelTotalXp = pso.read_u32(class + 0x0C * (GameData.level - 1) + 0x08)
					local nextLevelTotalXp = pso.read_u32(class + 0x0C * GameData.level + 0x08)
					GameData.thisLevelXp = nextLevelTotalXp - thisLevelTotalXp
						-- xp to level up from beginning of current level
						
					GameData.levelProgress = totalXp - thisLevelTotalXp
						-- character's xp past beginning of current level
						
					-- GameData.toNextLevel = GameData.thisLevelXp - GameData.levelProgress
					-- GameData.levelProgressFloat = GameData.levelProgress / GameData.thisLevelXp
				else -- player is level 200
					GameData.thisLevelXp = 0
					GameData.levelProgress = 0
					GameData.toNextLevel = 0
					GameData.levelProgressFloat = 1
				end -- if GameData.level < 200
			end -- if pltAddress ~= 0
		end -- if ActiveGameData.xp
		
		if ActiveGameData.ata then GameData.ata = pso.read_u16(playerAddr + 0x2D4) end
		
		if ActiveGameData.player then
			local tempPlayer = readPlayerMonsterData(playerAddr)
			GameData.playerHP = tempPlayer.hp
			GameData.playerHPmax = tempPlayer.hpMax
			GameData.playerFrozen = tempPlayer.statusFrozen
			GameData.playerConfused = tempPlayer.statusConfused
			GameData.playerParalyzed = tempPlayer.statusParalyzed
			GameData.playerDefTech = tempPlayer.defTech
			GameData.playerAtkTech = tempPlayer.atkTech
			GameData.playerTP = pso.read_u16(playerAddr + 0x336)
			GameData.playerTPmax = pso.read_u16(playerAddr + 0x2BE)
			GameData.playerInvulnerabilityTime = pso.read_u32(playerAddr + 0x720) / 30
		end -- if ActiveGameData.Player
		
		if ActiveGameData.party then
			GameData.party = {}
			for i = 0, 11 do
				local partyMemberAddr = pso.read_u32(_playerArray + i * 4)
				if partyMemberAddr ~= 0 and partyMemberAddr ~= playerAddr then
					local partyMemberData = readPlayerMonsterData(partyMemberAddr)
					partyMemberData.tp = pso.read_u16(partyMemberAddr + 0x336)
					partyMemberData.tpMax = pso.read_u16(partyMemberAddr + 0x2BE)
					partyMemberData.invulnerabilityTime = pso.read_u32(partyMemberAddr + 0x720) / 30
					local partyMemberName = pso.read_wstr(partyMemberAddr + 0x428, 12)
					if string.sub(partyMemberName, 1, 1) == "\t" then
						partyMemberName = string.sub(partyMemberName, 3)
					end -- if string.sub(partyMemberName, 1, 1) == "\t"
					partyMemberData.name = string.gsub(partyMemberName, "%%", "%%%%")
					table.insert(GameData.party, partyMemberData)
				end -- if partyMemberAddr ~= 0 and partyMemberAddr ~= playerAddr
			end -- for i = 0, 11
		end -- if ActiveGameData.party
		
		if ActiveGameData.meseta then GameData.meseta = pso.read_u32(playerAddr + 0xE4C) end
		
		local _lobby, _pioneer2 = 0xF, 0
		if ActiveGameData.sessionTime then
			local now = os.time()
			local location = pso.read_u32(0x00AAFC9C + 0x04)
			if location ~= _lobby then
				if location == lastLocation then
					local frameTime = now - lastTime
					GameData.elapsedTime = GameData.elapsedTime + frameTime
					GameData.sessionXp = pso.read_u32(playerAddr + 0xE48) - sessionStartXp
					-- GameData.sessionXpRate = GameData.sessionXp / GameData.elapsedTime
					if location ~= _pioneer2 then
						GameData.dungeonTime = GameData.dungeonTime + frameTime
						-- GameData.dungeonXpRate = GameData.sessionXp / GameData.dungeonTime
					end -- if location ~= _pioneer2
				else -- location ~= lastLocation
					if lastLocation == _lobby then
						initSessionTime()
						sessionStartXp = pso.read_u32(playerAddr + 0xE48)
						-- lastLocation = location
						-- lastTime = now
					end -- if location == lastLocation
				end -- if location == lastLocation
			end -- if location ~= _lobby
			lastLocation = location
			lastTime = now
		end -- if ActiveGameData.sessionTime
		
		if ActiveGameData.floorItems or ActiveGameData.inventory then
			if ActiveGameData.floorItems then
				GameData.floorItems = {}
			end
			if ActiveGameData.inventory then
				GameData.inventory = {}
			end
			local playerIndex = pso.read_u32(_myPlayerIndex)
			local itemArray = pso.read_u32(0x00A8D81C)
			local inventoryIndex, floorIndex = 0, 0
			local itemAddr
			for i = 1, pso.read_u32(0x00A8D820) do
				itemAddr = pso.read_u32(itemArray + 4 * (i - 1))
				if itemAddr ~= 0 then
					local owner = pso.read_i8(itemAddr + 0xE4)
					if owner == -1 and ActiveGameData.floorItems then
						floorIndex = floorIndex + 1
						local item = readItemData(itemAddr, "floor")
						item.index = floorIndex
						table.insert(GameData.floorItems, item)
					elseif owner == playerIndex and ActiveGameData.inventory then
						inventoryIndex = inventoryIndex + 1
						local item = readItemData(itemAddr, "inventory")
						-- if GameData.elapsedTime < 2 then
							-- print(item.name)
						-- end
						-- if item then
							item.index = inventoryIndex
							table.insert(GameData.inventory, item)
						-- end -- if item
					end -- check: inventory item or floor item
				end -- if itemAddr ~= 0
			end -- iterate through items array
			GameData.inventorySpaceUsed = inventoryIndex
		end -- if ActiveGameData.floorItems or ActiveGameData.inventory
		
		if ActiveGameData.bank then
			GameData.bank = {}
			local bankAddress = pso.read_i32(_bankPointer)
			if bankAddress ~= 0 then
				bankAddress = bankAddress + 0x021C
				GameData.bankSpaceUsed = pso.read_u8(bankAddress)
				GameData.bankMeseta = pso.read_i32(bankAddress + 4)
				for i = 1, GameData.bankSpaceUsed do
					local item = readItemData(bankAddress + i * 24 - 16, "bank")
					if item then
						item.bankIndex = i
						table.insert(GameData.bank, item)
					end -- if item
				end -- iterate through bank items
			end -- if bankAddress ~= 0
		end -- if ActiveGameData.bank
		
		if ActiveGameData.monsterList then
			GameData.monsterList = {}
			-- local monsterAddrList = {}
			local nameGroup = 2
			if pso.read_u32(0x00A9CD68) == 3 then
				nameGroup = 4
			end
			local playerRoom1 = pso.read_u16(playerAddr + _room)
			local playerRoom2 = pso.read_u16(playerAddr + 0x2E)
			-- local playerX = pso.read_f32(playerAddr + 0x38)
			-- local playerY = pso.read_f32(playerAddr + 0x3C)
			local playerCount = pso.read_u32(0x00AAE168)
			local entityCount = pso.read_u32(0x00AAE164) - 1
			for i = 0, entityCount do
				local thisMonster = {}
				local monsterAddr = pso.read_u32(0x00AAD720 + 4 * (playerCount + i))
				-- thisMonster.hp = pso.read_u16(monsterAddr + _hp)
				if monsterAddr ~= 0 then
					local monsterId = pso.read_u32(monsterAddr + _monsterUnitxtId)
					if monsterId == 45 or monsterId == 73 then
						thisMonster.name = readFromUnitxt(nameGroup, pso.read_u32(monsterAddr + _monsterUnitxtId))
						thisMonster.hp = pso.read_u32(monsterAddr + bossHpOffset[monsterId])
						thisMonster.hpMax = pso.read_u32(monsterAddr + bossHpMaxOffset[monsterId])
						local maxDataPtr = pso.read_u32(0x00A43CC8)
						if maxDataPtr ~= 0 then -- still has armor layer
							if i == 0 then -- this is the head
								thisMonster.ap = pso.read_u32(monsterAddr + maskHpOffset[monsterId])
								thisMonster.apMax = pso.read_u32(monsterAddr + 0x20)
							else -- this is a body segment
								thisMonster.ap = pso.read_u32(monsterAddr + shellHpOffset[monsterId])
								thisMonster.apMax = pso.read_u32(monsterAddr + 0x1C)
							end -- if i == 0
						end -- maxDataPtr ~= 0
					else
						-- table.insert(monsterAddrList, monsterAddr)
						local monsterRoom = pso.read_u16(monsterAddr + _room)
						-- print(pso.read_u16(monsterAddr + _hp))
						-- print(monsterRoom .. " == " .. playerRoom1 .. " or " .. playerRoom2)
						-- print((monsterRoom == playerRoom1 or monsterRoom == playerRoom2) and pso.read_u16(monsterAddr + _hp) > 0)
						if (monsterRoom == playerRoom1 or monsterRoom == playerRoom2) and pso.read_u16(monsterAddr + _hp) > 0 then
							-- print("live monster!")
							thisMonster = readPlayerMonsterData(monsterAddr)
							thisMonster.name = readFromUnitxt(nameGroup, pso.read_u32(monsterAddr + _monsterUnitxtId))
							table.insert(GameData.monsterList, thisMonster)
						end -- if monster in same room and alive
					end -- if monsterId == 45 or monsterId == 73
				end -- if monsterAddr ~= 0
			end -- iterate through monster list
		-- print("my addon monster addresses:")
		-- for i, ma in ipairs(monsterAddrList) do print(i .. " " .. ma) end
		end -- if ActiveGameData.monsterList
		
	end -- check: player data present or not
end -- local function retrievePsoData

psodata.setActive = function(dataGroup) ActiveGameData[dataGroup] = true end

psodata.activeDataReset = function() ActiveGameData = {} end

psodata.init = function()
	GameData = {menuState=0, level=0, thisLevelXp=0, toNextLevel=0, levelProgress=0, levelProgressFloat=0, meseta=0, sessionTime=0, elapsedTime=0, sessionXp=0, sessionXpRate=0, dungeonTime=0, dungeonXpRate=0, inventorySpaceUsed=0, bankSpaceUsed=0, floorItems={}, inventory={}, bank={}, party={}, monsterList={}, playerHP=0, playerHPmax=0, playerFrozen=false, playerConfused=false, playerParalyzed=false, playerDefTech=initTechData(), playerAtkTech=initTechData(), playerTP=0, playerTPmax=0, playerInvulnerabilityTime=0}
	GameData.player = {hp=0, hpMax=0, tp=0, tpMax=0, ata=0, statusFrozen=false, statusConfused=false, statusParalyzed=false, invulnerabilityTime=0, defTech=initTechData(), atkTech=initTechData()}
	-- GameData.inventory =
		-- {
		-- {["index"]=1, ["type"]="weapon", ["equipped"]=false, ["name"]="Sword", ["wrapped"]=false, ["killcount"]=0, ["untekked"]=false, ["isSrank"]=false, ["SrankName"]="", ["special"]="none", ["Native"]=0, ["A. Beast"]=0, ["Machine"]=10, ["Dark"]=0, ["Hit"]=5},
		-- {["index"]=2, ["type"]="frame", ["equipped"]=false, ["name"]="Frame", ["wrapped"]=false, ["slots"]=2, ["defense"]=1, ["defenseMax"]=5, ["evade"]=2, ["evadeMax"]=5},
		-- {["index"]=3, ["type"]="barrier", ["equipped"]=false, ["name"]="Barrier", ["wrapped"]=false, ["defense"]=4, ["defenseMax"]=4, ["evade"]=0, ["evadeMax"]=4},
		-- {["index"]=4, ["type"]="unit", ["equipped"]=false, ["name"]="Elf/Arm", ["wrapped"]=false, ["killcount"]=0, ["unitMod"]=0},
		-- {["index"]=5, ["type"]="mag", ["equipped"]=true, ["name"]="Diwari", ["wrapped"]=false, ["def"]=5, ["pow"]=150, ["dex"]=45, ["mind"]=0, ["sync"]=120, ["iq"]=200, ["color"]="blue", ["pb"]="", ["timer"]=0},
		-- {["index"]=6, ["type"]="tool", ["name"]="Resta", ["wrapped"]=false, ["techniqueLevel"]=5},
		-- {["index"]=7, ["type"]="tool", ["name"]="Difluid", ["wrapped"]=false, ["quantity"]=8},
		-- {["index"]=8, ["type"]="meseta", ["name"]="Meseta", ["wrapped"]=false, ["quantity"]=300}
		-- }
	-- GameData.party =
		-- {
			-- {["hp"]=500, ["hpMax"]=600, ["statusFrozen"]=false, ["statusConfused"]=false, ["statusParalyzed"]=false, ["defTech"]=nil, ["atkTech"]=nil, ["tp"]=300, ["tpMax"]=400, ["invulnerabilityTime"]=0, ["name"]="Wednesday"}
		-- }
	initSessionTime()
end

do -- define psodata getter functions

	local sf = {} -- string functions
	local lf = {} -- list functions
	local bf = {} -- boolean functions
	local pf = {} -- progress functions

	sf["Player Current HP"] = function() return GameData.playerHP end
	sf["Player Maximum HP"] = function() return GameData.playerHPmax end
	sf["Player Current TP"] = function() return GameData.playerTP end
	sf["Player Maximum TP"] = function() return GameData.playerTPmax end
	sf["Player Invulnerability Time Remaining"] = function() return GameData.playerInvulnerabilityTime end
	sf["Player Level"] = function() return GameData.level end
	sf["XP From Beginning to End of Current Player Level"] = function() return GameData.thisLevelXp end
	sf["Player XP Progress to Next Level"] = function() return GameData.levelProgress end
	sf["Player ATA"] = function() return GameData.ata end
	sf["Player Meseta Carried"] = function() return GameData.meseta end
	sf["Session Time Elapsed"] = function() return GameData.elapsedTime end
	sf["Session XP Accumulated"] = function() return GameData.sessionXp end
	sf["Session Time Elapsed in Dungeon"] = function() return GameData.dungeonTime end
	sf["Number of Inventory Slots Used"] = function() return GameData.inventorySpaceUsed end
	sf["Number of Inventory Slots Free"] = function() return 30 - GameData.inventorySpaceUsed end
	sf["Number of Bank Slots Used"] = function() return GameData.bankSpaceUsed end
	sf["Number of Bank Slots Free"] = function() return 200 - GameData.bankSpaceUsed end
	sf["Bank Meseta"] = function() return GameData.bankMeseta end
	-- sf["Player HP: Current/Maximum"] = function() return GameData.playerHP .. "/" .. GameData.playerHPmax end
	-- sf["Player TP: Current/Maximum"] = function() return GameData.playerTP .. "/" .. GameData.playerTPmax end
	-- sf["Player XP: Level Progress/Level Base Needed"] = function() return GameData.levelProgress .. "/" .. GameData.thisLevelXp end
	sf["Player XP: to Next Level"] = function() return GameData.thisLevelXp - GameData.levelProgress end
	sf["XP/Second This Session"] = function() return GameData.sessionXp / GameData.elapsedTime end
	sf["kXP/Hour This Session"] = function() return GameData.sessionXp / GameData.elapsedTime * 3.6 end
	sf["XP/Second in Dungeon"] = function() return GameData.sessionXp / GameData.dungeonTime end
	sf["kXP/Hour in Dungeon"] = function() return GameData.sessionXp / GameData.dungeonTime * 3.6 end
	-- sf["Inventory Space: Used/Total"] = function() return GameData.inventorySpaceUsed .. "/30" end
	-- sf["Bank Space: Used/Total"] = function() return GameData.bankSpaceUsed .. "/200" end

	lf["Inventory Items"] = function() return GameData.inventory end
	lf["Floor Items"] = function() return GameData.floorItems end
	lf["Bank Items"] = function() return GameData.bank end
	lf["Party Members"] = function() return GameData.party end
	lf["Monsters in Current Room"] = function() return GameData.monsterList end

	bf["Player Status: Frozen"] = function() return GameData.playerFrozen end
	bf["Player Status: Confused"] = function() return GameData.playerConfused end
	bf["Player Status: Paralyzed"] = function() return GameData.playerParalyzed end

	pf["Player HP"] = function() return GameData.playerHP / GameData.playerHPmax end
	pf["Player TP"] = function() return GameData.playerTP / GameData.playerTPmax end
	pf["Player Deband/Zalure Timer"] = function()
		local result = 0
		result = GameData.playerDefTech.timeLeft / GameData.playerDefTech.totalTime
	end
	pf["Player Shifta/Jellen Timer"] = function() return GameData.playerAtkTech.timeLeft / GameData.playerAtkTech.totalTime end
	pf["Player XP: Level Progress"] = function() return GameData.levelProgress / GameData.thisLevelXp end

	pf["Player S/D/J/Z Timer"] = function()
		defFloat = GameData.playerDefTech.timeLeft / GameData.playerDefTech.totalTime
		atkFloat = GameData.playerAtkTech.timeLeft / GameData.playerAtkTech.totalTime
		if (defFloat == 0) or (defFloat > atkFloat) then
			return atkFloat
		else
			return defFloat
		end
	end

	psodata.stringFunctions = sf
	psodata.listFunctions = lf
	psodata.booleanFunctions = bf
	psodata.progressFunctions = pf

	psodata.listFields = {}
	psodata.listSubFields = {}
	psodata.listSubFields['Inventory Items'] =
		{
		['weapon'] = {'index', 'type', 'equipped', 'name', 'grind', 'wrapped', 'killcount', 'untekked', 'isSrank', 'SrankName', 'special', 'Native', 'A. Beast', 'Machine', 'Dark', 'Hit'},
		['frame'] = {'index', 'type', 'equipped', 'name', 'wrapped', 'slots', 'defense', 'defenseMax', 'evade', 'evadeMax'},
		['barrier'] = {'index', 'type', 'equipped', 'name', 'wrapped', 'defense', 'defenseMax', 'evade', 'evadeMax'},
		['unit'] = {'index', 'type', 'equipped', 'name', 'wrapped', 'killcount', 'unitMod'},
		['mag'] = {'index', 'type', 'equipped', 'name', 'wrapped', 'def', 'pow', 'dex', 'mind', 'sync', 'iq', 'color', 'pb', 'timer'},
		['technique disk'] = {'index', 'type', 'name', 'wrapped', 'techniqueLevel'},
		['tool'] = {'index', 'type', 'name', 'wrapped', 'quantity'},
		['meseta'] = {'index', 'type', 'name', 'wrapped', 'quantity'}
		}
	psodata.listSubFields['Floor Items'] =
		{
		['weapon'] = {'index', 'type', 'name', 'grind', 'wrapped', 'killcount', 'untekked', 'isSrank', 'SrankName', 'special', 'Native', 'A. Beast', 'Machine', 'Dark', 'Hit'},
		['frame'] = {'index', 'type', 'name', 'wrapped', 'slots', 'defense', 'defenseMax', 'evade', 'evadeMax'},
		['barrier'] = {'index', 'type', 'name', 'wrapped', 'defense', 'defenseMax', 'evade', 'evadeMax'},
		['unit'] = {'index', 'type', 'name', 'wrapped', 'killcount', 'unitMod'},
		['mag'] = {'index', 'type', 'name', 'wrapped', 'def', 'pow', 'dex', 'mind', 'sync', 'iq', 'color', 'pb'},
		['technique disk'] = {'index', 'type', 'name', 'wrapped', 'techniqueLevel'},
		['tool'] = {'index', 'type', 'name', 'wrapped', 'quantity'},
		['meseta'] = {'index', 'type', 'name', 'wrapped', 'quantity'}
		}
	psodata.listSubFields['Bank Items'] = psodata.listSubFields['Floor Items']
		-- {
		-- ['weapon'] = {'index', 'type', 'name', 'wrapped', 'killcount', 'untekked', 'isSrank', 'SrankName', 'special', 'Native', 'A. Beast', 'Machine', 'Dark', 'Hit'},
		-- ['frame'] = {'index', 'type', 'name', 'wrapped', 'slots', 'defense', 'defenseMax', 'evade', 'evadeMax'},
		-- ['barrier'] = {'index', 'type', 'name', 'wrapped', 'defense', 'defenseMax', 'evade', 'evadeMax'},
		-- ['unit'] = {'index', 'type', 'name', 'wrapped', 'killcount', 'unitMod'},
		-- ['mag'] = {'index', 'type', 'name', 'wrapped', 'def', 'pow', 'dex', 'mind', 'sync', 'iq', 'color', 'pb'},
		-- ['technique disk'] = {'index', 'type', 'name', 'wrapped', 'techniqueLevel'},
		-- ['tool'] = {'index', 'type', 'name', 'wrapped', 'quantity'},
		-- ['meseta'] = {'index', 'type', 'name', 'wrapped', 'quantity'}
		-- }
	psodata.listFields['Party Members'] = {'hp', 'hpMax', 'statusFrozen', 'statusConfused', 'statusParalyzed', 'defTech', 'atkTech', 'tp', 'tpMax', 'invulnerabilityTime', 'name'}
	psodata.listFields['Monsters in Current Room'] = {'hp', 'hpMax', 'statusFrozen', 'statusConfused', 'statusParalyzed', 'defTech', 'atkTech', 'name'}

	for _, list in pairs(psodata.listSubFields) do
		for _, sublist in pairs(list) do
			for index, value in pairs(sublist) do
				sublist[value] = index
			end
		end
	end

	for _, list in pairs(psodata.listFields) do
		for index, value in pairs(list) do
			list[value] = index
		end
	end

	-- df.menuState = function() return GameData.menuState end
	-- sf["Player Status: Deband / Zalure"] = function() return GameData.playerDefTech end
	-- sf["Player Status: Shifta / Jellen"] = function() return GameData.playerAtkTech end

end

psodata.getGameData = function(fieldName) return df[fieldName]() end

return psodata