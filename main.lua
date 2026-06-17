local Player = require('src/player')

function love.load()
  player = Player.new(100, 100)
end

function love.update(dt)
  player:update(dt)
end

function love.draw()
  player:draw()
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
end
