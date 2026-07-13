local Entity  = Object:extend()

local GRAVITY = 1800

function Entity:new(x, y, width, height, anims)
  -- Position --
  self.x             = x
  self.y             = y
  self.width         = width
  self.height        = height
  self.isFacingRight = true

  -- Vertical --
  self.vy            = 0
  self.isGrounded    = false

  -- Animation --
  self.anims         = anims
  self.sheets        = {}
  self.quads         = {}
  self.state         = nil
  self.currentFrame  = 1
  self.frameTimer    = 0
  self.frameInterval = nil

  -- load spritesheets + build quads --
  for key, value in pairs(anims) do
    if not self.sheets[value.file] then
      self.sheets[value.file] = love.graphics.newImage(value.file)
    end

    self.sheets[key] = self.sheets[value.file]
    self.quads[key]  = {}

    local offset     = value.sheetOffset or 0
    for i = 0, value.totalFrames - 1 do
      self.quads[key][i + 1] = love.graphics.newQuad(
        (offset + i) * value.frameWidth, -- x
        0,                               -- y
        value.frameWidth,                -- width
        value.frameHeight,               -- height
        self.sheets[key]:getDimensions() -- spritesheet width + height
      )
    end
  end
end

function Entity:setState(newState)
  if self.state == newState then return end
  self.state         = newState
  self.currentFrame  = 1
  self.frameTimer    = 0
  self.frameInterval = nil
end

function Entity:updatePhysics(dt, world)
  self.vy         = self.vy + GRAVITY * dt -- gravity is being applied to vertical velocity
  self.y          = self.y + self.vy * dt  -- player y position is being affected by vertical velocity
  self.isGrounded = false                  -- reset each phrame, collision sets to true if grounded

  -- Tile collision --
  if world then
    local tiles = world:getTiles()
    for _, tile in ipairs(tiles) do
      if self:detectCollision(tile) then
        self:resolveCollision(tile)
      end
    end
  end
end

function Entity:updateAnimation(dt)
  local value = self.anims[self.state]
  if not value then return end
  local interval = self.frameInterval or value.interval

  -- single frame non-looping: fire onAnimationEnd after one interval --
  if value.totalFrames == 1 and not value.loop then
    self.frameTimer = self.frameTimer + dt
    if self.frameTimer >= interval then
      self.frameTimer = 0
      self:onAnimationEnd()
    end
    return -- exit here, don't fall through
  end

  self.frameTimer = self.frameTimer + dt

  if self.frameTimer >= interval then
    self.frameTimer = self.frameTimer - interval

    if value.loop then
      self.currentFrame = (self.currentFrame % value.totalFrames) + 1
    elseif self.currentFrame < value.totalFrames then
      self.currentFrame = self.currentFrame + 1
    else
      self:onAnimationEnd()
    end
  end
end

function Entity:onAnimationEnd()
  -- override in subclass --
end

function Entity:detectCollision(other)
  return self.x < other.x + other.width
      and self.x + self.width > other.x
      and self.y < other.y + other.height
      and self.y + self.height > other.y
end

function Entity:resolveCollision(tile)
  local overlapTileLeft   = (self.x + self.width) - tile.x
  local overlapTileRight  = (tile.x + tile.width) - self.x
  local overlapTileTop    = (self.y + self.height) - tile.y
  local overlapTileBottom = (tile.y + tile.height) - self.y
  local minOverlap        = math.min(
    overlapTileLeft,
    overlapTileRight,
    overlapTileTop,
    overlapTileBottom
  )

  if minOverlap == overlapTileTop then
    self.y          = tile.y - self.height
    self.vy         = 0
    self.isGrounded = true
  elseif minOverlap == overlapTileBottom then
    self.y  = tile.y + tile.height
    self.vy = 0
  elseif minOverlap == overlapTileLeft then
    self.x = tile.x - self.width
  elseif minOverlap == overlapTileRight then
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

  local animOffsetX = def.offsetX or 0
  local animOffsetY = def.offsetY or 0

  love.graphics.draw(
    self.sheets[self.state],                               -- drawable
    self.quads[self.state][self.currentFrame],             -- quad
    self.x + (spriteOffsetX or 0) + offsetX + animOffsetX, -- x
    self.y + (spriteOffsetY or 0) + animOffsetY,           -- y
    0,                                                     -- r
    flipX * scaleX,                                        -- sx
    scaleY                                                 -- sy
  )
end

return Entity
