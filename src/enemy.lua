local Entity  = require('src.entity')
local Debug   = require('src.debug')

local Enemy   = {}
Enemy.__index = Enemy
setmetatable(Enemy, { __index = Entity })

local SCALE_X            = 2
local SCALE_Y            = 2
local WALK_SPEED         = 80
local CHASE_SPEED        = 200
local AGGRO_RANGE        = 400
local ATTACK_RANGE       = 95
local HEALTH             = 3
local ATTACK_END_DELAY   = 0.5 -- pause after full combo before attacking again
local HURT_DURATION      = 0.3
local ENEMY_HITBOX_WIDTH = 80

local function distanceTo(a, b)
  local ax = a.x + a.width / 2
  local bx = b.x + b.width / 2
  return math.abs(ax - bx)
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
  run = {
    file        = 'sprites/skeleton-sword/run.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 8,
    interval    = 0.12,
    loop        = true
  },
  attack_1 = {
    file        = 'sprites/skeleton-sword/attack-1.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 5,
    activeFrame = 4,
    interval    = 0.1,
    loop        = false
  },
  attack_2 = {
    file        = 'sprites/skeleton-sword/attack-2.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 6,
    activeFrame = 4,
    interval    = 0.1,
    loop        = false
  },
  attack_3 = {
    file        = 'sprites/skeleton-sword/attack-3.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 4,
    activeFrame = 3,
    interval    = 0.1,
    loop        = false
  },
  hurt = {
    file        = 'sprites/skeleton-sword/hurt.png',
    frameWidth  = 128,
    frameHeight = 128,
    totalFrames = 2,
    interval    = 0.05,
    loop        = false
  }
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
  self.attackTimer  = 0 -- cooldown between attacks --
  self.attackChain  = 0 -- which attack in sequence --
  self.isAttacking  = false
  self.isHurt       = false

  self:setState('idle')
  return self
end

function Enemy:update(dt, world, player)
  local dist = distanceTo(self, player)

  -- hurt timer tick --
  if self.isHurt then
    -- onAnimationEnd handles this --
  end

  -- tick attack cooldown --
  if self.attackTimer > 0 then
    self.attackTimer = self.attackTimer - dt
  end

  -- AI State transitions --
  if not self.isHurt then
    if self.isAttacking then
      local dir = player.x > self.x and 1 or -1
      self.isFacingRight = dir == 1
    elseif dist <= ATTACK_RANGE and self.attackTimer <= 0 then
      self.aiState = 'attack'
      self.isAttacking = true
      self.attackChain = 1
      self:setState('attack_1')
    elseif dist <= AGGRO_RANGE then
      self.aiState = 'chase'
    else
      self.aiState = 'patrol'
    end
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
    if dist > ATTACK_RANGE then
      local dir = player.x > self.x and 1 or -1
      self.x = self.x + CHASE_SPEED * dir * dt
      self.isFacingRight = dir == 1
    end
  end

  self:updatePhysics(dt, world)
  self:updateAnimation(dt)

  -- state machine --
  if self.isHurt then
    self:setState('hurt')
  elseif self.isAttacking then
    -- do nothing
  elseif self.aiState == 'chase' and dist <= ATTACK_RANGE then
    self:setState('idle') -- in range but waiting for cooldown
  elseif self.aiState == 'patrol' then
    self:setState('walk')
  elseif self.aiState == 'chase' then
    self:setState('run')
  else
    self:setState('idle')
  end

  -- Debug --
  Debug.log('enemy_state', self.aiState)
  Debug.log('enemy_health', self.health)
end

function Enemy:onAnimationEnd()
  if self.state == 'attack_1' then
    self.attackChain = 2
    self:setState('attack_2')
  elseif self.state == 'attack_2' then
    self.attackChain = 3
    self:setState('attack_3')
  elseif self.state == 'attack_3' then
    self.isAttacking = false
    self.attackChain = 0
    self.attackTimer = ATTACK_END_DELAY
    self.aiState = 'idle'
    self:setState('idle')
  elseif self.state == 'hurt' then
    self.isHurt  = false
    self.aiState = 'patrol'
    self.setState('idle')
  end
end

function Enemy:getHitbox()
  local attackStates = {
    attack_1 = true,
    attack_2 = true,
    attack_3 = true
  }
  if not attackStates[self.state] then return nil end

  local def = ANIMS[self.state]
  if def.activeFrame and self.currentFrame < def.activeFrame then
    return nil
  end

  local hx = self.isFacingRight
      and self.x + self.width
      or self.x - ENEMY_HITBOX_WIDTH

  return {
    x = hx,
    y = self.y + 10,
    width = ENEMY_HITBOX_WIDTH,
    height = self.height - 20
  }
end

function Enemy:takeDamage(amount)
  if self.isHurt then
    return
  end

  self.health = self.health - amount
  self.isHurt = true
  self.hurtTimer = HURT_DURATION
  self.isAttacking = false
  self.attackChain = 0
  self.aiState = 'hurt'

  if self.health <= 0 then
    self.health = 0
    Debug.log('enemy_health', 'DEAD')
  end

  self:setState('hurt')
end

function Enemy:draw()
  Entity.draw(self, SPRITE_OFFSET_X, SPRITE_OFFSET_Y, SCALE_X, SCALE_Y)

  -- debug collision box
  -- love.graphics.setColor(0, 1, 0, 0.5)
  -- love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
  -- love.graphics.setColor(1, 1, 1, 1)
end

return Enemy
