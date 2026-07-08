local Entity   = require('src.entity')
local Debug    = require('src.debug')

local Player   = {}
Player.__index = Player
setmetatable(Player, { __index = Entity }) -- Player falls back to Entity

local SCALE_X                 = 3
local SCALE_Y                 = 3
local MOVE_SPEED              = 350
local SPRINT_SPEED            = 600
local DASH_SPEED              = 1200
local DASH_DURATION           = 0.2
local DASH_COOLDOWN           = 0.5
local JUMP_FORCE              = -900 -- jump height
local JUMP_CUT                = 0.4
local COYOTE_TIME             = 0.1  -- seconds you can still jump after walking off a ledge
local JUMP_BUFFER             = 0.1  -- seconds before landing that a jump input is remembered
local ATTACK_STATES           = { 'attack_1', 'attack_2', 'attack_3' }
local PLAYER_HEALTH           = 10
local INVINCIBILITY_TIME      = 1.0
local HITBOX_WIDTH            = 100
local SPECIAL_ATTACK_FORCE    = -600
local SPECIAL_ATTACK_COOLDOWN = 5.0

local ANIMS                   = {
  idle = {
    file        = 'sprites/player/idle.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 10,
    interval    = 0.2,
    loop        = true
  },
  run = {
    file        = 'sprites/player/run.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 16,
    interval    = 0.04,
    loop        = true,
  },
  dash = {
    file        = 'sprites/player/dash.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 8,
    interval    = 0.07,
    loop        = false
  },
  sprint = {
    file        = 'sprites/player/run.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 16,
    interval    = 0.03,
    loop        = true
  },
  jump_start = {
    file        = 'sprites/player/jump-start.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 3,
    interval    = 0.07,
    loop        = false
  },
  jump = {
    file        = 'sprites/player/jump.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 3,
    interval    = 0.07,
    loop        = false
  },
  jump_transition = {
    file        = 'sprites/player/jump-tran.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 3,
    interval    = 0.07,
    loop        = false
  },
  jump_fall = {
    file        = 'sprites/player/jump-fall.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 3,
    interval    = 0.07,
    loop        = false
  },
  air_attack = {
    file = 'sprites/player/air-attack.png',
    frameWidth = 96,
    frameHeight = 96,
    totalFrames = 6,
    activeFrame = 3,
    interval = 0.07,
    loop = false
  },
  attack_1 = {
    file        = 'sprites/player/attack-1.png',
    frameWidth  = 96,
    frameHeight = 96,
    sheetOffset = 3,
    totalFrames = 4,
    activeFrame = 2,
    interval    = 0.06,
    loop        = false
  },
  attack_2 = {
    file        = 'sprites/player/attack-2.png',
    frameWidth  = 96,
    frameHeight = 96,
    sheetOffset = 2,
    totalFrames = 4,
    activeFrame = 2,
    interval    = 0.06,
    loop        = false
  },
  attack_3 = {
    file        = 'sprites/player/attack-3.png',
    frameWidth  = 96,
    frameHeight = 96,
    sheetOffset = 1,
    totalFrames = 5,
    activeFrame = 2,
    interval    = 0.06,
    loop        = false
  },
  special_attack = {
    file        = 'sprites/player/special-attack.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 14,
    activeFrame = 6,
    interval    = 0.08,
    loop        = false
  },
  hurt = {
    file        = 'sprites/player/hurt.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 4,
    interval    = 0.05,
    loop        = false
  }
}

local SPRITE_OFFSET_X         = -130
local SPRITE_OFFSET_Y         = -150

function Player.new(x, y)
  local self = Entity.new(x, y, 36, 86, ANIMS)
  setmetatable(self, Player)

  -- Jump --
  self.jumpHeld           = false
  self.jumpBufferTimer    = 0
  self.coyoteTimer        = COYOTE_TIME
  self.noGravity          = false

  -- Attack --
  self.isLocked           = false
  self.attackChain        = 0
  self.attackBuffered     = false
  self.isSpecialAttacking = false
  self.specialCooldown    = 0

  -- Dash --
  self.isDashing          = false
  self.dashTimer          = 0
  self.dashCooldown       = 0
  self.dashAlpha          = 1
  self.dashHeld           = false
  self.isSprinting        = false

  -- Health --
  self.health             = PLAYER_HEALTH
  self.isInvincible       = false
  self.invincibleTimer    = 0
  self.isHurt             = false

  self:setState('idle')
  return self
end

function Player:update(dt, world, effects)
  -- Horizontal movement --
  if love.keyboard.isDown('a') then
    self.isFacingRight = false
    if not self.isLocked or self.state == 'air_attack' then
      local speed = self.isSprinting and SPRINT_SPEED or MOVE_SPEED
      self.x = self.x - speed * dt
    end
  elseif love.keyboard.isDown('d') then
    self.isFacingRight = true
    if not self.isLocked or self.state == 'air_attack' then
      local speed = self.isSprinting and SPRINT_SPEED or MOVE_SPEED
      self.x = self.x + speed * dt
    end
  end

  -- Dash --
  if self.isDashing then
    local dir      = self.isFacingRight and 1 or -1
    self.x         = self.x + DASH_SPEED * dir * dt
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
  local isMoving = love.keyboard.isDown('a') or love.keyboard.isDown('d')
  if self.isSprinting and (not self.dashHeld or not isMoving) then
    self.isSprinting = false
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

  -- Special attack cooldown --
  if self.specialCooldown > 0 then
    self.specialCooldown = self.specialCooldown - dt
    if self.specialCooldown <= 0 then
      self.specialCooldown = 0
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

  -- Coyote time --
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
  elseif self.isSpecialAttacking then
    self:setState('special_attack')
  elseif self.isGrounded and self.state == 'air_attack' then -- land after air attack mid swing
    self.isLocked    = false
    self.attackChain = 0
    self:setState('idle')
  elseif self.isLocked then
    -- do nothing
  elseif not self.isGrounded and self.coyoteTimer <= 0 then
    local inJumpChain = self.state == 'jump_start'
        or self.state == 'jump'
        or self.state == 'jump_transition'
        or self.state == 'jump_fall'
        or self.state == 'air_attack'
    if not inJumpChain then
      self:setState('jump_fall')
    end
  elseif self.isSprinting and self.dashHeld and isMoving then
    self:setState('sprint')
  elseif love.keyboard.isDown('a') or love.keyboard.isDown('d') then
    self:setState('run')
  else
    self:setState('idle')
  end

  -- Debug --
  Debug.log('state', self.state)
  Debug.log('special_cooldown', string.format("%.1f", self.specialCooldown))
  Debug.log('vy', string.format("%.1f", self.vy))
end

function Player:onAnimationEnd()
  if self.state == 'jump_start' then
    self:setState('jump')
  elseif self.state == 'jump' then
    self:setState('jump_transition')
  elseif self.state == 'jump_transition' then
    self:setState('jump_fall')
  elseif self.state == 'dash' then
    -- no action needed
  elseif self.state == 'attack_1' or self.state == 'attack_2' then
    if self.attackBuffered then
      self.attackBuffered = false
      self.attackChain    = self.attackChain + 1
      local nextState     = ATTACK_STATES[self.attackChain]
      if nextState then
        self:setState(nextState)
      else
        self.isLocked    = false
        self.attackChain = 0
        self:setState('idle')
      end
    else
      self.isLocked    = false
      self.attackChain = 0
      self:setState('idle')
    end
  elseif self.state == 'attack_3' then
    self.isLocked       = false
    self.attackChain    = 0
    self.attackBuffered = false
    self:setState('idle')
  elseif self.state == 'air_attack' then
    self.isLocked    = false
    self.attackChain = 0
    self:setState('jump_fall')
  elseif self.state == 'special_attack' then
    self.isSpecialAttacking = false
    self.isLocked           = false
    self.noGravity          = false
    self:setState('jump_fall')
  elseif self.state == 'hurt' then
    self.isHurt   = false
    self.isLocked = false
    self:setState('idle')
  end
end

function Player:pressJump()
  self.jumpBufferTimer = JUMP_BUFFER
  self:jump()
end

function Player:releaseJump()
  if self.vy < 0 then
    self.vy = self.vy * JUMP_CUT
  end
  self.jumpHeld = false
end

function Player:jump()
  if self.coyoteTimer > 0 then
    self.vy             = JUMP_FORCE
    self.jumpHeld       = true
    self.coyoteTimer    = 0
    self.isLocked       = false
    self.attackChain    = 0
    self.attackBuffered = false
    self:setState('jump_start')
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

function Player:specialAttack()
  if self.specialCooldown > 0 then return end

  self.isSpecialAttacking = true
  self.specialCooldown    = SPECIAL_ATTACK_COOLDOWN
  self.isLocked           = true
  self.attackChain        = 0
  self.attackBuffered     = false
  self.vy                 = SPECIAL_ATTACK_FORCE
  Debug.log('special_vy', self.vy) -- confirm force is being set
  self:setState('special_attack')
end

function Player:dash()
  if not self.isDashing and self.dashCooldown <= 0 and not self.isLocked then
    self.isDashing = true
    self.dashTimer = DASH_DURATION
    self:setState('dash')
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

function Player:draw()
  love.graphics.setColor(1, 1, 1, self.dashAlpha)
  Entity.draw(self, SPRITE_OFFSET_X, SPRITE_OFFSET_Y, SCALE_X, SCALE_Y)
  love.graphics.setColor(1, 1, 1, 1)

  -- debug collision box
  love.graphics.setColor(1, 0, 0, 0.5)
  love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
  love.graphics.setColor(1, 1, 1, 1)

  -- debug special attack hitbox
  local hitbox = self:getHitbox()
  if hitbox then
    love.graphics.setColor(1, 1, 0, 0.5)
    love.graphics.rectangle('line', hitbox.x, hitbox.y, hitbox.width, hitbox.height)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

return Player
