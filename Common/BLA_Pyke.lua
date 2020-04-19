require("BLA_Common") -- load common functions
require('GamsteronPrediction')

GameMinionCount      = Game.MinionCount;
GameMinion         = Game.Minion;
GameTimer        = Game.Timer;

class "Pyke"

local function QCastTime(unit)
  return (((myHero.pos:DistanceTo(unit) - 400) / 140) / 10) + 0.75
end

local function HasBuff(unit, buffname)
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.name == buffname and buff.count > 0 then
      return true
    end
  end
  return false
end

function UltDamage()
  local LvL = myHero.levelData.lvl
  local Dmg1 = ({250, 250, 250, 250, 250, 250, 290, 330, 370, 400, 430, 450, 470, 490, 510, 530, 540, 550})[LvL]
  local Dmg2 = 0.8 * myHero.bonusDamage + 1.5 * myHero.armorPen

  local RDmg = nil

  if Dmg1 ~= nill then
    RDmg = Dmg1 + Dmg2
  else
    RDmg = Dmg2
  end


  return RDmg
end


function Pyke:__init()

  -- dados dos feiticos
  EData = { Type = _G.SPELLTYPE_LINE, Collision = false, Delay = 0.28, Radius = 60, Range = 550, Speed = 500  }
  QData = { Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 55, Range = 1000, Speed = 1700, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}   }
  QDataJungle =  { Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 55, Range = 1000, Speed = 1700, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_YASUOWALL}    }
  RData =  { Type = _G.SPELLTYPE_CIRCLE, Collision = false, Delay = 0.5, Radius = 250, Range = 750, Speed = 1000 }

  self:LoadMenu()
  
  
  OnAllyHeroLoad(function(hero)
    TableInsert(Allys, hero);
  end)

  OnEnemyHeroLoad(function(hero)
    TableInsert(Enemys, hero);
  end)
  

  Callback.Add("Tick", function() self:Tick() end)


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

function Pyke:LoadMenu()

  Menu = MenuElement({type = MENU, id = "BLAPyke", name = "PussyAIO Pyke Mod RC 0.1"})

  --ComboMenu
  Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.Combo:MenuElement({id = "QRange", name = "Use[Q] if range bigger than -->", value = 400, min = 0, max = 1100, step = 10})
  Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
  Menu.Combo:MenuElement({id = "UseR", name = "[R] Kill", value = true})
  Menu.Combo:MenuElement({type = MENU, id = "W", name = "W Setting"})
  Menu.Combo.W:MenuElement({id = "UseW", name = "[W]", value = true})
  Menu.Combo.W:MenuElement({id = "WRange", name = "Use[W] if range bigger than -->", value = 500, min = 0, max = 1000, step = 10})

  --JungleMenu
  Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  Menu.Harass:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.Harass:MenuElement({id = "QRange", name = "Use[Q] if range bigger than -->", value = 400, min = 0, max = 1100, step = 10})


  --JungleMenu
  Menu:MenuElement({type = MENU, id = "Jungle", name = "Jungle"})
  Menu.Jungle:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.Jungle:MenuElement({id = "QRange", name = "Use[Q] if range bigger than -->", value = 10, min = 0, max = 1100, step = 10})
  Menu.Jungle:MenuElement({id = "UseE", name = "[E]", value = true})

  --ClearMenu
  Menu:MenuElement({type = MENU, id = "Clear", name = "Clear"})
  Menu.Clear:MenuElement({id = "UseE", name = "[E]", value = true})


  --Prediction
  Menu:MenuElement({type = MENU, id = "Pred", name = "Prediction"})
  Menu.Pred:MenuElement({id = "PredQ", name = "Hitchance[Q]", value = 1, drop = {"Normal", "High", "Immobile"}})
  Menu.Pred:MenuElement({id = "PredE", name = "Hitchance[E]", value = 1, drop = {"Normal", "High", "Immobile"}})
  Menu.Pred:MenuElement({id = "PredR", name = "Hitchance[R]", value = 1, drop = {"Normal", "High", "Immobile"}})


end


function Pyke:Tick()
  if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
    return
  end

  if Orb.Modes[ORBWALKER_MODE_COMBO] then
    self:Ult()
    self:Combo()
  elseif Orb.Modes[ORBWALKER_MODE_HARASS] then
    self:Harass()
  elseif Orb.Modes[ORBWALKER_MODE_LANECLEAR] then
    self:Clear()
    self:JungleClear()
  end

end

function Pyke:Ult()
  local target = self:GetTarget(800)
  if target == nil then return end
  local buff1 = HasBuff(target, "PykeQMelee")
  local buff2 = HasBuff(myHero, "PykeQ")
  local startR = 0
  local RTarget = nil

  if not buff1 and not buff2 and Menu.Combo.UseR:Value() and Ready(_R) and IsValid(target) and myHero.pos:DistanceTo(target.pos) < 750 then
    local RDmg = UltDamage()
    if RDmg >= target.health then
      if GameTimer() - startR < 2 and RTarget == target then return end

      local pred = GetGamsteronPrediction(target, RData, myHero)
      if pred.Hitchance >= Menu.Pred.PredR:Value()+1 then
        Control.CastSpell(HK_R, pred.CastPosition)
        startR = GameTimer()
        RTarget = target
      end
    end
  end
end


function Pyke:Combo()

  local target = self:GetTarget(1050)
  
  if target == nil then return end
  if IsValid(target) then

    -- cast Q
    if Menu.Combo.UseQ:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) >= Menu.Combo.QRange:Value()
      and myHero.pos:DistanceTo(target.pos) < 1050 then

      local pred = GetGamsteronPrediction(target, QData, myHero)
      local Time = QCastTime(pred.CastPosition)

      if pred.Hitchance >= Menu.Pred.PredQ:Value()+1 then

        CastQReady = true

        -- Apertar o Q
        Control.KeyDown(HK_Q)

        _G.SDK.Orbwalker:SetAttack(false)

        -- Soltar o q
        DelayAction(
          function()

            _G.SDK.Orbwalker:SetMovement(false)
            Control.SetCursorPos(pred.CastPosition) -- Coloco em cima do cara
            Control.KeyUp(HK_Q) -- Libero o Q

            -- Libero movimentos
            _G.SDK.Orbwalker:SetMovement(true)
            _G.SDK.Orbwalker:SetAttack(true)
            CastQReady = false

          end, Time
        )
      end
    end

    -- cast E
    if Menu.Combo.UseE:Value() and myHero.pos:DistanceTo(target.pos) > 100 and myHero.pos:DistanceTo(target.pos) <= 400
      and Ready(_E) and ((Ready(_Q) and not CastQReady) or not Ready(_Q)) then
      local pred = GetGamsteronPrediction(target, EData, myHero)
      if pred.Hitchance >= Menu.Pred.PredE:Value()+1 then
        _G.SDK.Orbwalker:SetMovement(false)
        Control.CastSpell(HK_E, pred.CastPosition)
        _G.SDK.Orbwalker:SetMovement(true)
      end
    end

    if Menu.Combo.W.UseW:Value() and myHero.pos:DistanceTo(target.pos) > Menu.Combo.W.WRange:Value() and Ready(_W) then
      Control.CastSpell(HK_W)
    end

  end
end

function Pyke:Harass()
  local target = self:GetTarget(1050)
  if target == nil then return end
  if IsValid(target) then

    -- cast Q
    if Menu.Harass.UseQ:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) >= Menu.Harass.QRange:Value()
      and myHero.pos:DistanceTo(target.pos) < 1050 then

      local pred = GetGamsteronPrediction(target, QData, myHero)
      local Time = QCastTime(pred.CastPosition)

      if pred.Hitchance >= Menu.Pred.PredQ:Value()+1 then

        CastQReady = true

        -- Apertar o Q
        Control.KeyDown(HK_Q)

        _G.SDK.Orbwalker:SetAttack(false)

        -- Soltar o q
        DelayAction(
          function()

            _G.SDK.Orbwalker:SetMovement(false)
            Control.SetCursorPos(pred.CastPosition) -- Coloco em cima do cara
            Control.KeyUp(HK_Q) -- Libero o Q

            -- Libero movimentos
            _G.SDK.Orbwalker:SetMovement(true)
            _G.SDK.Orbwalker:SetAttack(true)
            CastQReady = false

          end, Time
        )
      end
    end
  end

end

function Pyke:Clear()
  for i = 1, GameMinionCount() do
    local minion = GameMinion(i)
    if myHero.pos:DistanceTo(minion.pos) <= 400 and minion.team == TEAM_ENEMY and IsValid(minion) then



      -- cast E
      if Menu.Clear.UseE:Value() and myHero.pos:DistanceTo(minion.pos) > 100 and myHero.pos:DistanceTo(minion.pos) <= 400
        and Ready(_E) and ((Ready(_Q) and not CastQReady) or not Ready(_Q)) then
        local pred = GetGamsteronPrediction(minion, EData, myHero)
        if pred.Hitchance >= Menu.Pred.PredE:Value()+1 then
          _G.SDK.Orbwalker:SetMovement(false)
          Control.CastSpell(HK_E, pred.CastPosition)
          _G.SDK.Orbwalker:SetMovement(true)
        end
      end

    end
  end
end

function Pyke:JungleClear()

  for i = 1, GameMinionCount() do
    local minion = GameMinion(i)
    if myHero.pos:DistanceTo(minion.pos) <= 1000 and minion.team == TEAM_JUNGLE and IsValid(minion) then
      -- cast Q
      if Menu.Jungle.UseQ:Value() and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) >= Menu.Jungle.QRange:Value()
        and myHero.pos:DistanceTo(minion.pos) < 1000 then

        local pred = GetGamsteronPrediction(minion, QDataJungle, myHero)
        local Time = QCastTime(pred.CastPosition)

        if pred.Hitchance >= Menu.Pred.PredQ:Value()+1 then
          CastQReady = true

          -- Apertar o Q
          Control.KeyDown(HK_Q)

          _G.SDK.Orbwalker:SetAttack(false)

          -- Soltar o q
          DelayAction(
            function()

              _G.SDK.Orbwalker:SetMovement(false)
              Control.SetCursorPos(pred.CastPosition) -- Coloco em cima do cara
              Control.KeyUp(HK_Q) -- Libero o Q

              -- Libero movimentos
              _G.SDK.Orbwalker:SetMovement(true)
              _G.SDK.Orbwalker:SetAttack(true)
              CastQReady = false

            end, Time
          )
        end
      end


      -- cast E
      if Menu.Jungle.UseE:Value() and myHero.pos:DistanceTo(minion.pos) > 100 and myHero.pos:DistanceTo(minion.pos) <= 400
        and Ready(_E) and ((Ready(_Q) and not CastQReady) or not Ready(_Q)) then
        local pred = GetGamsteronPrediction(minion, EData, myHero)
        if pred.Hitchance >= Menu.Pred.PredE:Value()+1 then
          _G.SDK.Orbwalker:SetMovement(false)
          Control.CastSpell(HK_E, pred.CastPosition)
          _G.SDK.Orbwalker:SetMovement(true)
        end
      end



    end
  end

end


function Pyke:GetTarget(range, list)

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


Pyke()
