local Player = require('src.player')
local World = require('src.world')
local Camera = require('src.camera')
local Effects = require('src.effects')

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


  -- debug
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("active effects: " .. #effects.active, 10, 10)
  love.graphics.print("dashCooldown: " .. string.format("%.2f", player.dashCooldown), 10, 28)
  love.graphics.print("isDashing: " .. tostring(player.isDashing), 10, 46)
end

function love.keypressed(key)
  if key == 'space' then
    player:pressJump()
  end

  if key == 'j' then
    print("j pressed")
    player:dash()
  end

  if key == 'k' then
    player:attack()
  end

  if key == 'e' then
    effects:addDashReady(player.x, player.y)
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
