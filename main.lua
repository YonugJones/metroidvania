local Player = require('src.player')
local World = require('src.world')

function love.load()
  world = World.new()
  player = Player.new(100, 100)
end

function love.update(dt)
  player:update(dt, world)
end

function love.draw()
  world:draw()
  player:draw()
end

function love.keypressed(key)
  if key == 'space' then
    player:jump()
  end

  if key == 'escape' then
    love.event.quit()
  end
end
