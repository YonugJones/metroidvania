local Entity  = require('src.entity')
local Debug   = require('src.debug')

local Enemy   = {}
Enemy.__index = Enemy
setmetatable(Enemy, { __index = Entity })

local SCALE_X         = 2
local SCALE_Y         = 2
local WALK_SPEED      = 80
local CHASE_SPEED     = 160
local AGGRO_RANGE     = 300
local ATTACK_RANGE    = 60
local HEALTH          = 3

local ANIMS           = {
  idle = {
    file        = 'sprites/skeleton-sword/idle.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 7,
    interval    = 0.3,
    loop        = true
  },
}

local SPRITE_OFFSET_X = -96
local SPRITE_OFFSET_Y = -140

function Enemy.new(x, y)
  local self = Entity.new(x, y, 48, 110, ANIMS)
  setmetatable(self, Enemy)

  self.health    = HEALTH
  self.isDead    = false
  self.patrolDir = 1 -- 1 = right, -1 = left
  self.aiState   = 'patrol'

  self:setState('idle')
  return self
end

function Enemy:update(dt, world, player)
  self:updatePhysics(dt, world)
  self:updateAnimation(dt)

  -- Debug --
  Debug.log('enemy_state', self.aiState)
  Debug.log('enemy_health', self.health)
end

function Enemy:draw()
  Entity.draw(self, SPRITE_OFFSET_X, SPRITE_OFFSET_Y, SCALE_X, SCALE_Y)

  -- debug collision box
  love.graphics.setColor(0, 1, 0, 0.5)
  love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
  love.graphics.setColor(1, 1, 1, 1)
end

return Enemy
