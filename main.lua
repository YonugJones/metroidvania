Object        = require 'lib.classic'
local World   = require 'src.world'
local Player  = require 'src.player'
-- local Enemy   = require 'src.enemy'
local Camera  = require 'src.camera'
local Effects = require 'src.effects'
local Debug   = require 'src.debug'

function love.load()
  world = World.new()
  player = Player(200, 200)
  -- enemy = Enemy.new(500, 200)
  camera = Camera.new()
  effects = Effects.new()
end

local function checkHitboxOverlap(a, b)
  if not a or not b then
    return false
  end

  return a.x < b.x + b.width
      and a.x + a.width > b.x
      and a.y < b.y + b.height
      and a.y + a.height > b.y
end

function love.update(dt)
  player:update(dt, world, effects)
  -- enemy:update(dt, world, player)

  -- Player hits enemy --
  local playerHitbox = player:getHitbox()
  -- local enemyHurtbox = {
  --   x      = enemy.x,
  --   y      = enemy.y,
  --   width  = enemy.width,
  --   height = enemy.height
  -- }

  -- if checkHitboxOverlap(playerHitbox, enemyHurtbox) then
  --   enemy:takeDamage(1)
  -- end

  -- Enemy hits player --
  -- local enemyHitbox = enemy:getHitbox()
  -- local playerHurtbox = {
  --   x      = player.x,
  --   y      = player.y,
  --   width  = player.width,
  --   height = player.height
  -- }

  -- if checkHitboxOverlap(enemyHitbox, playerHurtbox) then
  --   player:takeDamage(1)
  -- end

  camera:follow(player, love.graphics.getWidth(), love.graphics.getHeight())
  effects:update(dt)
end

function love.draw()
  world:draw(camera)
  camera:attach()

  -- enemy:draw()
  player:draw()
  effects:draw()
  camera:detach()
  Debug.draw()
end

function love.keypressed(key)
  if key == 'space' then
    player:pressJump()
  end

  if key == 'j' then
    player.dashHeld = true
    player:dash()
  end

  if key == 'k' then
    player:attack()
  end

  if key == 's' then
    player:slide()
  end

  if key == 'p' then
    Debug.toggle()
  end

  if key == 'escape' then
    love.event.quit()
  end
end

function love.keyreleased(key)
  if key == 'space' then
    player:releaseJump()
  end

  if key == 'j' then
    player.dashHeld = false
  end
end
