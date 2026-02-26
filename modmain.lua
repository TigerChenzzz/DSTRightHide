GLOBAL.setmetatable(env, {
	__index = function(t, k)
		return GLOBAL.rawget(GLOBAL, k)
	end
})

--#region apis
local isServer = TheNet:GetIsServer()
local function GetTick() return TheSim:GetTick() end

local function toggleAnimState(inst, show, isShadow)
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
--#endregion

--#region 万物隐藏

local hidetable = {}
local hide_prefab = {}
local function getRangeEnts(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local insts = TheSim:FindEntities(x, y, z, 10)
    return insts
end
local function hideSingle(inst, show)
	inst = inst or TheInput:GetWorldEntityUnderMouse()
	if inst and inst.AnimState then
		if show then
			hidetable[inst] = nil
		else
			hidetable[inst] = true
		end
		-- ent.AnimState:SetScale(0, 0)
		toggleAnimState(inst, show)
	end
end
local function hideRange(inst)
	inst = inst or TheInput:GetWorldEntityUnderMouse()
	if not inst then return end
	if type(inst.prefab) ~= "string" then return end
	hide_prefab[inst] = true
	local ents = getRangeEnts(inst)
	for k, v in pairs(ents) do
		if v.prefab and v.prefab == inst.prefab then
			if v and v.AnimState then
				hidetable[v] = true
				-- v.AnimState:SetScale(0, 0)
				toggleAnimState(v, false)
			end
		end
	end
end
--[=[
TheInput:AddMouseButtonHandler(function(button, down, x, y)
	if not down then return false end
	if button == MOUSEBUTTON_RIGHT and TheInput:IsKeyDown(KEY_LCTRL) and TheInput:IsKeyDown(KEY_LALT)
	then
		hideSingle()
    elseif button == MOUSEBUTTON_LEFT
        and TheInput:IsKeyDown(KEY_H) then
			hideRange()
	end
end)
--]=]
local function showallhide()
	for k, v in pairs(hidetable) do
		if k and k:IsValid() and k.AnimState then
			-- k.AnimState:SetScale(1, 1)
			toggleAnimState(k, true)
			if k.Show then
				k:Show()
			end
		end
	end
	hidetable = {}
	hide_prefab = {}
end

if M_INSERT_BUTTON then
    M_INSERT_BUTTON("万物隐藏", {
        onclick = function(target)
			hideSingle()
		end,
        ignore_alt = true
    })
    M_INSERT_BUTTON("万物隐藏解除", {
        onselectfn = function(target)
            showallhide()
        end,
    })
end

local inventorybar = require("widgets/inventorybar")
local oldrebuild = inventorybar.Rebuild
function inventorybar:Rebuild(...)
        local a = oldrebuild(self, ...)

        if self.inspectcontrol then
            local oldfn = self.inspectcontrol.onclick
            self.inspectcontrol.onclick = function(...)
			showallhide()
                return oldfn(...)
		end
	end

        return a
end

--#endregion

--#region 隐藏影怪

local hide = false
local shadowcreature = {
	["crawlingnightmare"] = 'shadow',
	["crawlinghorror"] = 'shadow',
	["terrorbeak"] = 'shadow',
	["nightmarebeak"] = 'shadow',
}
local hidetable2 = {}
for k, v in pairs(shadowcreature) do
	AddPrefabPostInit(k, function(inst)
		if hide then
			inst:DoTaskInTime(0, function()
				if inst and inst.AnimState then
					hidetable2[inst] = true
					-- inst.AnimState:SetScale(0, 0)
					toggleAnimState(inst, false, true)
				elseif inst and inst.Hide then
					hidetable2[inst] = true
					inst:Hide()
				end
			end)
		end
	end)
end
local function showallhide2()
	for k, v in pairs(hidetable2) do
		if k and k:IsValid() and k.AnimState then
			-- k.AnimState:SetScale(1, 1)
			toggleAnimState(k, true, true)
		elseif k and k:IsValid() and k.Show then
			k:Show()
		end
	end
	hidetable2 = {}
end
AddClassPostConstruct("widgets/sanitybadge", function(self)
	local old1 = self.OnControl
	function self:OnControl(control, down)
		if control == CONTROL_ACCEPT and down then
			if ThePlayer:HasTag("shadowdominance") then
				hide = not hide
				if hide then
					for k, v in pairs(TheSim:FindEntities(ThePlayer:GetPosition().x, 0, ThePlayer:GetPosition().z, 40, { "shadowsubmissive" })) do
						if v and v.AnimState then
							hidetable2[v] = true
							-- v.AnimState:SetScale(0, 0)
							toggleAnimState(v, false, true)
						elseif v and v.Hide then
							hidetable2[v] = true
							v:Hide()
						end
					end
				else
					showallhide2()
				end
			else
				hide = false
				showallhide2()
			end
		end
		return old1(self, control, down)
	end
end)
AddPrefabPostInit("inventory_classified", function(inst) --需要改一下写法
	inst:ListenForEvent('equips[head]dirty', function()
		hide = false
		showallhide2()
	end)
end)

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
		if not (table_any(hidetable) or table_any(hide_prefab)) then return old_result end
		local result = {}
		for _, v in ipairs(old_result) do
			if (not hidetable[v]) and (not hide_prefab[v.prefab]) then
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
	local insts = TheSim:FindEntities(x, y, z, 10)
	for _, inst in pairs(insts) do
		if inst and inst:IsValid() and inst.AnimState and hide_prefab[inst.prefab] then
			hideSingle(inst)
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
	if TheInput:IsKeyDown(KEY_LALT) then
		showallhide()
		return
	end
	if not TheInput:IsKeyDown(KEY_LCTRL) then return end
	if TheInput:IsKeyDown(KEY_LSHIFT) then
		hideSingle()
	else
		hideRange()
	end
end)

--#endregion

--#region 安全词
TheInput:AddKeyDownHandler(KEY_W, function()
    if TheInput:IsKeyDown(KEY_S) and TheInput:IsKeyDown(KEY_H) and TheInput:IsKeyDown(KEY_O) then
        showallhide()
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
