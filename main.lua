local World = require('src.world')
local Player = require('src.player')
local Enemy = require('src.enemy')
local Camera = require('src.camera')
local Effects = require('src.effects')
local Debug = require('src.debug')

function love.load()
  world = World.new()
  player = Player.new(200, 200)
  enemy = Enemy.new(500, 200)
  camera = Camera.new()
  effects = Effects.new()
end

function love.update(dt)
  player:update(dt, world, effects)
  enemy:update(dt, world, player)
  camera:follow(player, love.graphics.getWidth(), love.graphics.getHeight())
  effects:update(dt)
end

function love.draw()
  world:draw(camera)
  camera:attach()

  enemy:draw()
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
