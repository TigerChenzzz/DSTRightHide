GLOBAL.setmetatable(env, {
	__index = function(t, k)
		return GLOBAL.rawget(GLOBAL, k)
	end
})
--万物隐藏
local hidetable = {}
local function getRangeEnts(ent)
    local x, y, z = ent.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 10)
    return ents
end
TheInput:AddMouseButtonHandler(function(button, down, x, y)
	if not down then return false end
	if button == MOUSEBUTTON_RIGHT and TheInput:IsKeyDown(KEY_LCTRL) and TheInput:IsKeyDown(KEY_LALT)
	then
		local ent = TheInput:GetWorldEntityUnderMouse()
		local hud = TheInput:GetHUDEntityUnderMouse()
		local ishudundermouse = not ent and hud
		if ishudundermouse and hud and hud.Hide then
			hidetable[hud] = true
			hud:Hide()
		elseif ent and ent.AnimState then
			hidetable[ent] = true
			ent.AnimState:SetScale(0, 0)
		elseif ent and ent.Hide then
			hidetable[ent] = true
			ent:Hide()
		end
    elseif button == MOUSEBUTTON_LEFT
        and TheInput:IsKeyDown(KEY_H) then
        local ent = TheInput:GetWorldEntityUnderMouse()
        local hud = TheInput:GetHUDEntityUnderMouse()
        local ishudundermouse = not ent and hud
        if ishudundermouse and hud and hud.Hide then
            hidetable[hud] = true
            hud:Hide()
        elseif ent then
            local ents = getRangeEnts(ent)
            for k, v in pairs(ents) do
                if v.prefab and v.prefab == ent.prefab then
                    if v and v.AnimState then
                        hidetable[v] = true
                        v.AnimState:SetScale(0, 0)
                    elseif v and v.Hide then
                        hidetable[v] = true
                        v:Hide()
                    end
                end
            end
        end
	end
end)
local function showallhide()
	for k, v in pairs(hidetable) do
		if k and k:IsValid() and k.AnimState then
			k.AnimState:SetScale(1, 1)
			if k.Show then
				k:Show()
			end
		elseif k and k:IsValid() and k.Show then
			k:Show()
		end
	end
	hidetable = {}
end
if M_INSERT_BUTTON then
    M_INSERT_BUTTON("万物隐藏", {
        onclick = function(target)
            local ent = TheInput:GetWorldEntityUnderMouse()
            local hud = TheInput:GetHUDEntityUnderMouse()
            local ishudundermouse = not ent and hud
            if ishudundermouse and hud and hud.Hide then
                hidetable[hud] = true
                hud:Hide()
            elseif ent and ent.AnimState then
                hidetable[ent] = true
                ent.AnimState:SetScale(0, 0)
            elseif ent and ent.Hide then
                hidetable[ent] = true
                ent:Hide()
            end
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

--隐藏影怪
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
					inst.AnimState:SetScale(0, 0)
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
			k.AnimState:SetScale(1, 1)
		elseif k and k:IsValid() and k.AnimState then
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
							v.AnimState:SetScale(0, 0)
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
--安全词
TheInput:AddKeyDownHandler(KEY_W, function()
    if TheInput:IsKeyDown(KEY_S) and TheInput:IsKeyDown(KEY_H) and TheInput:IsKeyDown(KEY_O) then
        showallhide()
    end
end)
