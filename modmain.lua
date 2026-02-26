--#region apis

GLOBAL.setmetatable(env, {
	__index = function(t, k)
		return GLOBAL.rawget(GLOBAL, k)
	end
})

local isServer = TheNet:GetIsServer()
local function GetTick() return TheSim:GetTick() end

local function xor(a, b)
	return (a and not b) or (not a and b)
end

-- should check AnimState first
local function toggleAnimState(inst, show)
	if inst.origin_mult == nil then
		inst.origin_mult = {inst.AnimState:GetMultColour()}
	end
	local mult = shallowcopy(inst.origin_mult)
	if not show then
		mult[4] = 0.2 * mult[4]
	end
	inst.AnimState:SetMultColour(unpack(mult))
end

local function oldToggleAnimState(inst, show)
	if show then
		inst.AnimState:SetScale(1, 1)
	else
		inst.AnimState:SetScale(0, 0)
	end
end

local function tiger_print(first, ...)
	print("**Tiger** " .. tostring(first), ...)
end
local function table_any(t)
	for _, _ in pairs(t) do
		return true
	end
	return false
end

local function getRangeEnts(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local insts = TheSim:FindEntities(x, y, z, 10)
    return insts
end
--#endregion

--#region 万物隐藏

local hideTable = {}
local hidePrefabs = {}

local function hideSingle(inst, show, isSpecial)
	inst = inst or TheInput:GetWorldEntityUnderMouse()
	if not inst then return end
	if not inst.AnimState then return end
	if isSpecial then
		if show then
			hideTable[inst] = nil
		else
			hideTable[inst] = true
		end
	end
	toggleAnimState(inst, show)
end

local function hideRange(inst)
	inst = inst or TheInput:GetWorldEntityUnderMouse()
	if not inst then return end
	if type(inst.prefab) ~= "string" then return end
	hidePrefabs[inst.prefab] = true
	local insts = getRangeEnts(inst)
	for _, v in pairs(insts) do
		if v.prefab and v.prefab == inst.prefab then
			hideSingle(v)
		end
	end
end

local function showAllHide()
	for k, _ in pairs(hideTable) do
		if k and k:IsValid() and k.AnimState then
			toggleAnimState(k, true)
		end
	end
	hideTable = {}
	hidePrefabs = {}
end

--#region 自检时显示全部
local inventorybar = require("widgets/inventorybar")
local oldrebuild = inventorybar.Rebuild
function inventorybar:Rebuild(...)
        local a = oldrebuild(self, ...)

        if self.inspectcontrol then
            local oldfn = self.inspectcontrol.onclick
            self.inspectcontrol.onclick = function(...)
				showAllHide()
                return oldfn(...)
			end
		end

        return a
end
--#endregion

--#endregion

--#region Hook TheSim
local function hookTheSim()
	tiger_print("Hook TheSim GetEntitiesAtScreenPoint start")
	local sim = TheSim
	local met = getmetatable(sim)
	if met == nil then tiger_print("metatable nil") return end
	local ind = met.__index
	if type(ind) ~= "table" then tiger_print("__index type is ", type(ind)) return end
	local old = sim.GetEntitiesAtScreenPoint
	function ind:GetEntitiesAtScreenPoint(...)
		local old_result = old(self, ...)
		if not (table_any(hideTable) or table_any(hidePrefabs)) then return old_result end
		local result = {}
		for _, v in ipairs(old_result) do
			if (not hideTable[v]) and (not hidePrefabs[v.prefab]) then
				table.insert(result, v)
			end
		end
		return result
	end
	tiger_print("Hook TheSim GetEntitiesAtScreenPoint to null finish")
end
hookTheSim()
--#endregion

--#region Player Periodic Task
local function playerPeriodicTask()
	local x, y, z = ThePlayer.Transform:GetWorldPosition()
	local insts = TheSim:FindEntities(x, y, z, 20)
	for _, inst in pairs(insts) do
		if inst and inst:IsValid() and inst.AnimState then
			if hidePrefabs[inst.prefab] then
				toggleAnimState(inst, false)
			elseif not hideTable[inst] then
				toggleAnimState(inst, true)
			end
		end
	end
end

local function doPlayerPeriodicTaskSafe()
	local player = ThePlayer
	if not player then return end
	if player.rightHideTask then return end
	player.rightHideTask = player:DoPeriodicTask(1, playerPeriodicTask)
end
--#endregion

--#region inputs

--#region main inputs
TheInput:AddKeyDownHandler(KEY_H, function()
	doPlayerPeriodicTaskSafe()
	if TheInput:IsKeyDown(KEY_LALT) then
		showAllHide()
		return
	end
	if not TheInput:IsKeyDown(KEY_LCTRL) then return end
	if TheInput:IsKeyDown(KEY_LSHIFT) then
		hideSingle(nil, false, true)
	else
		hideRange()
	end
end)
--#endregion

--#region 安全词
TheInput:AddKeyDownHandler(KEY_W, function()
    if TheInput:IsKeyDown(KEY_S) and TheInput:IsKeyDown(KEY_H) and TheInput:IsKeyDown(KEY_O) then
        showAllHide()
    end
end)
--#endregion

--#region test
--[=[
TheInput:AddKeyDownHandler(KEY_N, function()
	if not TheInput:IsKeyDown(KEY_LCTRL) then return end
	local entities = TheSim:GetEntitiesAtScreenPoint(TheSim:GetPosition())
	if TheInput:IsKeyDown(KEY_LSHIFT) then
		local first = entities[1]
		if first == nil then
			c_announce("first is nil")
			return
		end
		c_announce("hide[first] is " .. tostring(hidetable[first]))
	else
		c_announce("hide count is " .. tostring(hidetable.size))
	end
end)
--]=]
--#endregion

--#endregion
