-- =====================================================
--   ANIME CARD COLLECTION HUB
--   By TochZero | Delta Executor Compatible
-- =====================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- =====================================================
-- VARIAVEIS GLOBAIS
-- =====================================================
local toggled = {
    AutoSpin = false,
    AutoCollect = false,
    AutoBattle = false,
    AutoUpgrade = false,
    AutoSell = false,
    AutoQuest = false,
    GodMode = false,
    InfiniteJump = false,
    SpeedHack = false,
    AutoFarm = false,
    AutoRebirth = false,
    AutoMerge = false,
    NoClip = false,
    ESPCards = false,
    AutoEquip = false,
}

local configs = {
    SpeedValue = 32,
    AutoSpinDelay = 0.5,
    AutoCollectDelay = 0.3,
    AutoSellRarity = "Common",
    AutoUpgradeRarity = "Rare",
    AutoRebirthAt = 1000,
}

-- =====================================================
-- GUI PRINCIPAL
-- =====================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnimeCardHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Frame principal
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 500)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Borda gradiente
local UIStroke = Instance.new("UIStroke")
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Color = Color3.fromRGB(255, 100, 0)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

-- Título
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 10, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local UICornerTitle = Instance.new("UICorner")
UICornerTitle.CornerRadius = UDim.new(0, 12)
UICornerTitle.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🃏 Anime Card Collection Hub"
TitleLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local UICornerClose = Instance.new("UICorner")
UICornerClose.CornerRadius = UDim.new(0, 8)
UICornerClose.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- MinimizeBtn
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 35, 0, 35)
MinBtn.Position = UDim2.new(1, -80, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar

local UICornerMin = Instance.new("UICorner")
UICornerMin.CornerRadius = UDim.new(0, 8)
UICornerMin.Parent = MinBtn

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, child in ipairs(MainFrame:GetChildren()) do
        if child ~= TitleBar then
            child.Visible = not minimized
        end
    end
    MainFrame.Size = minimized and UDim2.new(0, 480, 0, 45) or UDim2.new(0, 480, 0, 500)
end)

-- =====================================================
-- TABS
-- =====================================================
local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1, 0, 0, 35)
TabFrame.Position = UDim2.new(0, 0, 0, 48)
TabFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
TabFrame.BorderSizePixel = 0
TabFrame.Parent = MainFrame

local tabNames = {"Auto", "Player", "Cards", "Misc", "Settings"}
local tabs = {}
local tabBtns = {}

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -10, 1, -95)
ContentFrame.Position = UDim2.new(0, 5, 0, 88)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local function createTab(name, index)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 88, 1, -4)
    btn.Position = UDim2.new(0, (index-1)*90 + 4, 0, 2)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamSemibold
    btn.BorderSizePixel = 0
    btn.Parent = TabFrame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.Visible = index == 1
    page.Parent = ContentFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = page

    tabs[name] = page
    tabBtns[name] = btn

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(tabs) do p.Visible = false end
        for _, b in pairs(tabBtns) do
            b.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            b.TextColor3 = Color3.fromRGB(180,180,180)
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    if index == 1 then
        btn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    return page
end

for i, name in ipairs(tabNames) do
    createTab(name, i)
end

-- =====================================================
-- FUNÇÕES HELPERS
-- =====================================================
local function createToggle(parent, labelText, toggleKey)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -8, 0, 38)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    container.BorderSizePixel = 0
    container.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 46, 0, 24)
    toggleBtn.Position = UDim2.new(1, -54, 0.5, -12)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    toggleBtn.Text = ""
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = container

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = toggleBtn

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 18, 0, 18)
    circle.Position = UDim2.new(0, 3, 0.5, -9)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent = toggleBtn

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(1, 0)
    cc.Parent = circle

    toggleBtn.MouseButton1Click:Connect(function()
        toggled[toggleKey] = not toggled[toggleKey]
        local on = toggled[toggleKey]
        TweenService:Create(circle, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
        toggleBtn.BackgroundColor3 = on and Color3.fromRGB(255, 100, 0) or Color3.fromRGB(80, 80, 80)
    end)

    return container
end

local function createButton(parent, labelText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.BorderSizePixel = 0
    btn.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 180, 0)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function createSeparator(parent)
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -8, 0, 2)
    sep.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    sep.BorderSizePixel = 0
    sep.BackgroundTransparency = 0.7
    sep.Parent = parent
end

-- =====================================================
-- ABA AUTO
-- =====================================================
local autoPage = tabs["Auto"]
createLabel(autoPage, "⚡ Automações")
createSeparator(autoPage)
createToggle(autoPage, "🔄 Auto Spin", "AutoSpin")
createToggle(autoPage, "💎 Auto Coletar Cartas", "AutoCollect")
createToggle(autoPage, "⚔️ Auto Battle", "AutoBattle")
createToggle(autoPage, "⬆️ Auto Upgrade", "AutoUpgrade")
createToggle(autoPage, "💰 Auto Vender Cartas", "AutoSell")
createToggle(autoPage, "📋 Auto Quest", "AutoQuest")
createToggle(autoPage, "🔁 Auto Farm", "AutoFarm")
createToggle(autoPage, "🔃 Auto Rebirth", "AutoRebirth")
createToggle(autoPage, "🔀 Auto Merge", "AutoMerge")
createToggle(autoPage, "🎴 Auto Equipar Melhor Carta", "AutoEquip")

-- =====================================================
-- ABA PLAYER
-- =====================================================
local playerPage = tabs["Player"]
createLabel(playerPage, "🧍 Player Hacks")
createSeparator(playerPage)
createToggle(playerPage, "🛡️ God Mode", "GodMode")
createToggle(playerPage, "💨 Speed Hack", "SpeedHack")
createToggle(playerPage, "🚀 Infinite Jump", "InfiniteJump")
createToggle(playerPage, "👻 No Clip", "NoClip")
createSeparator(playerPage)
createButton(playerPage, "📍 Teleportar para Spawn", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)
    end
end)
createButton(playerPage, "🏠 Teleportar para Loja", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local shop = workspace:FindFirstChild("Shop") or workspace:FindFirstChild("Store")
        if shop then
            char.HumanoidRootPart.CFrame = shop.CFrame + Vector3.new(0, 5, 0)
        end
    end
end)
createButton(playerPage, "⚡ Teleportar para Arena", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local arena = workspace:FindFirstChild("Arena") or workspace:FindFirstChild("Battle")
        if arena then
            char.HumanoidRootPart.CFrame = arena.CFrame + Vector3.new(0, 5, 0)
        end
    end
end)

-- =====================================================
-- ABA CARDS
-- =====================================================
local cardsPage = tabs["Cards"]
createLabel(cardsPage, "🃏 Cartas & Inventário")
createSeparator(cardsPage)
createToggle(cardsPage, "👁️ ESP Cartas no Mapa", "ESPCards")
createSeparator(cardsPage)
createButton(cardsPage, "🗑️ Vender Todas Common", function()
    local backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer:FindFirstChild("Inventory")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:FindFirstChild("Rarity") and item.Rarity.Value == "Common" then
                local remote = game:GetService("ReplicatedStorage"):FindFirstChild("SellCard", true)
                if remote then remote:FireServer(item) end
            end
        end
    end
end)
createButton(cardsPage, "⭐ Vender Todas Uncommon", function()
    local backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer:FindFirstChild("Inventory")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:FindFirstChild("Rarity") and item.Rarity.Value == "Uncommon" then
                local remote = game:GetService("ReplicatedStorage"):FindFirstChild("SellCard", true)
                if remote then remote:FireServer(item) end
            end
        end
    end
end)
createButton(cardsPage, "🔮 Fazer Merge de Todas", function()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("MergeAll", true)
    if remote then remote:FireServer() end
end)
createButton(cardsPage, "🏆 Equipar Melhor Carta", function()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("EquipBest", true)
    if remote then remote:FireServer() end
end)
createButton(cardsPage, "📦 Abrir Todos os Packs", function()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("OpenPack", true)
    if remote then
        for i = 1, 50 do
            remote:FireServer()
            task.wait(0.2)
        end
    end
end)

-- =====================================================
-- ABA MISC
-- =====================================================
local miscPage = tabs["Misc"]
createLabel(miscPage, "🛠️ Ferramentas Extras")
createSeparator(miscPage)
createButton(miscPage, "🔔 Notificação de Teste", function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Anime Card Hub",
        Text = "Hub ativo e funcionando! 🃏",
        Duration = 4,
    })
end)
createButton(miscPage, "💻 Copiar UserID", function()
    setclipboard(tostring(LocalPlayer.UserId))
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Copiado!",
        Text = "UserID copiado: "..LocalPlayer.UserId,
        Duration = 3,
    })
end)
createButton(miscPage, "🔄 Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)
createButton(miscPage, "🌐 Trocar para Servidor Vazio", function()
    local servers = {}
    local ok, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(
            game:GetService("HttpService"):GetAsync(
                "https://games.roproxy.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            )
        )
    end)
    if ok and result and result.data then
        for _, s in ipairs(result.data) do
            if s.playing < s.maxPlayers - 2 then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                return
            end
        end
    end
end)
createButton(miscPage, "📊 Ver Ping", function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Ping",
        Text = "Ping atual: "..math.floor(LocalPlayer:GetNetworkPing()*1000).."ms",
        Duration = 3,
    })
end)
createSeparator(miscPage)
createButton(miscPage, "🗺️ ESP Jogadores", function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and not hrp:FindFirstChild("ESP_BillBoard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ESP_BillBoard"
                bb.Size = UDim2.new(0, 100, 0, 30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.AlwaysOnTop = true
                bb.Parent = hrp
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Text = plr.Name
                lbl.TextColor3 = Color3.fromRGB(255,100,0)
                lbl.TextSize = 14
                lbl.Font = Enum.Font.GothamBold
                lbl.Parent = bb
            end
        end
    end
end)

-- =====================================================
-- ABA SETTINGS
-- =====================================================
local settingsPage = tabs["Settings"]
createLabel(settingsPage, "⚙️ Configurações")
createSeparator(settingsPage)
createLabel(settingsPage, "Velocidade do Player")
createButton(settingsPage, "🐢 Velocidade Normal (16)", function()
    configs.SpeedValue = 16
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)
createButton(settingsPage, "🚶 Velocidade Média (32)", function()
    configs.SpeedValue = 32
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 32 end
    end
end)
createButton(settingsPage, "💨 Alta Velocidade (80)", function()
    configs.SpeedValue = 80
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 80 end
    end
end)
createButton(settingsPage, "🚀 Velocidade Máxima (200)", function()
    configs.SpeedValue = 200
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 200 end
    end
end)
createSeparator(settingsPage)
createButton(settingsPage, "❌ Fechar Hub", function()
    ScreenGui:Destroy()
end)
createButton(settingsPage, "♻️ Resetar Toggles", function()
    for k in pairs(toggled) do toggled[k] = false end
end)

-- =====================================================
-- ARRASTAR JANELA
-- =====================================================
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- =====================================================
-- KEYBIND: INSERT para abrir/fechar
-- =====================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- =====================================================
-- LOOP PRINCIPAL
-- =====================================================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    -- Speed Hack
    if toggled.SpeedHack and hum then
        hum.WalkSpeed = configs.SpeedValue
    end

    -- God Mode
    if toggled.GodMode and hum then
        hum.Health = hum.MaxHealth
    end

    -- Infinite Jump
    if toggled.InfiniteJump and hum then
        hum:GetPropertyChangedSignal("Jump"):connect(function()
            if hum.Jump then hum.Jump = false end
        end)
    end

    -- No Clip
    if toggled.NoClip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Auto Spin loop
task.spawn(function()
    while true do
        task.wait(configs.AutoSpinDelay)
        if toggled.AutoSpin then
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Spin", true)
            if remote then pcall(function() remote:FireServer() end) end
        end
    end
end)

-- Auto Collect loop
task.spawn(function()
    while true do
        task.wait(configs.AutoCollectDelay)
        if toggled.AutoCollect then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "Card" or obj.Name == "CardDrop" or obj.Name == "Drop" then
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local dist = (char.HumanoidRootPart.Position - obj.Position).Magnitude
                        if dist < 50 then
                            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("CollectCard", true)
                            if remote then pcall(function() remote:FireServer(obj) end) end
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Battle loop
task.spawn(function()
    while true do
        task.wait(1)
        if toggled.AutoBattle then
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("StartBattle", true)
                or game:GetService("ReplicatedStorage"):FindFirstChild("AutoBattle", true)
            if remote then pcall(function() remote:FireServer() end) end
        end
    end
end)

-- Auto Quest loop
task.spawn(function()
    while true do
        task.wait(2)
        if toggled.AutoQuest then
            local accept = game:GetService("ReplicatedStorage"):FindFirstChild("AcceptQuest", true)
            local complete = game:GetService("ReplicatedStorage"):FindFirstChild("CompleteQuest", true)
            if accept then pcall(function() accept:FireServer() end) end
            if complete then pcall(function() complete:FireServer() end) end
        end
    end
end)

-- Auto Rebirth loop
task.spawn(function()
    while true do
        task.wait(3)
        if toggled.AutoRebirth then
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Rebirth", true)
            if remote then pcall(function() remote:FireServer() end) end
        end
    end
end)

-- Auto Merge loop
task.spawn(function()
    while true do
        task.wait(1.5)
        if toggled.AutoMerge then
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("MergeAll", true)
            if remote then pcall(function() remote:FireServer() end) end
        end
    end
end)

-- Auto Upgrade loop
task.spawn(function()
    while true do
        task.wait(1)
        if toggled.AutoUpgrade then
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("UpgradeCard", true)
            if remote then pcall(function() remote:FireServer() end) end
        end
    end
end)

-- Auto Equip loop
task.spawn(function()
    while true do
        task.wait(2)
        if toggled.AutoEquip then
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("EquipBest", true)
            if remote then pcall(function() remote:FireServer() end) end
        end
    end
end)

-- =====================================================
-- NOTIFICAÇÃO INICIAL
-- =====================================================
task.wait(1)
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "🃏 Anime Card Hub",
    Text = "Hub carregado! Pressione INSERT para abrir/fechar.",
    Duration = 5,
})

print("[AnimeCardHub] Carregado com sucesso! | TochZero")
