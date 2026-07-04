local Entity   = {}
Entity.__index = Entity

local GRAVITY  = 1800

function Entity.new(x, y, width, height, anims)
  local self         = setmetatable({}, Entity)
  -- Position --
  self.x             = x
  self.y             = y
  self.width         = width
  self.height        = height
  self.isFacingRight = true

  -- Vertical --
  self.vy            = 0
  self.isGrounded    = true

  -- Animation --
  self.sheets        = {}
  self.quads         = {}
  self.state         = nil
  self.currentFrame  = 1
  self.frameTimer    = 0
  self.anims         = anims

  -- Load spritesheets and build quads
  for name, def in pairs(anims) do
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

  return self
end

function Entity:setState(newState)
  if self.state == newState then return end
  self.state         = newState
  self.currentFrame  = 1
  self.frameTimer    = 0
  self.frameInterval = nil
end

function Entity:updatePhysics(dt, world)
  -- Apply gravity --
  self.vy = self.vy + GRAVITY * dt
  -- Apply vertical velocity --
  self.y = self.y + self.vy * dt
  -- Reset grounded state --
  self.isGrounded = false
  -- Tile collision --
  local tiles = world:getTiles()
  for _, tile in ipairs(tiles) do
    if self:overlaps(tile) then
      self:resolveCollision(tile)
    end
  end
end

function Entity:updateAnimation(dt)
  local def = self.anims[self.state]
  if not def then return end
  local interval = self.frameInterval or def.interval

  self.frameTimer = self.frameTimer + dt
  if self.frameTimer >= def.interval then
    self.frameTimer = self.frameTimer - interval

    if def.loop then
      self.currentFrame = (self.currentFrame % def.totalFrames) + 1
    elseif self.currentFrame < def.totalFrames then
      self.currentFrame = self.currentFrame + 1
    else
      self:onAnimationEnd()
    end
  end
end

function Entity:onAnimationEnd()
  -- override in subclass
end

function Entity:overlaps(other)
  return self.x < other.x + other.width
      and self.x + self.width > other.x
      and self.y < other.y + other.height
      and self.y + self.height > other.y
end

function Entity:resolveCollision(tile)
  local overlapLeft   = (self.x + self.width) - tile.x
  local overlapRight  = (tile.x + tile.width) - self.x
  local overlapTop    = (self.y + self.height) - tile.y
  local overlapBottom = (tile.y + tile.height) - self.y
  local minOverlap    = math.min(overlapLeft, overlapRight, overlapTop, overlapBottom)

  if minOverlap == overlapTop then -- Entity hits top of tile
    self.y          = tile.y - self.height
    self.vy         = 0
    self.isGrounded = true
  elseif minOverlap == overlapBottom then -- Entity hits bottom of tile
    self.y  = tile.y + tile.height
    self.vy = 0
  elseif minOverlap == overlapLeft then  -- Entity hits left side of tile
    self.x = tile.x - self.width
  elseif minOverlap == overlapRight then -- Entity hits right side of tile
    self.x = tile.x + tile.width
  end
end

function Entity:draw(spriteOffsetX, spriteOffsetY, scaleX, scaleY)
  local def = self.anims[self.state]
  if not def then return end

  scaleX = scaleX or 1
  scaleY = scaleY or 1

  local flipX = self.isFacingRight and 1 or -1
  local offsetX = self.isFacingRight and 0 or def.frameWidth * scaleX

  love.graphics.draw(
    self.sheets[self.state],
    self.quads[self.state][self.currentFrame],
    self.x + offsetX + (spriteOffsetX or 0),
    self.y + (spriteOffsetY or 0),
    0,
    flipX * scaleX,
    scaleY
  )

  -- -- debug collision box
  -- love.graphics.setColor(1, 0, 0, 0.5)
  -- love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
  -- love.graphics.setColor(1, 1, 1)
end

return Entity
