require("BLA_Common") -- load common functions
require('GamsteronPrediction')
require('PussyDamageLib')

local LocalTableSort        = table.sort
local LocalStringFind       = string.find
local inUlt = false

class "Galio"

function Galio:__init()

  self.Q = {Type = _G.SPELLTYPE_CIRCLE, delay=0.10, radius=150, range = 825}
  self.W = {delay=0.01, radius=0, range = 0}
  self.E = {Type = _G.SPELLTYPE_LINE, range = 650,delay=0.20, speed=2300, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_ENEMYHERO, _G.COLLISION_YASUOWALL}}
  self.R = {Type = _G.SPELLTYPE_LINE, range = 4000, width=900, delay=1.25}

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
      if lastMove + 120 > GetTickCount() then
        args.Process = false
      else
        args.Process = true
        lastMove = GetTickCount()
      end
    end
  )
end

function Galio:LoadMenu()

  self.Menu = MenuElement({type = MENU, id = "BLAGalio", name = "SoldierAIO Galio RC 0.1"})

  self.Menu:MenuElement({type = MENU, id = "combo", name = "Combo"})
  self.Menu.combo:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.combo:MenuElement({id = "maxQ", name = "q max distance in Combo", value = 700, min = 30, max = 825, step = 1})

  self.Menu.combo:MenuElement({id = "W", name = "W - if my hp < hp enemy", value = true})

  self.Menu.combo:MenuElement({id = "E", name = "E", value = true})
  self.Menu.combo:MenuElement({id = "EWithoutLogics", name = "E without logics", value = false})
  self.Menu.combo:MenuElement({id = "EInTower", name = "E in the ally tower", value = true})
  self.Menu.combo:MenuElement({id = "EAloneEnemy", name = "E alone enemy and my health >", value = true})
  self.Menu.combo:MenuElement({id = "EAloneEnemyAllyExist", name = "E alone enemy and ally near", value = true})
  self.Menu.combo:MenuElement({id = "EMoreOneHitChance", name = "E 1+ enemy hitchan. and my hp no low", value = true})
  self.Menu.combo:MenuElement({id = "EBackMyAndTowerLife", name = "E enemy back me and tower life", value = true})

  self.Menu.combo:MenuElement({id = "maxE", name = "E max distance in Combo", value = 580, min = 10, max = 650, step = 1})


  self.Menu.combo:MenuElement({id = "R", name = "R", value = true})

  self.Menu.combo:MenuElement({type = MENU, id = "comboUltConfig", name = "Custom Ult"})
  self.Menu.combo.comboUltConfig:MenuElement({id = "maxCountEnemies", name = "Max enemys count", value = 600, min = 0, max = 1000, step = 1})
  self.Menu.combo.comboUltConfig:MenuElement({id = "maxDistance", name = "Max Distance (+ 1200 = insecure) ", value = 1200, min = 0, max = 5500, step = 1})


  self.Menu:MenuElement({type = MENU, id = "harass", name = "Harass"})
  self.Menu.harass:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.harass:MenuElement({id = "E", name = "E", value = true})

  self.Menu:MenuElement({type = MENU, id = "clear", name = "Clear"})
  self.Menu.clear:MenuElement({id = "Q", name = "Q", value = true})

  self.Menu.clear:MenuElement({id = "QMin", name = "Q Min minions", value = 3, min = 1, max = 5, step = 1})
  self.Menu.clear:MenuElement({id = "E", name = "E", value = true})

  self.Menu:MenuElement({type = MENU, id = "lastHit", name = "LastHit"})
  self.Menu.lastHit:MenuElement({id = "Q", name = "Q", value = true})


  self.Menu:MenuElement({type = MENU, id = "auto", name = "Auto (insecure)"})
  self.Menu.auto:MenuElement({id = "W", name = "W", value = true})

  self.Menu:MenuElement({type = MENU, id = "escape", name = "Escape (use Orb Key)"})
  self.Menu.escape:MenuElement({id = "W", name = "W if have >= 1 enemy's <", value = true})
  self.Menu.escape:MenuElement({id = "E", name = "E to ward off the enemy from ally", value = true})

  self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
  self.Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
  --self.Menu.Drawing:MenuElement({id = "W", name = "Draw [W] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})

end


function Galio:Tick()
  if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
    return
  end

  self:Auto()

  if Orb.Modes[ORBWALKER_MODE_COMBO] then
    self:Combo()
  elseif Orb.Modes[ORBWALKER_MODE_HARASS] then
    self:Harass()
  elseif Orb.Modes[ORBWALKER_MODE_LANECLEAR] then
    self:Clear()
  elseif Orb.Modes[ORBWALKER_MODE_LASTHIT] then
    self:LastHit()
  elseif Orb.Modes[ORBWALKER_MODE_FLEE] then

    -- W Start
    if self.Menu.escape.W:Value()  and lastW +160  < GetTickCount() and Ready(_W)
      and self:HeroesAround(700,myHero.pos,TEAM_ENEMY)>=1  then
      Control.CastSpell(HK_W)
      lastW = GetTickCount()
    end
    -- W End

    -- E Start
    -- afastar inimigo de aliado morrendo
    target = self:GetTarget(650)
    numLwHealthAlly = HeroesAroundLowHealthCompMe(380,myHero.pos,TEAM_ENEMY)
   
    if self.Menu.escape.E:Value()  and lastE +140 and Ready(_E)
      and IsValid(target)
      and (target.health*1.30) < myHero.health
      and numLwHealthAlly>=1 then
      Control.CastSpell(HK_E)
      lastE = GetTickCount()
    end

  end

end

function Galio:Combo()

  local target = nil
  local numAround = nil




  -- R Start DOU SE TIVER ALIADO com hp menor que o meu e inimigo perto
  if self.Menu.combo.R:Value() then

    -- Pegar aliados com life menor que o meu
    target = GetObjHeroesAroundLowHealthCompMe(self.Menu.combo.comboUltConfig.maxDistance:Value(),myHero.pos,TEAM_ALLY)

    if IsValid(target) and Ready(_R)  and lastR + 150 < GetTickCount() then
      -- Verificar se tem inimigos perto deles
      numAround=HeroesAround(600,target.pos,TEAM_ENEMY)
      if numAround > 0 and numAround < self.Menu.combo.comboUltConfig.maxCountEnemies:Value() then
        Control.CastSpell(HK_R, target)
        lastR = GetTickCount()
        return
      end

    end
  end

  -- R End



  -- Q Start
  target = self:GetTarget(self.Menu.combo.maxQ:Value())
  if IsValid(target) and Ready(_Q) and lastQ + 150 < GetTickCount() then

    if self.Menu.combo.Q:Value()  then
      local Pred = GetGamsteronPrediction(target, self.Q, myHero)
      if Pred.Hitchance >= _G.HITCHANCE_NORMAL then
        Control.CastSpell(HK_Q, Pred.CastPosition)
        lastQ = GetTickCount()
        return
      end
    end
  end
  -- Q End


  -- E Start
  target = self:GetTarget(self.Menu.combo.maxE:Value())
  if self.Menu.combo.E:Value()  and lastE +120  < GetTickCount() and Ready(_E) and IsValid(target) then

    local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
    local Pred = GetGamsteronPrediction(target, self.E, myHero)
    if Pred.Hitchance >= _G.HITCHANCE_NORMAL  then

      -- Se tiver marcado para dar e sem logicas
      if self.Menu.combo.EWithoutLogics:Value() then
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
        inE=true
      end

      -- Se estiver dentro da minha torre jogo pro alto
      if self.Menu.combo.EInTower:Value() and IsSendUnderTurretAlly(myHero,target.pos) then
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
        inE=true
      else

        numAround = HeroesAroundLowHealthCompMe(500,myHero.pos,TEAM_ENEMY)
        local numAroundAlly = HeroesAround(700,myHero.pos,TEAM_ALLY)
        local countGroupEnemys = HeroesAroundLowHealthCompMe(90,target.pos,TEAM_ENEMY)


        -- se ele estiver sozinho e meu life È maior, jogo pro alto
        if self.Menu.combo.EAloneEnemy :Value()
          and myHero.health > target.health
          and numAround == 0  then
          Control.CastSpell(HK_E,Pred.CastPosition)
          lastE = GetTickCount()
          inE=true
        end

        --¥se ele estiver sozinho e eu tiver com um amigo
        if self.Menu.combo.EAloneEnemyAllyExist :Value()
          and numAround == 0
          and numAroundAlly>0
        then
          Control.CastSpell(HK_E,Pred.CastPosition)
          lastE = GetTickCount()
          inE=true
        end



        -- se tiver inimigo perto dele, meu life n„o tiver muito baixo, amigo perto de mim e puder pegar nos dois, jogo pro alto
        if self.Menu.combo.EMoreOneHitChance :Value()
          and (myHero.health/2) > target.health and numAround > 0
          and numAroundAlly > 0 and countGroupEnemys>0 then
          Control.CastSpell(HK_E,Pred.CastPosition)
          lastE = GetTickCount()
          inE=true
        end

        -- Se eu n√£o conseguir nada e ele tiver atras de mim, jogo pro alto
        if self.Menu.combo.EBackMyAndTowerLife:Value() then
          for i = 1, Game.TurretCount() do
            local turret = Game.Turret(i)
            if turret.isAlly and not turret.dead then
              if turret.pos:DistanceTo(target.pos) < turret.pos:DistanceTo(myHero.pos) then
                local Pred = GetGamsteronPrediction(target, self.E, myHero)
                if  Pred.Hitchance >= _G.HITCHANCE_NORMAL and Ready(_E)  then
                  Control.CastSpell(HK_E,Pred.CastPosition)
                  lastE = GetTickCount()
                  inE=true
                end
              end
            end
          end
        end
      end

    end

    -- W
    target = self:GetTarget(600)
    if Ready(_W) and IsValid(target) and (myHero.health/1.3) < target.health then
      Control.CastSpell(HK_W)
      lastW = GetTickCount()
    end
    -- W End

  end

end

function Galio:Auto()
  -- W Start
  if self.Menu.auto.W:Value()  and lastW +160  < GetTickCount() and Ready(_W)
    and self:HeroesAround(700,myHero.pos,TEAM_ENEMY)>2  then
    Control.CastSpell(HK_W)
    lastW = GetTickCount()
  end
  -- W End

end

function Galio:Harass()


  local target = nil


  -- Q Start
  target = self:GetTarget(800)
  if IsValid(target) and Ready(_Q) and lastQ + 150 < GetTickCount() then
    if self.Menu.harass.Q:Value()  then
      local Pred = GetGamsteronPrediction(target, self.Q, myHero)
      if Pred.Hitchance >= _G.HITCHANCE_HIGH then
        Control.CastSpell(HK_Q, Pred.CastPosition)
        lastQ = GetTickCount()
        return
      end
    end
  end
  -- Q End

  -- E
  target = self:GetTarget(600)
  if self.Menu.harass.E:Value() and IsValid(target) and Ready(_E) and lastE + 120 < GetTickCount()  then
    Control.CastSpell(HK_E,Pred.CastPosition)
    lastE = GetTickCount()
    inE=true
  end

end

function Galio:Clear()


  local eMinions = SDK.ObjectManager:GetEnemyMinions(650)
  for i = 1, #eMinions do
    local target = eMinions[i]

    -- Q Start

    if self.Menu.clear.Q:Value() and IsValid(target) and Ready(_Q) and lastQ + 150 < GetTickCount()
    then

      local count = GetMinionCount(310, target)

      if  self.Menu.clear.QMin:Value() >= count then

        local Pred = GetGamsteronPrediction(target, self.Q, myHero)

        Control.CastSpell(HK_Q, target)
        lastQ = GetTickCount()
        return


      end
    end
    -- Q End


  end

  local eMinions = SDK.ObjectManager:GetEnemyMinions(650)
  for i = 1, #eMinions do
    local target = eMinions[i]

    -- E
   
    if self.Menu.clear.E:Value() and IsValid(target) and Ready(_E) and lastE + 120 < GetTickCount()  then
    
      local Pred = GetGamsteronPrediction(target, self.E, myHero)
      if Pred.Hitchance >= _G.HITCHANCE_NORMAL then
   
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
        inE=true
      end
    end

  end

end


function Galio:LastHit()


  local eMinions = SDK.ObjectManager:GetEnemyMinions(650)
  for i = 1, #eMinions do
    local target = eMinions[i]


    if self.Menu.lastHit.Q:Value() and  IsValid(target) and Ready(_Q) and lastQ + 150 < GetTickCount()
    then
      local WDmg = getdmg("Q", target, myHero, 1)
      local Pred = GetGamsteronPrediction(target, self.Q, myHero)
      if Pred.Hitchance >= _G.HITCHANCE_NORMAL
        and (WDmg > target.health) then
        Control.CastSpell(HK_Q, Pred.CastPosition)
        lastQ = GetTickCount()
        return

      end
    end
  end
  -- Q End


  if self.Menu.lastHit.E:Value() and  IsValid(target) and Ready(_E) and lastE + 120 < GetTickCount()
  then
    local WDmg = getdmg("E", target, myHero, 1)
    if (WDmg > target.health) then
      Control.CastSpell(HK_E,target)
      lastE = GetTickCount()
      inE=true
    end
  end

end


function Galio:Draw()
  if myHero.dead then return  end
  if self.Menu.Drawing.R:Value() and Ready(_R) then
    Draw.Circle(myHero, 4000, 1, Draw.Color(255, 225, 255, 10))
  end
  if self.Menu.Drawing.Q:Value() and Ready(_Q) then
    Draw.Circle(myHero, 850, 1, Draw.Color(225, 225, 0, 10))
  end
  if self.Menu.Drawing.E:Value() and Ready(_E) then
    Draw.Circle(myHero, 650, 1, Draw.Color(225, 225, 125, 10))
  end
end



function GetMinionCount(range, pos)
  if pos == nil then return false end
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

function Galio:GetTarget(range, list)
  local targetList = {}
  local inputList = list or Enemys

  for i = 1, #Enemys do
    local hero = Enemys[i]
    if GetDistanceSquared(hero.pos, myHero.pos) < range * range and IsValid(hero) then
      targetList[#targetList + 1] = hero
    end
  end

  return TargetSelector:GetTarget(targetList)
end

function Galio:GetTargetInRange(range, target)
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


function Galio:GetHeroInRange(range, target)

  for i = 1, #Enemys do
    local hero = Enemys[i]
    if IsValid(hero) then
      if GetDistanceSquared(target.pos, hero.pos) < range * range then
        return hero
      end
    end
  end
end


function Galio:HeroesAround(range, pos, team)
  pos = pos or myHero.pos
  team = team or foe
  Count = 0
  for i = 1, Game.HeroCount() do
    hero = Game.Hero(i)
    if hero and hero.team == team and not hero.dead and GetDistanceSquared(pos, hero.pos) < range then
      Count = Count + 1
    end
  end
  return Count
end



Galio()
