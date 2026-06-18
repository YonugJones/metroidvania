local World = {}
World.__index = World

local TILE_SIZE = 32

local MAP = {
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }, -- floor
}

function World.new()
  local self = setmetatable({}, World)
  self.tileSize = TILE_SIZE
  self.map = MAP
  return self
end

function World:draw()
  -- Loop through the rows
  for row = 1, #self.map, 1 do
    -- Loop through the columns of each row
    for col = 1, #self.map[row], 1 do
      -- If there is a block
      if self.map[row][col] == 1 then
        -- define the x position of a block - left side of block
        local x = (col - 1) * self.tileSize
        -- define the y position of a block - Top side of block
        local y = (row - 1) * self.tileSize

        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle('fill', x, y, self.tileSize, self.tileSize)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle('line', x, y, self.tileSize, self.tileSize)
      end
    end
  end
  love.graphics.setColor(1, 1, 1)
end

function World:getTiles()
  local tiles = {}

  for row = 1, #self.map, 1 do
    for col = 1, #self.map[row], 1 do
      if self.map[row][col] == 1 then
        table.insert(tiles, {
          x = (col) * self.tileSize,
          y = (row - 1) * self.tileSize,
          width = self.tileSize,
          height = self.tileSize,
        })
      end
    end
  end
  return tiles
end

return World
