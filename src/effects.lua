local Effects = {}
Effects.__index = Effects

function Effects.new()
  local self = setmetatable({}, Effects)
  self.active = {} -- list of active effects
  return self
end

function Effects:addDashReady(x, y)
  table.insert(self.active, {
    type      = 'dashReady',
    x         = x,
    y         = y,
    timer     = 0,
    duration  = 0.4,
    maxRadius = 48
  })
end

function Effects:update(dt)
  for i = #self.active, 1, -1 do
    local e = self.active[i]
    e.timer = e.timer + dt
    if e.timer > e.duration then
      table.remove(self.active, i)
    end
  end
end

function Effects:draw()
  for _, e in ipairs(self.active) do
    local progress = e.timer / e.duration   -- 0 → 1 over duration
    local radius   = e.maxRadius * progress -- expands outward
    local alpha    = 0.8 * (1 - progress)   -- fades out

    love.graphics.setColor(0.5, 0.8, 1, alpha)
    love.graphics.setLineWidth(2)
    love.graphics.circle('line', e.x, e.y, radius)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
  end
end

return Effects
