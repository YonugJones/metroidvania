local Background = Object:extend()

-- parallax speeds: 0 = fixed, 1 = moves with camera
local LAYERS     = {
  { file = 'sprites/backgrounds/sky.png',     speed = 0.1 },
  { file = 'sprites/backgrounds/clouds.png',  speed = 0.2 },
  { file = 'sprites/backgrounds/flora-1.png', speed = 0.4 },
  { file = 'sprites/backgrounds/flora-2.png', speed = 0.6 },
}

local IMG_WIDTH  = 960
local IMG_HEIGHT = 544

function Background:new()
  self.layers = {}
  for i, def in ipairs(LAYERS) do
    self.layers[i] = {
      image = love.graphics.newImage(def.file),
      speed = def.speed
    }
  end
end

function Background:draw(camera)
  for _, layer in ipairs(self.layers) do
    -- offset this layer by a fraction of the camera position
    local offsetX = camera.x * layer.speed
    local offsetY = camera.y * layer.speed

    -- tile horizontally so it never runs out
    local startX = -(offsetX % IMG_WIDTH)
    if startX > 0 then startX = startX - IMG_WIDTH end

    local y = -offsetY

    local x = startX
    while x < love.graphics.getWidth() do
      love.graphics.draw(layer.image, x, y)
      x = x + IMG_WIDTH
    end
  end
end

return Background
