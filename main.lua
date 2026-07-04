local Player = require('src.player')
local World = require('src.world')
local Camera = require('src.camera')
local Effects = require('src.effects')

debugLines = {}

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
  for i, line in ipairs(debugLines) do
    love.graphics.print(line, 10, 10 + (i - 1) * 18)
  end
  debugLines = {}

  table.insert(debugLines, "draw running: " .. tostring(player.isSprinting))
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

  if key == 'j' then
    player.dashHeld = false
  end
end
