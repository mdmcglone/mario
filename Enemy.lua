Enemy = Class{}

require 'Animation'

local MOVE_SPEED = 90
local JUMP_SPEED = 400
local GRAVITY = 28

function Enemy:init(map, x)
    self.width = 16
    self.height = 14

    self.x = x
    self.y = map.tileHeight * (map.mapHeight / 2 - 1) - self.height

	self.dx = 0
	self.dy = 0

    self.texture = love.graphics.newImage('graphics/enemy.png')
    self.frames = generateQuads(self.texture,self.width,self.height)

    self.state = 'running'
    self.direction = 'right'
    



	self.animations = {
    	['running'] = Animation {
      		texture = self.texture,
      		frames = {
    			self.frames[1], self.frames[2]
    		},
    		interval = 0.2
    	}
    }
    
    self.animation = self.animations['running']
    
    self.behaviors = {
         ['running'] = function(dt)
            if self.direction == 'right' then
                self.dx = MOVE_SPEED / 2
            elseif self.direction == 'left' then
                self.dx = -MOVE_SPEED / 2
            end
         end,

         ['dying'] = function(dt)
            self.scaleY = self.scaleY - dt
         end,

         ['dead'] = function(dt)

         end
         
    }

end

function Enemy:update(dt)
    self.behaviors[self.state](dt)

    self.animation:update(dt)

	self.y = self.y + self.dy*dt
    self.x = self.x + self.dx*dt

    			
	self:checkRightCollision()
    self:checkLeftCollision()
    

  -- if self.scaleY <= 0 then
   --     self.state = 'dead'
   -- end


end

function Enemy:render()

    local scaleX
	if self.direction == 'left' then
    	scaleX = -1
	elseif self.direction == 'right' then
    	scaleX = 1
    end
    
    love.graphics.draw(self.texture, self.animation:getCurrentFrame(), math.floor(self.x), math.floor(self.y),
    0, scaleX, 1, self.width / 2)
	

end

function Enemy:collides(tile)

    local collidables = {
        TILE_BRICK, JUMP_BLOCK, JUMP_BLOCK_HIT, MUSHROOM_TOP, MUSHROOM_BOTTOM
    }

    for _, v in ipairs(collidables) do
        if tile == v then
            return true
        end
    end

    return false

end

function Enemy:checkLeftCollision()
	if self.dx < 0 then
		if self:collides(map:tileAt(self.x - self.width/2,self.y)) or
			self:collides(map:tileAt(self.x - self.width/2,self.y + self.height - 1)) then

            self.direction = 'right'

        end
        
        if map:tileAt(self.x - self.width/2, self.y + self.height) == TILE_EMPTY then
            self.direction = 'right'
        end
	end
end

function Enemy:checkRightCollision()
	if self.dx > 0 then
		if self:collides(map:tileAt(self.x + self.width / 2,self.y)) or
			self:collides(map:tileAt(self.x + self.width / 2,self.y + self.height - 1)) then

            self.direction = 'left'

        end
        
        if map:tileAt(self.x + self.width/2, self.y + self.height) == TILE_EMPTY then
            self.direction = 'left'
        end
	end
end

