local Entity   = require('src.entity')
local Debug    = require('src.debug')

local Player   = {}
Player.__index = Player
setmetatable(Player, { __index = Entity }) -- Player falls back to Entity

local SCALE_X         = 2.5
local SCALE_Y         = 2.5
local MOVE_SPEED      = 350
local SPRINT_SPEED    = 600
local DASH_SPEED      = 1000
local DASH_DURATION   = 0.2
local DASH_COOLDOWN   = 1
local JUMP_FORCE      = -200  -- jump height
local JUMP_HOLD_FORCE = -3000 -- jump hold height
local MAX_JUMP_TIME   = 0.2
local ATTACK_STATES   = { 'attack1', 'attack2', 'attack3' }
-- local COMBO_RECOVERY_TIME = 0.3 -- only final hit has recovery
local COYOTE_TIME     = 0.1 -- seconds you can still jump after walking off a ledge
local JUMP_BUFFER     = 0.1 -- seconds before landing that a jump input is remembered


local ANIMS           = {
  idle = {
    file        = 'sprites/SAMURAI/IDLE.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 10,
    interval    = 0.18,
    loop        = true
  },
  run = {
    file        = 'sprites/SAMURAI/RUN.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 16,
    interval    = 0.05,
    loop        = true
  },
  dash = {
    file        = 'sprites/SAMURAI/DASH.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 8,
    interval    = 0.04,
    loop        = false
  },
  sprint = {
    file        = 'sprites/SAMURAI/RUN.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 16,
    interval    = 0.03,
    loop        = true
  },
  jump_start = {
    file        = 'sprites/SAMURAI/JUMP-START.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 3,
    interval    = 0.07,
    loop        = false
  },
  jump = {
    file        = 'sprites/SAMURAI/JUMP.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 3,
    interval    = 0.07,
    loop        = false
  },
  jump_transition = {
    file        = 'sprites/SAMURAI/JUMP-TRANSITION.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 3,
    interval    = 0.07,
    loop        = false
  },
  jump_fall = {
    file        = 'sprites/SAMURAI/JUMP-FALL.png',
    frameWidth  = 96,
    frameHeight = 96,
    totalFrames = 3,
    interval    = 0.07,
    loop        = false
  },
  air_attack = {
    file = 'sprites/SAMURAI/AIR-ATTACK.png',
    frameWidth = 96,
    frameHeight = 96,
    totalFrames = 6,
    interval = 0.07,
    loop = false
  },
  attack1 = {
    file        = 'sprites/SAMURAI/ATTACK-1.png',
    frameWidth  = 96,
    frameHeight = 96,
    sheetOffset = 0,
    totalFrames = 7,
    interval    = 0.05,
    loop        = false
  },
  attack2 = {
    file        = 'sprites/SAMURAI/ATTACK-2.png',
    frameWidth  = 96,
    frameHeight = 96,
    sheetOffset = 0,
    totalFrames = 7,
    interval    = 0.07,
    loop        = false
  },
  attack3 = {
    file        = 'sprites/SAMURAI/ATTACK-3.png',
    frameWidth  = 96,
    frameHeight = 96,
    sheetOffset = 0,
    totalFrames = 7,
    interval    = 0.07,
    loop        = false
  },
}

local SPRITE_OFFSET_X = -105
local SPRITE_OFFSET_Y = -120

function Player.new(x, y)
  local self = Entity.new(x, y, 40, 80, ANIMS)
  setmetatable(self, Player)

  -- Jump --
  self.jumpHeld        = false
  self.jumpTimer       = 0
  self.coyoteTimer     = COYOTE_TIME
  self.jumpBufferTimer = 0

  -- Attack --
  self.isLocked        = false
  self.attackChain     = 0
  self.attackBuffered  = false

  -- Dash --
  self.isDashing       = false
  self.dashTimer       = 0
  self.dashCooldown    = 0
  self.dashAlpha       = 1
  self.dashHeld        = false
  self.isSprinting     = false

  self:setState('idle')
  return self
end

function Player:update(dt, world, effects)
  -- Horizontal movement --
  if love.keyboard.isDown('a') then
    self.isFacingRight = false -- Always update direction (attacking)
    if not self.isLocked then
      local speed = self.isSprinting and SPRINT_SPEED or MOVE_SPEED
      self.x = self.x - speed * dt
    end
  elseif love.keyboard.isDown('d') then
    self.isFacingRight = true -- Always update direction (attacking)
    if not self.isLocked then
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
  if self.isSprinting and not self.dashHeld then
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

  -- Variable jump extension --
  if self.jumpHeld then
    if love.keyboard.isDown('space') and self.jumpTimer < MAX_JUMP_TIME then
      self.vy        = self.vy + JUMP_HOLD_FORCE * dt
      self.jumpTimer = self.jumpTimer + dt
    else
      self.jumpHeld = false
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
  elseif self.isGrounded and self.state == 'air_attack' then
    self.isLocked = false
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
  elseif self.isSprinting and self.dashHeld then
    self:setState('sprint')
  elseif love.keyboard.isDown('a') or love.keyboard.isDown('d') then
    self:setState('run')
  else
    self:setState('idle')
  end

  -- Debug --
  Debug.log('state', self.state)
  Debug.log('isSprinting', self.isSprinting)
  Debug.log('dashHeld', self.dashHeld)
end

function Player:onAnimationEnd()
  -- Jump --
  if self.state == 'jump_start' then
    self:setState('jump')
  elseif self.state == 'jump' then
    self:setState('jump_transition')
  elseif self.state == 'jump_transition' then
    self:setState('jump_fall')
    -- Dash --
  elseif self.state == 'dash' then -- no action needed, handled in Player:dash()
    -- Attack --
  elseif self.state == 'attack1' or self.state == 'attack2' then
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
  elseif self.state == 'attack3' then
    self.isLocked       = false
    self.attackChain    = 0
    self.attackBuffered = false
    self:setState('idle')
  elseif self.state == 'air_attack' then
    self.isLocked = false
    self.attackChain = 0
    self:setState('jump_fall')
  end
end

function Player:pressJump()
  self.jumpBufferTimer = JUMP_BUFFER
  self:jump()
end

function Player:jump()
  if self.coyoteTimer > 0 then
    self.vy             = JUMP_FORCE
    self.jumpHeld       = true
    self.jumpTimer      = 0
    self.coyoteTimer    = 0
    self.isLocked       = false
    -- self.isRecovering   = false
    self.attackChain    = 0
    self.attackBuffered = false
    self:setState('jump_start')
  end
end

function Player:attack()
  if not self.isGrounded and not self.isLocked then
    -- air attack --
    self.isLocked = true
    self.attackChain = 0
    self:setState('air_attack')
  elseif self.isGrounded and not self.isLocked then
    -- ground attack --
    self.isLocked = true
    self.attackChain = 1
    self:setState('attack1')
  elseif self.isGrounded and self.isLocked and self.attackChain < 3 and not self.attackBuffered then
    self.attackBuffered = true
  end
end

function Player:dash()
  if not self.isDashing and self.dashCooldown <= 0 and not self.isLocked then
    self.isDashing = true
    self.dashTimer = DASH_DURATION
    self:setState('dash')
  end
end

function Player:draw()
  love.graphics.setColor(1, 1, 1, self.dashAlpha)
  Entity.draw(self, SPRITE_OFFSET_X, SPRITE_OFFSET_Y, SCALE_X, SCALE_Y)
  love.graphics.setColor(1, 1, 1, 1)
end

return Player
