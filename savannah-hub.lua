-- ================================================
-- SAVANNAH LIFE HUB v3 | TochZero | 2026
-- Vida de Savana - NOYO Productions
-- Delta Executor Compatible - ALL FUNCTIONS FIXED
-- ================================================

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local HTTP = game:GetService("HttpService")
local TEL = game:GetService("TeleportService")
local SGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer
local WS = workspace

-- Limpa instancia anterior
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("SavannahHub"):Destroy()
end)

-- ================================================
-- NOTIFICACAO
-- ================================================
local function N(t, m, d)
    pcall(function()
        SGui:SetCore("SendNotification",{Title=t,Text=m,Duration=d or 4})
    end)
end

-- ================================================
-- ESTADO
-- ================================================
local T = {
    GodMode=false, InfStamina=false, Speed=false,
    NoClip=false, InfJump=false, KillAura=false,
    AutoFarm=false, AutoEat=false, AutoDrink=false,
    ESPAnimals=false, ESPFood=false,
    AutoRespawn=false, AntiAFK=false,
}
local CFG = {
    Speed=50, KillRange=20, FarmRange=60,
}

-- ================================================
-- CONEXOES
-- ================================================
local CONN = {}
local function off(k)
    if CONN[k] then
        pcall(function() CONN[k]:Disconnect() end)
        CONN[k] = nil
    end
end

-- ================================================
-- HELPERS
-- ================================================
local function Chr()  return LP.Character end
local function HRP()
    local c=Chr() return c and c:FindFirstChild("HumanoidRootPart")
end
local function Hum()
    local c=Chr() return c and c:FindFirstChildOfClass("Humanoid")
end

local function getAnimals()
    local out={}
    for _,v in ipairs(WS:GetDescendants()) do
        if v:IsA("Humanoid") and v.Health>0 and v.Parent~=Chr() then
            local r=v.Parent:FindFirstChild("HumanoidRootPart")
            if r then out[#out+1]={hum=v,root=r,model=v.Parent} end
        end
    end
    return out
end

local FOOD_KW={"meat","carcass","corpse","berry","fruit","grass","herb","prey","food","flesh","plant","kill"}
local WATER_KW={"water","lake","river","pond","oasis","drink","pool"}

local function getNearest(keywords, mustBePart)
    local hrp=HRP() if not hrp then return end
    local best,bd=nil,math.huge
    for _,obj in ipairs(WS:GetDescendants()) do
        local n=obj.Name:lower()
        for _,kw in ipairs(keywords) do
            if n:find(kw) then
                local p = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                if p then
                    local d=(hrp.Position-p.Position).Magnitude
                    if d<bd then best=p bd=d end
                end
                break
            end
        end
    end
    return best,bd
end

-- ================================================
-- 1. GOD MODE
-- ================================================
local function setGodMode(on)
    off("god")
    if on then
        CONN["god"]=RS.Heartbeat:Connect(function()
            local h=Hum() if not h then return end
            h.Health=h.MaxHealth
            local c=Chr() if not c then return end
            -- trava todos NumberValues de stats
            for _,v in ipairs(c:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local n=v.Name:lower()
                    if n:find("hunger") or n:find("thirst") or n:find("food") or n:find("water") or n:find("health") then
                        if v.Value < v.Parent:FindFirstChild("Max") and v.Parent:FindFirstChild("Max").Value
                            or v.Value < 100 then
                            pcall(function()
                                local mx = v.Parent:FindFirstChild("Max")
                                v.Value = mx and mx.Value or 100
                            end)
                        end
                    end
                end
            end
            -- via atributos
            for _,name in ipairs({"Hunger","Thirst","Food","Water","Stamina","Energy"}) do
                pcall(function()
                    local val=c:GetAttribute(name)
                    if type(val)=="number" and val<100 then c:SetAttribute(name,100) end
                end)
            end
        end)
        N("God Mode","HP, Fome e Sede no MAX!")
    else N("God Mode","OFF") end
end

-- ================================================
-- 2. STAMINA INFINITA
-- ================================================
local function setStamina(on)
    off("stamina")
    if on then
        CONN["stamina"]=RS.Heartbeat:Connect(function()
            local c=Chr() if not c then return end
            for _,v in ipairs(c:GetDescendants()) do
                if (v:IsA("NumberValue") or v:IsA("IntValue")) then
                    local n=v.Name:lower()
                    if n=="stamina" or n=="energy" or n=="sprint" or n=="endurance" or n=="fatigue" then
                        pcall(function()
                            local mx=v.Parent:FindFirstChild("Max")
                            local maxVal = mx and mx.Value or 100
                            if v.Value < maxVal then v.Value = maxVal end
                        end)
                    end
                end
            end
            for _,name in ipairs({"Stamina","Energy","Sprint","Endurance"}) do
                pcall(function()
                    local val=c:GetAttribute(name)
                    if type(val)=="number" and val<100 then c:SetAttribute(name,100) end
                end)
            end
        end)
        N("Stamina","Stamina infinita ON!")
    else N("Stamina","OFF") end
end

-- ================================================
-- 3. SPEED HACK
-- ================================================
local function setSpeed(on)
    off("speed")
    if on then
        CONN["speed"]=RS.Heartbeat:Connect(function()
            local h=Hum() if h then h.WalkSpeed=CFG.Speed end
        end)
        N("Speed","Velocidade "..CFG.Speed)
    else
        local h=Hum() if h then h.WalkSpeed=16 end
        N("Speed","Velocidade normal")
    end
end

-- ================================================
-- 4. NO CLIP
-- ================================================
local function setNoClip(on)
    off("noclip")
    if on then
        CONN["noclip"]=RS.Stepped:Connect(function()
            local c=Chr() if not c then return end
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
        N("NoClip","Atravessa paredes ON!")
    else N("NoClip","OFF") end
end

-- ================================================
-- 5. INFINITE JUMP (metodo estavel)
-- ================================================
local _ijConn
local function setInfJump(on)
    if _ijConn then _ijConn:Disconnect() _ijConn=nil end
    if on then
        _ijConn = UIS.JumpRequest:Connect(function()
            local h=Hum()
            if h and h:GetState()~=Enum.HumanoidStateType.Jumping then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        N("Inf Jump","Pulo infinito ON!")
    else N("Inf Jump","OFF") end
end

-- ================================================
-- 6. KILL AURA (sem BodyVelocity depreciado)
-- ================================================
local function setKillAura(on)
    off("killaura")
    if not on then N("Kill Aura","OFF") return end
    CONN["killaura"]=RS.Heartbeat:Connect(function()
        local hrp=HRP() if not hrp then return end
        for _,a in ipairs(getAnimals()) do
            if (hrp.Position-a.root.Position).Magnitude <= CFG.KillRange then
                -- Metodo 1: Remote de ataque
                for _,v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                    if v:IsA("RemoteEvent") then
                        local n=v.Name:lower()
                        if n:find("attack") or n:find("bite") or n:find("damage") or n:find("hit") or n:find("slash") then
                            pcall(function() v:FireServer(a.model) end)
                            pcall(function() v:FireServer(a.root) end)
                        end
                    end
                end
                -- Metodo 2: Tool equipada
                local c=Chr()
                if c then
                    local tool=c:FindFirstChildOfClass("Tool")
                    if tool then
                        for _,v in ipairs(tool:GetDescendants()) do
                            if v:IsA("RemoteEvent") then
                                pcall(function() v:FireServer(a.root.Position) end)
                                pcall(function() v:FireServer(a.model) end)
                            end
                        end
                        -- Faz o handle tocar o alvo
                        local handle=tool:FindFirstChild("Handle")
                        if handle then
                            pcall(function()
                                local old=handle.CFrame
                                handle.CFrame=a.root.CFrame
                                task.defer(function() pcall(function() handle.CFrame=old end) end)
                            end)
                        end
                    end
                end
                -- Metodo 3: LinearVelocity (substituto moderno do BodyVelocity)
                pcall(function()
                    local att=Instance.new("Attachment")
                    att.Parent=a.root
                    local lv=Instance.new("LinearVelocity")
                    lv.Attachment0=att
                    lv.MaxForce=math.huge
                    lv.VectorVelocity=(a.root.Position-hrp.Position).Unit*120
                    lv.Parent=a.root
                    game:GetService("Debris"):AddItem(lv,0.08)
                    game:GetService("Debris"):AddItem(att,0.08)
                end)
            end
        end
    end)
    N("Kill Aura","Raio "..CFG.KillRange.." studs ON!")
end

-- ================================================
-- 7. AUTO FARM (task.spawn - sem travar)
-- ================================================
local _farmRunning=false
local function setAutoFarm(on)
    _farmRunning=on
    off("autofarm")
    if not on then N("Auto Farm","OFF") return end
    N("Auto Farm","Farmando!")
    task.spawn(function()
        while _farmRunning do
            task.wait(0.3)
            local hrp=HRP() if not hrp then continue end
            local animals=getAnimals()
            local nearest,nd=nil,math.huge
            for _,a in ipairs(animals) do
                local d=(hrp.Position-a.root.Position).Magnitude
                if d<nd and d<=CFG.FarmRange then nearest=a nd=d end
            end
            if nearest then
                -- Teleporta atras do alvo
                hrp.CFrame=CFrame.new(nearest.root.Position+Vector3.new(0,2,3))
                -- Ataca via remotes
                for _,v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                    if v:IsA("RemoteEvent") then
                        local n=v.Name:lower()
                        if n:find("attack") or n:find("bite") or n:find("damage") or n:find("hit") then
                            pcall(function() v:FireServer(nearest.model) end)
                        end
                    end
                end
                -- Ataca via tool
                local c=Chr()
                if c then
                    local tool=c:FindFirstChildOfClass("Tool")
                    if tool then
                        for _,v in ipairs(tool:GetDescendants()) do
                            if v:IsA("RemoteEvent") then
                                pcall(function() v:FireServer(nearest.root.Position) end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ================================================
-- 8. AUTO COMER (task.spawn)
-- ================================================
local _eatRunning=false
local function setAutoEat(on)
    _eatRunning=on
    if not on then N("Auto Eat","OFF") return end
    N("Auto Eat","Comendo automaticamente!")
    task.spawn(function()
        while _eatRunning do
            task.wait(1)
            local p,d=getNearest(FOOD_KW)
            if p then
                local hrp=HRP() if not hrp then continue end
                if d>3 then hrp.CFrame=CFrame.new(p.Position+Vector3.new(0,2,0)) end
                -- Tenta simular toque
                pcall(function()
                    local fire=p.Touched
                    local h=hrp
                    fire:Fire(h)
                end)
                -- Remotes de comer
                for _,v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                    if v:IsA("RemoteEvent") then
                        local n=v.Name:lower()
                        if n:find("eat") or n:find("consume") or n:find("feed") then
                            pcall(function() v:FireServer(p.Parent or p) end)
                        end
                    end
                end
            end
        end
    end)
end

-- ================================================
-- 9. AUTO BEBER (task.spawn)
-- ================================================
local _drinkRunning=false
local function setAutoDrink(on)
    _drinkRunning=on
    if not on then N("Auto Drink","OFF") return end
    N("Auto Drink","Bebendo automaticamente!")
    task.spawn(function()
        while _drinkRunning do
            task.wait(1)
            local p,d=getNearest(WATER_KW)
            if p then
                local hrp=HRP() if not hrp then continue end
                if d>3 then hrp.CFrame=CFrame.new(p.Position+Vector3.new(0,2,0)) end
                pcall(function() p.Touched:Fire(hrp) end)
                for _,v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                    if v:IsA("RemoteEvent") then
                        local n=v.Name:lower()
                        if n:find("drink") or n:find("water") or n:find("thirst") then
                            pcall(function() v:FireServer(p.Parent or p) end)
                        end
                    end
                end
            end
        end
    end)
end

-- ================================================
-- 10. ESP ANIMAIS (sem memory leak)
-- ================================================
local _espAnimalConn
local function setESPAnimals(on)
    if _espAnimalConn then _espAnimalConn:Disconnect() _espAnimalConn=nil end
    -- limpa ESP anterior
    for _,v in ipairs(WS:GetDescendants()) do
        if v.Name=="_AESP" then pcall(function() v:Destroy() end) end
    end
    if not on then N("ESP Animais","OFF") return end
    -- Cria ESPs uma vez e atualiza
    local tracked={}
    _espAnimalConn=RS.Heartbeat:Connect(function()
        local hrp=HRP()
        for _,a in ipairs(getAnimals()) do
            if a.root.Parent and not a.root:FindFirstChild("_AESP") then
                local bb=Instance.new("BillboardGui")
                bb.Name="_AESP"
                bb.AlwaysOnTop=true
                bb.Size=UDim2.new(0,130,0,30)
                bb.StudsOffset=Vector3.new(0,4,0)
                bb.Parent=a.root
                local lbl=Instance.new("TextLabel")
                lbl.Size=UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency=1
                lbl.Font=Enum.Font.GothamBold
                lbl.TextSize=12
                lbl.TextStrokeTransparency=0
                lbl.Parent=bb
                tracked[bb]={
                    lbl=lbl,
                    hum=a.hum,
                    root=a.root,
                    name=a.model.Name
                }
            end
        end
        -- atualiza labels
        for bb,info in pairs(tracked) do
            if not bb.Parent then
                tracked[bb]=nil
                continue
            end
            local dist = hrp and math.floor((hrp.Position-info.root.Position).Magnitude) or 0
            local hp = info.hum.Health
            local maxhp = info.hum.MaxHealth
            local pct = maxhp>0 and math.floor(hp/maxhp*100) or 0
            info.lbl.Text = info.name.." ["..dist.."m] "..pct.."%"
            info.lbl.TextColor3 = pct<30
                and Color3.fromRGB(255,50,50)
                or pct<60
                and Color3.fromRGB(255,200,0)
                or Color3.fromRGB(80,255,80)
        end
    end)
    N("ESP Animais","ON - nome, distancia e HP!")
end

-- ================================================
-- 11. ESP COMIDA
-- ================================================
local _espFoodConn
local function setESPFood(on)
    if _espFoodConn then _espFoodConn:Disconnect() _espFoodConn=nil end
    for _,v in ipairs(WS:GetDescendants()) do
        if v.Name=="_FESP" then pcall(function() v:Destroy() end) end
    end
    if not on then N("ESP Comida","OFF") return end
    _espFoodConn=RS.Heartbeat:Connect(function()
        for _,obj in ipairs(WS:GetDescendants()) do
            local n=obj.Name:lower()
            local isFood,isWater=false,false
            for _,kw in ipairs(FOOD_KW) do if n:find(kw) then isFood=true break end end
            for _,kw in ipairs(WATER_KW) do if n:find(kw) then isWater=true break end end
            if (isFood or isWater) and obj:IsA("BasePart") and not obj:FindFirstChild("_FESP") then
                local bb=Instance.new("BillboardGui")
                bb.Name="_FESP"
                bb.AlwaysOnTop=true
                bb.Size=UDim2.new(0,90,0,22)
                bb.StudsOffset=Vector3.new(0,2.5,0)
                bb.Parent=obj
                local lbl=Instance.new("TextLabel")
                lbl.Size=UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency=1
                lbl.Font=Enum.Font.GothamBold
                lbl.TextSize=11
                lbl.TextStrokeTransparency=0
                lbl.TextColor3=isWater
                    and Color3.fromRGB(50,180,255)
                    or Color3.fromRGB(80,255,80)
                lbl.Text=(isWater and "Agua" or "Comida").." - "..obj.Name
                lbl.Parent=bb
            end
        end
    end)
    N("ESP Comida","Comida=Verde | Agua=Azul")
end

-- ================================================
-- 12. AUTO RESPAWN (flag evita spam)
-- ================================================
local _respawnLock=false
local function setAutoRespawn(on)
    off("respawn")
    if not on then N("Auto Respawn","OFF") return end
    CONN["respawn"]=RS.Heartbeat:Connect(function()
        local h=Hum()
        if h and h.Health<=0 and not _respawnLock then
            _respawnLock=true
            task.delay(1.5,function()
                pcall(function() LP:LoadCharacter() end)
                task.wait(3)
                _respawnLock=false
            end)
        end
    end)
    N("Auto Respawn","Respawn automatico ON!")
end

-- ================================================
-- 13. ANTI AFK (metodo seguro - movimento simulado)
-- ================================================
local _afkRunning=false
local function setAntiAFK(on)
    _afkRunning=on
    off("afk")
    if not on then N("Anti AFK","OFF") return end
    task.spawn(function()
        while _afkRunning do
            task.wait(60)
            if not _afkRunning then break end
            -- simula movimento minimo
            local h=Hum()
            if h then
                local oldWS=h.WalkSpeed
                h.WalkSpeed=0.01
                task.wait(0.1)
                h.WalkSpeed=oldWS
            end
        end
    end)
    -- tambem desabilita idle detection via atributo
    pcall(function()
        LP.Character:SetAttribute("Idle",false)
    end)
    N("Anti AFK","Nao sera desconectado!")
end

-- ================================================
-- 14. TELEPORTE UTIL
-- ================================================
local function tpTo(part)
    local hrp=HRP() if not hrp or not part then return false end
    hrp.CFrame=CFrame.new(part.Position+Vector3.new(0,4,0))
    return true
end

local function tpNearest(kw, label)
    local p,d=getNearest(kw)
    if p and tpTo(p) then
        N("Teleporte",label.." ("..math.floor(d).."m)")
    else
        N("Teleporte",label.." nao encontrado")
    end
end

local function tpNearestAnimal()
    local hrp=HRP() if not hrp then return end
    local animals=getAnimals()
    local best,bd=nil,math.huge
    for _,a in ipairs(animals) do
        local d=(hrp.Position-a.root.Position).Magnitude
        if d<bd and d>2 then best=a bd=d end
    end
    if best then
        tpTo(best.root)
        N("Teleporte",best.model.Name.." ("..math.floor(bd).."m)")
    else
        N("Teleporte","Nenhum animal no raio")
    end
end

-- ================================================
-- GUI
-- ================================================
local GUI=Instance.new("ScreenGui")
GUI.Name="SavannahHub"
GUI.ResetOnSpawn=false
GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
GUI.Parent=game:GetService("CoreGui")

local MF=Instance.new("Frame")
MF.Size=UDim2.new(0,360,0,470)
MF.Position=UDim2.new(0,16,0.5,-235)
MF.BackgroundColor3=Color3.fromRGB(10,10,16)
MF.BorderSizePixel=0
MF.Parent=GUI
Instance.new("UICorner",MF).CornerRadius=UDim.new(0,10)
local mfStroke=Instance.new("UIStroke",MF)
mfStroke.Color=Color3.fromRGB(200,130,0)
mfStroke.Thickness=2

-- Topbar
local TOP=Instance.new("Frame")
TOP.Size=UDim2.new(1,0,0,38)
TOP.BackgroundColor3=Color3.fromRGB(18,10,4)
TOP.BorderSizePixel=0
TOP.Parent=MF
Instance.new("UICorner",TOP).CornerRadius=UDim.new(0,10)

local TL=Instance.new("TextLabel")
TL.Size=UDim2.new(1,-72,1,0)
TL.Position=UDim2.new(0,8,0,0)
TL.BackgroundTransparency=1
TL.Text="Savannah Life Hub v3"
TL.TextColor3=Color3.fromRGB(255,175,0)
TL.TextSize=13
TL.Font=Enum.Font.GothamBold
TL.TextXAlignment=Enum.TextXAlignment.Left
TL.Parent=TOP

local function mkTopBtn(txt,col,ox)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,24)
    b.Position=UDim2.new(1,ox,0,7)
    b.BackgroundColor3=col
    b.Text=txt b.TextColor3=Color3.new(1,1,1)
    b.TextSize=11 b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0 b.Parent=TOP
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end

local _min=false
mkTopBtn("X",Color3.fromRGB(170,30,30),-30).MouseButton1Click:Connect(function()
    MF.Visible=not MF.Visible
end)
mkTopBtn("-",Color3.fromRGB(50,50,70),-60).MouseButton1Click:Connect(function()
    _min=not _min
    for _,c in ipairs(MF:GetChildren()) do
        if c~=TOP then c.Visible=not _min end
    end
    MF.Size=_min and UDim2.new(0,360,0,38) or UDim2.new(0,360,0,470)
end)

-- Tab bar
local TABROW=Instance.new("Frame")
TABROW.Size=UDim2.new(1,0,0,28)
TABROW.Position=UDim2.new(0,0,0,40)
TABROW.BackgroundColor3=Color3.fromRGB(14,14,22)
TABROW.BorderSizePixel=0
TABROW.Parent=MF

local CONTENT=Instance.new("Frame")
CONTENT.Size=UDim2.new(1,-8,1,-76)
CONTENT.Position=UDim2.new(0,4,0,72)
CONTENT.BackgroundTransparency=1
CONTENT.Parent=MF

local PAGES,PBTNS={},{}
local TABNAMES={"Auto","Combat","Player","Misc"}

local function mkPage(name,idx)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,84,1,-4)
    btn.Position=UDim2.new(0,(idx-1)*88+2,0,2)
    btn.BackgroundColor3=Color3.fromRGB(22,22,36)
    btn.Text=name btn.TextColor3=Color3.fromRGB(150,150,150)
    btn.TextSize=11 btn.Font=Enum.Font.GothamSemibold
    btn.BorderSizePixel=0 btn.Parent=TABROW
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)

    local pg=Instance.new("ScrollingFrame")
    pg.Size=UDim2.new(1,0,1,0)
    pg.BackgroundTransparency=1
    pg.BorderSizePixel=0
    pg.ScrollBarThickness=3
    pg.AutomaticCanvasSize=Enum.AutomaticSize.Y
    pg.CanvasSize=UDim2.new(0,0,0,0)
    pg.Visible=idx==1
    pg.Parent=CONTENT
    local lay=Instance.new("UIListLayout")
    lay.Padding=UDim.new(0,4)
    lay.Parent=pg
    local pad=Instance.new("UIPadding")
    pad.PaddingTop=UDim.new(0,3)
    pad.PaddingLeft=UDim.new(0,1)
    pad.Parent=pg

    PAGES[name]=pg PBTNS[name]=btn
    btn.MouseButton1Click:Connect(function()
        for _,p in pairs(PAGES) do p.Visible=false end
        for _,b in pairs(PBTNS) do
            b.BackgroundColor3=Color3.fromRGB(22,22,36)
            b.TextColor3=Color3.fromRGB(150,150,150)
        end
        pg.Visible=true
        btn.BackgroundColor3=Color3.fromRGB(190,120,0)
        btn.TextColor3=Color3.new(1,1,1)
    end)
    if idx==1 then
        btn.BackgroundColor3=Color3.fromRGB(190,120,0)
        btn.TextColor3=Color3.new(1,1,1)
    end
end
for i,n in ipairs(TABNAMES) do mkPage(n,i) end

-- Helpers GUI
local function mkLbl(p,t)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-2,0,18)
    l.BackgroundTransparency=1
    l.Text=t l.TextColor3=Color3.fromRGB(255,175,0)
    l.TextSize=10 l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.Parent=p
end
local function mkSep(p)
    local s=Instance.new("Frame")
    s.Size=UDim2.new(1,-2,0,1)
    s.BackgroundColor3=Color3.fromRGB(190,120,0)
    s.BackgroundTransparency=0.6
    s.BorderSizePixel=0
    s.Parent=p
end
local function mkBtn(p,t,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-2,0,30)
    b.BackgroundColor3=Color3.fromRGB(24,24,40)
    b.Text=t b.TextColor3=Color3.new(1,1,1)
    b.TextSize=10 b.Font=Enum.Font.GothamSemibold
    b.BorderSizePixel=0 b.Parent=p
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    local sk=Instance.new("UIStroke",b)
    sk.Color=Color3.fromRGB(190,120,0)
    sk.Thickness=1 sk.Transparency=0.5
    b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(45,32,8) end)
    b.MouseLeave:Connect(function() b.BackgroundColor3=Color3.fromRGB(24,24,40) end)
end

local knobs={}
local function mkToggle(p,t,key,fn)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,-2,0,32)
    row.BackgroundColor3=Color3.fromRGB(16,16,26)
    row.BorderSizePixel=0
    row.Parent=p
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-52,1,0)
    lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=t lbl.TextColor3=Color3.fromRGB(205,205,205)
    lbl.TextSize=10 lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=row

    local track=Instance.new("TextButton")
    track.Size=UDim2.new(0,40,0,18)
    track.Position=UDim2.new(1,-44,0.5,-9)
    track.BackgroundColor3=Color3.fromRGB(55,55,55)
    track.Text="" track.BorderSizePixel=0
    track.Parent=row
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,13,0,13)
    knob.Position=UDim2.new(0,3,0.5,-6.5)
    knob.BackgroundColor3=Color3.new(1,1,1)
    knob.BorderSizePixel=0
    knob.Parent=track
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local function upd()
        local on=T[key]
        TS:Create(knob,TweenInfo.new(0.1),{
            Position=on and UDim2.new(1,-16,0.5,-6.5) or UDim2.new(0,3,0.5,-6.5)
        }):Play()
        track.BackgroundColor3=on and Color3.fromRGB(190,120,0) or Color3.fromRGB(55,55,55)
    end
    knobs[key]={upd=upd}

    track.MouseButton1Click:Connect(function()
        T[key]=not T[key]
        upd()
        if fn then fn(T[key]) end
    end)
end

-- ================================================
-- ABA AUTO
-- ================================================
local aP=PAGES["Auto"]
mkLbl(aP,"Automacao de Sobrevivencia")
mkSep(aP)
mkToggle(aP,"Auto Comer (vai a comida)","AutoEat",setAutoEat)
mkToggle(aP,"Auto Beber (vai a agua)","AutoDrink",setAutoDrink)
mkToggle(aP,"Auto Farm (vai a animais e ataca)","AutoFarm",setAutoFarm)
mkToggle(aP,"Auto Respawn (respawn ao morrer)","AutoRespawn",setAutoRespawn)
mkToggle(aP,"Anti AFK (nao desconecta)","AntiAFK",setAntiAFK)
mkSep(aP)
mkLbl(aP,"Raio do Auto Farm")
mkBtn(aP,"Raio: 40 studs",function() CFG.FarmRange=40 N("Farm","Raio 40") end)
mkBtn(aP,"Raio: 60 studs",function() CFG.FarmRange=60 N("Farm","Raio 60") end)
mkBtn(aP,"Raio: 100 studs",function() CFG.FarmRange=100 N("Farm","Raio 100") end)

-- ================================================
-- ABA COMBAT
-- ================================================
local cP=PAGES["Combat"]
mkLbl(cP,"Combate")
mkSep(cP)
mkToggle(cP,"Kill Aura (ataca no raio)","KillAura",setKillAura)
mkSep(cP)
mkLbl(cP,"Raio Kill Aura")
mkBtn(cP,"Raio: 10 studs",function() CFG.KillRange=10 N("KillAura","Raio 10") end)
mkBtn(cP,"Raio: 20 studs",function() CFG.KillRange=20 N("KillAura","Raio 20") end)
mkBtn(cP,"Raio: 35 studs",function() CFG.KillRange=35 N("KillAura","Raio 35") end)
mkBtn(cP,"Raio: 50 studs",function() CFG.KillRange=50 N("KillAura","Raio 50") end)
mkSep(cP)
mkLbl(cP,"ESP")
mkToggle(cP,"ESP Animais (nome + dist + HP%)","ESPAnimals",setESPAnimals)
mkToggle(cP,"ESP Comida/Agua no mapa","ESPFood",setESPFood)

-- ================================================
-- ABA PLAYER
-- ================================================
local pP=PAGES["Player"]
mkLbl(pP,"Player / Animal Hacks")
mkSep(pP)
mkToggle(pP,"God Mode (HP+Fome+Sede max)","GodMode",setGodMode)
mkToggle(pP,"Stamina Infinita","InfStamina",setStamina)
mkToggle(pP,"Speed Hack","Speed",setSpeed)
mkToggle(pP,"Pulo Infinito","InfJump",setInfJump)
mkToggle(pP,"No Clip (atravessa paredes)","NoClip",setNoClip)
mkSep(pP)
mkLbl(pP,"Velocidade")
mkBtn(pP,"16 - Normal",function()
    CFG.Speed=16
    if T.Speed then setSpeed(true) else local h=Hum() if h then h.WalkSpeed=16 end end
end)
mkBtn(pP,"32 - Rapido",function()
    CFG.Speed=32
    if T.Speed then setSpeed(true) end
end)
mkBtn(pP,"60 - Muito Rapido",function()
    CFG.Speed=60
    if T.Speed then setSpeed(true) end
end)
mkBtn(pP,"100 - Maximo",function()
    CFG.Speed=100
    if T.Speed then setSpeed(true) end
end)
mkSep(pP)
mkLbl(pP,"Teleportes")
mkBtn(pP,"Ir para Agua mais proxima",function() tpNearest(WATER_KW,"Agua") end)
mkBtn(pP,"Ir para Comida mais proxima",function() tpNearest(FOOD_KW,"Comida") end)
mkBtn(pP,"Ir para Animal mais proximo",function() tpNearestAnimal() end)
mkBtn(pP,"Ir para Spawn (0,5,0)",function()
    local hrp=HRP()
    if hrp then hrp.CFrame=CFrame.new(0,5,0) N("TP","Spawn!") end
end)

-- ================================================
-- ABA MISC
-- ================================================
local mP=PAGES["Misc"]
mkLbl(mP,"Ferramentas")
mkSep(mP)
mkBtn(mP,"Ver Ping",function()
    N("Ping",math.floor(LP:GetNetworkPing()*1000).."ms")
end)
mkBtn(mP,"Copiar UserID",function()
    pcall(function() setclipboard(tostring(LP.UserId)) end)
    N("UserID","Copiado: "..LP.UserId)
end)
mkBtn(mP,"Listar Remotes no Console (F9)",function()
    local list={}
    for _,v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            list[#list+1]=v:GetFullName()
        end
    end
    table.sort(list)
    print("\n=== REMOTES ="..#list.." ===")
    for _,n in ipairs(list) do print(n) end
    N("Remotes",#list.." remotes no F9!")
end)
mkBtn(mP,"Info Char + Stats (F9)",function()
    local c=Chr() if not c then N("Info","Sem char") return end
    local h=Hum()
    print("\n=== CHAR: "..c.Name.." ===")
    if h then print("HP: "..h.Health.."/"..h.MaxHealth) print("Speed: "..h.WalkSpeed) end
    for _,v in ipairs(c:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("StringValue") then
            print(v:GetFullName().." = "..tostring(v.Value))
        end
    end
    N("Info","Impresso no F9!")
end)
mkBtn(mP,"Rejoin",function()
    TEL:Teleport(game.PlaceId,LP)
end)
mkBtn(mP,"Server Hop (servidor vazio)",function()
    local ok,res=pcall(function()
        return HTTP:JSONDecode(HTTP:GetAsync(
            "https://games.roproxy.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        ))
    end)
    if ok and res and res.data then
        for _,s in ipairs(res.data) do
            if s.id~=game.JobId and s.playing<s.maxPlayers-1 then
                TEL:TeleportToPlaceInstance(game.PlaceId,s.id,LP)
                return
            end
        end
    end
    N("Server Hop","Nenhum servidor vazio.")
end)
mkSep(mP)
mkBtn(mP,"Resetar TUDO",function()
    for key,_ in pairs(T) do
        if T[key] then
            T[key]=false
            if knobs[key] then knobs[key].upd() end
        end
    end
    setGodMode(false) setStamina(false) setSpeed(false)
    setNoClip(false) setInfJump(false) setKillAura(false)
    setAutoFarm(false) setAutoEat(false) setAutoDrink(false)
    setESPAnimals(false) setESPFood(false)
    setAutoRespawn(false) setAntiAFK(false)
    N("Reset","Tudo desativado!")
end)
mkBtn(mP,"Fechar Hub",function() GUI:Destroy() end)

-- ================================================
-- DRAG
-- ================================================
local _drag,_ds,_dp=false
TOP.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        _drag=true _ds=i.Position _dp=MF.Position
    end
end)
TOP.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then _drag=false end
end)
UIS.InputChanged:Connect(function(i)
    if _drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-_ds
        MF.Position=UDim2.new(_dp.X.Scale,_dp.X.Offset+d.X,_dp.Y.Scale,_dp.Y.Offset+d.Y)
    end
end)

-- INSERT toggle
UIS.InputBegan:Connect(function(i,gpe)
    if not gpe and i.KeyCode==Enum.KeyCode.Insert then
        MF.Visible=not MF.Visible
    end
end)

-- ================================================
-- INICIO
-- ================================================
task.wait(0.5)
N("Savannah Life Hub v3","Carregado! INSERT = abrir/fechar")
print("[SavannahHub v3] OK | TochZero")
