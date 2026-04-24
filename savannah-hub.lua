-- ================================================
-- SAVANNAH LIFE HUB v5 | TochZero | 2026
-- Tecnicas reais de scripts funcionais publicos
-- Hitbox Expand | Grab Aura | Anti-Grab | Fly
-- Stamina LP attr | GodMode sethiddenproperty
-- ================================================

local Players   = game:GetService("Players")
local RS        = game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local TS        = game:GetService("TweenService")
local RepS      = game:GetService("ReplicatedStorage")
local Debris    = game:GetService("Debris")
local SGui      = game:GetService("StarterGui")
local TEL       = game:GetService("TeleportService")
local HTTP      = game:GetService("HttpService")
local LP        = Players.LocalPlayer
local WS        = workspace
local Cam       = WS.CurrentCamera

pcall(function()
    game:GetService("CoreGui"):FindFirstChild("SavannahHub"):Destroy()
end)

local function N(t,m,d)
    pcall(function()
        SGui:SetCore("SendNotification",{Title=t,Text=m,Duration=d or 4})
    end)
end

-- ================================================
-- ESTADO
-- ================================================
local T = {
    GodMode=false, InfStamina=false, InfOxygen=false,
    Speed=false, Fly=false, NoClip=false, InfJump=false,
    KillAura=false, HitboxExpand=false,
    GrabAura=false, AntiGrab=false,
    AutoFarm=false, AutoEat=false, AutoDrink=false,
    ESPAnimals=false, ESPItems=false,
    AutoRespawn=false, AntiAFK=false,
}
local CFG = {
    Speed       = 50,
    FlySpeed    = 80,
    KillRange   = 20,
    FarmRange   = 80,
    HitboxSize  = 12,
    GrabRange   = 25,
}

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

local FOOD_KW  = {"meat","carcass","corpse","berry","fruit","grass","herb","prey","food","flesh","plant","kill","bone","crab","fish","egg","mushroom","insect","bug","leaf"}
local WATER_KW = {"water","lake","river","pond","oasis","drink","pool","puddle","mud","swamp"}
local COIN_KW  = {"coin","gold","cash","token","money","gem","reward","collectible","xp","exp","score"}

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

local function getRemotes(kws)
    local out={}
    for _,v in ipairs(RepS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n=v.Name:lower()
            for _,kw in ipairs(kws) do
                if n:find(kw) then out[#out+1]=v break end
            end
        end
    end
    return out
end

-- ================================================
-- TELEPORTE ANTI-REVERTER (mantém 90 frames)
-- ================================================
local _tpTgt,_tpHold=nil,false
local function tpSafe(pos)
    local hrp=HRP() if not hrp then return end
    _tpTgt={pos=pos,f=0} _tpHold=true
    hrp.CFrame=CFrame.new(pos)
end
CONN["tphold"]=RS.Heartbeat:Connect(function()
    if not _tpHold or not _tpTgt then return end
    local hrp=HRP() if not hrp then _tpHold=false return end
    _tpTgt.f=_tpTgt.f+1
    if _tpTgt.f<=90 then hrp.CFrame=CFrame.new(_tpTgt.pos)
    else _tpHold=false _tpTgt=nil end
end)

local function tpNearest(kws,label)
    local p,d=getNearestPart(kws)
    if p then tpSafe(p.Position+Vector3.new(0,4,0)) N("TP",label.." "..math.floor(d).."m")
    else N("TP",label.." nao encontrado") end
end
local function tpNearestAnimal()
    local hrp=HRP() if not hrp then return end
    local best,bd=nil,math.huge
    for _,a in ipairs(getAnimals()) do
        local d=(hrp.Position-a.root.Position).Magnitude
        if d<bd and d>3 then best=a bd=d end
    end
    if best then tpSafe(best.root.Position+Vector3.new(0,3,3)) N("TP",best.model.Name.." "..math.floor(bd).."m")
    else N("TP","Nenhum animal") end
end

-- ================================================
-- 1. GOD MODE
-- sethiddenproperty trava MaxHealth server-side
-- HealthChanged + Died como fallback
-- ================================================
local _godConns={}
local function setGodMode(on)
    off("god")
    for _,c in ipairs(_godConns) do pcall(function() c:Disconnect() end) end
    _godConns={}
    if not on then N("God Mode","OFF") return end

    local function protectChar(ch)
        if not ch then return end
        local h=ch:FindFirstChildOfClass("Humanoid")
        if h then
            -- sethiddenproperty e unica forma de travar MaxHealth via cliente
            pcall(function() sethiddenproperty(h,"Health",math.huge) end)
            pcall(function() sethiddenproperty(h,"MaxHealth",math.huge) end)
            h:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
            _godConns[#_godConns+1]=h.HealthChanged:Connect(function(hp)
                if hp<h.MaxHealth then pcall(function() h.Health=h.MaxHealth end) end
            end)
            _godConns[#_godConns+1]=h.Died:Connect(function()
                pcall(function() h.Health=h.MaxHealth end)
            end)
        end
        -- NumberValues de stats
        for _,v in ipairs(ch:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n=v.Name:lower()
                if n:find("hunger") or n:find("thirst") or n:find("food")
                   or n:find("water") or n:find("health") or n:find("hp") then
                    _godConns[#_godConns+1]=v.Changed:Connect(function(val)
                        local mx=v.Parent:FindFirstChild("Max")
                        local target=mx and mx.Value or 100
                        if val<target*0.95 then pcall(function() v.Value=target end) end
                    end)
                end
            end
        end
        -- Atributos do char e do LP
        local function lockAttrib(obj,attr)
            local n=attr:lower()
            if n:find("hunger") or n:find("thirst") or n:find("food")
               or n:find("water") or n:find("health") or n:find("hp") then
                pcall(function()
                    local val=obj:GetAttribute(attr)
                    if type(val)=="number" and val<100 then obj:SetAttribute(attr,100) end
                end)
            end
        end
        _godConns[#_godConns+1]=ch.AttributeChanged:Connect(function(a) lockAttrib(ch,a) end)
        _godConns[#_godConns+1]=LP.AttributeChanged:Connect(function(a) lockAttrib(LP,a) end)
    end

    protectChar(Chr())
    _godConns[#_godConns+1]=LP.CharacterAdded:Connect(function(c)
        task.wait(0.3) protectChar(c)
    end)

    CONN["god"]=RS.Heartbeat:Connect(function()
        local h=Hum()
        if h and h.Health<h.MaxHealth then pcall(function() h.Health=h.MaxHealth end) end
        -- Atributos LP (stamina, hunger, thirst ficam no LP em muitos jogos de sobrevivencia)
        for _,attr in ipairs({"Hunger","Thirst","Food","Water","Health","HP","Stamina","Energy","Oxygen"}) do
            pcall(function()
                local v=LP:GetAttribute(attr)
                if type(v)=="number" and v<100 then LP:SetAttribute(attr,100) end
            end)
        end
    end)
    N("God Mode","HP + Stats bloqueados!")
end

-- ================================================
-- 2. STAMINA INFINITA
-- Em Savannah Life stamina fica como atributo do LP
-- ================================================
local function setStamina(on)
    off("stamina")
    if not on then N("Stamina","OFF") return end
    CONN["stamina"]=RS.Heartbeat:Connect(function()
        -- Atributo do LP (padrao Savannah Life)
        for _,attr in ipairs({"Stamina","stamina","Energy","energy","Sprint","Endurance","Fatigue","Vigor"}) do
            pcall(function()
                local v=LP:GetAttribute(attr)
                if type(v)=="number" and v<100 then LP:SetAttribute(attr,100) end
            end)
        end
        -- NumberValues no char tambem
        local c=Chr() if not c then return end
        for _,v in ipairs(c:GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) then
                local n=v.Name:lower()
                if n=="stamina" or n=="energy" or n=="sprint" or n=="endurance" or n=="vigor" then
                    pcall(function()
                        local mx=v.Parent:FindFirstChild("Max")
                        local maxV=mx and mx.Value or 100
                        if v.Value<maxV then v.Value=maxV end
                    end)
                end
            end
        end
    end)
    N("Stamina","Infinita ON!")
end

-- ================================================
-- 3. OXIGENIO INFINITO
-- ================================================
local function setOxygen(on)
    off("oxygen")
    if not on then N("Oxigenio","OFF") return end
    CONN["oxygen"]=RS.Heartbeat:Connect(function()
        for _,attr in ipairs({"Oxygen","oxygen","Air","Breath","Breathe"}) do
            pcall(function()
                local v=LP:GetAttribute(attr)
                if type(v)=="number" and v<100 then LP:SetAttribute(attr,100) end
            end)
        end
        local c=Chr() if not c then return end
        for _,v in ipairs(c:GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) then
                if v.Name:lower():find("oxygen") or v.Name:lower():find("air") or v.Name:lower():find("breath") then
                    pcall(function() v.Value=v.Parent:FindFirstChild("Max") and v.Parent:FindFirstChild("Max").Value or 100 end)
                end
            end
        end
    end)
    N("Oxigenio","Infinito ON!")
end

-- ================================================
-- 4. SPEED
-- ================================================
local function setSpeed(on)
    off("speed")
    if on then
        CONN["speed"]=RS.Heartbeat:Connect(function()
            local h=Hum() if h then h.WalkSpeed=CFG.Speed end
        end)
        N("Speed",CFG.Speed.." studs/s")
    else
        local h=Hum() if h then h.WalkSpeed=16 end
        N("Speed","Normal (16)")
    end
end

-- ================================================
-- 5. FLY REAL
-- Usa BodyGyro + LinearVelocity (sem BodyVelocity depreciado)
-- W/S = frente/tras | Q/E = sobe/desce via camera
-- ================================================
local _flyBG, _flyLV, _flyAtt
local function setFly(on)
    off("fly")
    -- Remove instancias anteriores
    pcall(function() if _flyBG then _flyBG:Destroy() end end)
    pcall(function() if _flyLV then _flyLV:Destroy() end end)
    pcall(function() if _flyAtt then _flyAtt:Destroy() end end)

    if not on then
        local h=Hum() if h then h.PlatformStand=false end
        N("Fly","OFF") return
    end

    local hrp=HRP() if not hrp then N("Fly","Sem char") return end
    local h=Hum() if h then h.PlatformStand=true end

    _flyAtt=Instance.new("Attachment") _flyAtt.Parent=hrp

    _flyBG=Instance.new("BodyGyro")
    _flyBG.MaxTorque=Vector3.new(4e5,4e5,4e5)
    _flyBG.P=1e4 _flyBG.D=100
    _flyBG.Parent=hrp

    _flyLV=Instance.new("LinearVelocity")
    _flyLV.Attachment0=_flyAtt
    _flyLV.MaxForce=math.huge
    _flyLV.VectorVelocity=Vector3.zero
    _flyLV.Parent=hrp

    CONN["fly"]=RS.Heartbeat:Connect(function()
        local hrp2=HRP() if not hrp2 then return end
        local cf=Cam.CFrame
        local fwd  = UIS:IsKeyDown(Enum.KeyCode.W)
        local bwd  = UIS:IsKeyDown(Enum.KeyCode.S)
        local up2  = UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.Q)
        local dn   = UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.E)
        local left = UIS:IsKeyDown(Enum.KeyCode.A)
        local right= UIS:IsKeyDown(Enum.KeyCode.D)
        local vel  = Vector3.zero
        if fwd   then vel=vel+cf.LookVector*CFG.FlySpeed end
        if bwd   then vel=vel-cf.LookVector*CFG.FlySpeed end
        if left  then vel=vel-cf.RightVector*CFG.FlySpeed end
        if right then vel=vel+cf.RightVector*CFG.FlySpeed end
        if up2   then vel=vel+Vector3.new(0,CFG.FlySpeed,0) end
        if dn    then vel=vel-Vector3.new(0,CFG.FlySpeed,0) end
        _flyLV.VectorVelocity=vel
        if vel.Magnitude>0 then
            _flyBG.CFrame=CFrame.new(hrp2.Position,hrp2.Position+vel)
        end
    end)
    N("Fly","W/S/A/D/Espaco/Ctrl")
end

-- ================================================
-- 6. NO CLIP
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
-- 7. INFINITE JUMP
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
-- 8. HITBOX EXPANDER
-- Aumenta o HRP.Size para que qualquer ataque
-- com magnitude check acerte o alvo
-- Tecnica confirmada em scripts funcionais publicos
-- ================================================
local _origSizes={}
local function setHitbox(on)
    if on then
        local sz=Vector3.new(CFG.HitboxSize,CFG.HitboxSize,CFG.HitboxSize)
        for _,a in ipairs(getAnimals()) do
            if not _origSizes[a.root] then
                _origSizes[a.root]=a.root.Size
            end
            pcall(function() a.root.Size=sz end)
        end
        -- Mantém expandido em loop
        off("hitbox")
        CONN["hitbox"]=RS.Heartbeat:Connect(function()
            for _,a in ipairs(getAnimals()) do
                if a.root.Size.X<CFG.HitboxSize then
                    if not _origSizes[a.root] then _origSizes[a.root]=a.root.Size end
                    pcall(function() a.root.Size=Vector3.new(CFG.HitboxSize,CFG.HitboxSize,CFG.HitboxSize) end)
                end
            end
        end)
        N("Hitbox",CFG.HitboxSize.."x expandido!")
    else
        off("hitbox")
        -- Restaura tamanhos originais
        for root,sz in pairs(_origSizes) do
            pcall(function() root.Size=sz end)
        end
        _origSizes={}
        N("Hitbox","Restaurado")
    end
end

-- ================================================
-- 9. KILL AURA
-- Hitbox + Humanoid.Health=0 + Remotes + Tool
-- ================================================
local function setKillAura(on)
    off("killaura")
    if not on then N("Kill Aura","OFF") return end
    local tick2=0
    CONN["killaura"]=RS.Heartbeat:Connect(function(dt)
        tick2=tick2+dt if tick2<0.08 then return end tick2=0
        local hrp=HRP() if not hrp then return end
        local c=Chr()
        for _,a in ipairs(getAnimals()) do
            local dist=(hrp.Position-a.root.Position).Magnitude
            if dist<=CFG.KillRange then
                -- M1: HP=0 direto
                pcall(function() a.hum.Health=0 end)
                -- M2: sethiddenproperty
                pcall(function() sethiddenproperty(a.hum,"Health",0) end)
                -- M3: Remotes de ataque
                for _,v in ipairs(getRemotes({"attack","bite","damage","hit","slash","claw","kill","hurt","melee","strike"})) do
                    pcall(function() v:FireServer(a.model,a.root,a.root.Position,100) end)
                    pcall(function() v:FireServer(a.hum) end)
                end
                -- M4: Tool handle teleport + activate
                if c then
                    local tool=c:FindFirstChildOfClass("Tool")
                    if tool then
                        local handle=tool:FindFirstChild("Handle")
                        if handle then
                            local savedCF=handle.CFrame
                            handle.CFrame=a.root.CFrame
                            -- Dispara Activated
                            pcall(function() tool.Activated:Fire() end)
                            task.defer(function() pcall(function() handle.CFrame=savedCF end) end)
                        end
                        for _,rem in ipairs(tool:GetDescendants()) do
                            if rem:IsA("RemoteEvent") then
                                pcall(function() rem:FireServer(a.root.Position) end)
                                pcall(function() rem:FireServer(a.model) end)
                            end
                        end
                    end
                end
                -- M5: LinearVelocity knockback
                pcall(function()
                    local att=Instance.new("Attachment") att.Parent=a.root
                    local lv=Instance.new("LinearVelocity")
                    lv.Attachment0=att lv.MaxForce=math.huge
                    lv.VectorVelocity=(a.root.Position-hrp.Position).Unit*250
                    lv.Parent=a.root
                    Debris:AddItem(lv,0.05) Debris:AddItem(att,0.05)
                end)
            end
        end
    end)
    N("Kill Aura","Raio "..CFG.KillRange.." ON!")
end

-- ================================================
-- 10. GRAB AURA
-- Cria AlignPosition puxando animais para voce
-- Tecnica vista em scripts publicos de Savannah Life
-- ================================================
local _grabInsts={}
local function setGrabAura(on)
    off("grab")
    -- Limpa instancias
    for _,t in ipairs(_grabInsts) do
        pcall(function() t[1]:Destroy() end)
        pcall(function() t[2]:Destroy() end)
    end
    _grabInsts={}

    if not on then N("Grab Aura","OFF") return end

    CONN["grab"]=RS.Heartbeat:Connect(function()
        local hrp=HRP() if not hrp then return end

        -- Garante attachment no HRP do player
        local selfAtt=hrp:FindFirstChild("_GrabSelfAtt")
        if not selfAtt then
            selfAtt=Instance.new("Attachment")
            selfAtt.Name="_GrabSelfAtt"
            selfAtt.Parent=hrp
        end

        for _,a in ipairs(getAnimals()) do
            local dist=(hrp.Position-a.root.Position).Magnitude
            if dist<=CFG.GrabRange and not a.root:FindFirstChild("_GrabAP") then
                -- Attachment no alvo
                local att=Instance.new("Attachment")
                att.Name="_GrabAtt"
                att.Parent=a.root

                -- AlignPosition puxa o alvo ate voce
                local ap=Instance.new("AlignPosition")
                ap.Name="_GrabAP"
                ap.Attachment0=att
                ap.Attachment1=selfAtt
                ap.MaxForce=math.huge
                ap.MaxVelocity=math.huge
                ap.Responsiveness=200
                ap.Parent=a.root

                _grabInsts[#_grabInsts+1]={ap,att}
                Debris:AddItem(ap,3)
                Debris:AddItem(att,3)
            end
        end
    end)
    N("Grab Aura","Puxando animais! Raio "..CFG.GrabRange)
end

-- ================================================
-- 11. ANTI-GRAB / ANTI-PUXAO
-- Remove BodyPosition, AlignPosition, VectorForce
-- que outros players ou o jogo colocam no seu char
-- Tecnica principal dos scripts publicos funcionais
-- ================================================
local function setAntiGrab(on)
    off("antigrab")
    if not on then N("Anti-Grab","OFF") return end
    CONN["antigrab"]=RS.Heartbeat:Connect(function()
        local c=Chr() if not c then return end
        local hrp=HRP() if not hrp then return end
        -- Remove constraints de forca externos
        for _,v in ipairs(hrp:GetChildren()) do
            if v:IsA("BodyPosition") or v:IsA("BodyVelocity")
               or v:IsA("BodyForce") or v:IsA("BodyMover") then
                if v.Name~="_FlyBG" then
                    pcall(function() v:Destroy() end)
                end
            end
        end
        -- Remove AlignPosition / VectorForce que nao sao nossos
        for _,v in ipairs(hrp:GetChildren()) do
            if (v:IsA("AlignPosition") or v:IsA("VectorForce") or v:IsA("LinearVelocity"))
               and not v.Name:find("_Fly") then
                pcall(function() v:Destroy() end)
            end
        end
        -- Anti-freeze: garante que o char pode se mover
        for _,v in ipairs(c:GetDescendants()) do
            if v:IsA("BasePart") and v.Anchored and v~=hrp then
                pcall(function() v.Anchored=false end)
            end
        end
    end)
    N("Anti-Grab","Nenhum animal pode te puxar!")
end

-- ================================================
-- 12. AUTO FARM (Teleporte + Kill Aura + Grab)
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
                -- Teleporte anti-reverter
                tpSafe(best.root.Position+Vector3.new(0,2,2))
                task.wait(0.1)
                -- Mata o alvo
                pcall(function() best.hum.Health=0 end)
                pcall(function() sethiddenproperty(best.hum,"Health",0) end)
                -- Remotes
                for _,v in ipairs(getRemotes({"attack","bite","damage","hit","kill","hurt","claw","melee","strike"})) do
                    pcall(function() v:FireServer(best.model,best.root,100) end)
                    pcall(function() v:FireServer(best.hum) end)
                end
                -- Tool
                local c=Chr() if not c then continue end
                local tool=c:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool.Activated:Fire() end)
                    local handle=tool:FindFirstChild("Handle")
                    if handle then
                        local sv=handle.CFrame
                        handle.CFrame=best.root.CFrame
                        task.defer(function() pcall(function() handle.CFrame=sv end) end)
                    end
                    for _,rem in ipairs(tool:GetDescendants()) do
                        if rem:IsA("RemoteEvent") then
                            pcall(function() rem:FireServer(best.root.Position) end)
                        end
                    end
                end
            end
        end
    end)
end

-- ================================================
-- 13. AUTO COMER
-- ================================================
local _eatRun=false
local function setAutoEat(on)
    _eatRun=on
    if not on then N("Auto Eat","OFF") return end
    N("Auto Eat","ON")
    task.spawn(function()
        while _eatRun do
            task.wait(0.8)
            local p,d=getNearestPart(FOOD_KW)
            if p then
                local hrp=HRP() if not hrp then continue end
                tpSafe(p.Position+Vector3.new(0,3,0))
                task.wait(0.15)
                pcall(function() p.Touched:Fire(hrp) end)
                for _,v in ipairs(getRemotes({"eat","consume","feed","food","hunger","interact","pickup","collect"})) do
                    pcall(function() v:FireServer(p.Parent or p) end)
                    pcall(function() v:FireServer(p) end)
                end
            end
        end
    end)
end

-- ================================================
-- 14. AUTO BEBER
-- ================================================
local _drinkRun=false
local function setAutoDrink(on)
    _drinkRun=on
    if not on then N("Auto Drink","OFF") return end
    N("Auto Drink","ON")
    task.spawn(function()
        while _drinkRun do
            task.wait(0.8)
            local p,d=getNearestPart(WATER_KW)
            if p then
                local hrp=HRP() if not hrp then continue end
                tpSafe(p.Position+Vector3.new(0,2,0))
                task.wait(0.15)
                pcall(function() p.Touched:Fire(hrp) end)
                for _,v in ipairs(getRemotes({"drink","water","thirst","hydrat","interact","collect"})) do
                    pcall(function() v:FireServer(p.Parent or p) end)
                    pcall(function() v:FireServer(p) end)
                end
            end
        end
    end)
end

-- ================================================
-- 15. ESP ANIMAIS
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
                bb.Size=UDim2.new(0,150,0,34) bb.StudsOffset=Vector3.new(0,4,0)
                bb.Parent=a.root
                local lbl=Instance.new("TextLabel")
                lbl.Size=UDim2.new(1,0,1,0) lbl.BackgroundTransparency=1
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
-- 16. ESP ITEMS (comida/agua/moedas)
-- ================================================
local _espIConn
local function setESPItems(on)
    if _espIConn then _espIConn:Disconnect() _espIConn=nil end
    for _,v in ipairs(WS:GetDescendants()) do
        if v.Name=="_IESP" then pcall(function() v:Destroy() end) end
    end
    if not on then N("ESP Items","OFF") return end
    _espIConn=RS.Heartbeat:Connect(function()
        for _,obj in ipairs(WS:GetDescendants()) do
            if not obj:IsA("BasePart") or obj:FindFirstChild("_IESP") then continue end
            local n=obj.Name:lower()
            local isF,isW,isC=false,false,false
            for _,kw in ipairs(FOOD_KW)  do if n:find(kw) then isF=true break end end
            for _,kw in ipairs(WATER_KW) do if n:find(kw) then isW=true break end end
            for _,kw in ipairs(COIN_KW)  do if n:find(kw) then isC=true break end end
            if isF or isW or isC then
                local bb=Instance.new("BillboardGui")
                bb.Name="_IESP" bb.AlwaysOnTop=true
                bb.Size=UDim2.new(0,110,0,22) bb.StudsOffset=Vector3.new(0,2.5,0)
                bb.Parent=obj
                local lbl=Instance.new("TextLabel")
                lbl.Size=UDim2.new(1,0,1,0) lbl.BackgroundTransparency=1
                lbl.Font=Enum.Font.GothamBold lbl.TextSize=10
                lbl.TextStrokeTransparency=0
                lbl.TextColor3=isC and Color3.fromRGB(255,220,0)
                    or isW and Color3.fromRGB(50,180,255)
                    or Color3.fromRGB(80,255,80)
                lbl.Text=(isC and "[Moeda] " or isW and "[Agua] " or "[Comida] ")..obj.Name
                lbl.Parent=bb
            end
        end
    end)
    N("ESP Items","Verde=Comida Azul=Agua Amarelo=Moeda")
end

-- ================================================
-- 17. AUTO RESPAWN
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
-- 18. ANTI AFK
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
            if h then local s=h.WalkSpeed h.WalkSpeed=0.001 task.wait(0.05) h.WalkSpeed=s end
        end
    end)
    N("Anti AFK","Ativo!")
end

-- ================================================
-- GUI
-- ================================================
local GUI=Instance.new("ScreenGui")
GUI.Name="SavannahHub" GUI.ResetOnSpawn=false
GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
GUI.Parent=game:GetService("CoreGui")

local MF=Instance.new("Frame")
MF.Size=UDim2.new(0,370,0,540)
MF.Position=UDim2.new(0,16,0.5,-270)
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
TL.Size=UDim2.new(1,-72,1,0) TL.Position=UDim2.new(0,8,0,0)
TL.BackgroundTransparency=1 TL.Text="Savannah Hub v5"
TL.TextColor3=Color3.fromRGB(255,175,0)
TL.TextSize=13 TL.Font=Enum.Font.GothamBold
TL.TextXAlignment=Enum.TextXAlignment.Left TL.Parent=TOP

local function mkTopBtn(txt,col,ox)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,24) b.Position=UDim2.new(1,ox,0,7)
    b.BackgroundColor3=col b.Text=txt
    b.TextColor3=Color3.new(1,1,1) b.TextSize=11 b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0 b.Parent=TOP
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end
mkTopBtn("X",Color3.fromRGB(160,30,30),-30).MouseButton1Click:Connect(function()
    MF.Visible=not MF.Visible
end)
local _min=false
mkTopBtn("-",Color3.fromRGB(45,45,65),-60).MouseButton1Click:Connect(function()
    _min=not _min
    for _,c in ipairs(MF:GetChildren()) do
        if c~=TOP then c.Visible=not _min end
    end
    MF.Size=_min and UDim2.new(0,370,0,38) or UDim2.new(0,370,0,540)
end)

local TABROW=Instance.new("Frame")
TABROW.Size=UDim2.new(1,0,0,28) TABROW.Position=UDim2.new(0,0,0,40)
TABROW.BackgroundColor3=Color3.fromRGB(13,13,21)
TABROW.BorderSizePixel=0 TABROW.Parent=MF

local CONT=Instance.new("Frame")
CONT.Size=UDim2.new(1,-8,1,-76) CONT.Position=UDim2.new(0,4,0,72)
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
    pg.Size=UDim2.new(1,0,1,0) pg.BackgroundTransparency=1
    pg.BorderSizePixel=0 pg.ScrollBarThickness=3
    pg.AutomaticCanvasSize=Enum.AutomaticSize.Y
    pg.CanvasSize=UDim2.new(0,0,0,0)
    pg.Visible=idx==1 pg.Parent=CONT
    local lay=Instance.new("UIListLayout")
    lay.Padding=UDim.new(0,4) lay.Parent=pg
    local pad=Instance.new("UIPadding")
    pad.PaddingTop=UDim.new(0,3) pad.PaddingLeft=UDim.new(0,1) pad.Parent=pg

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
    l.Size=UDim2.new(1,-2,0,17) l.BackgroundTransparency=1
    l.Text=t l.TextColor3=Color3.fromRGB(255,175,0)
    l.TextSize=10 l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=p
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
    return b
end

local knobs={}
local function mkToggle(p,t,key,fn)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,-2,0,32)
    row.BackgroundColor3=Color3.fromRGB(15,15,25)
    row.BorderSizePixel=0 row.Parent=p
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-50,1,0) lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=t
    lbl.TextColor3=Color3.fromRGB(200,200,200)
    lbl.TextSize=10 lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Parent=row

    local track=Instance.new("TextButton")
    track.Size=UDim2.new(0,40,0,18)
    track.Position=UDim2.new(1,-44,0.5,-9)
    track.BackgroundColor3=Color3.fromRGB(50,50,50)
    track.Text="" track.BorderSizePixel=0 track.Parent=row
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
mkToggle(aP,"Auto Comer","AutoEat",setAutoEat)
mkToggle(aP,"Auto Beber","AutoDrink",setAutoDrink)
mkToggle(aP,"Auto Farm (teleporta + mata)","AutoFarm",setAutoFarm)
mkToggle(aP,"Auto Respawn ao morrer","AutoRespawn",setAutoRespawn)
mkToggle(aP,"Anti AFK","AntiAFK",setAntiAFK)
mkSep(aP)
mkLbl(aP,"Raio Auto Farm")
mkBtn(aP,"40 studs",function() CFG.FarmRange=40 N("Farm","40") end)
mkBtn(aP,"80 studs",function() CFG.FarmRange=80 N("Farm","80") end)
mkBtn(aP,"120 studs",function() CFG.FarmRange=120 N("Farm","120") end)

-- ================================================
-- ABA COMBAT
-- ================================================
local cP=PAGES["Combat"]
mkLbl(cP,"Combate")
mkSep(cP)
mkToggle(cP,"Kill Aura (5 metodos)","KillAura",setKillAura)
mkToggle(cP,"Hitbox Expander (facilita acertos)","HitboxExpand",setHitbox)
mkToggle(cP,"Grab Aura (puxa animais)","GrabAura",setGrabAura)
mkToggle(cP,"Anti-Grab (ninguem te puxa)","AntiGrab",setAntiGrab)
mkSep(cP)
mkLbl(cP,"Raio Kill Aura")
mkBtn(cP,"10 studs",function() CFG.KillRange=10 N("KA","10") end)
mkBtn(cP,"20 studs",function() CFG.KillRange=20 N("KA","20") end)
mkBtn(cP,"35 studs",function() CFG.KillRange=35 N("KA","35") end)
mkBtn(cP,"50 studs",function() CFG.KillRange=50 N("KA","50") end)
mkSep(cP)
mkLbl(cP,"Hitbox Size")
mkBtn(cP,"8 studs",function() CFG.HitboxSize=8 if T.HitboxExpand then setHitbox(true) end end)
mkBtn(cP,"15 studs",function() CFG.HitboxSize=15 if T.HitboxExpand then setHitbox(true) end end)
mkBtn(cP,"25 studs",function() CFG.HitboxSize=25 if T.HitboxExpand then setHitbox(true) end end)
mkSep(cP)
mkLbl(cP,"ESP")
mkToggle(cP,"ESP Animais (dist + HP%)","ESPAnimals",setESPAnimals)
mkToggle(cP,"ESP Items (comida/agua/moedas)","ESPItems",setESPItems)

-- ================================================
-- ABA PLAYER
-- ================================================
local pP=PAGES["Player"]
mkLbl(pP,"Player Hacks")
mkSep(pP)
mkToggle(pP,"God Mode (HP+Stats)","GodMode",setGodMode)
mkToggle(pP,"Stamina Infinita (LP attr)","InfStamina",setStamina)
mkToggle(pP,"Oxigenio Infinito","InfOxygen",setOxygen)
mkToggle(pP,"Speed Hack","Speed",setSpeed)
mkToggle(pP,"Fly (W/S/A/D + Espaco/Ctrl)","Fly",setFly)
mkToggle(pP,"Pulo Infinito","InfJump",setInfJump)
mkToggle(pP,"No Clip","NoClip",setNoClip)
mkSep(pP)
mkLbl(pP,"Velocidade Walk")
mkBtn(pP,"16 - Normal",function()
    CFG.Speed=16
    if T.Speed then setSpeed(true) else local h=Hum() if h then h.WalkSpeed=16 end end
end)
mkBtn(pP,"32 - Rapido",function() CFG.Speed=32 if T.Speed then setSpeed(true) end end)
mkBtn(pP,"60 - Muito Rapido",function() CFG.Speed=60 if T.Speed then setSpeed(true) end end)
mkBtn(pP,"100 - Maximo",function() CFG.Speed=100 if T.Speed then setSpeed(true) end end)
mkSep(pP)
mkLbl(pP,"Velocidade Fly")
mkBtn(pP,"40 - Normal",function() CFG.FlySpeed=40 N("Fly","40") end)
mkBtn(pP,"80 - Rapido",function() CFG.FlySpeed=80 N("Fly","80") end)
mkBtn(pP,"150 - Turbo",function() CFG.FlySpeed=150 N("Fly","150") end)
mkSep(pP)
mkLbl(pP,"Teleportes")
mkBtn(pP,"Ir para Agua",function() tpNearest(WATER_KW,"Agua") end)
mkBtn(pP,"Ir para Comida",function() tpNearest(FOOD_KW,"Comida") end)
mkBtn(pP,"Ir para Animal",function() tpNearestAnimal() end)
mkBtn(pP,"Ir para Spawn (0,5,0)",function() tpSafe(Vector3.new(0,5,0)) N("TP","Spawn!") end)
mkSep(pP)
mkBtn(pP,"Resetar Personagem",function()
    local h=Hum() if h then h.Health=0 end
    task.wait(0.5) pcall(function() LP:LoadCharacter() end)
    N("Reset","OK!")
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
mkBtn(mP,"Listar Atributos LP (F9)",function()
    print("\n=== ATRIBUTOS LP ===")
    for k,v in pairs(LP:GetAttributes()) do print(k.." = "..tostring(v)) end
    local c=Chr()
    if c then
        print("\n=== ATRIBUTOS CHAR ===")
        for k,v in pairs(c:GetAttributes()) do print(k.." = "..tostring(v)) end
    end
    N("Attrs","Impresso no F9!")
end)
mkBtn(mP,"Info Char / Stats (F9)",function()
    local c=Chr() if not c then N("Info","Sem char") return end
    local h=Hum()
    print("\n=== CHAR: "..c.Name.." ===")
    if h then print("HP: "..h.Health.."/"..h.MaxHealth.." | Speed: "..h.WalkSpeed) end
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
    N("Server Hop","Sem servidor disponivel")
end)
mkSep(mP)
mkBtn(mP,"RESETAR TUDO",function()
    for key in pairs(T) do
        if T[key] then T[key]=false if knobs[key] then knobs[key]() end end
    end
    setGodMode(false) setStamina(false) setOxygen(false)
    setSpeed(false) setFly(false) setNoClip(false) setInfJump(false)
    setKillAura(false) setHitbox(false) setGrabAura(false) setAntiGrab(false)
    setAutoFarm(false) setAutoEat(false) setAutoDrink(false)
    setESPAnimals(false) setESPItems(false)
    setAutoRespawn(false) setAntiAFK(false)
    N("Reset","Tudo OFF!")
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

task.wait(0.5)
N("Savannah Hub v5","Carregado! INSERT = abrir/fechar | F9 = debug")
print("[SavannahHub v5] OK | TochZero 2026")
