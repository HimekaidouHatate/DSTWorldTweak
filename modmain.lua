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

AddPrefabPostInit("backpack", UpdateBackpack)