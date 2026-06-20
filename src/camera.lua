local Camera = {}
Camera.__index = Camera

function Camera.new()
  local self = setmetatable({}, Camera)

  self.x = 0
  self.y = 0

  return self
end

-- Center the camera on a target (the player)
function Camera:follow(target, screenWidth, screenHeight)
  -- We want the target centered on screen, so we offset by half the screen
  self.x = target.x - screenWidth / 2
  self.y = target.y - screenHeight / 2
end

-- Apply the camera transform before drawing the world
function Camera:attach()
  love.graphics.push()
  love.graphics.translate(-self.x, -self.y)
end

-- Restore the transform after drawing
function Camera:detach()
  love.graphics.pop()
end

return Camera
