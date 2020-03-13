require("BLA_Common") -- load common functions
require('GamsteronPrediction')
require('PussyDamageLib')

GameMinionCount      = Game.MinionCount;

GameMinion         = Game.Minion;

class "Darius"

local function GetEnemyHeroes()
  return Enemies
end

function GetMinionCount(range, pos)
  local pos = pos.pos
  local count = 0
  for i = 1,Game.MinionCount() do
    local hero = Game.Minion(i)
    local Range = range * range
    if hero.team ~= TEAM_ALLY and hero.dead == false and GetDistanceSquared(pos, hero.pos) < Range then
      count = count + 1
    end
  end
  return count
end

function Darius:__init()

  self.Q =   {Type = _G.SPELLTYPE_CIRCLE, Delay = 0.25, Radius = 425, Range = 450,  Collision = false }
  self.W =   {Type = _G.SPELLTYPE_LINE, Range = 145, Collision = true }
  self.E =   {Type = _G.SPELLTYPE_LINE, Range = 550-20, Collision = true } -- decress range by acert
  self.R =   {Type = _G.SPELLTYPE_LINE, Range = 460 }


  self:LoadMenu()

  OnAllyHeroLoad(function(hero)
    TableInsert(Allys, hero);
  end)

  OnEnemyHeroLoad(function(hero)
    TableInsert(Enemys, hero);
  end)

  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)

  Orb:OnPreMovement(
    function(args)
      if lastMove + 60 > GetTickCount() then
        args.Process = false
      else
        args.Process = true
        lastMove = GetTickCount()
      end
    end
  )
end

function Darius:LoadMenu()

  Menu = MenuElement({type = MENU, id = "BLADarius", name = "Darius RC 0.1"})

  --ComboMenu
  Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
  Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
  Menu.Combo:MenuElement({id = "UseR", name = "[R]", value = true})
  Menu.Combo:MenuElement({id = "ignite", name = "Ignite in Combo", value = true})
  Menu.Combo:MenuElement({id = "exaust", name = "Exhaust in Combo", value = true})
  Menu.Combo:MenuElement({id = "ignitehp", name = "Ignite HP:", value = 35, min = 5, max = 95, identifier = "%"})


  -- Harasss
  Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  Menu.Harass:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.Harass:MenuElement({id = "UseW", name = "[W]", value = false})
  Menu.Harass:MenuElement({id = "UseE", name = "[E]", value = false})
  Menu.Harass:MenuElement({id = "HarassMinMana", name = "Harass Min Mana ", value = 30, min = 0, max = 100, identifier = "%"})

  -- Auto
  Menu:MenuElement({type = MENU, id = "Auto", name = "Auto"})
  Menu.Auto:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.Auto:MenuElement({id = "UseE", name = "[E]", value = true})
  Menu.Auto:MenuElement({id = "UseR", name = "[R]", value = true})

  -- LastHit
  Menu:MenuElement({type = MENU, id = "LastHit", name = "LastHit"})
  Menu.LastHit:MenuElement({id = "UseQ", name = "[Q]", value = false})
  Menu.LastHit:MenuElement({id = "UseW", name = "[W]", value = true})
  Menu.LastHit:MenuElement({id = "Qmin", name = "[Q] If Hit X Minion ", value = 2, min = 1, max = 6, step = 1, identifier = "Minion/s"})
  Menu.LastHit:MenuElement({id = "QMinMana", name = "[Q] Min Mana ", value = 30, min = 0, max = 100, identifier = "%"})



  --LaneClear Menu
  Menu:MenuElement({type = MENU, id = "Clear", name = "LaneClear"})
  Menu.Clear:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.Clear:MenuElement({id = "UseE", name = "[E]", value = false})
  Menu.Clear:MenuElement({id = "UseW", name = "[W]", value = true})
  Menu.Clear:MenuElement({id = "Qmin", name = "[Q] If Hit X Minion ", value = 2, min = 1, max = 6, step = 1, identifier = "Minion/s"})
  Menu.Clear:MenuElement({id = "CleanMinMana", name = "Clean Min Mana ", value = 30, min = 0, max = 100, identifier = "%"})

  --JungleClear
  Menu:MenuElement({type = MENU, id = "JClear", name = "JungleClear"})
  Menu.JClear:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.JClear:MenuElement({id = "UseW", name = "[W]", value = true})
  Menu.JClear:MenuElement({id = "UseE", name = "[E]", value = false})
  Menu.JClear:MenuElement({id = "CleanMinMana", name = "Clean Min Mana ", value = 30, min = 0, max = 100, identifier = "%"})

  --Prediction
  Menu:MenuElement({type = MENU, id = "Pred", name = "Prediction"})
  Menu.Pred:MenuElement({id = "PredE", name = "Hitchance [E]", value = 1, drop = {"Normal", "High", "Immobile"}})
  Menu.Pred:MenuElement({id = "PredQ", name = "Hitchance [Q]", value = 1, drop = {"Normal", "High", "Immobile"}})

  --Drawing
  Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
  Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q]", value = false})
  Menu.Drawing:MenuElement({id = "W", name = "Draw [W]", value = false})
  Menu.Drawing:MenuElement({id = "E", name = "Draw [E]", value = false})
  Menu.Drawing:MenuElement({id = "R", name = "Draw [R]", value = false})

end


function Darius:Tick()
  if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
    return
  end


  self:Auto()



  if Orb.Modes[ORBWALKER_MODE_COMBO] then
    self:Combo()
    self:castIginite()
    self:castExaust()
  elseif Orb.Modes[ORBWALKER_MODE_HARASS] then
    self:Harass()
  elseif Orb.Modes[ORBWALKER_MODE_LASTHIT] then
    self:LastHit()
  elseif Orb.Modes[ORBWALKER_MODE_LANECLEAR] then
    self:Clear()
    self:JungleClear()
  elseif Orb.Modes[ORBWALKER_MODE_FLEE] then
    self:castExaust()
  end

end

function Darius:Auto()


  local target = self:GetTarget(550)
  if target == nil then return end

  -- E Logic to send tower ally
  local finalPos = target.pos:Extended(myHero.pos, 0)

  -- Logica para mandar para torre aliada
  if IsSendUnderTurretAlly(myHero,finalPos) then
    if myHero.pos:DistanceTo(target.pos) < self.E.Range and Menu.Auto.UseE:Value() and Ready(_E)  then
      local pred = GetGamsteronPrediction(target, self.E, myHero)
      if pred.Hitchance >= 2 then
        Control.CastSpell(HK_E, pred.CastPosition)
      end
    end
  end

  -- KS Q Logic
  if myHero.pos:DistanceTo(target.pos) < self.Q.Range and Menu.Auto.UseQ:Value() and Ready(_Q)  then
    local WDmg = getdmg("Q", target, myHero, 1)
    if (WDmg > target.health) then
      Control.CastSpell(HK_Q, target.pos)
    end
  end

  -- KS R Logic
  if myHero.pos:DistanceTo(target.pos) < self.R.Range and Menu.Auto.UseR:Value() and Ready(_R)
    and  self:GetRdmg(target) > target.health  then
    Control.CastSpell(HK_R, target)

  end

end


function Darius:Combo()

  local target = self:GetTarget(550)
  if target == nil then return end

  if IsValid(target) then

    -- Q logic
    if myHero.pos:DistanceTo(target.pos) < self.Q.Range and Menu.Combo.UseQ:Value() and Ready(_Q) and self:HasPassiveBuff(myHero) then
      _G.SDK.Orbwalker:SetAttack(false)
      _G.SDK.Orbwalker:SetMovement(false)
      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)^2
      if myHero.pos:DistanceTo(target.pos) > 350 then
        Control.Move(myHero.pos:Extended(target.pos, distanceSqr + 500))
      end
      if myHero.pos:DistanceTo(target.pos) < 350 then
        Control.Move(target.pos:Extended(myHero.pos, distanceSqr + 500))
      end

      local pred = GetGamsteronPrediction(target, self.Q, myHero)
      if pred.Hitchance >= Menu.Pred.PredQ:Value()+1 then
        Control.CastSpell(HK_Q)
      end

      _G.SDK.Orbwalker:SetAttack(true)
      _G.SDK.Orbwalker:SetMovement(true)
    end

    -- Q Logic
    if myHero.pos:DistanceTo(target.pos) < self.Q.Range and Menu.Combo.UseQ:Value() and Ready(_Q) then
      _G.SDK.Orbwalker:SetAttack(false)
      _G.SDK.Orbwalker:SetMovement(false)
      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)^2
      if myHero.pos:DistanceTo(target.pos) > 350 then
        Control.Move(myHero.pos:Extended(target.pos, distanceSqr + 500))
      end
      if myHero.pos:DistanceTo(target.pos) < 350 then
        Control.Move(target.pos:Extended(myHero.pos, distanceSqr + 500))
      end

      local pred = GetGamsteronPrediction(target, self.Q, myHero)
      if pred.Hitchance >= Menu.Pred.PredQ:Value()+1 then
        Control.CastSpell(HK_Q)
      end

      _G.SDK.Orbwalker:SetAttack(true)
      _G.SDK.Orbwalker:SetMovement(true)
    end

    -- E logic combo
    if myHero.pos:DistanceTo(target.pos) < self.E.Range and Menu.Combo.UseE:Value() and Ready(_E) then
      local pred = GetGamsteronPrediction(target, self.E, myHero)
      if pred.Hitchance >= Menu.Pred.PredE:Value()+1 then
        Control.CastSpell(HK_E, pred.CastPosition)
      end
    end
  end

  -- W Logic
  if myHero.pos:DistanceTo(target.pos) < self.W.Range-30 and Menu.Combo.UseW:Value() and Ready(_W) then
    Control.CastSpell(HK_W,target.pos)
  end

  -- R Logic
  if myHero.pos:DistanceTo(target.pos) < self.R.Range-30 and Menu.Combo.UseR:Value() and Ready(_R)
    and self:GetRdmg(target) > target.health then
    Control.CastSpell(HK_R, target.pos)
  end
end

function Darius:Harass()

  local target = self:GetTarget(550)
  if target == nil then return end

  if IsValid(target) 
      and  myHero.mana/myHero.maxMana >= Menu.Harass.HarassMinMana:Value() / 100 then
    -- Q logic
    if myHero.pos:DistanceTo(target.pos) < self.Q.Range and Menu.Harass.UseQ:Value() and Ready(_Q) and self:HasPassiveBuff(myHero) then
      Orb:DisableMovement(true)

      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)^2
      if myHero.pos:DistanceTo(target.pos) > 350 then
        Control.Move(myHero.pos:Extended(target.pos, distanceSqr + 500))
      end
      if myHero.pos:DistanceTo(target.pos) < 350 then
        Control.Move(target.pos:Extended(myHero.pos, distanceSqr + 500))
      end

      local pred = GetGamsteronPrediction(target, self.Q, myHero)
      if pred.Hitchance >= Menu.Pred.PredQ:Value()+1 then
        Control.CastSpell(HK_Q)
      end

      Orb:DisableMovement(false)
    end

    -- Q Logic
    --    if myHero.pos:DistanceTo(target.pos) < self.Q.Range and Menu.Harass.UseQ:Value() and Ready(_Q) then
    --      local pred = GetGamsteronPrediction(target, self.Q, myHero)
    --      if pred.Hitchance >= Menu.Pred.PredQ:Value()+1 then
    --        Control.CastSpell(HK_Q)
    --      end
    --    end

    -- E logic combo
    if myHero.pos:DistanceTo(target.pos) < self.E.Range and Menu.Harass.UseE:Value() and Ready(_E) then
      local pred = GetGamsteronPrediction(target, self.E, myHero)
      if pred.Hitchance >= Menu.Pred.PredE:Value()+1 then
        Control.CastSpell(HK_E, pred.CastPosition)
      end
    end
  end

  -- W Logic
  if myHero.pos:DistanceTo(target.pos) < self.W.Range-30 and Menu.Harass.UseW:Value() and Ready(_W) then
    Control.CastSpell(HK_W,target.pos)
  end
end


function Darius:Clear()
  for i = 1, GameMinionCount() do
    local minion = GameMinion(i)
    if IsValid(minion) 
      and  myHero.mana/myHero.maxMana >= Menu.Clear.CleanMinMana:Value() / 100 then
      -- Q
      if Menu.Clear.UseQ:Value() and Ready(_Q)
        and myHero.pos:DistanceTo(minion.pos) <= self.Q.Range
        and myHero.pos:DistanceTo(minion.pos) > 250
        and minion.team == TEAM_ENEMY and IsValid(minion) then

        local count = GetMinionCount(160, minion)
        if count >= Menu.Clear.Qmin:Value() then
          Control.CastSpell(HK_Q, minion.pos)
        end
      end

      -- W
      if myHero.pos:DistanceTo(minion.pos) <= self.W.Range and Menu.Clear.UseW:Value() and Ready(_W) then
        Control.CastSpell(HK_W, minion.pos)
      end

    end
  end
end



function Darius:LastHit()

  for i = 1, GameMinionCount() do
    local minion = GameMinion(i)

    if IsValid(minion) then

      -- Q
      if Menu.LastHit.UseQ:Value() and Ready(_Q)
        and myHero.pos:DistanceTo(minion.pos) <= self.Q.Range
        and myHero.pos:DistanceTo(minion.pos) > 80
        and minion.team == TEAM_ENEMY and IsValid(minion) then

        local count = GetMinionCount(160, minion)
        if count >= Menu.LastHit.Qmin:Value() then
          local WDmg = getdmg("Q", minion, myHero, 1)
          if (WDmg > minion.health+10) 
          and  myHero.mana/myHero.maxMana >= Menu.LastHit.QMinMana:Value() / 100 then
            Control.CastSpell(HK_Q)
          end
        end
      end

      -- W
      if myHero.pos:DistanceTo(minion.pos) <= self.W.Range and Menu.LastHit.UseW:Value() and Ready(_W) then
        local WDmg = getdmg("W", minion, myHero, 1)
        if (WDmg > minion.health) then
          Control.CastSpell(HK_W, minion.pos)
        end
      end
    end
  end
end



function Darius:JungleClear()
  for i = 1, GameMinionCount() do
    local minion = GameMinion(i)

    if IsValid(minion)  
      and  myHero.mana/myHero.maxMana >= Menu.JClear.CleanMinMana:Value() / 100 then

      -- Q logic
      if myHero.pos:DistanceTo(minion.pos) < self.Q.Range and Menu.JClear.UseQ:Value() and Ready(_Q) then
        _G.SDK.Orbwalker:SetAttack(false)
        _G.SDK.Orbwalker:SetMovement(false)

        local distanceSqr = GetDistanceSquared(myHero.pos, minion.pos)^2
        if myHero.pos:DistanceTo(minion.pos) > 350 then
          Control.Move(myHero.pos:Extended(minion.pos, distanceSqr + 500))
        end
        if myHero.pos:DistanceTo(minion.pos) < 350 then
          Control.Move(minion.pos:Extended(myHero.pos, distanceSqr + 500))
        end

        local pred = GetGamsteronPrediction(minion, self.Q, myHero)
        if pred.Hitchance >= Menu.Pred.PredQ:Value()+1 then
          Control.CastSpell(HK_Q)
        end
        _G.SDK.Orbwalker:SetAttack(true)
        _G.SDK.Orbwalker:SetMovement(true)
      end

      -- Q Logic
      if myHero.pos:DistanceTo(minion.pos) < self.Q.Range and Menu.Harass.UseQ:Value() and Ready(_Q) then
        local pred = GetGamsteronPrediction(minion, self.Q, myHero)
        if pred.Hitchance >= Menu.Pred.PredQ:Value()+1 then
          Control.CastSpell(HK_Q)
        end
      end

      if Menu.JClear.UseW:Value() and Ready(_W) then
        Control.CastSpell(HK_W, minion.pos)
      end

      if myHero.pos:DistanceTo(minion.pos) <= self.E.Range and Menu.JClear.UseE:Value() and Ready(_E) then
        Control.CastSpell(HK_E, minion.pos)
      end
    end
  end
end


function GetMinionCount(range, pos)
  local pos = pos.pos
  local count = 0
  for i = 1,Game.MinionCount() do
    local hero = Game.Minion(i)
    local Range = range * range
    if hero.team ~= TEAM_ALLY and hero.dead == false and GetDistanceSquared(pos, hero.pos) < Range then
      count = count + 1
    end
  end
  return count
end



function Darius:castIginite()
  if Menu.Combo.ignite:Value() == false then return end
  for i = 1, #Enemys do
    local target = Enemys[i]
    if IsValid(target)  and myHero.pos:DistanceTo(target.pos) <= 580 then
      local TargetHp = target.health/target.maxHealth

      if TargetHp <= Menu.Combo.ignitehp:Value()/100 then
        if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
          Control.CastSpell(HK_SUMMONER_1, target)
        elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
          Control.CastSpell(HK_SUMMONER_2, target)

        end

      end
    end
  end

end

-- ok
function Darius:castExaust()
  if Menu.Combo.exaust:Value() == false then return end
  for i = 1, #Enemys do
    local target = Enemys[i]
    if IsValid(target)  and myHero.pos:DistanceTo(target.pos) <= 600 then
      if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" and Ready(SUMMONER_1) then
        Control.CastSpell(HK_SUMMONER_1, target)
      elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_2) then
        Control.CastSpell(HK_SUMMONER_2, target)
      end
    end
  end
end


function Darius:GetTarget(range, list)
  local targetList = {}
  local inputList = list or Enemys
  for i = 1, #inputList do
    local hero = inputList[i]
    if GetDistanceSquared(hero.pos, myHero.pos) < range * range and IsValid(hero) then
      targetList[#targetList + 1] = hero
    end
  end

  return TargetSelector:GetTarget(targetList)
end

function Darius:GetTargetInRange(range, target)
  local counter = 0
  for i = 1, #Enemys do
    local hero = Enemys[i]
    if IsValid(hero) then
      if GetDistanceSquared(target.pos, hero.pos) < range * range then
        counter = counter + 1
      end
    end
  end
  return counter
end


function Darius:GetRdmg(unit)

  local totalDmg = 0
  if unit then
    local rLvl = myHero:GetSpellData(_R).level
    if rLvl > 0 then
      local count = self:GetHemoCount(unit)
      local stackDmg = ({ 20, 40, 60 })[rLvl]
      local baseDmg = ({ 100, 200, 300 })[rLvl]
      local ad = 0.75 * myHero.bonusDamage
      local ad2 = 0.15 * myHero.bonusDamage
      totalDmg = totalDmg + baseDmg + ad + (count * (stackDmg + ad2))
    end
  end
  return totalDmg
end


function Darius:GetHemoCount(unit)

  if unit then
    for i = 1, unit.buffCount do
      local buff = unit:GetBuff(i)
      if buff and buff.count > 0 and buff.name:lower() == "dariushemo" then
        return buff.count
      end
    end
  end
  return 0
end

function Darius:Draw()
  if myHero.dead then return  end
  if Menu.Drawing.R:Value() and Ready(_R) then
    Draw.Circle(myHero, 460, 1, Draw.Color(255, 225, 255, 10))
  end
  if Menu.Drawing.Q:Value() and Ready(_Q) then
    Draw.Circle(myHero, 425, 1, Draw.Color(225, 225, 0, 10))
  end
  if Menu.Drawing.E:Value() and Ready(_E) then
    Draw.Circle(myHero, 550, 1, Draw.Color(225, 225, 125, 10))
  end
end

function Darius:HasPassiveBuff(unit)
  local name = "dariusqcast"
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff and buff.count > 0 and buff.name == name then
      return true, buff.duration, buff.count
    end
  end
  return false
end



Darius()
