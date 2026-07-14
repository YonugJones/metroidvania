local Debug   = {}

local lines   = {}
local enabled = true

function Debug.log(key, value)
  if not enabled then return end
  lines[key] = tostring(value) -- keyed so each label only appears once
end

function Debug.toggle()
  enabled = not enabled
  lines   = {}
end

function Debug.draw()
  if not enabled then return end

  local screenWidth = love.graphics.getWidth()
  local boxWidth    = 250
  local x           = screenWidth - boxWidth - 5
  local y           = 10

  -- count keyed entries --
  local count       = 0
  for _ in pairs(lines) do count = count + 1 end

  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle('fill', x, 5, boxWidth, (8 + count * 18))
  love.graphics.setColor(1, 1, 0)
  for key, value in pairs(lines) do
    love.graphics.print(key .. ": " .. value, x + 5, y)
    y = y + 18
  end
  love.graphics.setColor(1, 1, 1)
  lines = {}
end

return Debug
