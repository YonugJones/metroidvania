local Player               = {}
Player.__index             = Player

local MOVE_SPEED           = 200
local GRAVITY              = 800 -- pixels per second squared, pulls player down
local JUMP_FORCE           = -400
local JUMP_HOLD_FORCE      = -600
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

  self.x               = x
  self.y               = y
  self.width           = 32
  self.height          = 80
  self.vy              = 0
  self.isGrounded      = false
  self.isFacingRight   = true
  self.jumpHeld        = false
  self.jumpTimer       = 0
  self.isLocked        = false -- true while attack animation plays
  self.attackChain     = 0     -- which hit in the combo (1, 2, 3)
  self.attackBuffered  = false -- true if v was pressed during attack
  self.recoveryTimer   = 0
  self.isRecovering    = false
  self.coyoteTimer     = 0
  self.jumpBufferTimer = 0

  -- Load all spritesheets and build quads
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

function Player:update(dt, world)
  -- Horizontal movement
  if love.keyboard.isDown('left') then
    self.isFacingRight = false
    if not self.isLocked then
      self.x = self.x - MOVE_SPEED * dt
    end
  elseif love.keyboard.isDown('right') then
    self.isFacingRight = true
    if not self.isLocked then
      self.x = self.x + MOVE_SPEED * dt
    end
  end

  -- Variable jump extension
  if self.jumpHeld then
    if love.keyboard.isDown('space') and self.jumpTimer < MAX_JUMP_TIME then
      self.vy        = self.vy + JUMP_HOLD_FORCE * dt
      self.jumpTimer = self.jumpTimer + dt
    else
      self.jumpHeld = false
    end
  end

  -- Apply gravity
  self.vy = self.vy + GRAVITY * dt

  -- Apply vertical velocity
  self.y = self.y + self.vy * dt

  -- Reset grounded state each frame before checking
  self.isGrounded = false

  -- Check collision against all solid tiles
  local tiles = world:getTiles()
  for _, tile in ipairs(tiles) do
    if self:overlaps(tile) then
      self:resolveCollision(tile)
    end
  end

  -- Coyote time: count down after leaving the ground
  if self.isGrounded then
    self.coyoteTimer = COYOTE_TIME -- Keep refreshing while grounded
  else
    self.coyoteTimer = self.coyoteTimer - dt
  end

  -- Jump buffer: count down after space is pressed
  if self.jumpBufferTimer > 0 then
    self.jumpBufferTimer = self.jumpBufferTimer - dt
  end

  -- Auto jump if buffer is still active when landing
  if self.isGrounded and self.jumpBufferTimer > 0 then
    self:jump()
    self.jumpBufferTimer = 0
  end

  -- Recovery after attack combo
  if self.isRecovering then
    self.recoveryTimer = self.recoveryTimer - dt
    if self.recoveryTimer <= 0 then
      self.isRecovering = false
      self.isLocked = false
    end
  end

  -- Advance animation frame
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

  if self.isLocked then
    -- attack animation is playing so do not switch state
  elseif not self.isGrounded then
    if self.vy < 0 then
      self:setState('jump_up')
    else
      self:setState('jump_down')
    end
  elseif love.keyboard.isDown('left') or love.keyboard.isDown('right') then
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

function Player:onAnimationEnd()
  if self.state == 'attack1' or self.state == 'attack2' then
    if self.attackBuffered then
      -- advance to next hit in chain
      self.attackBuffered = false
      self.attackChain    = self.attackChain + 1
      self:setState(ATTACK_STATES[self.attackChain])
    else
      -- no buffered attack input, unlock and return to idel
      self.isLocked    = false
      self.attackChain = 0
      self:setState('idle')
    end
  elseif self.state == 'attack3' then
    -- end of chain
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

  if minOverlap == overlapTop then
    -- Player hit the top of a tile — land on it
    self.y          = tile.y - self.height
    self.vy         = 0
    self.isGrounded = true
  elseif minOverlap == overlapBottom then
    -- Player hit the bottom of a tile — bump head
    self.y  = tile.y + tile.height
    self.vy = 0
  elseif minOverlap == overlapLeft then
    -- Player hit the left side of a tile
    self.x = tile.x - self.width
  elseif minOverlap == overlapRight then
    -- Player hit the right side of a tile
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

function Player:draw()
  local def     = ANIMS[self.state]
  local scaleX  = self.isFacingRight and 1 or -1
  local offsetX = self.isFacingRight and 0 or def.frameWidth

  love.graphics.setColor(1, 1, 1)
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
