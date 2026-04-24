-- =====================================================
--   SAVANNAH LIFE HUB | By TochZero
--   Vida de Savana - NOYO Productions
--   Delta Executor Compatible | 2026
-- =====================================================

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local HttpService    = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LP             = Players.LocalPlayer
local Mouse          = LP:GetMouse()

-- Remove hub anterior se existir
local old = game:GetService("CoreGui"):FindFirstChild("SavannahHub")
if old then old:Destroy() end

-- =====================================================
-- NOTIFICACAO
-- =====================================================
local function notify(title, msg, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title = title, Text = msg, Duration = dur or 4
        })
    end)
end

-- =====================================================
-- ESTADO DOS TOGGLES
-- =====================================================
local T = {
    WalkSpeed    = false,
    InfStamina   = false,
    GodMode      = false,
    NoClip       = false,
    InfJump      = false,
    KillAura     = false,
    AutoFarm     = false,
    AutoEat      = false,
    AutoDrink    = false,
    ESPAnimals   = false,
    ESPFood      = false,
    AutoRespawn  = false,
    SilentAim    = false,
    AntiAFK      = false,
}

local CFG = {
    Speed       = 50,
    KillAuraRange = 20,
    AutoFarmRange = 60,
    ESPColor    = Color3.fromRGB(255, 80, 0),
}

-- =====================================================
-- CONEXOES (para poder desligar limpo)
-- =====================================================
local Connections = {}
local function clearConn(key)
    if Connections[key] then
        pcall(function() Connections[key]:Disconnect() end)
        Connections[key] = nil
    end
end

-- =====================================================
-- HELPERS DO JOGO
-- =====================================================
local function getChar()  return LP.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- Encontra atributo ou valor no char (stamina, hunger, thirst)
local function findStat(names)
    local c = getChar()
    if not c then return nil end
    for _, name in ipairs(names) do
        local v = c:FindFirstChild(name, true)
        if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then
            return v
        end
        -- tenta via atributo
        local ok, val = pcall(function() return c:GetAttribute(name) end)
        if ok and val then return {Value = val, IsAttr = true, AttrName = name} end
    end
    return nil
end

-- Encontra todos NPCs/animais no workspace
local function getAnimals()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Health > 0 then
            local root = obj.Parent:FindFirstChild("HumanoidRootPart")
            if root and obj.Parent ~= LP.Character then
                table.insert(list, {hum = obj, root = root, model = obj.Parent})
            end
        end
    end
    return list
end

-- Encontra comida/agua no workspace
local function getFoodItems()
    local list = {}
    local keywords = {"food","meat","berry","grass","water","drink","carcass","corpse","prey","flesh","herb","plant"}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw) then
                    table.insert(list, obj)
                    break
                end
            end
        end
    end
    return list
end

-- =====================================================
-- FUNCOES PRINCIPAIS
-- =====================================================

-- WALKSPEED
local function applySpeed(on)
    clearConn("speed")
    if on then
        Connections["speed"] = RunService.Heartbeat:Connect(function()
            local h = getHum()
            if h then h.WalkSpeed = CFG.Speed end
        end)
        notify("Speed","Velocidade "..CFG.Speed.." ativada!")
    else
        local h = getHum()
        if h then h.WalkSpeed = 16 end
        notify("Speed","Velocidade normal.")
    end
end

-- STAMINA INFINITA (zera o consumo travando o valor no maximo)
local function applyInfStamina(on)
    clearConn("stamina")
    if on then
        Connections["stamina"] = RunService.Heartbeat:Connect(function()
            local c = getChar()
            if not c then return end
            -- tenta por varias nomenclaturas usadas em jogos de animal
            for _, name in ipairs({"Stamina","Energy","Endurance","Sprint"}) do
                local v = c:FindFirstChild(name, true)
                if v and v:IsA("NumberValue") then
                    v.Value = v.Value < (v:FindFirstChild("Max") and v:FindFirstChild("Max").Value or 100)
                        and (v:FindFirstChild("Max") and v:FindFirstChild("Max").Value or 100) or v.Value
                end
            end
            -- via atributo
            for _, name in ipairs({"Stamina","Energy","Sprint","Endurance"}) do
                pcall(function()
                    local cur = c:GetAttribute(name)
                    if cur and type(cur) == "number" and cur < 100 then
                        c:SetAttribute(name, 100)
                    end
                end)
            end
        end)
        notify("Stamina","Stamina infinita ativada!")
    else
        notify("Stamina","Stamina normal.")
    end
end

-- GOD MODE
local function applyGodMode(on)
    clearConn("god")
    if on then
        Connections["god"] = RunService.Heartbeat:Connect(function()
            local h = getHum()
            if h then
                h.Health = h.MaxHealth
                -- trava fome e sede via atributos
                local c = getChar()
                if c then
                    for _, name in ipairs({"Hunger","Thirst","Food","Water","Starving"}) do
                        pcall(function()
                            local v = c:FindFirstChild(name, true)
                            if v and v:IsA("NumberValue") then
                                local mx = v:FindFirstChild("Max")
                                v.Value = mx and mx.Value or 100
                            end
                            local cur = c:GetAttribute(name)
                            if cur and type(cur) == "number" then
                                c:SetAttribute(name, 100)
                            end
                        end)
                    end
                end
            end
        end)
        notify("God Mode","HP + Fome + Sede no MAX!")
    else
        notify("God Mode","Desativado.")
    end
end

-- NO CLIP
local function applyNoClip(on)
    clearConn("noclip")
    if on then
        Connections["noclip"] = RunService.Stepped:Connect(function()
            local c = getChar()
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end)
        notify("NoClip","Ativado!")
    else
        notify("NoClip","Desativado.")
    end
end

-- INFINITE JUMP
local infJumpConn
local function applyInfJump(on)
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    if on then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local h = getHum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        notify("Inf Jump","Pulo infinito ativado!")
    else
        notify("Inf Jump","Desativado.")
    end
end

-- KILL AURA (ataca tudo no raio via tool ou dano direto)
local function applyKillAura(on)
    clearConn("killaura")
    if not on then notify("Kill Aura","Desativado.") return end
    Connections["killaura"] = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        if not hrp then return end
        local animals = getAnimals()
        for _, a in ipairs(animals) do
            local dist = (hrp.Position - a.root.Position).Magnitude
            if dist <= CFG.KillAuraRange then
                -- Tenta via tool equipada
                local c = getChar()
                if c then
                    local tool = c:FindFirstChildOfClass("Tool")
                    if tool then
                        local handle = tool:FindFirstChild("Handle")
                        if handle then
                            local touch = handle.Touched
                            pcall(function() touch:Fire(a.root) end)
                        end
                        -- tenta remote de ataque
                        local remote = tool:FindFirstChild("Attack") or tool:FindFirstChild("Bite")
                            or tool:FindFirstChild("Hit") or tool:FindFirstChildOfClass("RemoteEvent")
                        if remote and remote:IsA("RemoteEvent") then
                            pcall(function() remote:FireServer(a.root) end)
                        end
                    end
                end
                -- Tenta via RemoteEvent global de ataque
                for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                    if v:IsA("RemoteEvent") then
                        local n = v.Name:lower()
                        if n:find("attack") or n:find("bite") or n:find("damage") or n:find("hit") or n:find("kill") then
                            pcall(function() v:FireServer(a.model, a.root.Position) end)
                        end
                    end
                end
                -- Fallback: empurra o alvo (simula ataque fisico)
                pcall(function()
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = (a.root.Position - hrp.Position).Unit * 80
                    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
                    bv.Parent = a.root
                    game:GetService("Debris"):AddItem(bv, 0.15)
                end)
            end
        end
    end)
    notify("Kill Aura","Raio: "..CFG.KillAuraRange.." studs!")
end

-- AUTO FARM (vai ate animal mais proximo e ataca)
local function applyAutoFarm(on)
    clearConn("autofarm")
    if not on then notify("Auto Farm","Desativado.") return end
    Connections["autofarm"] = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        if not hrp then return end
        local animals = getAnimals()
        local nearest, nearDist = nil, math.huge
        for _, a in ipairs(animals) do
            local d = (hrp.Position - a.root.Position).Magnitude
            if d < nearDist and d <= CFG.AutoFarmRange then
                nearest = a
                nearDist = d
            end
        end
        if nearest then
            -- Move ate o alvo
            hrp.CFrame = CFrame.new(nearest.root.Position + Vector3.new(0,3,3))
            -- Ataca via remotes
            for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if v:IsA("RemoteEvent") then
                    local n = v.Name:lower()
                    if n:find("attack") or n:find("bite") or n:find("damage") or n:find("hit") then
                        pcall(function() v:FireServer(nearest.model, nearest.root.Position) end)
                    end
                end
            end
        end
    end)
    notify("Auto Farm","Farmando animais no raio "..CFG.AutoFarmRange.."!")
end

-- AUTO COMER
local function applyAutoEat(on)
    clearConn("autoeat")
    if not on then notify("Auto Eat","Desativado.") return end
    Connections["autoeat"] = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        if not hrp then return end
        local items = getFoodItems()
        for _, item in ipairs(items) do
            local part = item:IsA("BasePart") and item or item:FindFirstChildOfClass("BasePart")
            if part then
                local d = (hrp.Position - part.Position).Magnitude
                if d < 30 then
                    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0,3,0))
                    -- Tenta remote de comer
                    for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                        if v:IsA("RemoteEvent") then
                            local n = v.Name:lower()
                            if n:find("eat") or n:find("consume") or n:find("food") or n:find("feed") then
                                pcall(function() v:FireServer(item) end)
                            end
                        end
                    end
                    -- Toca no item (ativa TouchEnded/Touched)
                    pcall(function() part.Touched:Fire(hrp) end)
                    break
                end
            end
        end
    end)
    notify("Auto Eat","Comendo automaticamente!")
end

-- AUTO BEBER
local function applyAutoDrink(on)
    clearConn("autodrink")
    if not on then notify("Auto Drink","Desativado.") return end
    Connections["autodrink"] = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        if not hrp then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("water") or n:find("drink") or n:find("lake") or n:find("river") or n:find("pond")) then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                if part then
                    local d = (hrp.Position - part.Position).Magnitude
                    if d < 50 then
                        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0,3,0))
                        for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                            if v:IsA("RemoteEvent") then
                                local vn = v.Name:lower()
                                if vn:find("drink") or vn:find("water") or vn:find("thirst") then
                                    pcall(function() v:FireServer(obj) end)
                                end
                            end
                        end
                        pcall(function() part.Touched:Fire(hrp) end)
                        break
                    end
                end
            end
        end
    end)
    notify("Auto Drink","Bebendo automaticamente!")
end

-- ESP ANIMAIS
local espAnimalConn
local espLabels = {}
local function removeESPAnimals()
    for _, bb in ipairs(espLabels) do pcall(function() bb:Destroy() end) end
    espLabels = {}
    if espAnimalConn then espAnimalConn:Disconnect() espAnimalConn = nil end
end
local function applyESPAnimals(on)
    removeESPAnimals()
    if not on then notify("ESP","Animais ESP desativado.") return end
    espAnimalConn = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        for _, a in ipairs(getAnimals()) do
            if not a.root:FindFirstChild("_ESP_BB") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "_ESP_BB"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,120,0,28)
                bb.StudsOffset = Vector3.new(0,3.5,0)
                bb.Parent = a.root
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 13
                lbl.TextStrokeTransparency = 0
                lbl.TextColor3 = CFG.ESPColor
                lbl.Parent = bb
                table.insert(espLabels, bb)
                -- atualiza nome e distancia
                RunService.Heartbeat:Connect(function()
                    if not bb.Parent then return end
                    local dist = hrp and math.floor((hrp.Position - a.root.Position).Magnitude) or 0
                    lbl.Text = a.model.Name.." ["..dist.."m]"
                    lbl.TextColor3 = a.hum.Health < a.hum.MaxHealth * 0.3
                        and Color3.fromRGB(255,50,50) or CFG.ESPColor
                end)
            end
        end
    end)
    notify("ESP","Animais destacados!")
end

-- ESP COMIDA
local espFoodConn
local espFoodLabels = {}
local function removeESPFood()
    for _, bb in ipairs(espFoodLabels) do pcall(function() bb:Destroy() end) end
    espFoodLabels = {}
    if espFoodConn then espFoodConn:Disconnect() espFoodConn = nil end
end
local function applyESPFood(on)
    removeESPFood()
    if not on then notify("ESP Food","Desativado.") return end
    espFoodConn = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        local items = getFoodItems()
        for _, item in ipairs(items) do
            local part = item:IsA("BasePart") and item or item:FindFirstChildOfClass("BasePart")
            if part and not part:FindFirstChild("_FESP") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "_FESP"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,90,0,22)
                bb.StudsOffset = Vector3.new(0,2,0)
                bb.Parent = part
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 11
                lbl.TextStrokeTransparency = 0
                lbl.TextColor3 = Color3.fromRGB(80,255,80)
                lbl.Text = "🍖 "..item.Name
                lbl.Parent = bb
                table.insert(espFoodLabels, bb)
            end
        end
    end)
    notify("ESP Food","Comida destacada!")
end

-- AUTO RESPAWN
local function applyAutoRespawn(on)
    clearConn("respawn")
    if not on then notify("Auto Respawn","Desativado.") return end
    Connections["respawn"] = RunService.Heartbeat:Connect(function()
        local h = getHum()
        if h and h.Health <= 0 then
            task.wait(0.5)
            LP:LoadCharacter()
        end
    end)
    notify("Auto Respawn","Ativado! Respawn automatico ao morrer.")
end

-- ANTI AFK
local function applyAntiAFK(on)
    clearConn("afk")
    if not on then notify("Anti AFK","Desativado.") return end
    local vd = Instance.new("VirtualUser")
    vd.Parent = game
    Connections["afk"] = RunService.Heartbeat:Connect(function()
        vd:CaptureController()
        vd:ClickButton2(Vector2.new())
    end)
    notify("Anti AFK","Ativado! Nao sera desconectado.")
end

-- SILENT AIM
local silentAimConn
local function applySilentAim(on)
    if silentAimConn then silentAimConn:Disconnect() silentAimConn = nil end
    if not on then notify("Silent Aim","Desativado.") return end
    silentAimConn = RunService.RenderStepped:Connect(function()
        local hrp = getHRP()
        if not hrp then return end
        local nearest, nearDist = nil, math.huge
        local animals = getAnimals()
        for _, a in ipairs(animals) do
            local d = (hrp.Position - a.root.Position).Magnitude
            if d < nearDist then nearest = a nearDist = d end
        end
        if nearest then
            Mouse.Target = nearest.root
            -- move camera para mirar
            local cam = workspace.CurrentCamera
            if cam then
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, nearest.root.Position)
            end
        end
    end)
    notify("Silent Aim","Ativado! Mira automatica em animais.")
end

-- TELEPORTES especificos
local function teleportToNearest(keywords, label)
    local hrp = getHRP()
    if not hrp then return end
    local nearest, nearDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        local match = false
        for _, kw in ipairs(keywords) do
            if n:find(kw) then match = true break end
        end
        if match and obj:IsA("BasePart") then
            local d = (hrp.Position - obj.Position).Magnitude
            if d < nearDist then nearest = obj nearDist = d end
        end
    end
    if nearest then
        hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0,5,0))
        notify("Teleporte", label.." encontrado! ("..math.floor(nearDist).."m)")
    else
        notify("Teleporte","Nenhum "..label.." encontrado no mapa.")
    end
end

-- =====================================================
-- GUI
-- =====================================================
local SG2 = Instance.new("ScreenGui")
SG2.Name = "SavannahHub"
SG2.ResetOnSpawn = false
SG2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG2.Parent = game:GetService("CoreGui")

-- Frame principal (370x480)
local MF = Instance.new("Frame")
MF.Size = UDim2.new(0,370,0,480)
MF.Position = UDim2.new(0,12,0.5,-240)
MF.BackgroundColor3 = Color3.fromRGB(10,10,18)
MF.BorderSizePixel = 0
MF.Parent = SG2
Instance.new("UICorner",MF).CornerRadius = UDim.new(0,10)
local st = Instance.new("UIStroke",MF)
st.Color = Color3.fromRGB(210,140,0)
st.Thickness = 2

-- Topbar
local TB = Instance.new("Frame")
TB.Size = UDim2.new(1,0,0,40)
TB.BackgroundColor3 = Color3.fromRGB(20,12,5)
TB.BorderSizePixel = 0
TB.Parent = MF
Instance.new("UICorner",TB).CornerRadius = UDim.new(0,10)

local TL = Instance.new("TextLabel")
TL.Size = UDim2.new(1,-80,1,0)
TL.Position = UDim2.new(0,10,0,0)
TL.BackgroundTransparency = 1
TL.Text = "🦁 Savannah Life Hub"
TL.TextColor3 = Color3.fromRGB(255,180,0)
TL.TextSize = 14
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left
TL.Parent = TB

local function topBtn(txt, col, xOff)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,28,0,26)
    b.Position = UDim2.new(1,xOff,0,7)
    b.BackgroundColor3 = col
    b.Text = txt
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = TB
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,5)
    return b
end

local CloseB = topBtn("X", Color3.fromRGB(180,30,30), -34)
CloseB.MouseButton1Click:Connect(function() MF.Visible = not MF.Visible end)

local minimized = false
local MinB = topBtn("_", Color3.fromRGB(50,50,70), -66)
MinB.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, c in ipairs(MF:GetChildren()) do
        if c ~= TB then c.Visible = not minimized end
    end
    MF.Size = minimized and UDim2.new(0,370,0,40) or UDim2.new(0,370,0,480)
end)

-- Tabs
local TabRow = Instance.new("Frame")
TabRow.Size = UDim2.new(1,0,0,30)
TabRow.Position = UDim2.new(0,0,0,42)
TabRow.BackgroundColor3 = Color3.fromRGB(15,15,25)
TabRow.BorderSizePixel = 0
TabRow.Parent = MF

local pages = {}
local pagebtns = {}
local tabList = {"Auto","Combat","Player","Misc"}

local CArea = Instance.new("Frame")
CArea.Size = UDim2.new(1,-8,1,-80)
CArea.Position = UDim2.new(0,4,0,78)
CArea.BackgroundTransparency = 1
CArea.Parent = MF

local function mkPage(name, idx)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,88,1,-4)
    btn.Position = UDim2.new(0,(idx-1)*90+2,0,2)
    btn.BackgroundColor3 = Color3.fromRGB(25,25,40)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(160,160,160)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamSemibold
    btn.BorderSizePixel = 0
    btn.Parent = TabRow
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.Visible = idx == 1
    page.Parent = CArea
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0,4)
    lay.Parent = page
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0,4)
    pad.PaddingLeft = UDim.new(0,2)
    pad.Parent = page

    pages[name] = page
    pagebtns[name] = btn

    btn.MouseButton1Click:Connect(function()
        for _,p in pairs(pages) do p.Visible = false end
        for _,b in pairs(pagebtns) do
            b.BackgroundColor3 = Color3.fromRGB(25,25,40)
            b.TextColor3 = Color3.fromRGB(160,160,160)
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(200,130,0)
        btn.TextColor3 = Color3.new(1,1,1)
    end)
    if idx == 1 then
        btn.BackgroundColor3 = Color3.fromRGB(200,130,0)
        btn.TextColor3 = Color3.new(1,1,1)
    end
end
for i,n in ipairs(tabList) do mkPage(n,i) end

-- Helpers GUI
local function mkLabel(p, txt)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-4,0,20)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.fromRGB(255,180,0)
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = p
end
local function mkSep(p)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1,-4,0,1)
    s.BackgroundColor3 = Color3.fromRGB(200,130,0)
    s.BackgroundTransparency = 0.6
    s.BorderSizePixel = 0
    s.Parent = p
end
local function mkBtn(p, txt, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-4,0,32)
    b.BackgroundColor3 = Color3.fromRGB(28,28,45)
    b.Text = txt
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 11
    b.Font = Enum.Font.GothamSemibold
    b.BorderSizePixel = 0
    b.Parent = p
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    local sk = Instance.new("UIStroke",b)
    sk.Color = Color3.fromRGB(200,130,0)
    sk.Thickness = 1
    sk.Transparency = 0.55
    b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(50,38,10) end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(28,28,45) end)
    return b
end
local function mkToggle(p, txt, key, fn)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-4,0,34)
    row.BackgroundColor3 = Color3.fromRGB(18,18,30)
    row.BorderSizePixel = 0
    row.Parent = p
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-55,1,0)
    lbl.Position = UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = Color3.fromRGB(210,210,210)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0,42,0,20)
    track.Position = UDim2.new(1,-48,0.5,-10)
    track.BackgroundColor3 = Color3.fromRGB(60,60,60)
    track.Text = ""
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local function refresh()
        local on = T[key]
        TweenService:Create(knob, TweenInfo.new(0.12),{
            Position = on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
        }):Play()
        track.BackgroundColor3 = on and Color3.fromRGB(200,130,0) or Color3.fromRGB(60,60,60)
    end

    track.MouseButton1Click:Connect(function()
        T[key] = not T[key]
        refresh()
        if fn then fn(T[key]) end
    end)
end

-- =====================================================
-- ABA AUTO
-- =====================================================
local aP = pages["Auto"]
mkLabel(aP, "⚡ Automacoes de Sobrevivencia")
mkSep(aP)
mkToggle(aP, "🌿 Auto Comer (vai a comida)", "AutoEat", applyAutoEat)
mkToggle(aP, "💧 Auto Beber (vai a agua)", "AutoDrink", applyAutoDrink)
mkToggle(aP, "🌾 Auto Farm (vai a animais)", "AutoFarm", applyAutoFarm)
mkToggle(aP, "🔁 Auto Respawn ao morrer", "AutoRespawn", applyAutoRespawn)
mkToggle(aP, "🛋️ Anti AFK", "AntiAFK", applyAntiAFK)
mkSep(aP)
mkLabel(aP, "📏 Raio de Auto Farm")
mkBtn(aP, "Raio: 40 studs", function() CFG.AutoFarmRange=40 notify("Farm Range","40") end)
mkBtn(aP, "Raio: 60 studs", function() CFG.AutoFarmRange=60 notify("Farm Range","60") end)
mkBtn(aP, "Raio: 100 studs", function() CFG.AutoFarmRange=100 notify("Farm Range","100") end)

-- =====================================================
-- ABA COMBAT
-- =====================================================
local cP = pages["Combat"]
mkLabel(cP, "⚔️ Combate")
mkSep(cP)
mkToggle(cP, "💥 Kill Aura (ataca no raio)", "KillAura", applyKillAura)
mkToggle(cP, "🎯 Silent Aim (mira automatica)", "SilentAim", applySilentAim)
mkSep(cP)
mkLabel(cP, "📏 Raio do Kill Aura")
mkBtn(cP, "Raio: 10 studs", function() CFG.KillAuraRange=10 notify("Kill Aura","Raio: 10") end)
mkBtn(cP, "Raio: 20 studs", function() CFG.KillAuraRange=20 notify("Kill Aura","Raio: 20") end)
mkBtn(cP, "Raio: 35 studs", function() CFG.KillAuraRange=35 notify("Kill Aura","Raio: 35") end)
mkBtn(cP, "Raio: 50 studs", function() CFG.KillAuraRange=50 notify("Kill Aura","Raio: 50") end)
mkSep(cP)
mkLabel(cP, "🔍 ESP")
mkToggle(cP, "👁️ ESP Animais (nome + distancia)", "ESPAnimals", applyESPAnimals)
mkToggle(cP, "🍖 ESP Comida/Agua", "ESPFood", applyESPFood)

-- =====================================================
-- ABA PLAYER
-- =====================================================
local pP = pages["Player"]
mkLabel(pP, "🧍 Hacks do Animal")
mkSep(pP)
mkToggle(pP, "🛡️ God Mode (HP+Fome+Sede max)", "GodMode", applyGodMode)
mkToggle(pP, "⚡ Stamina Infinita", "InfStamina", applyInfStamina)
mkToggle(pP, "💨 WalkSpeed Hack", "WalkSpeed", applySpeed)
mkToggle(pP, "🚀 Pulo Infinito", "InfJump", applyInfJump)
mkToggle(pP, "👻 No Clip", "NoClip", applyNoClip)
mkSep(pP)
mkLabel(pP, "🚀 Velocidade")
mkBtn(pP, "16 — Normal", function() CFG.Speed=16 if T.WalkSpeed then applySpeed(true) end end)
mkBtn(pP, "32 — Rapido", function() CFG.Speed=32 if T.WalkSpeed then applySpeed(true) end end)
mkBtn(pP, "60 — Muito Rapido", function() CFG.Speed=60 if T.WalkSpeed then applySpeed(true) end end)
mkBtn(pP, "100 — Maximo", function() CFG.Speed=100 if T.WalkSpeed then applySpeed(true) end end)
mkSep(pP)
mkLabel(pP, "📍 Teleportes")
mkBtn(pP, "💧 Ir para Agua/Rio mais proximo", function()
    teleportToNearest({"water","lake","river","pond","oasis"},"Agua")
end)
mkBtn(pP, "🍖 Ir para Comida mais proxima", function()
    teleportToNearest({"food","meat","berry","carcass","prey","corpse","grass","herb"},"Comida")
end)
mkBtn(pP, "🦁 Ir para Animal mais proximo", function()
    local hrp = getHRP()
    if not hrp then return end
    local animals = getAnimals()
    local nearest, nearDist = nil, math.huge
    for _, a in ipairs(animals) do
        local d = (hrp.Position - a.root.Position).Magnitude
        if d < nearDist then nearest=a nearDist=d end
    end
    if nearest then
        hrp.CFrame = CFrame.new(nearest.root.Position + Vector3.new(0,5,3))
        notify("Teleporte","Animal encontrado: "..nearest.model.Name.." ("..math.floor(nearDist).."m)")
    else
        notify("Teleporte","Nenhum animal encontrado.")
    end
end)
mkBtn(pP, "🏠 Ir para Spawn (0,5,0)", function()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(0,5,0)
        notify("Teleporte","Spawn!")
    end
end)

-- =====================================================
-- ABA MISC
-- =====================================================
local mP = pages["Misc"]
mkLabel(mP, "🛠️ Ferramentas")
mkSep(mP)
mkBtn(mP, "📊 Ver Ping", function()
    notify("Ping", math.floor(LP:GetNetworkPing()*1000).."ms")
end)
mkBtn(mP, "💻 Copiar UserID", function()
    pcall(function() setclipboard(tostring(LP.UserId)) end)
    notify("UserID","Copiado: "..LP.UserId)
end)
mkBtn(mP, "🔍 Listar Remotes (F9)", function()
    local list = {}
    for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(list, v.Name)
        end
    end
    table.sort(list)
    print("=== REMOTES ("..#list..") ===")
    for _,n in ipairs(list) do print(" > "..n) end
    notify("Remotes","F9 para ver os "..#list.." remotes!")
end)
mkBtn(mP, "📋 Info do Personagem", function()
    local c = getChar()
    if not c then notify("Info","Sem personagem.") return end
    local h = getHum()
    print("=== CHAR INFO ===")
    print("Nome:", c.Name)
    if h then print("HP:", h.Health, "/", h.MaxHealth) print("Speed:", h.WalkSpeed) end
    for _, v in ipairs(c:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            print(v:GetFullName(), "=", v.Value)
        end
    end
    notify("Info","Personagem impresso no F9!")
end)
mkBtn(mP, "🔄 Rejoin", function()
    TeleportService:Teleport(game.PlaceId, LP)
end)
mkBtn(mP, "🌐 Server Hop", function()
    local ok, result = pcall(function()
        return HttpService:JSONDecode(
            HttpService:GetAsync("https://games.roproxy.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
        )
    end)
    if ok and result and result.data then
        for _, s in ipairs(result.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers - 1 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                return
            end
        end
    end
    notify("Server Hop","Nenhum servidor vazio.")
end)
mkSep(mP)
mkBtn(mP, "♻️ Resetar Tudo", function()
    applyGodMode(false)     T.GodMode=false
    applyInfStamina(false)  T.InfStamina=false
    applySpeed(false)       T.WalkSpeed=false
    applyNoClip(false)      T.NoClip=false
    applyInfJump(false)     T.InfJump=false
    applyKillAura(false)    T.KillAura=false
    applyAutoFarm(false)    T.AutoFarm=false
    applyAutoEat(false)     T.AutoEat=false
    applyAutoDrink(false)   T.AutoDrink=false
    applyESPAnimals(false)  T.ESPAnimals=false
    applyESPFood(false)     T.ESPFood=false
    applyAutoRespawn(false) T.AutoRespawn=false
    applyAntiAFK(false)     T.AntiAFK=false
    applySilentAim(false)   T.SilentAim=false
    notify("Reset","Todos os hacks desativados.")
end)
mkBtn(mP, "❌ Fechar Hub", function() SG2:Destroy() end)

-- =====================================================
-- DRAG
-- =====================================================
local drag, dStart, dPos2 = false
TB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true dStart = i.Position dPos2 = MF.Position
    end
end)
TB.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dStart
        MF.Position = UDim2.new(dPos2.X.Scale, dPos2.X.Offset+d.X, dPos2.Y.Scale, dPos2.Y.Offset+d.Y)
    end
end)

-- INSERT abre/fecha
UserInputService.InputBegan:Connect(function(i, gpe)
    if not gpe and i.KeyCode == Enum.KeyCode.Insert then
        MF.Visible = not MF.Visible
    end
end)

-- =====================================================
-- INICIO
-- =====================================================
task.wait(0.5)
notify("🦁 Savannah Life Hub","Loaded! INSERT = abrir/fechar")
print("[SavannahHub] Pronto | TochZero")
