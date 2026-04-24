-- =====================================================
--   ANIME CARD COLLECTION HUB v2 (FIXED)
--   By TochZero | Delta Executor Compatible
-- =====================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local SG = game:GetService("StarterGui")

local function notify(title, text)
    pcall(function()
        SG:SetCore("SendNotification", {Title = title, Text = text, Duration = 4})
    end)
end

-- =====================================================
-- ESTADOS
-- =====================================================
local toggled = {
    GodMode = false,
    SpeedHack = false,
    InfiniteJump = false,
    NoClip = false,
    AutoSpin = false,
    AutoCollect = false,
    AutoBattle = false,
    AutoFarm = false,
    AutoSell = false,
    AutoQuest = false,
    AutoRebirth = false,
    AutoMerge = false,
    AutoUpgrade = false,
    ESPPlayers = false,
    ESPCards = false,
}

local cfg = { Speed = 32 }

-- =====================================================
-- FUNCOES QUE REALMENTE FUNCIONAM
-- =====================================================

-- God Mode: mantém HP no max via Heartbeat
local godConn
local function toggleGodMode(on)
    if godConn then godConn:Disconnect() godConn = nil end
    if on then
        godConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = hum.MaxHealth end
            end
        end)
        notify("God Mode", "Ativado! HP sempre cheio.")
    else
        notify("God Mode", "Desativado.")
    end
end

-- Speed Hack via Heartbeat
local speedConn
local function toggleSpeed(on)
    if speedConn then speedConn:Disconnect() speedConn = nil end
    if on then
        speedConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = cfg.Speed end
            end
        end)
        notify("Speed Hack", "Ativado! Velocidade: "..cfg.Speed)
    else
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        notify("Speed Hack", "Desativado.")
    end
end

-- Infinite Jump via StateChanged
local jumpConn
local function toggleInfJump(on)
    if jumpConn then jumpConn:Disconnect() jumpConn = nil end
    if on then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                jumpConn = hum.StateChanged:Connect(function(_, new)
                    if new == Enum.HumanoidStateType.Landed then
                        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                    end
                end)
            end
        end
        UserInputService.JumpRequest:Connect(function()
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
        notify("Infinite Jump", "Ativado!")
    else
        notify("Infinite Jump", "Desativado.")
    end
end

-- No Clip via Heartbeat
local noclipConn
local function toggleNoClip(on)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                        p.CanCollide = false
                    end
                end
            end
        end)
        notify("No Clip", "Ativado!")
    else
        notify("No Clip", "Desativado.")
    end
end

-- ESP Jogadores
local espPlayersConn
local function toggleESPPlayers(on)
    if not on then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bb = hrp:FindFirstChild("ESP_BB")
                    if bb then bb:Destroy() end
                end
            end
        end
        notify("ESP", "Desativado.")
        return
    end
    local function addESP(plr)
        if plr == LocalPlayer then return end
        local function applyTag(char)
            local hrp = char:WaitForChild("HumanoidRootPart", 3)
            if not hrp then return end
            if hrp:FindFirstChild("ESP_BB") then return end
            local bb = Instance.new("BillboardGui")
            bb.Name = "ESP_BB"
            bb.Size = UDim2.new(0, 120, 0, 30)
            bb.StudsOffset = Vector3.new(0, 3.5, 0)
            bb.AlwaysOnTop = true
            bb.Parent = hrp
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,1,0)
            lbl.BackgroundTransparency = 1
            lbl.Text = plr.Name
            lbl.TextColor3 = Color3.fromRGB(255, 80, 0)
            lbl.TextStrokeTransparency = 0
            lbl.TextSize = 14
            lbl.Font = Enum.Font.GothamBold
            lbl.Parent = bb
        end
        if plr.Character then applyTag(plr.Character) end
        plr.CharacterAdded:Connect(applyTag)
    end
    for _, plr in ipairs(Players:GetPlayers()) do addESP(plr) end
    Players.PlayerAdded:Connect(addESP)
    notify("ESP", "Jogadores destacados!")
end

-- ESP Cartas/Drops no workspace
local espCardConn
local function toggleESPCards(on)
    if espCardConn then espCardConn:Disconnect() espCardConn = nil end
    if not on then notify("ESP Cards", "Desativado.") return end
    espCardConn = RunService.Heartbeat:Connect(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if (obj.Name:lower():find("card") or obj.Name:lower():find("drop") or obj.Name:lower():find("pack"))
            and obj:IsA("BasePart") and not obj:FindFirstChild("CESP") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "CESP"
                bb.Size = UDim2.new(0, 80, 0, 20)
                bb.StudsOffset = Vector3.new(0, 2, 0)
                bb.AlwaysOnTop = true
                bb.Parent = obj
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Text = "🃏 "..obj.Name
                lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                lbl.TextStrokeTransparency = 0
                lbl.TextSize = 11
                lbl.Font = Enum.Font.GothamBold
                lbl.Parent = bb
            end
        end
    end)
    notify("ESP Cards", "Cartas/drops destacados!")
end

-- Auto Collect: teleporta char até drops próximos
local autoCollectConn
local function toggleAutoCollect(on)
    if autoCollectConn then autoCollectConn:Disconnect() autoCollectConn = nil end
    if not on then notify("Auto Collect", "Desativado.") return end
    autoCollectConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and
               (obj.Name:lower():find("card") or obj.Name:lower():find("drop") or obj.Name:lower():find("collect")) then
                local dist = (hrp.Position - obj.Position).Magnitude
                if dist > 1 and dist < 80 then
                    hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                end
            end
        end
    end)
    notify("Auto Collect", "Ativado! Indo buscar cartas.")
end

-- Auto Farm: toca em NPCs/mobs próximos
local autoFarmConn
local function toggleAutoFarm(on)
    if autoFarmConn then autoFarmConn:Disconnect() autoFarmConn = nil end
    if not on then notify("Auto Farm", "Desativado.") return end
    autoFarmConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local nearest, nearDist = nil, math.huge
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj ~= hum and obj.Health > 0 then
                local root = obj.Parent:FindFirstChild("HumanoidRootPart")
                if root then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d < nearDist then nearest = root nearDist = d end
                end
            end
        end
        if nearest then
            hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 0, 2.5))
        end
    end)
    notify("Auto Farm", "Ativado! Farmando mobs.")
end

-- Auto Spin: busca remotes com "spin" no nome
local function doAutoSpin()
    local found = false
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            if v.Name:lower():find("spin") or v.Name:lower():find("gacha") or v.Name:lower():find("roll") then
                pcall(function()
                    if v:IsA("RemoteEvent") then v:FireServer()
                    else v:InvokeServer() end
                end)
                found = true
            end
        end
    end
    return found
end

task.spawn(function()
    while true do
        task.wait(0.8)
        if toggled.AutoSpin then
            if not doAutoSpin() then
                -- Tenta clicar botão de spin na GUI
                for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                    if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                        local n = gui.Name:lower()
                        if n:find("spin") or n:find("roll") or n:find("gacha") then
                            pcall(function() gui.Activated:Fire() end)
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Battle: busca remotes de batalha
local function doAutoBattle()
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("battle") or n:find("fight") or n:find("attack") or n:find("pvp") then
                pcall(function() v:FireServer() end)
            end
        end
    end
    -- Tenta clicar botão de batalha
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local n = gui.Name:lower()
            if n:find("battle") or n:find("fight") or n:find("attack") then
                pcall(function() gui.Activated:Fire() end)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1.5)
        if toggled.AutoBattle then doAutoBattle() end
    end
end)

-- Auto Sell
local function doAutoSell()
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("sell") then
                pcall(function() v:FireServer() end)
            end
        end
    end
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") and gui.Name:lower():find("sell") then
            pcall(function() gui.Activated:Fire() end)
        end
    end
end

task.spawn(function()
    while true do
        task.wait(2)
        if toggled.AutoSell then doAutoSell() end
    end
end)

-- Auto Quest
local function doAutoQuest()
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("quest") or n:find("mission") or n:find("task") then
                pcall(function() v:FireServer() end)
            end
        end
    end
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") then
            local n = gui.Name:lower()
            if n:find("quest") or n:find("claim") or n:find("complete") then
                pcall(function() gui.Activated:Fire() end)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(3)
        if toggled.AutoQuest then doAutoQuest() end
    end
end)

-- Auto Rebirth
local function doAutoRebirth()
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("rebirth") or n:find("prestige") or n:find("reset") then
                pcall(function() v:FireServer() end)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(4)
        if toggled.AutoRebirth then doAutoRebirth() end
    end
end)

-- Auto Merge
local function doAutoMerge()
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("merge") or n:find("combine") or n:find("fuse") then
                pcall(function() v:FireServer() end)
            end
        end
    end
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") then
            local n = gui.Name:lower()
            if n:find("merge") or n:find("combine") then
                pcall(function() gui.Activated:Fire() end)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(2)
        if toggled.AutoMerge then doAutoMerge() end
    end
end)

-- Auto Upgrade
local function doAutoUpgrade()
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("upgrade") or n:find("enhance") or n:find("level") then
                pcall(function() v:FireServer() end)
            end
        end
    end
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") then
            local n = gui.Name:lower()
            if n:find("upgrade") or n:find("enhance") then
                pcall(function() gui.Activated:Fire() end)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1.5)
        if toggled.AutoUpgrade then doAutoUpgrade() end
    end
end)

-- =====================================================
-- GUI
-- =====================================================
if game:GetService("CoreGui"):FindFirstChild("AnimeCardHub") then
    game:GetService("CoreGui"):FindFirstChild("AnimeCardHub"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnimeCardHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 510)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -255)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Color3.fromRGB(255, 100, 0)
stroke.Thickness = 2

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 8, 38)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🃏 Anime Card Hub v2"
TitleLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local function makeBtn(parent, text, color, pos, size)
    local b = Instance.new("TextButton")
    b.Size = size or UDim2.new(0, 35, 0, 28)
    b.Position = pos
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local CloseBtn = makeBtn(TitleBar, "X", Color3.fromRGB(200,40,40), UDim2.new(1,-38,0,8))
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

local minimized = false
local MinBtn = makeBtn(TitleBar, "_", Color3.fromRGB(50,50,80), UDim2.new(1,-78,0,8))
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, c in ipairs(MainFrame:GetChildren()) do
        if c ~= TitleBar then c.Visible = not minimized end
    end
    MainFrame.Size = minimized and UDim2.new(0,480,0,45) or UDim2.new(0,480,0,510)
end)

-- Tabs
local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1,0,0,34)
TabFrame.Position = UDim2.new(0,0,0,47)
TabFrame.BackgroundColor3 = Color3.fromRGB(18,18,32)
TabFrame.BorderSizePixel = 0
TabFrame.Parent = MainFrame

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1,-10,1,-90)
ContentFrame.Position = UDim2.new(0,5,0,86)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local tabs = {}
local tabBtns = {}
local tabNames = {"Auto","Player","Cards","Misc","Settings"}

local function createPage(name, index)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,88,1,-4)
    btn.Position = UDim2.new(0,(index-1)*90+2,0,2)
    btn.BackgroundColor3 = Color3.fromRGB(28,28,48)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(170,170,170)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamSemibold
    btn.BorderSizePixel = 0
    btn.Parent = TabFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = index == 1
    page.Parent = ContentFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,5)
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0,4)
    pad.Parent = page

    tabs[name] = page
    tabBtns[name] = btn

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(tabs) do p.Visible = false end
        for _, b in pairs(tabBtns) do
            b.BackgroundColor3 = Color3.fromRGB(28,28,48)
            b.TextColor3 = Color3.fromRGB(170,170,170)
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(255,100,0)
        btn.TextColor3 = Color3.new(1,1,1)
    end)
    if index == 1 then
        btn.BackgroundColor3 = Color3.fromRGB(255,100,0)
        btn.TextColor3 = Color3.new(1,1,1)
    end
    return page
end

for i,n in ipairs(tabNames) do createPage(n,i) end

-- Helpers GUI
local function mkLabel(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-6,0,22)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(255,180,0)
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
end

local function mkSep(parent)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1,-6,0,1)
    s.BackgroundColor3 = Color3.fromRGB(255,100,0)
    s.BackgroundTransparency = 0.6
    s.BorderSizePixel = 0
    s.Parent = parent
end

local function mkButton(parent, text, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-6,0,34)
    b.BackgroundColor3 = Color3.fromRGB(40,40,65)
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 12
    b.Font = Enum.Font.GothamSemibold
    b.BorderSizePixel = 0
    b.Parent = parent
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,7)
    local stroke2 = Instance.new("UIStroke",b)
    stroke2.Color = Color3.fromRGB(255,100,0)
    stroke2.Thickness = 1
    stroke2.Transparency = 0.5
    b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(60,40,80) end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(40,40,65) end)
    return b
end

local function mkToggle(parent, text, key, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-6,0,36)
    row.BackgroundColor3 = Color3.fromRGB(22,22,38)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,7)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-60,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210,210,210)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0,44,0,22)
    track.Position = UDim2.new(1,-52,0.5,-11)
    track.BackgroundColor3 = Color3.fromRGB(70,70,70)
    track.Text = ""
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,16,0,16)
    knob.Position = UDim2.new(0,3,0.5,-8)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local function refresh()
        local on = toggled[key]
        TweenService:Create(knob, TweenInfo.new(0.12), {
            Position = on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
        }):Play()
        track.BackgroundColor3 = on and Color3.fromRGB(255,100,0) or Color3.fromRGB(70,70,70)
    end

    track.MouseButton1Click:Connect(function()
        toggled[key] = not toggled[key]
        refresh()
        if callback then callback(toggled[key]) end
    end)

    return row
end

-- =====================================================
-- ABA AUTO
-- =====================================================
local aP = tabs["Auto"]
mkLabel(aP, "⚡ Automacoes")
mkSep(aP)
mkToggle(aP, "🔄 Auto Spin", "AutoSpin", nil)
mkToggle(aP, "💎 Auto Collect (move ao drop)", "AutoCollect", toggleAutoCollect)
mkToggle(aP, "⚔️ Auto Battle", "AutoBattle", nil)
mkToggle(aP, "🌾 Auto Farm (vai a mobs)", "AutoFarm", toggleAutoFarm)
mkToggle(aP, "💰 Auto Sell", "AutoSell", nil)
mkToggle(aP, "📋 Auto Quest", "AutoQuest", nil)
mkToggle(aP, "🔃 Auto Rebirth", "AutoRebirth", nil)
mkToggle(aP, "🔀 Auto Merge", "AutoMerge", nil)
mkToggle(aP, "⬆️ Auto Upgrade", "AutoUpgrade", nil)

-- =====================================================
-- ABA PLAYER
-- =====================================================
local pP = tabs["Player"]
mkLabel(pP, "🧍 Player Hacks")
mkSep(pP)
mkToggle(pP, "🛡️ God Mode (HP sempre cheio)", "GodMode", toggleGodMode)
mkToggle(pP, "💨 Speed Hack", "SpeedHack", toggleSpeed)
mkToggle(pP, "🚀 Infinite Jump", "InfiniteJump", toggleInfJump)
mkToggle(pP, "👻 No Clip", "NoClip", toggleNoClip)
mkSep(pP)
mkLabel(pP, "📍 Teleportes")
mkButton(pP, "🏁 Teleportar para Spawn (0,5,0)", function()
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        c.HumanoidRootPart.CFrame = CFrame.new(0,5,0)
        notify("Teleporte", "Spawn!")
    end
end)
mkButton(pP, "🏠 Ir para Loja", function()
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n:find("shop") or n:find("store") or n:find("loja")) and obj:IsA("BasePart") then
            hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0,5,0))
            notify("Teleporte", "Loja encontrada!")
            return
        end
    end
    notify("Teleporte", "Loja nao encontrada no workspace.")
end)
mkButton(pP, "⚔️ Ir para Arena/Battle", function()
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n:find("arena") or n:find("battle") or n:find("fight") or n:find("pvp")) and obj:IsA("BasePart") then
            hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0,5,0))
            notify("Teleporte", "Arena encontrada!")
            return
        end
    end
    notify("Teleporte", "Arena nao encontrada.")
end)
mkButton(pP, "📦 Ir para Pack/Gacha", function()
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n:find("gacha") or n:find("pack") or n:find("spin") or n:find("roll")) and obj:IsA("BasePart") then
            hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0,5,0))
            notify("Teleporte", "Gacha encontrado!")
            return
        end
    end
    notify("Teleporte", "Gacha nao encontrado.")
end)

-- Speed config
mkSep(pP)
mkLabel(pP, "⚙️ Configurar Velocidade")
mkButton(pP, "16 - Normal", function() cfg.Speed=16 notify("Speed","16") end)
mkButton(pP, "32 - Rapido", function() cfg.Speed=32 notify("Speed","32") end)
mkButton(pP, "80 - Muito Rapido", function() cfg.Speed=80 notify("Speed","80") end)
mkButton(pP, "200 - Maximo", function() cfg.Speed=200 notify("Speed","200") end)

-- =====================================================
-- ABA CARDS
-- =====================================================
local cP = tabs["Cards"]
mkLabel(cP, "🃏 Cartas & Inventario")
mkSep(cP)
mkToggle(cP, "👁️ ESP Cartas/Drops no Mapa", "ESPCards", toggleESPCards)
mkSep(cP)
mkButton(cP, "📦 Abrir Todos Packs (via Remote)", function()
    local count = 0
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("open") or n:find("pack") or n:find("unbox") then
                for i=1,30 do
                    pcall(function() v:FireServer() end)
                    task.wait(0.15)
                end
                count = count + 1
            end
        end
    end
    notify("Packs", count > 0 and "Abriu via "..count.." remotes!" or "Nenhum remote de pack encontrado.")
end)
mkButton(cP, "🗑️ Vender Tudo (via Remote)", function()
    local count = 0
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find("sell") then
            pcall(function() v:FireServer() end)
            count = count + 1
        end
    end
    notify("Sell", count > 0 and "Vendido via "..count.." remotes!" or "Nenhum remote de sell encontrado.")
end)
mkButton(cP, "🔀 Merge Tudo (via Remote)", function()
    local count = 0
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("merge") or n:find("combine") or n:find("fuse") then
                pcall(function() v:FireServer() end)
                count = count + 1
            end
        end
    end
    notify("Merge", count > 0 and "Merged via "..count.." remotes!" or "Nenhum remote de merge encontrado.")
end)
mkButton(cP, "🔍 Listar Remotes do Jogo", function()
    local list = {}
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(list, v.Name)
        end
    end
    print("[AnimeCardHub] Remotes encontrados:")
    for _, name in ipairs(list) do print(" -", name) end
    notify("Remotes", #list.." encontrados. Veja o output (F9).")
end)

-- =====================================================
-- ABA MISC
-- =====================================================
local mP = tabs["Misc"]
mkLabel(mP, "🛠️ Ferramentas")
mkSep(mP)
mkToggle(mP, "🗺️ ESP Jogadores", "ESPPlayers", toggleESPPlayers)
mkSep(mP)
mkButton(mP, "📊 Ver Ping", function()
    notify("Ping", math.floor(LocalPlayer:GetNetworkPing()*1000).."ms")
end)
mkButton(mP, "💻 Copiar UserID", function()
    pcall(function() setclipboard(tostring(LocalPlayer.UserId)) end)
    notify("UserID", "Copiado: "..LocalPlayer.UserId)
end)
mkButton(mP, "🔄 Rejoin", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)
mkButton(mP, "🌐 Server Hop (servidor vazio)", function()
    local ok, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(
            game:GetService("HttpService"):GetAsync(
                "https://games.roproxy.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            )
        )
    end)
    if ok and result and result.data then
        for _, s in ipairs(result.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers - 1 then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                return
            end
        end
    end
    notify("Server Hop", "Nenhum servidor vazio encontrado.")
end)
mkButton(mP, "🔔 Teste de Notificacao", function()
    notify("Hub v2", "Funcionando perfeitamente!")
end)
mkButton(mP, "🔍 Info do Jogo", function()
    print("[Hub] PlaceId:", game.PlaceId)
    print("[Hub] JobId:", game.JobId)
    print("[Hub] Players:", #Players:GetPlayers())
    notify("Info", "PlaceId: "..game.PlaceId.." | Veja F9")
end)

-- =====================================================
-- ABA SETTINGS
-- =====================================================
local sP = tabs["Settings"]
mkLabel(sP, "⚙️ Configuracoes")
mkSep(sP)
mkButton(sP, "♻️ Resetar Todos Toggles", function()
    for k in pairs(toggled) do
        if toggled[k] then
            toggled[k] = false
            if k == "GodMode" then toggleGodMode(false)
            elseif k == "SpeedHack" then toggleSpeed(false)
            elseif k == "NoClip" then toggleNoClip(false)
            elseif k == "AutoCollect" then toggleAutoCollect(false)
            elseif k == "AutoFarm" then toggleAutoFarm(false)
            elseif k == "ESPPlayers" then toggleESPPlayers(false)
            elseif k == "ESPCards" then toggleESPCards(false)
            end
        end
    end
    notify("Reset", "Todos os toggles desativados.")
end)
mkButton(sP, "❌ Fechar Hub", function()
    ScreenGui:Destroy()
end)

-- =====================================================
-- DRAG
-- =====================================================
local dragging, dStart, dPos
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dStart = i.Position
        dPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dStart
        MainFrame.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X, dPos.Y.Scale, dPos.Y.Offset+d.Y)
    end
end)

-- INSERT toggle
UserInputService.InputBegan:Connect(function(i, gpe)
    if not gpe and i.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- =====================================================
-- INICIO
-- =====================================================
task.wait(0.5)
notify("🃏 Anime Card Hub v2", "Carregado! INSERT para abrir/fechar.")
print("[AnimeCardHub v2] Pronto! | TochZero")
