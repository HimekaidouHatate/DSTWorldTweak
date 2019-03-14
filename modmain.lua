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

AddPrefabPostInit("forest", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end

	if SandStorm == 1 then
		-- Since it's not able to get values' reference, I had no option except for replacing every case where _sandstormactive is used to a new class variable's.
		local sandstorms = inst.components.sandstorms
		sandstorms._active = false -- This is now act like _sandstormactive.

		local _sandstormactive = sandstorms._active

		function sandstorms:IsInSandstorm(ent)
			return _sandstormactive
				and ent.components.areaaware ~= nil
				and ent.components.areaaware:CurrentlyInTag("sandstorm")
		end

		function sandstorms:GetSandstormLevel(ent)
			if _sandstormactive and
				ent.components.areaaware ~= nil and
				ent.components.areaaware:CurrentlyInTag("sandstorm") then
				local oasislevel = sandstorms:CalcOasisLevel(ent)
				return oasislevel < 1
					and math.clamp(sandstorms:CalcSandstormLevel(ent) - oasislevel, 0, 1)
					or 0
			end
			--TODO: entities without areaaware need to know if they're inside the sandstorm
			return 0
		end

		function sandstorms:IsSandstormActive()
			return _sandstormactive
		end


		local ToggleSandStorm, ShouldActivateSandstorm
		for k, v in pairs(inst.event_listening.seasontick[inst]) do
			local reference = UpvalueHacker.GetUpvalue(v, "ToggleSandstorm")

			if reference ~= nil then 
				ShouldActivateSandstorm = UpvalueHacker.GetUpvalue(reference, "ShouldActivateSandstorm")
				ToggleSandStorm = reference
				break
			end
		end

		if ToggleSandStorm ~= nil then
			ToggleSandStorm = function()
				print("ToggleSandStorm()")
				if _sandstormactive ~= (SandStorm ~= 0 and ShouldActivateSandstorm() and (SandStorm == 2 and not inst.components.worldstate.data.iswinter) or SandStorm == 3) then
					_sandstormactive = not _sandstormactive
					inst:PushEvent("ms_sandstormchanged", _sandstormactive)
				end
			end
		end
	end
end)