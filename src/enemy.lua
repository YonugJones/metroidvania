local Entity  = require('src.entity')
local Debug   = require('src.debug')

local Enemy   = {}
Enemy.__index = Enemy
setmetatable(Enemy, { __index = Entity })

local SCALE_X      = 2
local SCALE_Y      = 2
local WALK_SPEED   = 80
local CHASE_SPEED  = 160
local AGGRO_RANGE  = 400
local ATTACK_RANGE = 60
local HEALTH       = 3

local function distanceTo(a, b)
  return math.abs(a.x - b.x)
end

local ANIMS           = {
  idle = {
    file        = 'sprites/skeleton-sword/idle.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 7,
    interval    = 0.3,
    loop        = true
  },
  walk = {
    file        = 'sprites/skeleton-sword/walk.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 7,
    interval    = 0.18,
    loop        = true
  },
}

local SPRITE_OFFSET_X = -96
local SPRITE_OFFSET_Y = -140

function Enemy.new(x, y)
  local self = Entity.new(x, y, 48, 110, ANIMS)
  setmetatable(self, Enemy)

  self.health       = HEALTH
  self.isDead       = false
  self.aiState      = 'patrol'
  self.patrolDir    = 1
  self.patrolOrigin = x
  self.patrolDist   = 150

  self:setState('idle')
  return self
end

function Enemy:update(dt, world, player)
  local dist = distanceTo(self, player)

  -- AI State transitions --
  if dist <= ATTACK_RANGE then
    self.aiState = 'attack'
  elseif dist <= AGGRO_RANGE then
    self.aiState = 'chase'
  else
    self.aiState = 'patrol'
  end

  -- AI Behavior --
  if self.aiState == 'patrol' then
    self.x = self.x + WALK_SPEED * self.patrolDir * dt
    self.isFacingRight = self.patrolDir == 1

    if self.x > self.patrolOrigin + self.patrolDist then
      self.patrolDir = -1
    elseif self.x < self.patrolOrigin - self.patrolDist then
      self.patrolDir = 1
    end
  elseif self.aiState == 'chase' then
    local dir = player.x > self.x and 1 or -1
    self.x = self.x + CHASE_SPEED * dir * dt
    self.isFacingRight = dir == 1
  elseif self.aiState == 'attack' then
    -- attack logic here
  end

  self:updatePhysics(dt, world)
  self:updateAnimation(dt)

  -- state machine --
  if self.aiState == 'patrol' then
    self:setState('walk')
  elseif self.aiState == 'chase' then
    self:setState('walk') -- run next
  else
    self:setState('idle')
  end

  -- Debug --
  Debug.log('enemy_state', self.aiState)
  Debug.log('enemy_health', self.health)
end

function Enemy:draw()
  Entity.draw(self, SPRITE_OFFSET_X, SPRITE_OFFSET_Y, SCALE_X, SCALE_Y)

  -- debug collision box
  -- love.graphics.setColor(0, 1, 0, 0.5)
  -- love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
  -- love.graphics.setColor(1, 1, 1, 1)
end

return Enemy
