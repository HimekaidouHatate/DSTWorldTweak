GLOBAL.UpvalueHacker = GLOBAL.require "tools/UpvalueHacker" -- debug

local function onsave(inst, data)
	data.isnobat = inst.isnobat
end

local function onload(inst, data)
	if data ~= nil then
		inst.isnobat = data.isnobat
	end
	
	if inst.isnobat then
		inst:PushEvent("makenobat")
	end
end

local function OnMakeNoBat(inst)
	print("Made no bat spawning cave entrance", inst)
	inst.isnobat = true
	inst:AddTag("nospawn")
end

local function canspawn(inst)
	return not inst:HasTag("nospawn") and inst.components.worldmigrator:IsActive() or inst.components.worldmigrator:IsFull()
end

local function CaveEntranceFn(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end
	
	if inst.components.childspawner ~= nil then
		inst.components.childspawner.canspawnfn = canspawn
	end
	
	inst:ListenForEvent("makenobat", OnMakeNoBat)

	inst.OnSave = onsave
	inst.OnLoad = onload
end
AddPrefabPostInit("cave_entrance_open", CaveEntranceFn)

local function CanTakeItemTweak(inst)
	local _old = inst.components.container.CanTakeItemInSlot
	inst.components.container.CanTakeItemInSlot = function(self, item, slot)
		return _old(self, item, slot) and self.canbeopened
	end
end

local function CheckStatus(inst)
	if inst.components.container:IsEmpty() then
		inst.components.inventoryitem.cangoincontainer = true
		inst.components.container.canbeopened = true
	elseif not inst.components.container:IsEmpty() then
		inst.components.inventoryitem.cangoincontainer = false
		inst.components.container.canbeopened = false
	end
end

local function OnEquipTweak(inst)
	local _onequip = inst.components.equippable.onequipfn
	inst.components.equippable.onequipfn = function(inst, owner)
		_onequip(inst, owner)
		inst.components.container.canbeopened = true
	end

	local _onunequip = inst.components.equippable.onunequipfn
	inst.components.equippable.onunequipfn = function(inst, owner)
		_onunequip(inst, owner)
		inst.components.container.canbeopened = false
	end
end

local function UpdateBackpack(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
	inst:AddComponent("inventoryitem")

	CanTakeItemTweak(inst)
	OnEquipTweak(inst)

	inst:ListenForEvent("itemget", CheckStatus)
	inst:ListenForEvent("itemlose", CheckStatus)
end

local dirtystr = ""
local function CleanStr(inst)
	if dirtystr == "" then return end

	inst.debugstring:set(dirtystr)
	dirtystr = ""
end

local function QueueStr(str)
	dirtystr = dirtystr.."\n"..str
end

local function DebugCustom(...)
	local str = ""
    local n = GLOBAL.select('#', ...)
    local args = GLOBAL.toarray(...)
    for i = 1, n do
        str = str..tostring(args[i]).."\t"
    end

	GLOBAL.AllPlayers[1].components.talker:Say(str)
	if not (GLOBAL.TheNet:GetIsClient() and (GLOBAL.TheNet:GetIsServerAdmin() or GLOBAL.IsConsole())) then
		QueueStr(str)
	end
end

local function PrintOnLocal(inst)
	if inst._parent.HUD == nil then return end
	local str = inst.debugstring:value()
	print(str)
end

local function RegisterModNetListeners(inst)
	if GLOBAL.TheWorld and GLOBAL.TheWorld.ismastersim then
		inst._parent = inst.entity:GetParent()
	end

	--inst:ListenForEvent("debugstringdirty", PrintOnLocal)
	--inst:DoPeriodicTask(0, CleanStr)
	--GLOBAL.AddPrintLogger(DebugCustom)
end

AddPrefabPostInit("player_classified", function(inst)
	inst.debugstring = GLOBAL.net_string(inst.GUID, "debugstring", "debugstringdirty")

	inst:DoTaskInTime(2 * GLOBAL.FRAMES, RegisterModNetListeners) 
	-- delay two more FRAMES to ensure the original NetListeners to run first.
end)

AddPrefabPostInit("backpack", UpdateBackpack)

AddComponentPostInit("named", function(self)
    local function DoSetName(self) -- UpvalueHacker를 사용하지 않고 기존 함수 덮어씀
        self.inst.name = self.nameformat ~= nil and string.format(self.nameformat, self.name) or self.name
        self.inst.replica.named:SetName(self.inst.name)
    end
    
    self.SetName = function(self, name)
        self.name = "Yukari"
        if name == nil then
            self.inst.name = GLOBAL.STRINGS.NAMES[string.upper(self.inst.prefab)]
            self.inst.replica.named:SetName("")
        else
            DoSetName(self)
        end
    end
end)
