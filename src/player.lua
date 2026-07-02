local Entity   = require('src/entity')

local Player   = {}
Player.__index = Player
setmetatable(Player, { __index = Entity }) -- Player falls back to Entity

local MOVE_SPEED           = 350
local DASH_SPEED           = 900
local DASH_DURATION        = 0.2
local DASH_COOLDOWN        = 0.8
local JUMP_FORCE           = -400 -- jump height
local JUMP_HOLD_FORCE      = -600 -- jump hold height
local MAX_JUMP_TIME        = 0.2
local ATTACK_STATES        = { 'attack1', 'attack2', 'attack3' }
local ATTACK_RECOVERY_TIME = 0.3 -- seconds of vulnerability after combo ends
local COYOTE_TIME          = 0.1 -- seconds you can still jump after walking off a ledge
local JUMP_BUFFER          = 0.1 -- seconds before landing that a jump input is remembered

local ANIMS                = {
  idle = {
    file        = 'sprites/Shinobi/Idle.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 6,
    interval    = 0.12,
    loop        = true,
  },
  run = {
    file        = 'sprites/Shinobi/Run.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 8,
    interval    = 0.07,
    loop        = true,
  },
  jump_up = {
    file        = 'sprites/Shinobi/Jump.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 6,
    interval    = 0.07,
    sheetOffset = 0,
    loop        = false, -- hold on last frame
  },
  jump_down = {
    file        = 'sprites/Shinobi/Jump.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 6,
    interval    = 0.07,
    sheetOffset = 6,
    loop        = false, -- hold on last frame
  },
  attack1 = {
    file        = 'sprites/Shinobi/Attack_1.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 5,
    interval    = 0.07,
    loop        = false
  },
  attack2 = {
    file        = 'sprites/Shinobi/Attack_2.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 3,
    interval    = 0.07,
    loop        = false
  },
  attack3 = {
    file        = 'sprites/Shinobi/Attack_3.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 4,
    interval    = 0.07,
    loop        = false
  },
}

local SPRITE_OFFSET_X      = -48
local SPRITE_OFFSET_Y      = -48

function Player.new(x, y)
  local self = Entity.new(x, y, 32, 80, ANIMS)
  setmetatable(self, Player)
  Player.__index       = Player

  -- Jump --
  self.jumpHeld        = false
  self.jumpTimer       = 0
  self.coyoteTimer     = COYOTE_TIME
  self.jumpBufferTimer = 0

  -- Attack --
  self.isLocked        = false
  self.attackChain     = 0
  self.attackBuffered  = false
  self.recoveryTimer   = 0
  self.isRecovering    = false

  -- Dash --
  self.isDashing       = false
  self.dashTimer       = 0
  self.dashCooldown    = 0
  self.dashAlpha       = 1

  self:setState('idle')
  return self
end

function Player:update(dt, world, effects)
  -- Horizontal movement --
  if love.keyboard.isDown('a') then
    self.isFacingRight = false -- Always update direction (attacking)
    if not self.isLocked then
      self.x = self.x - MOVE_SPEED * dt
    end
  elseif love.keyboard.isDown('d') then
    self.isFacingRight = true -- Always update direction (attacking)
    if not self.isLocked then
      self.x = self.x + MOVE_SPEED * dt
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
    end
  end

  -- Cooldown --
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

  -- Recovery after attack combo --
  if self.isRecovering then
    self.recoveryTimer = self.recoveryTimer - dt
    if self.recoveryTimer <= 0 then
      self.isRecovering = false
      self.isLocked = false
    end
  end

  -- Animation --
  self:updateAnimation(dt)

  -- State machine --
  if self.isDashing then
    self:setState('run')
  elseif self.isLocked then
    -- do nothing
  elseif not self.isGrounded and self.coyoteTimer <= 0 then
    if self.vy < 0 then
      self:setState('jump_up')
    else
      self:setState('jump_down')
    end
  elseif love.keyboard.isDown('a') or love.keyboard.isDown('d') then
    self:setState('run')
  else
    self:setState('idle')
  end
end

-- Does it loop or hold the last frame (like a jump)? --
function Player:onAnimationEnd()
  if self.state == 'attack1' or self.state == 'attack2' then
    if self.attackBuffered then -- advance to next hit in chain
      self.attackBuffered = false
      self.attackChain    = self.attackChain + 1
      self:setState(ATTACK_STATES[self.attackChain])
    else -- no buffered attack input, unlock and return to idel
      self.isLocked    = false
      self.attackChain = 0
      self:setState('idle')
    end
  elseif self.state == 'attack3' then -- end of chain
    self.attackChain    = 0
    self.attackBuffered = false
    self.isRecovering   = true
    self.recoveryTimer  = ATTACK_RECOVERY_TIME
    self:setState('idle')
  end
end

function Player:pressJump()
  self.jumpBufferTimer = JUMP_BUFFER
  self:jump()
end

function Player:jump()
  if self.coyoteTimer > 0 then
    self.vy          = JUMP_FORCE
    self.jumpHeld    = true
    self.jumpTimer   = 0
    self.coyoteTimer = 0
  end
end

function Player:attack()
  if not self.isLocked and not self.isRecovering then
    self.isLocked    = true
    self.attackChain = 1
    self:setState('attack1')
  elseif self.isLocked and self.attackChain < 3 then
    -- buffer the next hit
    self.attackBuffered = true
  end
end

function Player:dash()
  if not self.isDashing and self.dashCooldown <= 0 and not self.isLocked then
    self.isDashing = true
    self.dashTimer = DASH_DURATION
  end
end

function Player:draw()
  love.graphics.setColor(1, 1, 1, self.dashAlpha)
  Entity.draw(self, SPRITE_OFFSET_X, SPRITE_OFFSET_Y)
  love.graphics.setColor(1, 1, 1, 1)
end

return Player
