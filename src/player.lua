local Player = {}
Player.__index = Player

local MOVE_SPEED = 200
local GRAVITY = 800 -- pixels per second squared, pulls player down
local JUMP_FORCE = -400
local ANIMS = {
  idle = {
    file        = 'sprites/Shinobi/Idle.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 6,
    interval    = 0.12,
  },
  run = {
    file        = 'sprites/Shinobi/Run.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 8,
    interval    = 0.07,
  },
}

function Player.new(x, y)
  -- creates an empty table, attach Player as its metatable, and name self
  local self         = setmetatable({}, Player)

  self.x             = x
  self.y             = y
  self.width         = 32
  self.height        = 80
  self.vy            = 0 -- vertical velocity, changes each frame
  self.isGrounded    = false
  self.isFacingRight = true

  -- Load all spritesheets and build quads
  self.sheets        = {}
  self.quads         = {}

  for name, def in pairs(ANIMS) do
    self.sheets[name] = love.graphics.newImage(def.file)
    self.quads[name]  = {}
    for i = 0, def.totalFrames - 1 do
      self.quads[name][i + 1] = love.graphics.newQuad(
        i * def.frameWidth,
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

-- Colon notation to avoid manually passing self into function
function Player:update(dt, world)
  -- Horizontal movement
  if love.keyboard.isDown('left') then
    self.x = self.x - MOVE_SPEED * dt
    self.isFacingRight = false
  elseif love.keyboard.isDown('right') then
    self.x = self.x + MOVE_SPEED * dt
    self.isFacingRight = true
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

  -- Advance animation frame
  local def = ANIMS[self.state]
  self.frameTimer = self.frameTimer + dt
  if self.frameTimer >= def.interval then
    self.frameTimer   = self.frameTimer - def.interval
    self.currentFrame = (self.currentFrame % def.totalFrames) + 1
  end

  -- Switch state based on movement
  if not self.isGrounded then
    self:setState('idle') -- jump anim later
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

function Player:jump()
  if self.isGrounded then
    self.vy = JUMP_FORCE
    self.isGrounded = false
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
