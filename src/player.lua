local Entity             = require 'src.entity'
local Player             = Entity:extend()
local Debug              = require 'src.debug'

-- size --
local WIDTH              = 36
local HEIGHT             = 86
local SPRITE_OFFSET_X    = -50 -- lower number moves sprite to the left
local SPRITE_OFFSET_Y    = -31 -- lower number moves sprite up
local SCALE_X            = 3
local SCALE_Y            = 3

-- movement --
local MOVE_SPEED         = 350
local SPRINT_SPEED       = 600
local DASH_DURATION      = 0.2
local DASH_COOLDOWN      = 0.5
local JUMP_FORCE         = -900 -- jump height
local JUMP_CUT           = 0.4
local COYOTE_TIME        = 0.1  -- seconds you can still jump after walking off a ledge
local JUMP_BUFFER        = 0.1  -- seconds before landing that a jump input is remembered

-- attack --
local PLAYER_HEALTH      = 10
local INVINCIBILITY_TIME = 1.0
local HITBOX_WIDTH       = 100

local ANIMS              = {
  idle = {
    file        = 'sprites/proto-woman/idle.png',
    frameWidth  = 48,
    frameHeight = 48,
    totalFrames = 10,
    interval    = 0.2,
    loop        = true
  },
  run = {
    file        = 'sprites/proto-woman/run.png',
    frameWidth  = 48,
    frameHeight = 48,
    totalFrames = 8,
    interval    = 0.1,
    loop        = true,
  },
  sprint = {
    file        = 'sprites/proto-woman/run.png',
    frameWidth  = 48,
    frameHeight = 48,
    totalFrames = 8,
    interval    = 0.08,
    loop        = true
  },
  dash = {
    file        = 'sprites/proto-woman/dash.png',
    frameWidth  = 48,
    frameHeight = 48,
    totalFrames = 9,
    interval    = 0.07,
    loop        = false
  },
  roll = {
    file        = 'sprites/proto-woman/roll.png',
    frameWidth  = 48,
    frameHeight = 48,
    totalFrames = 7,
    interval    = 0.09,
    loop        = false
  },
  jump_up = {
    file        = 'sprites/proto-woman/jump.png',
    frameWidth  = 48,
    frameHeight = 48,
    sheetOffset = 0,
    totalFrames = 3,
    interval    = 0.09,
    loop        = false
  },
  jump_fall = {
    file        = 'sprites/proto-woman/jump.png',
    frameWidth  = 48,
    frameHeight = 48,
    sheetOffset = 3,
    totalFrames = 3,
    interval    = 0.09,
    loop        = false
  },
  air_spin = {
    file        = 'sprites/proto-woman/air-spin.png',
    frameWidth  = 48,
    frameHeight = 48,
    totalFrames = 6,
    interval    = 0.07,
    loop        = false
  },
  slide = {
    file        = 'sprites/proto-woman/slide.png',
    frameWidth  = 48,
    frameHeight = 48,
    totalFrames = 8,
    interval    = 0.09,
    loop        = false
  },

  -- need frameWidthOffset
  attack_sheath = {
    file        = 'sprites/proto-woman/attack-sheathe.png',
    frameWidth  = 80,
    frameHeight = 64,
    totalFrames = 10,
    interval    = 0.07,
    loop        = true
  },

  attack_continuous = {
    file        = 'sprites/proto-woman/attack-continuous.png',
    frameWidth  = 80,
    frameHeight = 64,
    totalFrames = 9,
    interval    = 0.06,
    loop        = true
  },

  sword_stab = {
    file        = 'sprites/proto-woman/sword-stab.png',
    frameWidth  = 96,
    frameHeight = 48,
    totalFrames = 7,
    interval    = 0.11,
    loop        = false
  },

  sword_attack = {
    file        = 'sprites/proto-woman/sword-attack.png',
    frameWidth  = 64,
    frameHeight = 64,
    totalFrames = 6,
    interval    = 0.1,
    loop        = true
  },

  air_attack = {
    file = 'sprites/samurai-2/air-attack.png',
    frameWidth = 96,
    frameHeight = 96,
    totalFrames = 6,
    activeFrame = 3,
    interval = 0.07,
    loop = false
  },
  attack_1 = {
    file        = 'sprites/samurai-2/attack-1.png',
    frameWidth  = 96,
    frameHeight = 96,
    sheetOffset = 3,
    totalFrames = 4,
    activeFrame = 2,
    interval    = 0.06,
    loop        = false
  },
  attack_2 = {
    file        = 'sprites/samurai-2/attack-2.png',
    frameWidth  = 96,
    frameHeight = 96,
    sheetOffset = 2,
    totalFrames = 4,
    activeFrame = 2,
    interval    = 0.06,
    loop        = false
  },
  attack_3 = {
    file        = 'sprites/samurai-2/attack-3.png',
    frameWidth  = 96,
    frameHeight = 96,
    sheetOffset = 1,
    totalFrames = 5,
    activeFrame = 2,
    interval    = 0.06,
    loop        = false
  },
  hurt = {
    file        = 'sprites/samurai-2/hurt.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 4,
    interval    = 0.05,
    loop        = false
  }
}

function Player:new(x, y)
  Player.super.new(self, x, y, WIDTH, HEIGHT, ANIMS)

  -- movement --
  self.state           = 'idle'
  self.isLocked        = false
  self.jumpBufferTimer = 0
  self.coyoteTimer     = COYOTE_TIME

  -- Dash --
  self.isDashing       = false
  self.dashTimer       = 0
  self.dashCooldown    = 0
  self.dashAlpha       = 1
  self.dashHeld        = false
  self.isSprinting     = false

  -- attack --
  self.attackChain     = 0
  self.attackBuffered  = false

  -- Health --
  self.health          = PLAYER_HEALTH
  self.isInvincible    = false
  self.invincibleTimer = 0
  self.isHurt          = false
end

function Player:update(dt, world, effects)
  -- horizontal movement --
  local dir = self.isFacingRight and 1 or -1

  if love.keyboard.isDown('a') then
    self.isFacingRight = false
  elseif love.keyboard.isDown('d') then
    self.isFacingRight = true
  end

  if not self.isLocked or self.state == 'air_attack' or self.state == 'slide' or self.state == 'roll' then
    if self.isSprinting then
      self.x = self.x + SPRINT_SPEED * dir * dt
    elseif self.state == 'roll' then
      self.x = self.x + SPRINT_SPEED * dir * dt
    elseif love.keyboard.isDown('a') then
      self.x = self.x + MOVE_SPEED * dir * dt
    elseif love.keyboard.isDown('d') then
      self.x = self.x + MOVE_SPEED * dir * dt
    end
  end

  -- Dash --
  if self.isDashing then
    self.x         = self.x + SPRINT_SPEED * dir * dt
    self.vy        = 0 -- no gravity

    -- Fade out first half, fade in second half
    local progress = 1 - (self.dashTimer / DASH_DURATION)
    if progress < 0.5 then
      self.dashAlpha = 1 - (progress * 2)                 -- 1 → 0.2
    else
      self.dashAlpha = 0.2 + ((progress - 0.5) * 2 * 0.8) -- 0.2 → 1
    end

    self.dashTimer = self.dashTimer - dt
    if self.dashTimer <= 0 then
      self.isDashing    = false
      self.dashAlpha    = 1
      self.dashCooldown = DASH_COOLDOWN
      if self.dashHeld then
        self.isSprinting = true
      end
    end
  end

  -- sprint check --
  if self.isSprinting and not self.dashHeld then
    self.isSprinting = false
  end

  -- cancel slide if sprint released --
  if self.state == 'slide' and not self.dashHeld then
    self.isLocked = false
    self:setState('idle')
  end

  -- Dash cooldown --
  if self.dashCooldown > 0 then
    self.dashCooldown = self.dashCooldown - dt
    if self.dashCooldown <= 0 then
      self.dashCooldown = 0
      if effects then
        local cx = self.x + self.width / 2
        local cy = self.y + self.height / 2
        effects:addDashReady(cx, cy)
      end
    end
  end

  -- Invincibility frames --
  if self.isInvincible then
    self.invincibleTimer = self.invincibleTimer - dt
    if self.invincibleTimer <= 0 then
      self.isInvincible    = false
      self.invincibleTimer = 0
    end
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
  elseif self.isHurt then
    self:setState('hurt')
  elseif self.isGrounded and self.state == 'air_attack' then -- land after air attack mid swing
    self.isLocked    = false
    self.attackChain = 0
    self:setState('idle')
  elseif self.isLocked then
    -- do nothing
  elseif not self.isGrounded and self.coyoteTimer <= 0 then
    if self.state ~= 'jump_up'
        and self.state ~= 'jump_fall'
        and self.state ~= 'air_attack'
        and self.state ~= 'air_spin' then
      self:setState('jump_fall')
    end
  elseif self.isSprinting and self.dashHeld then
    self:setState('sprint')
  elseif love.keyboard.isDown('a') or love.keyboard.isDown('d') then
    self:setState('run')
  else
    self:setState('idle')
  end
  -- Debug --
  -- Debug.log('state', self.state)
end

function Player:draw()
  love.graphics.setColor(1, 1, 1, self.dashAlpha)
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
  if self.coyoteTimer > 0 then
    self.vy             = JUMP_FORCE
    self.coyoteTimer    = 0
    self.isLocked       = false
    self.attackChain    = 0
    self.attackBuffered = false
    if self.isSprinting then
      self:setState('air_spin')
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
  if not self.isDashing and self.dashCooldown <= 0 and not self.isLocked then
    self.isDashing = true
    self.dashTimer = DASH_DURATION
    self:setState('dash')
  end
end

function Player:slide()
  if not self.isGrounded or self.isLocked then
    return
  end

  if self.isSprinting then
    self.isLocked = true
    self:setState('slide')
  else
    self.isLocked = true
    self:setState('roll')
  end
end

function Player:attack()
  if not self.isGrounded and not self.isLocked then
    self.isLocked    = true
    self.attackChain = 0
    self:setState('air_attack')
  elseif self.isGrounded and not self.isLocked then
    self.isLocked    = true
    self.attackChain = 1
    self:setState('attack_1')
  elseif self.isGrounded and self.isLocked and self.attackChain < 3 and not self.attackBuffered then
    self.attackBuffered = true
  end
end

function Player:getHitbox()
  local attackStates = {
    attack_1       = true,
    attack_2       = true,
    attack_3       = true,
    air_attack     = true,
    special_attack = true
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
  -- jump --
  if self.state == 'jump_up' then
    self:setState('jump_fall')
  elseif self.state == 'air_spin' then
    self:setState('jump_fall')
    -- attack --
  elseif self.state == 'slide' then
    self.isLocked = false
    if self.dashHeld then
      self:setState('sprint')
    else
      self:setState('idle')
    end
  elseif self.state == 'roll' then
    self.isLocked = false
    self:setState('idle')
  elseif self.state == 'attack_1' or self.state == 'attack_2' then
    if self.attackBuffered then -- next attack is initiated
      self.attackBuffered = false
      self.attackChain    = self.attackChain + 1
      if self.attackChain <= 3 then
        self:setState('attack_' .. self.attackChain)
      else
        self.isLocked    = false
        self.attackChain = 0
        self:setState('idle')
      end
    else -- next attack is NOT initiated
      self.isLocked    = false
      self.attackChain = 0
      self:setState('idle')
    end
  elseif self.state == 'attack_3' then
    self.isLocked       = false
    self.attackChain    = 0
    self.attackBuffered = false
    self:setState('idle')
  elseif self.state == 'hurt' then
    self.isHurt   = false
    self.isLocked = false
    self:setState('idle')
  end
end

return Player
