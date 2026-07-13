local Hud = Object:extend()

function Hud:new()
end

function Hud:draw(player)
  local barWidth  = 200
  local barHeight = 16
  local x         = 20
  local healthY   = 20
  local staminaY  = 44

  -- Health bar --
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.rectangle('fill', x, healthY, barWidth, barHeight)
  love.graphics.setColor(0.8, 0.2, 0.2)
  love.graphics.rectangle('fill', x, healthY, barWidth * (player.health / 10), barHeight)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('HP', x + barWidth + 6, healthY)

  -- Stamina bar --
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.rectangle('fill', x, staminaY, barWidth, barHeight)

  local staminaColor = player.isExhausted
      and { 0.5, 0.5, 0.5 } -- gray when exhausted
      or { 0.2, 0.7, 0.2 } -- green when normal

  love.graphics.setColor(staminaColor)
  love.graphics.rectangle('fill', x, staminaY, barWidth * (player.stamina / 100), barHeight)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('SP', x + barWidth + 6, staminaY)
end

return Hud
