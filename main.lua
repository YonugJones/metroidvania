local Player = require('src.player')
local World = require('src.world')
local Camera = require('src.camera')
local Effects = require('src.effects')
local Debug = require('src.debug')

function love.load()
  world = World.new()
  player = Player.new(200, 200)
  camera = Camera.new()
  effects = Effects.new()
end

function love.update(dt)
  player:update(dt, world, effects)
  camera:follow(player, love.graphics.getWidth(), love.graphics.getHeight())
  effects:update(dt)
end

function love.draw()
  world:draw(camera)
  camera:attach()
  player:draw()
  effects:draw()
  camera:detach()
  Debug.draw()
  love.graphics.print('P: debug', 5, 100)
  love.graphics.print('WASD: move', 5, 118)
  love.graphics.print('J: dash/sprint', 5, 136)
  love.graphics.print('K: attack', 5, 154)
  love.graphics.print('SPACE: jump', 5, 172)
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
    player.jumpHeld = false
  end

  if key == 'j' then
    player.dashHeld = false
  end
end
