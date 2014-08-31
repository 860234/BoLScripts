if myHero.charName ~= "Talon" then return end
if VIP_USER then
    require "Prodiction"
end

local Config
local Minions
local FarmMinions
local JungleMinions
local JungleFarmMinions
local isattacking = 0
local AAanim = 0
local AAwind = 0
local lastAttack = 0
local timeToHit = 0
local nCC = 0
local CCtable = {}
local ResetAA = false
local Ult1Ready = false
local Ult2Ready = false
local AAreset = false
local Action = false
local CountDelay = false
local TimeCheck = false

--[[
local globalCC = { --A List like yasuo's block list, however containing the buff name of all stuns, slows, immobiles, suppressions.
	--A list of examples, not actual buffnames
	{charName = "Jinx", Debuff = "Wslow"},
	{charName = "Jinx", Debuff = "Eimmobilize"}
	{charName = "Talon", Debuff = "Wslow"}
}]]--

function OnLoad()
	PrintChat("<font color='#aaff34'>CarryMe</font><font color='#44BB77'>Talon</font> <font color='#99ff88'>Beta</font> <font color='#ffffff'>- a </font><font color='#BBFFBB'>Jarvis101</font><font color='#ffffff'>/</font><font color='#9999ff'>Fuggi</font> <font color='#ffffff'>Collaboration</font>")
    Menu()
    Init()

end

function OnProcessSpell(object,spellProc)
    if myHero.dead then return end
    if object.isMe and spellProc.name:lower():find("attack") then
        AAwind = spellProc.windUpTime
		AAanim = spellProc.animationTime
    end 
end

function Init()
    levelSequence = {2,1,3,2,2 ,4,2,1,2,1 ,4,1,1,3,3 ,4,3,3}
	Youmuu, BilgeWaterCutlass, Hydra, RuinedKing, Omen, Tiamat = nil, nil, nil, nil, nil, nil
	YoumuuR, BilgeWaterCutlassR, HydraR, RuinedKingR, OmenR, TiamatR = nil, nil, nil, nil, nil, nil

    eRange = 700
    qRange = 125
    w = { Range = 600, Delay = 0.01, Speed = 750, Width = 50}  --Needs  tweaking / pulled the values out of my ass

	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then 
		igniteSpell = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then 
		igniteSpell = SUMMONER_2
	else 
		igniteSpell = nil
	end
	
	Minions = minionManager(MINION_ENEMY, 1250, player, MINION_SORT_HEALTH_ASC)
	FarmMinions = minionManager(MINION_ENEMY, eRange, player, MINION_SORT_HEALTH_ASC)
	JungleFarmMinions = minionManager(MINION_JUNGLE, eRange, player, MINION_SORT_HEALTH_ASC)
	JungleMinions = minionManager(MINION_JUNGLE, 1250, player, MINION_SORT_HEALTH_ASC)
    ts = TargetSelector(TARGET_NEAR_MOUSE, 1300, DAMAGE_PHYSICAL)   
    ts.name = "Talon"
    Config:addTS(ts)

    if VIP_USER then
        Prod = ProdictManager.GetInstance()
        ProdW = Prod:AddProdictionObject(_W, w.Range, w.Speed, w.Delay, w.Width, myHero)
    end
    --[[
    for _, enemy in pairs(enemyHeroes) do
		for _, champ in pairs(globalCC) do
			if enemy.charName == champ.charName then
				table.insert(CCtable, champ.Debuff)
				nCC = nCC + 1
			end
		end
	end
    ]]--
    initDone = true
	
end

function Menu()
	Config = scriptConfig("CarryMeTalon", "talon")
    Config:addSubMenu("Harass Options", "SMharass")
    Config:addSubMenu("Farm Options", "SMfarm")
    Config:addSubMenu("SBTW Options", "SMsbtw")
    Config:addSubMenu("Auto Ult Options", "SMult")
    Config:addSubMenu("Other Options", "SMother")
    Config:addSubMenu("Drawing Options", "SMdraw")

	Config:addParam("farm", "Lane Clear", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
    Config:addParam("smartfarm", "Last Hit", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
    --Config:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
	Config:addParam("sbtw", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("flee", "Flee", SCRIPT_PARAM_ONKEYDOWN, false, 88)

	Config.SMharass:addParam("autoW", "Auto-W", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("S"))
    Config.SMharass:addParam("underTower", "Auto-W under Tower", SCRIPT_PARAM_ONOFF, true)
	Config.SMharass:addParam("StopIfBack", "Disable Auto-W if Recalling", SCRIPT_PARAM_ONOFF, true)
	--Config.SMharass:addParam("HuseMove", "Move to Mouse", SCRIPT_PARAM_ONOFF, true)

	Config.SMfarm:addParam("useQFarm", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.SMfarm:addParam("useWFarm", "Use W", SCRIPT_PARAM_ONOFF, true)
    Config.SMfarm:addParam("useAA", "Autoattack",SCRIPT_PARAM_ONOFF, true)
    Config.SMfarm:addParam("useMove", "Move to Mouse", SCRIPT_PARAM_ONOFF, true)

	Config.SMsbtw:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.SMsbtw:addParam("nilval", "Reset AA Q AA combo if enemy is out", SCRIPT_PARAM_INFO, "")
	Config.SMsbtw:addParam("TimeReset", "of range for more than 2s", SCRIPT_PARAM_ONOFF, true)
    Config.SMsbtw:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.SMsbtw:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
    Config.SMsbtw:addParam("minDistanceToE", "Min Distance to E",SCRIPT_PARAM_SLICE, 300, 1, 600, 0)
	Config.SMsbtw:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, false)
    Config.SMsbtw:addParam("useAA", "Autoattack",SCRIPT_PARAM_ONOFF, true)
    Config.SMsbtw:addParam("useMove", "Move to Mouse", SCRIPT_PARAM_ONOFF, true)
    --Config.SMsbtw:addParam("atf", "animtimefactor",SCRIPT_PARAM_SLICE, 0.75, 0.00, 1, 3)

    Config.SMult:addParam("autoRkillable", "Auto-R when Target is killable",SCRIPT_PARAM_ONOFF, true)
	Config.SMult:addParam("autoRkNumCast", "ignore safety params for KS",SCRIPT_PARAM_ONOFF, true)
    Config.SMult:addParam("autoRMin", "Auto-R Many Targets", SCRIPT_PARAM_ONOFF, false)
    Config.SMult:addParam("autoRnum", "# of Targets to Auto-R",SCRIPT_PARAM_SLICE, 4, 2, 5, 0)
    Config.SMult:addParam("autoRPercent", "Second R when above % Health",SCRIPT_PARAM_SLICE, 50, 1, 75, 0)
	
    Config.SMother:addParam("usePackets", "Use Packets", SCRIPT_PARAM_ONOFF, true)
    Config.SMother:addParam("killsteal", "Killsteal", SCRIPT_PARAM_ONOFF, true)
	--Config.SMother:addParam("ksW", "Use W to KS",SCRIPT_PARAM_ONOFF, false)
	Config.SMother:addParam("autoIg", "Auto Ignite Killable", SCRIPT_PARAM_ONOFF, true)
    Config.SMother:addParam("autoLevel", "AutoLevel (R>W>Q>E) Level 3 E", SCRIPT_PARAM_ONOFF, true)
	
	Config.SMdraw:addParam("drawW","Draw W-Range",SCRIPT_PARAM_ONOFF, true)
	Config.SMdraw:addParam("drawTarget","Draw Target",SCRIPT_PARAM_ONOFF, true)
    Config.SMdraw:addParam("drawText","Draw Text",SCRIPT_PARAM_ONOFF, true)

    Config.SMharass:permaShow("autoW")
    Config:permaShow("smartfarm")
    Config:permaShow("farm")
    Config:permaShow("flee")
    Config:permaShow("sbtw")
end

function checkItems()
    Hydra = GetInventorySlotItem(3074)
    RuinedKing = GetInventorySlotItem(3153)
    Omen = GetInventorySlotItem(3143)
    Tiamat = GetInventorySlotItem(3077)
    BilgeWaterCutlass = GetInventorySlotItem(3144)
    Youmuu = GetInventorySlotItem(3142)
    HydraR = (Hydra ~= nil and myHero:CanUseSpell(Hydra))
    RuinedKingR = (RuinedKing ~= nil and myHero:CanUseSpell(RuinedKing))
    OmenR = (Omen ~= nil and myHero:CanUseSpell(Omen))
    TiamatR = (Tiamat ~= nil and myHero:CanUseSpell(Tiamat))
    BilgeWaterCutlassR = (BilgeWaterCutlass ~= nil and myHero:CanUseSpell(BilgeWaterCutlass))
    YoumuuR = (Youmuu ~= nil and myHero:CanUseSpell(Youmuu))
	SwordofDivine = GetInventorySlotItem(3131)
	SwordofDivineR = (SwordofDivine ~= nil and myHero:CanUseSpell(SwordofDivine))
end

function calcDmg(unit)
    local aa = getDmg("AD", unit, myHero)
    local qDmg = myHero:CalcDamage(unit,(GetSpellData(_Q).level*20)+myHero.totalDamage)
    local wDmg = myHero:CalcDamage(unit,(GetSpellData(_W).level*25) + myHero.totalDamage*0.6)
    local bwcDamage = (BilgeWaterCutlass and getDmg("BWC",unit,myHero) or 0)
    local brkDamage = (RuinedKing and getDmg("RUINEDKING",unit,myHero,2) or 0)
    local igniteDamage = (igniteSpell and getDmg("IGNITE",unit,myHero) or 0)
    local rshDamage = (Hydra and aa*0.8 or 0)
    local tmtDamage = (Tiamat and aa*0.8 or 0)
    local totalDamage = wDmg + aa + qDmg + bwcDamage + brkDamage + igniteDamage + rshDamage + tmtDamage
    local sustainedDamage = ((aa) + (qDmg) + (0.5*wDmg))/2 
    local color
    local text

    if unit.health < totalDamage then
        color = ARGB(255,255,0,0)
        text = "Fuck him up!"
    elseif unit.health < totalDamage + 1.5*sustainedDamage then 
        color = ARGB(255,225,60,0)
        text = "Go for it!"
    elseif unit.health < totalDamage + 2.5*sustainedDamage then 
        color = ARGB(255,160,80,50)
        text = "Meh..."
    else 
        color = ARGB(255,127,127,127)
        text = "Get Backup"
    end
    return color, text
end

local pPos = nil 

function OnTick()
    if initDone then
        if Config.SMother.autoLevel then 
            autoLevelSetSequence(levelSequence)
        else
            autoLevelSetSequence({0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0})
        end
        ts:update();
        Target = ts.target
		
        QREADY = (myHero:CanUseSpell(_Q) == READY)
        EREADY = (myHero:CanUseSpell(_E) == READY)
        WREADY = (myHero:CanUseSpell(_W) == READY)
        RREADY = (myHero:CanUseSpell(_R) == READY)
        IREADY = (igniteSpell ~= nil and myHero:CanUseSpell(igniteSpell) == READY)
		AAREADY = CanAtk()
		
        checkItems()
        
		if Config.SMult.autoRMin then
			autoUlt()
		end

        if Target ~= nil and Config.SMult.autoRkillable then
            autoUlt2()
        end     
        
        if Config.SMother.autoIg and IREADY then 
            AutoI()
        end
        
        if VIP_USER and Target ~= nil then            
            local pos = ProdW:GetPrediction(Target)
            if pos ~= nil then pPos = pos end
        elseif not VIP_USER and Target ~= nil then
            pPos = Target
        end        
        
        if not Config.flee and not Config.sbtw then AutoW() end

        if Config.SMother.killsteal then killSteal() end

        if Config.sbtw then
            SBTW() 
        elseif Config.farm then
            farm()
        elseif Config.flee then
            flee()
        elseif Config.smartfarm then
            smartfarm()
        elseif Config.harass then
            harass()
        end
		
		if Config.SMother.TimeReset and os.clock() > lastAttack + (AAanim*2) + ((GetLatency()/2)*0.001) + 2 then
			AAreset = false
			ResetAA = false			
		end
    end
end

function AutoW()
    if Config.SMharass.autoW then
        if Target ~= nil then 
            if GetDistance(Target) < w.Range then
				local StopW = false
				if Config.SMharass.StopIfBack then
					for i = 1, myHero.buffCount, 1 do
						if myHero:getBuff(i).name == "Recall" then
							StopW = true
						end
					end
				end
                if Config.SMharass.underTower and not StopW then
                    W(Target)
                elseif not UnderTurret(myHero, true) and not StopW then
                        W(Target)
                end
            end
        end
    end    
end

--[[
function harass()
    -- if DIstance > Wdistance jump to minon and W
    if Target ~= nil then
        Minions:update()
        local distance = eRange
		
		--need to determine minion target, then following code will work for jump harass
		
		if GetDistance(minion, Target) < wRange and GetDistance(minion, myHero) < eRange and GetDistance(Target) > wRange then
			E(minion)
		end
		if GetDistance(Target) < wRange then
			W(Target)
		end
		if GetDistance(Target) < 125 then
			if ResetAA and QREADY then
					ResetAA = false
					Q(Target)
				end

				if os.clock()>isattacking then ResetAA = true end
				--lastAttack = GetTickCount()
				
				if QREADY then
					ResetAA = true
				end
				
				Attack(Target)
			end
		end
		if Config.SMharass.HuseMove and TimeToAtk() then
			myHero:MoveTo(mousePos.x, mousePos.z) 
		end
		
		
    end
end
]]
function selectMinion()
	FarmMinions:update()
	JungleFarmMinions:update()
	local distance = eRange
	for index, minion in pairs(FarmMinions.objects) do
		if ValidTarget(minion) then
			check = GetDistance(minion)
			if check < distance then 
				distance = check
				farmMinion = minion 
			end
		end
	end	
	for index, minion in pairs(JungleFarmMinions.objects) do
		if ValidTarget(minion) then
			check = GetDistance(minion)
			if check < distance then 
				distance = check
				farmMinion = minion 
			end
		end
	end	
	return farmMinion
end

function minionCount(unit, distance)
    local count=0
    local check
    FarmMinions:update()
    JungleFarmMinions:update()
    for index, minion in pairs(FarmMinions.objects) do
        if ValidTarget(minion) then
            check = GetDistance(unit, minion)
            if check < distance then 
                count = count + 1
            end
        end
    end 
    for index, minion in pairs(JungleFarmMinions.objects) do
        if ValidTarget(minion) then
            check = GetDistance(unit, minion)
            if check < distance then 
                count = count + 1
            end
        end
    end 
    return count
end

function MoveToMouse()
        local MousePos = Vector(mousePos.x, mousePos.y, mousePos.z)
        local Position = myHero + (Vector(MousePos) - myHero):normalized()*300
        myHero:MoveTo(Position.x, Position.z)
end

function getEDmg(minion)      
        return 100
end

function killSteal()
    for i = 1, heroManager.iCount, 1 do
        if ksTarget == nil then
            local damage = 0
            local eTarget = heroManager:getHero(i)
            if ValidTarget(eTarget, eRange) then                
                local qDmg = myHero:CalcDamage(eTarget,(GetSpellData(_Q).level*40) + myHero.totalDamage*1.3) --This is correct for Talon without his passive
                if QREADY then 
                    damage = qDmg
                end
                if EREADY then 
                    damage = damage * (1 + GetSpellData(_E).level*0.03)   
                end 
                if WREADY then 
                    damage = damage + myHero:CalcDamage(eTarget,(GetSpellData(_W).level*25) + myHero.totalDamage*0.6)
                end
                if damage > eTarget.health then
                    ksTarget = eTarget
                end
            end
        end
    end
    if ksTarget and GetDistance(ksTarget)<eRange then
        if ValidTarget(ksTarget) and WREADY then
            W(ksTarget)
        end
        if ValidTarget(ksTarget) and QREADY and EREADY then
            E(ksTarget)
        end
        if ValidTarget(ksTarget) and QREADY then
            if GetDistance(ksTarget) <= 125 then
                Q(ksTarget)
            end
        end
		if ValidTarget(ksTarget) then
			if CanAtk() then
				Attack(ksTarget)
			end
		end
				
    else 
      ksTarget = nil
    end
end

function getNearestMinion(unit)

	local closestMinion = nil
	local nearestDistance = 0

		Minions:update()
		JungleMinions:update()
		for index, minion in pairs(Minions.objects) do
			if minion ~= nil and minion.valid and string.find(minion.name,"Minion_") == 1 and minion.team ~= player.team and minion.dead == false then
				if GetDistance(minion) <= eRange then
					if nearestDistance < GetDistance(unit, minion) then
						nearestDistance = GetDistance(minion)
						closestMinion = minion
					end
				end
			end
		end
		for index, minion in pairs(JungleMinions.objects) do
			if minion ~= nil and minion.valid and minion.dead == false then
				if GetDistance(minion) <= eRange then
                    if nearestDistance < GetDistance(unit, minion) then
						nearestDistance = GetDistance(minion)
						closestMinion = minion
					end
				end
			end
		end
		for i = 1, heroManager.iCount, 1 do
			local minion = heroManager:getHero(i)
			if ValidTarget(minion, eRange) then
				if GetDistance(minion) <= eRange then
                    if nearestDistance < GetDistance(unit, minion) then
						nearestDistance = GetDistance(minion)
						closestMinion = minion
					end
				end
			end
		end
	return closestMinion
end

function flee()
	mPos = getNearestMinion(mousePos)
	if EREADY and mPos and GetDistance(mPos, mousePos) < GetDistance(mousePos) then
		E(mPos) 
	else 
		myHero:MoveTo(mousePos.x, mousePos.z) 
	end
end

function OnCreateObj(obj)
    --[[
    if GetDistance(obj) < 100 and obj.name:lower():find("blood") then 
        local file = io.open("C:\\talon.txt", "a")
        file:write("AS: "..myHero.attackSpeed.." - ANIM: "..animTimeUnchanged.." - WNDUP: ".. os.clock() - attackstart.."\n") 
        file:close()
    end
    ]]--
end
 
function OnDeleteObj(obj)
end


function OnUpdateBuff(unit, buff)
end

function OnGainBuff(unit, buff)
   -- PrintChat(buff.name)
end

function OnLoseBuff(unit, buff)
end

function OnDraw()
    if initDone == true then
        if Config.SMdraw.drawW then
                DrawCircle(myHero.x, myHero.y, myHero.z, w.Range, 0x5544AA)
        end

    	if Target ~= nil and Config.SMdraw.drawTarget then
    		for i=1,3, .5 do
    			DrawCircle(Target.x, Target.y, Target.z, 125+i, 0xFF0000)
    		end
    	end
        
        if Config.SMdraw.drawText then
            for i = 1, heroManager.iCount, 1 do
                local eTarget = heroManager:getHero(i)
                if ValidTarget(eTarget) and GetDistance(eTarget) < 20000 then
                    local pos = WorldToScreen(D3DXVECTOR3(eTarget.x, eTarget.y, eTarget.z))
                    local color, text = calcDmg(eTarget)
                    DrawText(tostring(text),22,pos.x-35 ,pos.y +20,color)   
                end
            end
        end
    end
end

function smartfarm() -- BY LittleRedEye Edited by Jarvis101
    selectMinion()
    for index, minion in pairs(FarmMinions.objects) do
        if ValidTarget(minion) then
            local aDmg = getDmg("AD", minion, myHero)
            if GetDistance(minion) <= (myHero.range + 75) then
                if minion.health < aDmg and CanAtk() then
                    Attack(minion)
                    break
                elseif not IsAtk() then
                    MoveToMouse()
                end
            end
        end
        break
    end
    if not IsAtk() then MoveToMouse() end
end


function farm()
    if ValidTarget(farmMinion, w.Range) then
            if WREADY then
                if Config.SMfarm.useWFarm then
                    W(farmMinion)
                end
            end
            if Config.SMfarm.useQFarm and GetDistance(farmMinion) < 400 then
                CastSpell(_Q)
            end

            if TiamatR and GetDistance(farmMinion) < 400 then CastSpell(Tiamat) end
            if HydraR and GetDistance(farmMinion) < 400 then CastSpell(Hydra) end
            if Config.SMfarm.useAA and CanAtk() then 
				Attack(farmMinion) 
			end
        else
        farmMinion = selectMinion()
        if Config.SMfarm.useMove then myHero:MoveTo(mousePos.x, mousePos.z) end
    end
end

function CanAtk()
    return os.clock() > lastAttack + AAanim + (GetLatency()/2)*0.001
end

function IsAtk()
    return os.clock() < lastAttack + AAwind + (GetLatency()/2)*0.001
end

function SBTW()
	if Target ~= nil then
		local TargetDistance = GetDistance(Target)
		--local CombatRoutine = analyzeCombatDmg(Target)
		
		if BilgeWaterCutlassR then CastSpell(BilgeWaterCutlass, Target) end
		if YoumuuR and TargetDistance < 500 then CastSpell(Youmuu) end
		if OmenR and TargetDistance < 550 then CastSpell(Omen) end
		if RuinedKingR then CastSpell(RuinedKing, Target) end
		if TiamatR and TargetDistance < 400 then CastSpell(Tiamat) end
		if HydraR and TargetDistance < 400 then CastSpell(Hydra) end
		if SwordofDivineR and TargetDistance < 500 then CastSpell(SwordofDivine) end
	
		if Config.SMsbtw.useW and WREADY and TargetDistance < 550 then
			W(pPos)
		end
		if Config.SMsbtw.useE and EREADY and TargetDistance < 600 and TargetDistance > Config.SMsbtw.minDistanceToE then
			E(Target)
		end

        if Config.SMsbtw.useAA and TargetDistance < 150 then
			Action = false
            if Config.SMsbtw.useQ and not IsAtk() and QREADY and ResetAA then
				AAreset = true
				ResetAA = false
				Action = true
				Q(Target)
            end
            if CanAtk() and not AAreset then
				ResetAA = true
				Action = true
				Attack(Target)
			elseif IsAtk() and AAreset then
				Action = true
				AAreset = false
				Attack(Target)
			end
			if not Action and CanAtk() then
				AAreset = false
				ResetAA = false
			end
		end
        if Config.SMsbtw.useR and RREADY and TargetDistance < 500 then
            R(Target)
        end
		
        if Config.SMsbtw.useMove and not IsAtk() then
            myHero:MoveTo(mousePos.x, mousePos.z) 
        end 
	else
		if Config.SMsbtw.useMove and not IsAtk() then
            myHero:MoveTo(mousePos.x, mousePos.z) 
        end
	end
end

function Attack(unit)
	CountDelay = true
    if VIP_USER and Config.SMother.usePackets then
		lastAttack = os.clock()
        --Packet("S_MOVE", {sourceNetworkId = myHero.networkID, type = 2, x = unit.x, y = unit.z}):send()
        myHero:Attack(unit)
    else
		lastAttack = os.clock()
        myHero:Attack(unit)
    end
end


function Q(unit)
	if GetDistance(unit) < 125 then
		if VIP_USER and Config.SMother.usePackets then
			 Packet("S_CAST", {spellId = _Q}):send()
		else
			CastSpell(_Q)
		end
	end
end

function W(unit)
    diffVecT1 = { x = 0, z = 0}
    diffVecT2 = { x = 0, z = 0}

    diffVecT1.x = myHero.x - unit.x
    diffVecT1.z = myHero.z - unit.z

    for i = 1, heroManager.iCount,1 do
        local eTarget = heroManager:getHero(i)
        if ValidTarget(eTarget) and unit ~= eTarget then
            diffVecT2.x = myHero.x - eTarget.x
            diffVecT2.z = myHero.z - eTarget.z
            DP = diffVecT1.x*diffVecT2.x + diffVecT2.z*diffVecT1.z
            alpha = math.acos(DP)
            if alpha < 0.3 * 3.1415 then -- Angle < 60
                unit.x = diffVecT1.x - diffVecT2.x
                unit.z = diffVecT1.z - diffVecT2.z
            end
        end
    end

    if VIP_USER and Config.SMother.usePackets then
        Packet("S_CAST", {spellId = _W, toX=unit.x, toY=unit.z, fromX=unit.x, fromY=unit.z}):send()
    else
        CastSpell(_W, unit.x, unit.z)
    end
end

function E(unit)
    if VIP_USER and Config.SMother.usePackets then
        Packet("S_CAST", {spellId = _E, targetNetworkId = unit.networkID}):send()
    else
        CastSpell(_E, unit)
    end
end

function R(unit)
    firstR = true
	for i = 1, myHero.buffCount, 1 do
		if myHero:getBuff(i).name == "talonshadowassaultbuff" then
			firstR = false
            break
        else
		end
	end
	if firstR then
        if VIP_USER and Config.SMother.usePackets then
            Packet("S_CAST", {spellId = _R}):send()
		else
			CastSpell(_R)
		end
	else
		if useR2() then --and nearestEnemy() < 500 then
            -- SHould only be done when there are enemies in the immediate vicinity --- ***[Already checked before calling this function]*** ---
			if VIP_USER and Config.SMother.usePackets then
                Packet("S_CAST", {spellId = _R}):send()
			else
				CastSpell(_R)
			end
		end
	end
end

function Tiamat()
end

function NonAtkItems(unit)
	if BilgeWaterCutlassR then CastSpell(BilgeWaterCutlass, Target) end
	if YoumuuR then CastSpell(Youmuu) end
	if OmenR and TargetDistance < 550 then CastSpell(Omen) end
	if RuinedKingR then CastSpell(RuinedKing, Target) end
	if TiamatR and TargetDistance < 400 then CastSpell(Tiamat) end
	if HydraR and TargetDistance < 400 then CastSpell(Hydra) end
end

function AutoI()
	if IREADY then
		for i = 1, heroManager.iCount,1 do
			local eTarget = heroManager:getHero(i)
			if ValidTarget(eTarget) and GetDistance(eTarget) < 600 and eTarget.health <= (50 + (20 * myHero.level)) then
				CastSpell(igniteSpell, eTarget)
			end
		end
	end
end

function analyzeCombatDmg(targ)
	local passiveBonus = isTargetCCd(targ)
	local Qdmg = getDmg("Q", targ, myHero, 3)
	local Wdmg = getDmg("W", targ, myHero, 3)
	local Emod = (getDmg("E", targ, myHero, 3)/100) + 1
	local Rdmg = getDmg("R", targ, myHero, 3)
    local AAdmg = 0
    if passiveBonus then
        AAdmg = getDmg("AD", targ, myHero) * 1.1
    else
        AAdmg = getDmg("AD", targ, myHero)
    end
	local Cdmg = Qdmg + AAdmg*2 + Wdmg
	local Blgdmg = (BilgeWaterCutlass and getDmg("BWC", targ, myHero) or 0)
	local Hydradmg = (Hydra and getDmg("HYDRA", targ, myHero) or 0)
	local Tiamatdmg = (Tiamats and getDmg("TIAMAT", targ, myHero) or 0)	
	local RKdmg = (RuinedKing and getDmg("RUINEDKING", targ, myHero) or 0)
	local Itemdmg = Blgdmg + Hydradmg + Tiamatdmg + RKdmg
	
	if Tiamatdmg > 0 then
		Itemdmg = Itemdmg + AAdmg
	end
	
	local escalate = 0
	
	if escalate == 0 and targ.health > Wdmg then
		escalate = 1
	end
	if escalate == 1 and targ.health > Cdmg*Emod then
		escalate = 2
	end
	if escalate == 2 and targ.health > Cdmg*Emod + Itemdmg then
		escalate = 3
	end
	if escalate == 3 and targ.health > (Cdmg + Itemdmg)*Emod then
		escalate = 4
	end
	if escalate == 4 and targ.health > Cdmg + Itemdmg + Rdmg then
		escalate = 5
	end
	if escalate == 5 and targ.health > (Cdmg + Itemdmg + Rdmg)*Emod then
		escalate = 6
	end
		
	return escalate
end

function isTargetCCd(targ)
	for i = 1, targ.buffCount, 1 do
		if targ:getBuff(i).name ~= nil then
			for o = 1, nCC, 1 do
				if string.find(targ:getBuff(i).name, CCtable[o]) then
					return true
				end
			end
		end
	end
	return false
end

function useR2()
    if not myHero.dead then    
        return ((myHero.maxHealth / 100) * myHero.health > Config.SMult.autoRPercent) --If health is above 50%
    end
end
--[[
Config.SMult:addParam("autoRkillable", "Auto-R when Target is killable",SCRIPT_PARAM_ONOFF, true)
Config.SMult:addParam("autoRkNumCast", "Calculate full R damage and ignore safety params for KS",SCRIPT_PARAM_ONOFF, true)
    Config.SMult:addParam("autoRMin", "Auto-R Many Targets", SCRIPT_PARAM_ONOFF, false)
    Config.SMult:addParam("RPercent", "Second R when above % Health",SCRIPT_PARAM_SLICE, 50, 1, 75, 0)
]]--
function autoUlt()
	local champCount = 0
	if Config.SMult.autoRMin then
		for i = 1, heroManager.iCount, 1 do
			local champ = heroManager:getHero(i)
			if ValidTarget(champ) and GetDistance(champ) < 500 then
				champCount = champCount + 1
			end
		end
		if champCount >= Config.SMult.autoRnum then
			R()
		end
	end			
end

function autoUlt2()
    if Config.SMult.autoRkillable then
        if Target.health < getDmg("R", Target, myHero, 1) and RREADY and GetDistance(Target) < 500 then
            R()
        end
        if autoRkNumCast then
            if Target.health < getDmg("R", Target, myHero, 3) and RREADY and GetDistance(Target) < 500 then
                KSR()
            end
        end
    end
end

function KSR()
    if VIP_USER and Config.SMother.usePackets then
        Packet("S_CAST", {spellId = _R}):send()
	else
		CastSpell(_R)
	end
end
