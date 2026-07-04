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

  local y = 10
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle('fill', 5, 5, 250, (8 + #lines * 18))
  love.graphics.setColor(1, 1, 0)
  for key, value in pairs(lines) do
    love.graphics.print(key .. ": " .. value, 10, y)
    y = y + 18
  end
  love.graphics.setColor(1, 1, 1)
  lines = {} -- clear each frame
end

return Debug
