local Player = {}
-- if any key is looked up on any instance of Player and not found,
-- that method will be looked up on Player itself
Player.__index = Player

local MOVE_SPEED = 200
local GRAVITY = 800 -- pixels per second squared, pulls player down
local JUMP_FORCE = -400

-- dot notation here since instance is being created manually,
-- not receiving it as self
function Player.new(x, y)
  -- creates an empty table, attach Player as its metatable, and name self
  local self = setmetatable({}, Player)

  self.x = x
  self.y = y
  self.width = 32
  self.height = 48
  self.vy = 0 -- vertical velocity, changes each frame
  self.isGrounded = false

  return self
end

-- Colon notation to avoid manually passing self into function
function Player:update(dt, world)
  if love.keyboard.isDown('left') then
    self.x = self.x - MOVE_SPEED * dt
  elseif love.keyboard.isDown('right') then
    self.x = self.x + MOVE_SPEED * dt
  end

  -- Apply gravity to vertical velocity every frame
  self.vy = self.vy + GRAVITY * dt

  -- Apply vertical velocity to position
  self.y = self.y + self.vy * dt

  -- -- Temp floor for player
  -- local floor = 500
  -- -- if foot position is lower than floor
  -- if self.y + self.height >= floor then
  --   self.y = floor - self.height
  --   self.vy = 0
  --   self.isGrounded = true
  -- else
  --   self.isGrounded = false
  -- end
end

function Player:jump()
  if self.isGrounded then
    self.vy = JUMP_FORCE
    self.isGrounded = false
  end
end

function Player:draw()
  love.graphics.setColor(0, 0.8, 1)
  love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
  love.graphics.setColor(1, 1, 1)
end

return Player
