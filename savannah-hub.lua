-- ================================================
-- SAVANNAH LIFE HUB v4 | TochZero | 2026
-- Vida de Savana - NOYO Productions
-- Delta Executor | FIXED: TP, GodMode, KillAura
-- ================================================

local Players    = game:GetService("Players")
local RS         = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TS         = game:GetService("TweenService")
local HTTP       = game:GetService("HttpService")
local TEL        = game:GetService("TeleportService")
local SGui       = game:GetService("StarterGui")
local RepS       = game:GetService("ReplicatedStorage")
local Debris     = game:GetService("Debris")
local LP         = Players.LocalPlayer
local WS         = workspace

pcall(function()
    game:GetService("CoreGui"):FindFirstChild("SavannahHub"):Destroy()
end)

-- ================================================
-- NOTIFICACAO
-- ================================================
local function N(t,m,d)
    pcall(function()
        SGui:SetCore("SendNotification",{Title=t,Text=m,Duration=d or 4})
    end)
end

-- ================================================
-- ESTADO
-- ================================================
local T = {
    GodMode=false,InfStamina=false,Speed=false,
    NoClip=false,InfJump=false,KillAura=false,
    AutoFarm=false,AutoEat=false,AutoDrink=false,
    ESPAnimals=false,ESPFood=false,
    AutoRespawn=false,AntiAFK=false,AutoCoins=false,
}
local CFG = {Speed=50,KillRange=20,FarmRange=60}

local CONN = {}
local function off(k)
    if CONN[k] then pcall(function() CONN[k]:Disconnect() end) CONN[k]=nil end
end

-- ================================================
-- HELPERS
-- ================================================
local function Chr()  return LP.Character end
local function HRP()  local c=Chr() return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum()  local c=Chr() return c and c:FindFirstChildOfClass("Humanoid") end

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

local FOOD_KW  ={"meat","carcass","corpse","berry","fruit","grass","herb","prey","food","flesh","plant","kill","bone"}
local WATER_KW ={"water","lake","river","pond","oasis","drink","pool","puddle"}
local COIN_KW  ={"coin","gold","cash","token","money","gem","reward","collectible"}

local function getNearestPart(keywords)
    local hrp=HRP() if not hrp then return nil,0 end
    local best,bd=nil,math.huge
    for _,obj in ipairs(WS:GetDescendants()) do
        local n=obj.Name:lower()
        for _,kw in ipairs(keywords) do
            if n:find(kw) then
                local p=obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
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

-- Scan remotes por palavra-chave
local function getRemotes(keywords)
    local out={}
    for _,v in ipairs(RepS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n=v.Name:lower()
            for _,kw in ipairs(keywords) do
                if n:find(kw) then out[#out+1]=v break end
            end
        end
    end
    return out
end

-- ================================================
-- TELEPORTE ANTI-REVERTER
-- Jogo tenta teleportar de volta? Loop mantém posição
-- ================================================
local _tpTarget=nil  -- {pos=Vector3, frames=int}
local _tpHold=false

local function tpSafe(pos)
    local hrp=HRP() if not hrp then return end
    _tpTarget={pos=pos,frames=0}
    _tpHold=true
    hrp.CFrame=CFrame.new(pos)
end

-- Loop que mantém posição por 90 frames (~1.5s) após teleporte
CONN["tphold"]=RS.Heartbeat:Connect(function()
    if not _tpHold or not _tpTarget then return end
    local hrp=HRP() if not hrp then _tpHold=false return end
    _tpTarget.frames=_tpTarget.frames+1
    if _tpTarget.frames<=90 then
        hrp.CFrame=CFrame.new(_tpTarget.pos)
    else
        _tpHold=false
        _tpTarget=nil
    end
end)

local function tpTo(part)
    if not part then return false end
    local p=part:IsA("BasePart") and part.Position or part
    tpSafe(p+Vector3.new(0,4,0))
    return true
end

local function tpNearest(kw,label)
    local p,d=getNearestPart(kw)
    if p then
        tpTo(p)
        N("Teleporte",label.." encontrado! "..math.floor(d).."m")
    else
        N("Teleporte",label.." nao encontrado no mapa")
    end
end

local function tpNearestAnimal()
    local hrp=HRP() if not hrp then return end
    local best,bd=nil,math.huge
    for _,a in ipairs(getAnimals()) do
        local d=(hrp.Position-a.root.Position).Magnitude
        if d<bd and d>3 then best=a bd=d end
    end
    if best then
        tpSafe(best.root.Position+Vector3.new(0,3,3))
        N("Teleporte",best.model.Name.." "..math.floor(bd).."m")
    else
        N("Teleporte","Nenhum animal encontrado")
    end
end

-- ================================================
-- 1. GOD MODE - Agressivo
-- Bloqueia: Humanoid.Health, HealthChanged, Died
-- E trava valores via NumberValue.Changed
-- ================================================
local _godConns={}
local function setGodMode(on)
    off("god")
    for _,c in ipairs(_godConns) do pcall(function() c:Disconnect() end) end
    _godConns={}

    if not on then N("God Mode","OFF") return end

    local function protectChar(c)
        if not c then return end
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then
            -- Bloqueia morte
            h:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
            -- Trava HP a cada mudanca
            _godConns[#_godConns+1]=h.HealthChanged:Connect(function(hp)
                if hp<h.MaxHealth then
                    h.Health=h.MaxHealth
                end
            end)
            -- Bloqueia evento Died
            _godConns[#_godConns+1]=h.Died:Connect(function()
                h.Health=h.MaxHealth
            end)
        end
        -- Trava todos NumberValues de stats
        for _,v in ipairs(c:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n=v.Name:lower()
                if n:find("hunger") or n:find("thirst") or n:find("food")
                    or n:find("water") or n:find("health") or n:find("hp") then
                    local conn=v.Changed:Connect(function(val)
                        local mx=v.Parent:FindFirstChild("Max")
                        local target=mx and mx.Value or 100
                        if val<target*0.99 then
                            pcall(function() v.Value=target end)
                        end
                    end)
                    _godConns[#_godConns+1]=conn
                end
            end
        end
        -- Atributos
        _godConns[#_godConns+1]=c.AttributeChanged:Connect(function(attr)
            local n=attr:lower()
            if n:find("hunger") or n:find("thirst") or n:find("food")
                or n:find("water") or n:find("health") or n:find("hp") then
                pcall(function()
                    local val=c:GetAttribute(attr)
                    if type(val)=="number" and val<100 then
                        c:SetAttribute(attr,100)
                    end
                end)
            end
        end)
    end

    -- Protege char atual e futuros
    protectChar(Chr())
    _godConns[#_godConns+1]=LP.CharacterAdded:Connect(function(c)
        task.wait(0.3)
        protectChar(c)
    end)

    -- Heartbeat como backup
    CONN["god"]=RS.Heartbeat:Connect(function()
        local h=Hum()
        if h and h.Health<h.MaxHealth then
            pcall(function() h.Health=h.MaxHealth end)
        end
        local c=Chr() if not c then return end
        for _,name in ipairs({"Hunger","Thirst","Food","Water","Stamina","Energy"}) do
            pcall(function()
                local val=c:GetAttribute(name)
                if type(val)=="number" and val<100 then c:SetAttribute(name,100) end
            end)
        end
    end)

    N("God Mode","HP + Fome + Sede bloqueados!")
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
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local n=v.Name:lower()
                    if n=="stamina" or n=="energy" or n=="sprint" or n=="endurance" or n=="fatigue" then
                        pcall(function()
                            local mx=v.Parent:FindFirstChild("Max")
                            local maxVal=mx and mx.Value or 100
                            if v.Value<maxVal then v.Value=maxVal end
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
-- 3. SPEED
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
        N("Speed","Normal")
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
        N("NoClip","ON")
    else N("NoClip","OFF") end
end

-- ================================================
-- 5. INFINITE JUMP
-- ================================================
local _ijConn
local function setInfJump(on)
    if _ijConn then _ijConn:Disconnect() _ijConn=nil end
    if on then
        _ijConn=UIS.JumpRequest:Connect(function()
            local h=Hum()
            if h and h:GetState()~=Enum.HumanoidStateType.Jumping then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        N("Inf Jump","ON")
    else N("Inf Jump","OFF") end
end

-- ================================================
-- 6. KILL AURA - Metodos multiplos
-- ================================================
local function setKillAura(on)
    off("killaura")
    if not on then N("Kill Aura","OFF") return end

    local _tick=0
    CONN["killaura"]=RS.Heartbeat:Connect(function(dt)
        _tick=_tick+dt
        if _tick<0.1 then return end  -- executa a cada 0.1s, nao todo frame
        _tick=0

        local hrp=HRP() if not hrp then return end
        local c=Chr()

        for _,a in ipairs(getAnimals()) do
            local dist=(hrp.Position-a.root.Position).Magnitude
            if dist<=CFG.KillRange then

                -- METODO 1: Forcar HP zero diretamente (mais efetivo)
                pcall(function()
                    a.hum.Health=0
                end)

                -- METODO 2: Remotes de ataque com multiplos args
                for _,v in ipairs(getRemotes({"attack","bite","damage","hit","slash","claw","kill","hurt"})) do
                    pcall(function() v:FireServer(a.model,a.root,a.root.Position,100) end)
                    pcall(function() v:FireServer(a.hum) end)
                    pcall(function() v:FireServer(a.root.Position) end)
                end

                -- METODO 3: Tool equipada - move handle até o alvo
                if c then
                    local tool=c:FindFirstChildOfClass("Tool")
                    if tool then
                        local handle=tool:FindFirstChild("Handle")
                        if handle then
                            local savedCF=handle.CFrame
                            handle.CFrame=a.root.CFrame
                            task.defer(function()
                                pcall(function() handle.CFrame=savedCF end)
                            end)
                        end
                        for _,rem in ipairs(tool:GetDescendants()) do
                            if rem:IsA("RemoteEvent") then
                                pcall(function() rem:FireServer(a.root.Position) end)
                                pcall(function() rem:FireServer(a.model) end)
                            end
                        end
                    end
                end

                -- METODO 4: Knockback com LinearVelocity (dano fisico)
                pcall(function()
                    local att=Instance.new("Attachment")
                    att.Parent=a.root
                    local lv=Instance.new("LinearVelocity")
                    lv.Attachment0=att
                    lv.MaxForce=math.huge
                    lv.VectorVelocity=(a.root.Position-hrp.Position).Unit*200
                    lv.Parent=a.root
                    Debris:AddItem(lv,0.05)
                    Debris:AddItem(att,0.05)
                end)
            end
        end
    end)
    N("Kill Aura","Raio "..CFG.KillRange.." ON!")
end

-- ================================================
-- 7. AUTO FARM
-- Teleporte contínuo antireverte + ataque
-- ================================================
local _farmRun=false
local function setAutoFarm(on)
    _farmRun=on
    if not on then N("Auto Farm","OFF") return end
    N("Auto Farm","Farmando!")
    task.spawn(function()
        while _farmRun do
            task.wait(0.15)
            local hrp=HRP() if not hrp then continue end
            local animals=getAnimals()
            local best,bd=nil,math.huge
            for _,a in ipairs(animals) do
                local d=(hrp.Position-a.root.Position).Magnitude
                if d<bd and d<=CFG.FarmRange then best=a bd=d end
            end
            if best then
                local targetPos=best.root.Position+Vector3.new(0,2,2)
                -- Teleporte continuo (antireverte por 90 frames via loop tphold)
                tpSafe(targetPos)
                task.wait(0.1)
                -- Mata o alvo
                pcall(function() best.hum.Health=0 end)
                -- Remotes de ataque
                for _,v in ipairs(getRemotes({"attack","bite","damage","hit","kill","hurt","claw"})) do
                    pcall(function() v:FireServer(best.model,best.root,100) end)
                    pcall(function() v:FireServer(best.hum) end)
                end
                -- Tool
                local c=Chr()
                if c then
                    local tool=c:FindFirstChildOfClass("Tool")
                    if tool then
                        for _,rem in ipairs(tool:GetDescendants()) do
                            if rem:IsA("RemoteEvent") then
                                pcall(function() rem:FireServer(best.root.Position) end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ================================================
-- 8. AUTO COMER
-- ================================================
local _eatRun=false
local function setAutoEat(on)
    _eatRun=on
    if not on then N("Auto Eat","OFF") return end
    N("Auto Eat","Comendo automaticamente!")
    task.spawn(function()
        while _eatRun do
            task.wait(0.8)
            local p,d=getNearestPart(FOOD_KW)
            if p then
                local hrp=HRP() if not hrp then continue end
                tpSafe(p.Position+Vector3.new(0,3,0))
                task.wait(0.15)
                -- Toca o item
                pcall(function() p.Touched:Fire(hrp) end)
                -- Remotes de comer
                for _,v in ipairs(getRemotes({"eat","consume","feed","food","hunger","interact"})) do
                    pcall(function() v:FireServer(p.Parent or p) end)
                    pcall(function() v:FireServer(p) end)
                end
            end
        end
    end)
end

-- ================================================
-- 9. AUTO BEBER
-- ================================================
local _drinkRun=false
local function setAutoDrink(on)
    _drinkRun=on
    if not on then N("Auto Drink","OFF") return end
    N("Auto Drink","Bebendo automaticamente!")
    task.spawn(function()
        while _drinkRun do
            task.wait(0.8)
            local p,d=getNearestPart(WATER_KW)
            if p then
                local hrp=HRP() if not hrp then continue end
                tpSafe(p.Position+Vector3.new(0,2,0))
                task.wait(0.15)
                pcall(function() p.Touched:Fire(hrp) end)
                for _,v in ipairs(getRemotes({"drink","water","thirst","hydrat","interact"})) do
                    pcall(function() v:FireServer(p.Parent or p) end)
                    pcall(function() v:FireServer(p) end)
                end
            end
        end
    end)
end

-- ================================================
-- 10. AUTO MOEDAS
-- ================================================
local _coinRun=false
local function setAutoCoins(on)
    _coinRun=on
    if not on then N("Auto Moedas","OFF") return end
    N("Auto Moedas","Coletando moedas!")
    task.spawn(function()
        while _coinRun do
            task.wait(0.5)
            local hrp=HRP() if not hrp then continue end

            -- Toca todas moedas próximas
            local found=0
            for _,obj in ipairs(WS:GetDescendants()) do
                local n=obj.Name:lower()
                for _,kw in ipairs(COIN_KW) do
                    if n:find(kw) then
                        local p=obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                        if p then
                            found=found+1
                            tpSafe(p.Position+Vector3.new(0,2,0))
                            task.wait(0.05)
                            pcall(function() p.Touched:Fire(hrp) end)
                            -- Remotes de coleta
                            for _,v in ipairs(getRemotes({"collect","coin","gold","token","reward","pickup","grab","earn"})) do
                                pcall(function() v:FireServer(obj) end)
                                pcall(function() v:FireServer(p) end)
                            end
                        end
                        break
                    end
                end
                if found>=5 then break end -- coleta 5 por ciclo
            end
        end
    end)
end

-- ================================================
-- 11. ESP ANIMAIS
-- ================================================
local _espAConn
local function setESPAnimals(on)
    if _espAConn then _espAConn:Disconnect() _espAConn=nil end
    for _,v in ipairs(WS:GetDescendants()) do
        if v.Name=="_AESP" then pcall(function() v:Destroy() end) end
    end
    if not on then N("ESP Animais","OFF") return end
    local tracked={}
    _espAConn=RS.Heartbeat:Connect(function()
        local hrp=HRP()
        for _,a in ipairs(getAnimals()) do
            if a.root.Parent and not a.root:FindFirstChild("_AESP") then
                local bb=Instance.new("BillboardGui")
                bb.Name="_AESP" bb.AlwaysOnTop=true
                bb.Size=UDim2.new(0,140,0,30) bb.StudsOffset=Vector3.new(0,4,0)
                bb.Parent=a.root
                local lbl=Instance.new("TextLabel")
                lbl.Size=UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency=1
                lbl.Font=Enum.Font.GothamBold lbl.TextSize=12
                lbl.TextStrokeTransparency=0 lbl.Parent=bb
                tracked[bb]={lbl=lbl,hum=a.hum,root=a.root,name=a.model.Name}
            end
        end
        for bb,info in pairs(tracked) do
            if not bb.Parent then tracked[bb]=nil continue end
            local dist=hrp and math.floor((hrp.Position-info.root.Position).Magnitude) or 0
            local pct=info.hum.MaxHealth>0 and math.floor(info.hum.Health/info.hum.MaxHealth*100) or 0
            info.lbl.Text=info.name.." ["..dist.."m] "..pct.."%"
            info.lbl.TextColor3=pct<30 and Color3.fromRGB(255,50,50)
                or pct<60 and Color3.fromRGB(255,200,0)
                or Color3.fromRGB(80,255,80)
        end
    end)
    N("ESP Animais","ON")
end

-- ================================================
-- 12. ESP COMIDA
-- ================================================
local _espFConn
local function setESPFood(on)
    if _espFConn then _espFConn:Disconnect() _espFConn=nil end
    for _,v in ipairs(WS:GetDescendants()) do
        if v.Name=="_FESP" then pcall(function() v:Destroy() end) end
    end
    if not on then N("ESP Comida","OFF") return end
    _espFConn=RS.Heartbeat:Connect(function()
        for _,obj in ipairs(WS:GetDescendants()) do
            if not obj:IsA("BasePart") or obj:FindFirstChild("_FESP") then continue end
            local n=obj.Name:lower()
            local isF,isW=false,false
            for _,kw in ipairs(FOOD_KW)  do if n:find(kw) then isF=true break end end
            for _,kw in ipairs(WATER_KW) do if n:find(kw) then isW=true break end end
            local isC=false
            for _,kw in ipairs(COIN_KW)  do if n:find(kw) then isC=true break end end
            if isF or isW or isC then
                local bb=Instance.new("BillboardGui")
                bb.Name="_FESP" bb.AlwaysOnTop=true
                bb.Size=UDim2.new(0,100,0,20) bb.StudsOffset=Vector3.new(0,2.5,0)
                bb.Parent=obj
                local lbl=Instance.new("TextLabel")
                lbl.Size=UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency=1
                lbl.Font=Enum.Font.GothamBold lbl.TextSize=10
                lbl.TextStrokeTransparency=0
                lbl.TextColor3=isC and Color3.fromRGB(255,220,0)
                    or isW and Color3.fromRGB(50,180,255)
                    or Color3.fromRGB(80,255,80)
                lbl.Text=(isC and "Moeda" or isW and "Agua" or "Comida").." "..obj.Name
                lbl.Parent=bb
            end
        end
    end)
    N("ESP Comida/Moedas","Verde=Comida Azul=Agua Amarelo=Moeda")
end

-- ================================================
-- 13. AUTO RESPAWN
-- ================================================
local _respLock=false
local function setAutoRespawn(on)
    off("respawn")
    if not on then N("Auto Respawn","OFF") return end
    CONN["respawn"]=RS.Heartbeat:Connect(function()
        local h=Hum()
        if h and h.Health<=0 and not _respLock then
            _respLock=true
            task.delay(1.5,function()
                pcall(function() LP:LoadCharacter() end)
                task.wait(3) _respLock=false
            end)
        end
    end)
    N("Auto Respawn","ON")
end

-- ================================================
-- 14. ANTI AFK
-- ================================================
local _afkRun=false
local function setAntiAFK(on)
    _afkRun=on
    if not on then N("Anti AFK","OFF") return end
    task.spawn(function()
        while _afkRun do
            task.wait(55)
            if not _afkRun then break end
            local h=Hum()
            if h then
                local s=h.WalkSpeed
                h.WalkSpeed=0.001 task.wait(0.05) h.WalkSpeed=s
            end
        end
    end)
    N("Anti AFK","Nao sera desconectado!")
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
MF.Size=UDim2.new(0,365,0,510)
MF.Position=UDim2.new(0,16,0.5,-255)
MF.BackgroundColor3=Color3.fromRGB(9,9,15)
MF.BorderSizePixel=0 MF.Parent=GUI
Instance.new("UICorner",MF).CornerRadius=UDim.new(0,10)
local mfSt=Instance.new("UIStroke",MF)
mfSt.Color=Color3.fromRGB(200,130,0) mfSt.Thickness=2

local TOP=Instance.new("Frame")
TOP.Size=UDim2.new(1,0,0,38)
TOP.BackgroundColor3=Color3.fromRGB(16,9,3)
TOP.BorderSizePixel=0 TOP.Parent=MF
Instance.new("UICorner",TOP).CornerRadius=UDim.new(0,10)

local TL=Instance.new("TextLabel")
TL.Size=UDim2.new(1,-72,1,0)
TL.Position=UDim2.new(0,8,0,0)
TL.BackgroundTransparency=1
TL.Text="Savannah Hub v4"
TL.TextColor3=Color3.fromRGB(255,175,0)
TL.TextSize=13 TL.Font=Enum.Font.GothamBold
TL.TextXAlignment=Enum.TextXAlignment.Left
TL.Parent=TOP

local function mkTopBtn(txt,col,ox)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,24)
    b.Position=UDim2.new(1,ox,0,7)
    b.BackgroundColor3=col b.Text=txt
    b.TextColor3=Color3.new(1,1,1)
    b.TextSize=11 b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0 b.Parent=TOP
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end
local _min=false
mkTopBtn("X",Color3.fromRGB(160,30,30),-30).MouseButton1Click:Connect(function()
    MF.Visible=not MF.Visible
end)
mkTopBtn("-",Color3.fromRGB(45,45,65),-60).MouseButton1Click:Connect(function()
    _min=not _min
    for _,c in ipairs(MF:GetChildren()) do
        if c~=TOP then c.Visible=not _min end
    end
    MF.Size=_min and UDim2.new(0,365,0,38) or UDim2.new(0,365,0,510)
end)

local TABROW=Instance.new("Frame")
TABROW.Size=UDim2.new(1,0,0,28)
TABROW.Position=UDim2.new(0,0,0,40)
TABROW.BackgroundColor3=Color3.fromRGB(13,13,21)
TABROW.BorderSizePixel=0 TABROW.Parent=MF

local CONT=Instance.new("Frame")
CONT.Size=UDim2.new(1,-8,1,-76)
CONT.Position=UDim2.new(0,4,0,72)
CONT.BackgroundTransparency=1 CONT.Parent=MF

local PAGES,PBTNS={},{}
local TABS={"Auto","Combat","Player","Misc"}

local function mkPage(name,idx)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,84,1,-4)
    btn.Position=UDim2.new(0,(idx-1)*88+2,0,2)
    btn.BackgroundColor3=Color3.fromRGB(20,20,34)
    btn.Text=name btn.TextColor3=Color3.fromRGB(145,145,145)
    btn.TextSize=11 btn.Font=Enum.Font.GothamSemibold
    btn.BorderSizePixel=0 btn.Parent=TABROW
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)

    local pg=Instance.new("ScrollingFrame")
    pg.Size=UDim2.new(1,0,1,0)
    pg.BackgroundTransparency=1 pg.BorderSizePixel=0
    pg.ScrollBarThickness=3
    pg.AutomaticCanvasSize=Enum.AutomaticSize.Y
    pg.CanvasSize=UDim2.new(0,0,0,0)
    pg.Visible=idx==1 pg.Parent=CONT
    local lay=Instance.new("UIListLayout")
    lay.Padding=UDim.new(0,4) lay.Parent=pg
    local pad=Instance.new("UIPadding")
    pad.PaddingTop=UDim.new(0,3)
    pad.PaddingLeft=UDim.new(0,1) pad.Parent=pg

    PAGES[name]=pg PBTNS[name]=btn
    btn.MouseButton1Click:Connect(function()
        for _,p in pairs(PAGES) do p.Visible=false end
        for _,b in pairs(PBTNS) do
            b.BackgroundColor3=Color3.fromRGB(20,20,34)
            b.TextColor3=Color3.fromRGB(145,145,145)
        end
        pg.Visible=true
        btn.BackgroundColor3=Color3.fromRGB(185,115,0)
        btn.TextColor3=Color3.new(1,1,1)
    end)
    if idx==1 then
        btn.BackgroundColor3=Color3.fromRGB(185,115,0)
        btn.TextColor3=Color3.new(1,1,1)
    end
end
for i,n in ipairs(TABS) do mkPage(n,i) end

local function mkLbl(p,t)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-2,0,17)
    l.BackgroundTransparency=1
    l.Text=t l.TextColor3=Color3.fromRGB(255,175,0)
    l.TextSize=10 l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.Parent=p
end
local function mkSep(p)
    local s=Instance.new("Frame")
    s.Size=UDim2.new(1,-2,0,1)
    s.BackgroundColor3=Color3.fromRGB(185,115,0)
    s.BackgroundTransparency=0.6
    s.BorderSizePixel=0 s.Parent=p
end
local function mkBtn(p,t,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-2,0,30)
    b.BackgroundColor3=Color3.fromRGB(22,22,38)
    b.Text=t b.TextColor3=Color3.new(1,1,1)
    b.TextSize=10 b.Font=Enum.Font.GothamSemibold
    b.BorderSizePixel=0 b.Parent=p
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    local sk=Instance.new("UIStroke",b)
    sk.Color=Color3.fromRGB(185,115,0) sk.Thickness=1 sk.Transparency=0.5
    b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(42,30,7) end)
    b.MouseLeave:Connect(function() b.BackgroundColor3=Color3.fromRGB(22,22,38) end)
end

local knobs={}
local function mkToggle(p,t,key,fn)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,-2,0,32)
    row.BackgroundColor3=Color3.fromRGB(15,15,25)
    row.BorderSizePixel=0 row.Parent=p
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-50,1,0)
    lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=t lbl.TextColor3=Color3.fromRGB(200,200,200)
    lbl.TextSize=10 lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=row

    local track=Instance.new("TextButton")
    track.Size=UDim2.new(0,40,0,18)
    track.Position=UDim2.new(1,-44,0.5,-9)
    track.BackgroundColor3=Color3.fromRGB(50,50,50)
    track.Text="" track.BorderSizePixel=0
    track.Parent=row
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,13,0,13)
    knob.Position=UDim2.new(0,3,0.5,-6.5)
    knob.BackgroundColor3=Color3.new(1,1,1)
    knob.BorderSizePixel=0 knob.Parent=track
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local function upd()
        local on=T[key]
        TS:Create(knob,TweenInfo.new(0.1),{
            Position=on and UDim2.new(1,-16,0.5,-6.5) or UDim2.new(0,3,0.5,-6.5)
        }):Play()
        track.BackgroundColor3=on and Color3.fromRGB(185,115,0) or Color3.fromRGB(50,50,50)
    end
    knobs[key]=upd
    track.MouseButton1Click:Connect(function()
        T[key]=not T[key] upd()
        if fn then fn(T[key]) end
    end)
end

-- ================================================
-- ABA AUTO
-- ================================================
local aP=PAGES["Auto"]
mkLbl(aP,"Automacao de Sobrevivencia")
mkSep(aP)
mkToggle(aP,"Auto Comer (teleporta + come)","AutoEat",setAutoEat)
mkToggle(aP,"Auto Beber (teleporta + bebe)","AutoDrink",setAutoDrink)
mkToggle(aP,"Auto Farm (teleporta + ataca)","AutoFarm",setAutoFarm)
mkToggle(aP,"Auto Moedas (coleta moedas)","AutoCoins",setAutoCoins)
mkToggle(aP,"Auto Respawn ao morrer","AutoRespawn",setAutoRespawn)
mkToggle(aP,"Anti AFK","AntiAFK",setAntiAFK)
mkSep(aP)
mkLbl(aP,"Raio Auto Farm")
mkBtn(aP,"40 studs",function() CFG.FarmRange=40 N("Farm","40") end)
mkBtn(aP,"60 studs",function() CFG.FarmRange=60 N("Farm","60") end)
mkBtn(aP,"100 studs",function() CFG.FarmRange=100 N("Farm","100") end)

-- ================================================
-- ABA COMBAT
-- ================================================
local cP=PAGES["Combat"]
mkLbl(cP,"Combate")
mkSep(cP)
mkToggle(cP,"Kill Aura (4 metodos de dano)","KillAura",setKillAura)
mkSep(cP)
mkLbl(cP,"Raio Kill Aura")
mkBtn(cP,"10 studs",function() CFG.KillRange=10 N("KA","10") end)
mkBtn(cP,"20 studs",function() CFG.KillRange=20 N("KA","20") end)
mkBtn(cP,"35 studs",function() CFG.KillRange=35 N("KA","35") end)
mkBtn(cP,"50 studs",function() CFG.KillRange=50 N("KA","50") end)
mkSep(cP)
mkLbl(cP,"ESP")
mkToggle(cP,"ESP Animais (dist + HP%)","ESPAnimals",setESPAnimals)
mkToggle(cP,"ESP Comida / Agua / Moedas","ESPFood",setESPFood)

-- ================================================
-- ABA PLAYER
-- ================================================
local pP=PAGES["Player"]
mkLbl(pP,"Player Hacks")
mkSep(pP)
mkToggle(pP,"God Mode (HP+Fome+Sede bloq.)","GodMode",setGodMode)
mkToggle(pP,"Stamina Infinita","InfStamina",setStamina)
mkToggle(pP,"Speed Hack","Speed",setSpeed)
mkToggle(pP,"Pulo Infinito","InfJump",setInfJump)
mkToggle(pP,"No Clip","NoClip",setNoClip)
mkSep(pP)
mkLbl(pP,"Velocidade")
mkBtn(pP,"16 - Normal",function()
    CFG.Speed=16 if T.Speed then setSpeed(true)
    else local h=Hum() if h then h.WalkSpeed=16 end end
end)
mkBtn(pP,"32 - Rapido",function() CFG.Speed=32 if T.Speed then setSpeed(true) end end)
mkBtn(pP,"60 - Muito Rapido",function() CFG.Speed=60 if T.Speed then setSpeed(true) end end)
mkBtn(pP,"100 - Maximo",function() CFG.Speed=100 if T.Speed then setSpeed(true) end end)
mkSep(pP)
mkLbl(pP,"Teleportes")
mkBtn(pP,"Ir para Agua mais proxima",function() tpNearest(WATER_KW,"Agua") end)
mkBtn(pP,"Ir para Comida mais proxima",function() tpNearest(FOOD_KW,"Comida") end)
mkBtn(pP,"Ir para Animal mais proximo",function() tpNearestAnimal() end)
mkBtn(pP,"Ir para Spawn",function()
    tpSafe(Vector3.new(0,5,0))
    N("TP","Spawn!")
end)
mkSep(pP)
mkLbl(pP,"Personagem")
mkBtn(pP,"Resetar Personagem",function()
    local h=Hum()
    if h then
        h.Health=0
        task.wait(0.5)
        pcall(function() LP:LoadCharacter() end)
        N("Reset","Personagem resetado!")
    end
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
mkBtn(mP,"Listar Remotes (F9)",function()
    local list={}
    for _,v in ipairs(RepS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            list[#list+1]=v:GetFullName()
        end
    end
    table.sort(list)
    print("\n=== REMOTES ("..#list..") ===")
    for _,n in ipairs(list) do print(n) end
    N("Remotes",#list.." no F9")
end)
mkBtn(mP,"Info Char + Stats (F9)",function()
    local c=Chr() if not c then N("Info","Sem char") return end
    local h=Hum()
    print("\n=== CHAR: "..c.Name.." ===")
    if h then print("HP: "..h.Health.."/"..h.MaxHealth.." | Speed: "..h.WalkSpeed) end
    for _,v in ipairs(c:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("StringValue") then
            print(v:GetFullName().." = "..tostring(v.Value))
        end
    end
    -- Atributos
    for k,v in pairs(c:GetAttributes()) do
        print("[Attr] "..k.." = "..tostring(v))
    end
    N("Info","Impresso no F9!")
end)
mkBtn(mP,"Rejoin",function()
    TEL:Teleport(game.PlaceId,LP)
end)
mkBtn(mP,"Server Hop",function()
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
    N("Server Hop","Nenhum servidor vazio")
end)
mkSep(mP)
mkBtn(mP,"RESETAR TUDO",function()
    for key in pairs(T) do
        if T[key] then T[key]=false
            if knobs[key] then knobs[key]() end
        end
    end
    setGodMode(false) setStamina(false) setSpeed(false)
    setNoClip(false) setInfJump(false) setKillAura(false)
    setAutoFarm(false) setAutoEat(false) setAutoDrink(false)
    setAutoCoins(false) setESPAnimals(false) setESPFood(false)
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
UIS.InputBegan:Connect(function(i,gpe)
    if not gpe and i.KeyCode==Enum.KeyCode.Insert then
        MF.Visible=not MF.Visible
    end
end)

-- ================================================
task.wait(0.5)
N("Savannah Hub v4","Carregado! INSERT = abrir/fechar")
print("[SavannahHub v4] OK | TochZero")
