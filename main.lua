local Player = require('src.player')
local World = require('src.world')
local Camera = require('src.camera')

function love.load()
  world = World.new()
  player = Player.new(200, 200)
  camera = Camera.new()
end

function love.update(dt)
  player:update(dt, world)
  camera:follow(player, love.graphics.getWidth(), love.graphics.getHeight())
end

function love.draw()
  world:draw(camera)
  camera:attach()
  player:draw()
  camera:detach()
end

function love.keypressed(key)
  if key == 'space' then
    player:pressJump()
  end

  if key == 'v' then
    player:attack()
  end

  if key == 'escape' then
    love.event.quit()
  end
end

function love.keyreleased(key)
  if key == 'space' then
    player.jumpHeld = false
  end
end
