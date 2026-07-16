local Entity               = require 'src.entity'
local Player               = Entity:extend()
local Debug                = require 'src.debug'

-- size --
local WIDTH                = 42
local HEIGHT               = 115
local SPRITE_OFFSET_X      = -123 -- lower number moves sprite to the left
local SPRITE_OFFSET_Y      = -138 -- lower number moves sprite up
local SCALE_X              = 3
local SCALE_Y              = 3

-- movement --
local WALK_SPEED           = 150
local RUN_SPEED            = 350
local SPRINT_SPEED         = 600
local DASH_DURATION        = 0.3
local JUMP_FORCE           = -900 -- jump height
local JUMP_CUT             = 0.4
local COYOTE_TIME          = 0.1  -- seconds you can still jump after walking off a ledge
local JUMP_BUFFER          = 0.1  -- seconds before landing that a jump input is remembered

-- attack --
local PLAYER_HEALTH        = 10
local INVINCIBILITY_TIME   = 1.0
local HITBOX_WIDTH         = 100
local UNARMED_COMBO        = { 'kick_2', 'punch_1', 'kick_3' }
local SWORD_COMBO          = { 'sword_attack_1', 'sword_attack_2', 'sword_attack_3', 'sword_attack_4' }

local MAX_STAMINA          = 100
local STAMINA_REGEN        = 30
local STAMINA_JUMP_COST    = 15
local STAMINA_DASH_COST    = 10
local STAMINA_ROLL_COST    = 30
local STAMINA_SPRINT_DRAIN = 20

local ANIMS                = {
  -- unarmed --
  idle = {
    file        = 'sprites/prototype/idle.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 7,
    interval    = 0.2,
    loop        = true
  },
  walk = {
    file        = 'sprites/prototype/walk.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 8,
    interval    = 0.15,
    loop        = true,
  },
  run = {
    file        = 'sprites/prototype/run.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 8,
    interval    = 0.1,
    loop        = true,
  },
  run_to_idle = {
    file        = 'sprites/prototype/run-to-idle.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 3,
    interval    = 0.04,
    loop        = false
  },
  sprint = {
    file        = 'sprites/prototype/sprint.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 6,
    interval    = 0.08,
    loop        = true
  },
  dash = {
    file        = 'sprites/prototype/dash.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 9,
    interval    = 0.07,
    loop        = false
  },
  roll = {
    file        = 'sprites/prototype/roll.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 10,
    interval    = 0.07,
    loop        = false
  },
  slide = {
    file        = 'sprites/prototype/slide.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 4,
    interval    = 0.09,
    loop        = false
  },
  jump_up = {
    file        = 'sprites/prototype/jump-up.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 1,
    interval    = 0.2,
    loop        = false
  },
  jump_mid = {
    file        = 'sprites/prototype/jump-mid.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 1,
    interval    = 0.4,
    loop        = false
  },
  jump_fall = {
    file        = 'sprites/prototype/jump-fall.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 1,
    interval    = 0.4,
    loop        = true
  },
  front_flip = {
    file        = 'sprites/prototype/front-flip.png',
    frameWidth  = 96,
    frameHeight = 84,
    sheetOffset = 3,
    totalFrames = 11,
    interval    = 0.07,
    loop        = false
  },

  punch_1 = { -- second hit in fist combo --
    file        = 'sprites/prototype/punch-1.png',
    frameWidth  = 96,
    frameHeight = 84,
    sheetOffset = 1,
    totalFrames = 5,
    interval    = 0.05,
    loop        = false
  },
  punch_2 = {
    file        = 'sprites/prototype/punch-2.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 4,
    interval    = 0.09,
    loop        = false
  },
  punch_3 = {
    file        = 'sprites/prototype/punch-3.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 7,
    interval    = 0.07,
    loop        = false
  },
  kick_1 = {
    file        = 'sprites/prototype/kick-1.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 9,
    interval    = 0.07,
    loop        = false
  },
  kick_2 = { -- first hit in fist combo
    file        = 'sprites/prototype/kick-2.png',
    frameWidth  = 96,
    frameHeight = 84,

    totalFrames = 6,
    interval    = 0.05,
    loop        = false
  },
  kick_3 = { -- third hit in fist combo
    file        = 'sprites/prototype/kick-3.png',
    frameWidth  = 96,
    frameHeight = 84,
    sheetOffset = 1,
    totalFrames = 8,
    interval    = 0.06,
    loop        = false
  },
  -- sword --
  sword_idle = {
    file        = 'sprites/prototype/sword-idle.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 7,
    interval    = 0.2,
    loop        = true,
  },
  sword_walk = {
    file        = 'sprites/prototype/sword-walk.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 8,
    interval    = 0.15,
    loop        = true,
  },
  sword_run = {
    file        = 'sprites/prototype/sword-run.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 8,
    interval    = 0.1,
    loop        = true,
  },
  sword_sprint = {
    file        = 'sprites/prototype/sword-sprint.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 6,
    interval    = 0.08,
    loop        = true,
  },
  sword_attack_1 = {
    file        = 'sprites/prototype/sword-attack-1.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 6,
    interval    = 0.07,
    loop        = false
  },
  sword_attack_2 = {
    file        = 'sprites/prototype/sword-attack-2.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 5,
    interval    = 0.07,
    loop        = false
  },
  sword_attack_3 = {
    file        = 'sprites/prototype/sword-attack-3.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 5,
    interval    = 0.07,
    loop        = false
  },
  sword_attack_4 = {
    file        = 'sprites/prototype/sword-attack-4.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 8,
    interval    = 0.07,
    loop        = false
  },
  sword_air_forward = {
    file        = 'sprites/prototype/sword-air-forward.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 4,
    interval    = 0.06,
    loop        = false,
  },
  sword_air_up = {
    file        = 'sprites/prototype/sword-air-up.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 6,
    interval    = 0.06,
    loop        = false,
  },
  sword_air_down = {
    file        = 'sprites/prototype/sword-air-down.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 6,
    interval    = 0.06,
    loop        = false,
  },

  -- gun --
  gun_idle = {
    file        = 'sprites/prototype/gun-idle.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 1,
    interval    = 0.2,
    loop        = true
  },
  gun_walk = {
    file        = 'sprites/prototype/gun-walk.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 8,
    interval    = 0.15,
    loop        = true,
  },
  gun_run = {
    file        = 'sprites/prototype/gun-run.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 8,
    interval    = 0.1,
    loop        = true
  },
  gun_sprint = {
    file        = 'sprites/prototype/gun-sprint.png',
    frameWidth  = 96,
    frameHeight = 84,
    totalFrames = 6,
    interval    = 0.08,
    loop        = true,
  },
}

function Player:new(x, y)
  Player.super.new(self, x, y, WIDTH, HEIGHT, ANIMS)
  -- movement --
  self.state           = 'idle'
  self.isLocked        = false
  self.jumpBufferTimer = 0
  self.coyoteTimer     = COYOTE_TIME
  self.weapon          = nil
  -- Dash --
  self.isDashing       = false
  self.dashTimer       = 0
  self.dashCooldown    = 0
  self.dashHeld        = false
  self.isSprinting     = false
  -- attack --
  self.attackChain     = 0
  self.attackBuffered  = false
  self.activeCombo     = nil
  -- Health --
  self.health          = PLAYER_HEALTH
  self.isInvincible    = false
  self.invincibleTimer = 0
  self.isHurt          = false
  -- Stamina --
  self.stamina         = MAX_STAMINA
  self.isExhausted     = false
end

function Player:update(dt, world)
  -- horizontal movement --
  local dir = self.isFacingRight and 1 or -1

  if love.keyboard.isDown('a') then
    self.isFacingRight = false
  elseif love.keyboard.isDown('d') then
    self.isFacingRight = true
  end

  if not self.isLocked
      or self.state == 'slide'
      or self.state == 'roll' then
    if self.isSprinting then
      self.x = self.x + SPRINT_SPEED * dir * dt
    elseif self.state == 'roll' then
      self.x = self.x + SPRINT_SPEED * dir * dt
    elseif love.keyboard.isDown('a') or love.keyboard.isDown('d') then
      local speed = self.isExhausted and WALK_SPEED or RUN_SPEED
      self.x = self.x + speed * dir * dt
    end
  end

  -- Dash --
  if self.isDashing then
    self.x         = self.x + SPRINT_SPEED * dir * dt
    self.vy        = 0 -- no gravity

    self.dashTimer = self.dashTimer - dt
    if self.dashTimer <= 0 then
      self.isDashing = false
      if self.dashHeld then
        self.isSprinting = true
      end
    end
  end

  -- sprint check --
  if self.isSprinting and not self.dashHeld then
    self.isSprinting = false
  end

  -- stamina --
  if self.isSprinting then
    self.stamina = self.stamina - STAMINA_SPRINT_DRAIN * dt
  else
    self.stamina = self.stamina + STAMINA_REGEN * dt
  end

  self.stamina = math.max(0, math.min(MAX_STAMINA, self.stamina))

  if self.stamina <= 0 then
    self.isExhausted = true
    self.isSprinting = false
  elseif self.stamina >= MAX_STAMINA * 0.25 then
    self.isExhausted = false
  end

  -- cancel slide if sprint released --
  if self.state == 'slide' and not self.dashHeld then
    self.isLocked = false
    self:setState('idle')
  end

  -- Physics + Collision via Entity --
  self:updatePhysics(dt, world)

  -- coyoteTimer tick --
  if self.isGrounded then
    self.coyoteTimer = COYOTE_TIME
  else
    self.coyoteTimer = self.coyoteTimer - dt
  end

  -- Jump buffer countdown --
  if self.jumpBufferTimer > 0 then
    self.jumpBufferTimer = self.jumpBufferTimer - dt
  end

  -- Auto jump landing
  if self.isGrounded and self.jumpBufferTimer > 0 then
    self:jump()
    self.jumpBufferTimer = 0
  end

  -- Animation --
  self:updateAnimation(dt)

  -- State machine --
  if self.isDashing then
    self:setState('dash')
  elseif self.isLocked then
    -- do nothing --
  elseif self.isExhausted and self.isGrounded then
    if self.weapon == 'sword' then
      self:setState('sword_walk')
    elseif self.weapon == 'gun' then
      self:setState('gun_walk')
    else
      self:setState('walk')
    end
  elseif self.isGrounded and self.state == 'sword_air_forward' then -- land after air attack mid swing
    self.isLocked    = false
    self.attackChain = 0
    if self.weapon then
      self:setState(self.weapon .. '_idle')
    end
  elseif not self.isGrounded and self.coyoteTimer <= 0 then
    if self.state ~= 'jump_up'
        and self.state ~= 'jump_mid'
        and self.state ~= 'jump_fall'
        and self.state ~= 'sword_air_forward'
        and self.state ~= 'front_flip' then
      self:setState('jump_fall')
    end
  elseif self.isSprinting and self.dashHeld then
    if self.weapon == 'sword' then
      self:setState('sword_sprint')
    elseif self.weapon == 'gun' then
      self:setState('gun_sprint')
    else
      self:setState('sprint')
    end
  elseif love.keyboard.isDown('a') or love.keyboard.isDown('d') then
    if self.weapon == 'sword' then
      self:setState('sword_run')
    elseif self.weapon == 'gun' then
      self:setState('gun_run')
    else
      self:setState('run')
    end
  elseif self.weapon == 'sword' then
    if self.state ~= 'sword_idle' then
      self:setState('sword_idle')
    end
  elseif self.weapon == 'gun' then
    if self.state ~= 'gun_idle' then
      self:setState('gun_idle')
    end
  else
    self:setState('idle')
  end
  -- Debug --
  Debug.log('state', self.state)
  Debug.log('vy', string.format("%.1f", self.vy))
  Debug.log('isGrounded', tostring(self.isGrounded))
end

function Player:draw()
  love.graphics.setColor(1, 1, 1)
  Entity.draw(self, SPRITE_OFFSET_X, SPRITE_OFFSET_Y, SCALE_X, SCALE_Y)
  love.graphics.setColor(1, 1, 1, 1)

  -- debug collision box
  love.graphics.setColor(1, 0, 0, 0.5)
  love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
  love.graphics.setColor(1, 1, 1, 1)

  -- debug special attack hitbox
  -- local hitbox = self:getHitbox()
  -- if hitbox then
  --   love.graphics.setColor(1, 1, 0, 0.5)
  --   love.graphics.rectangle('line', hitbox.x, hitbox.y, hitbox.width, hitbox.height)
  --   love.graphics.setColor(1, 1, 1, 1)
  -- end
end

function Player:pressJump()
  self.jumpBufferTimer = JUMP_BUFFER
  self:jump()
end

function Player:jump()
  if self.coyoteTimer > 0
      and self.stamina >= STAMINA_JUMP_COST
      and not self.isExhausted then
    self.stamina        = self.stamina - STAMINA_JUMP_COST
    self.vy             = JUMP_FORCE
    self.coyoteTimer    = 0
    self.isLocked       = false
    self.attackChain    = 0
    self.attackBuffered = false
    if self.isSprinting then
      self:setState('front_flip')
    else
      self:setState('jump_up')
    end
  end
end

function Player:releaseJump()
  if self.vy < 0 then
    self.vy = self.vy * JUMP_CUT
  end
end

function Player:dash()
  if not self.isDashing
      and self.dashCooldown <= 0
      and not self.isLocked
      and not self.isExhausted then
    if self.stamina >= STAMINA_DASH_COST then
      self.stamina = self.stamina - STAMINA_DASH_COST
      self.isDashing = true
      self.dashTimer = DASH_DURATION
      self:setState('dash')
    end
  end
end

function Player:slide()
  if not self.isGrounded or self.isLocked then
    return
  end
  if self.stamina >= STAMINA_ROLL_COST then
    if self.isSprinting then
      self.isLocked = true
      self:setState('slide')
    else
      self.isLocked = true
      self.stamina = self.stamina - STAMINA_ROLL_COST
      self:setState('roll')
    end
  end
end

function Player:toggleWeapon(weapon)
  if self.isLocked then return end

  if self.weapon == weapon then
    self.weapon = nil
    self:setState('idle')
  else
    self.weapon = weapon
    self:setState(weapon .. '_idle')
  end
end

function Player:testAnim(animName)
  if self.isLocked then return end
  self.isLocked = true
  self.attackChain = 0
  self:setState(animName)
end

function Player:attack()
  local combo
  if not self.weapon then
    combo = UNARMED_COMBO
  elseif self.weapon == 'sword' then
    combo = SWORD_COMBO
  else
    return
  end

  if not self.isLocked
      and self.isGrounded
      and not self.isExhausted then
    self.activeCombo = combo
    self.isLocked = true
    self.attackChain = 1
    self:setState(combo[1])
  elseif self.isLocked and self.attackChain < 4 and not self.attackBuffered then
    self.attackBuffered = true
  elseif not self.isGrounded
      and not self.isLocked
      and not self.isExhausted then
    self.isLocked = true
    if self.weapon == 'sword' then
      if love.keyboard.isDown('s') then
        self:setState('sword_air_down')
      elseif love.keyboard.isDown('w') then
        self:setState('sword_air_up')
      else
        self:setState('sword_air_forward')
      end
    end
  end
end

function Player:getHitbox()
  local attackStates = {
    attack_1          = true,
    attack_2          = true,
    attack_3          = true,
    sword_air_forward = true,
    special_attack    = true
  }
  if not attackStates[self.state] then return nil end

  local def = ANIMS[self.state]
  if def.activeFrame and self.currentFrame < def.activeFrame then
    return nil
  end

  local hx = self.isFacingRight
      and self.x + self.width
      or self.x - HITBOX_WIDTH

  return {
    x      = hx,
    y      = self.y + 10,
    width  = HITBOX_WIDTH,
    height = self.height - 20
  }
end

function Player:takeDamage(amount)
  if self.isInvincible or self.isHurt then
    return
  end

  self.health          = self.health - amount
  self.isHurt          = true
  self.isInvincible    = true
  self.invincibleTimer = INVINCIBILITY_TIME
  self.isLocked        = true

  if self.health <= 0 then
    self.health = 0
    Debug.log('player_health', 'DEAD')
  end

  self:setState('hurt')
end

function Player:onAnimationEnd()
  if self.state == 'jump_up' then
    self:setState('jump_mid')
  elseif self.state == 'jump_mid' then
    self:setState('jump_fall')
  elseif self.state == 'front_flip' then
    self:setState('jump_fall')

    -- air attack logic --
  elseif self.state == 'sword_air_forward'
      or self.state == 'sword_air_down'
      or self.state == 'sword_air_up' then
    self.isLocked = false
    if self.vy > 0 then
      self:setState('jump_fall')
    else
      self:setState('jump_up')
    end
  elseif self.state == 'roll' then
    self.isLocked = false
    self:setState('idle')
  elseif self.state == 'slide' then
    self.isLocked = false
    if self.dashHeld then
      self:setState('sprint')
    else
      self:setState('idle')
    end
  elseif self.state == 'hurt' then
    self.isHurt   = false
    self.isLocked = false
    self:setState('idle')
  elseif self.activeCombo and self.activeCombo[self.attackChain] == self.state then
    if self.attackBuffered then
      self.attackBuffered = false
      self.attackChain    = self.attackChain + 1
      local nextState     = self.activeCombo[self.attackChain]
      if nextState then
        self:setState(nextState)
      else
        self.isLocked    = false
        self.attackChain = 0
        self.activeCombo = nil
        self:setState('idle')
      end
    else
      self.isLocked    = false
      self.attackChain = 0
      self.activeCombo = nil
      self:setState('idle')
    end
  end
end

return Player
