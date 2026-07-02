local Player               = {}
Player.__index             = Player

local MOVE_SPEED           = 350
local DASH_SPEED           = 900
local DASH_DURATION        = 0.2
local DASH_COOLDOWN        = 0.8
local GRAVITY              = 1500 -- pixels per second squared, pulls player down
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

function Player.new(x, y)
  local self           = setmetatable({}, Player)
  -- Position --
  self.x               = x
  self.y               = y
  self.width           = 32
  self.height          = 80
  self.isFacingRight   = true
  -- Vertical --
  self.vy              = 0
  self.isGrounded      = false
  self.jumpHeld        = false
  self.jumpTimer       = 0
  self.coyoteTimer     = 0
  self.jumpBufferTimer = 0
  -- State --
  self.isLocked        = false -- true while attack animation plays
  self.attackChain     = 0     -- which hit in the combo (1, 2, 3)
  self.attackBuffered  = false -- true if v was pressed during attack
  self.recoveryTimer   = 0
  self.isRecovering    = false
  -- Dash --
  self.isDashing       = false
  self.dashTimer       = 0
  self.dashCooldown    = 0
  self.dashAlpha       = 1 -- transparency

  -- Load all spritesheets and build quads --
  self.sheets          = {}
  self.quads           = {}

  for name, def in pairs(ANIMS) do
    if not self.sheets[def.file] then
      self.sheets[def.file] = love.graphics.newImage(def.file)
    end

    self.sheets[name] = self.sheets[def.file]
    self.quads[name]  = {}
    local offset      = def.sheetOffset or 0
    for i = 0, def.totalFrames - 1 do
      self.quads[name][i + 1] = love.graphics.newQuad(
        (offset + i) * def.frameWidth,
        0,
        def.frameWidth,
        def.frameHeight,
        self.sheets[name]:getDimensions()
      )
    end
  end

  self.state        = 'idle'
  self.currentFrame = 1
  self.frameTimer   = 0

  return self
end

function Player:update(dt, world, effects)
  -- Horizontal movement --
  if love.keyboard.isDown('a') then
    self.isFacingRight = false
    if not self.isLocked then
      self.x = self.x - MOVE_SPEED * dt
    end
  elseif love.keyboard.isDown('d') then
    self.isFacingRight = true
    if not self.isLocked then
      self.x = self.x + MOVE_SPEED * dt
    end
  end

  -- Dash --
  if self.isDashing then
    local dir = self.isFacingRight and 1 or -1
    self.x = self.x + DASH_SPEED * dir * dt

    self.vy = 0 -- no gravity

    -- fase out first half, fade in second half
    local progress = 1 - (self.dashTimer / DASH_DURATION)
    if progress < 0.5 then
      self.dashAlpha = 1 - (progress * 2)                 -- 1 → 0.2
    else
      self.dashAlpha = 0.2 + ((progress - 0.5) * 2 * 0.8) -- 0.2 → 1
    end

    self.dashTimer = self.dashTimer - dt
    if self.dashTimer <= 0 then
      self.isDashing = false
      self.dashAlpha = 1
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
      else
        -- add this temporarily
        love.graphics.print("EFFECTS IS NIL", 10, 100)
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

  self.vy = self.vy + GRAVITY * dt -- Apply gravity
  self.y = self.y + self.vy * dt   -- Apply vertical velocity
  self.isGrounded = false          -- Reset grounded state each frame before checking

  -- Check collision --
  local tiles = world:getTiles()
  for _, tile in ipairs(tiles) do
    if self:overlaps(tile) then
      self:resolveCollision(tile)
    end
  end

  if self.isGrounded then          -- Coyote time: count down after leaving the ground
    self.coyoteTimer = COYOTE_TIME -- Keep refreshing while grounded
  else
    self.coyoteTimer = self.coyoteTimer - dt
  end

  if self.jumpBufferTimer > 0 then -- Jump buffer: count down after space is pressed
    self.jumpBufferTimer = self.jumpBufferTimer - dt
  end

  if self.isGrounded and self.jumpBufferTimer > 0 then -- Auto jump if buffer is still active when landing
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

  -- Advance animation frame --
  local def = ANIMS[self.state]
  self.frameTimer = self.frameTimer + dt
  if self.frameTimer >= def.interval then
    self.frameTimer = self.frameTimer - def.interval

    if def.loop then
      self.currentFrame = (self.currentFrame % def.totalFrames) + 1
    elseif self.currentFrame < def.totalFrames then
      self.currentFrame = self.currentFrame + 1
    else
      self:onAnimationEnd()
    end
  end

  -- Switch state block--
  if self.isDashing then
    self:setState('run')
  elseif self.isLocked then -- attack animation playing
    -- do nothing --
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

function Player:setState(newState)
  if self.state == newState then return end
  self.state        = newState
  self.currentFrame = 1
  self.frameTimer   = 0
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

-- Returns true if player rectangle overlaps a tile rectangle
function Player:overlaps(tile)
  return self.x < tile.x + tile.width
      and self.x + self.width > tile.x
      and self.y < tile.y + tile.height
      and self.y + self.height > tile.y
end

-- Pushes player out of a tile based on which side they entered from
function Player:resolveCollision(tile)
  -- How far we're overlapping on each axis
  local overlapLeft   = (self.x + self.width) - tile.x
  local overlapRight  = (tile.x + tile.width) - self.x
  local overlapTop    = (self.y + self.height) - tile.y
  local overlapBottom = (tile.y + tile.height) - self.y

  -- Find the smallest overlap — that's the axis to resolve on
  local minOverlap    = math.min(overlapLeft, overlapRight, overlapTop, overlapBottom)

  if minOverlap == overlapTop then -- Player hit the top of a tile — ⬇
    self.y          = tile.y - self.height
    self.vy         = 0
    self.isGrounded = true
  elseif minOverlap == overlapBottom then -- Player hit the bottom of a tile ⬆
    self.y  = tile.y + tile.height
    self.vy = 0
  elseif minOverlap == overlapLeft then  -- Player hit the left side of a tile |◀
    self.x = tile.x - self.width
  elseif minOverlap == overlapRight then -- Player hit the right side of a tile ▶|
    self.x = tile.x + tile.width
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
  print("dash() called")
  if not self.isDashing and self.dashCooldown <= 0 and not self.isLocked then
    print("dash started")
    self.isDashing = true
    self.dashTimer = DASH_DURATION
  end
end

function Player:draw()
  local def     = ANIMS[self.state]
  local scaleX  = self.isFacingRight and 1 or -1
  local offsetX = self.isFacingRight and 0 or def.frameWidth

  love.graphics.setColor(1, 1, 1, self.dashAlpha)
  love.graphics.draw(
    self.sheets[self.state],
    self.quads[self.state][self.currentFrame],
    self.x - 48 + offsetX,
    self.y - 48,
    0,
    scaleX,
    1
  )

  -- debug collision box
  love.graphics.setColor(1, 0, 0, 0.5)
  love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
  love.graphics.setColor(1, 1, 1)
end

return Player
