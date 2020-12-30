Player = Class{}

require 'Animation'

local MOVE_SPEED = 90
local JUMP_SPEED = 400
local GRAVITY = 28

function Player:init(map)
    self.width = 16
    self.height = 20

    self.x = map.tileWidth * 10
    self.y = map.tileHeight * (map.mapHeight / 2 - 1) - self.height

	self.dx = 0
	self.dy = 0

    self.texture = love.graphics.newImage('graphics/blue_alien.png')
    self.frames = generateQuads(self.texture,self.width,self.height)

	self.state = 'idle'
	self.direction = 'right'

	self.sounds = {
     	['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
      	['coin'] = love.audio.newSource('sounds/coin.wav', 'static'),
        ['hit'] = love.audio.newSource('sounds/hit.wav', 'static'),
		['victory'] = love.audio.newSource('sounds/pickup.wav', 'static')
    }
	
	
	self.messages = love.graphics.newImage('graphics/messages2.png')
    self.messageSprites = generateQuads(self.messages, 130, 20)


	self.animations = {
    	['idle'] = Animation {
      		texture = self.texture,
      		frames = {
    			self.frames[1]
    		},
    		interval = 1
    	},
      	['walking'] = Animation {
         	texture = self.texture, 
            frames = {
            	self.frames[9], self.frames[10], self.frames[11]
            },
          	interval = 0.15
        },
        ['jumping'] = Animation {
          texture = self.texture,
          frames = {
          		self.frames[3], self.frames[8]
          },
        	interval = 0.3	 
		},
		['death'] = Animation {
			texture  = self.texture, 
			frames = {
				self.frames[5]
			},

			interval = 1
		}
    }
    
    self.animation = self.animations['idle']
    
    self.behaviors = {
     	['idle'] = function(dt)
            if love.keyboard.isDown('space') then
            	self.state = 'jumping'
				self.animation = self.animations['jumping']
        		self.dy = -JUMP_SPEED
                self.sounds['jump']:play()
        	elseif love.keyboard.isDown('d') then
        		self.dx = MOVE_SPEED
				self.animation = self.animations['walking']
				self.direction = 'right'
    		elseif love.keyboard.isDown('a') then
        		self.dx = -MOVE_SPEED
				self.animation = self.animations['walking']
				self.direction = 'left'
			else
                self.animation = self.animations['idle']
                self.dx = 0
			end
			
			self:checkRightCollision()
			self:checkLeftCollision()

			if not self:collides(map:tileAt(self.x, self.y + self.height)) then

				self.state = 'jumping'
				self.animation = self.animations['jumping']
				self.dy = self.dy + GRAVITY
	
			end


        end,

      	['walking'] = function(dt)
            if love.keyboard.isDown('space') then
            	self.state = 'jumping'
				self.animation = self.animations['jumping']
        		self.dy = -JUMP_SPEED
    			self.sounds['jump']:play()
            elseif love.keyboard.isDown('d') then
        		self.dx = MOVE_SPEED
				self.animation = self.animations['walking']
				self.direction = 'right'
    		elseif love.keyboard.isDown('a') then
        		self.dx = -MOVE_SPEED
				self.animation = self.animations['walking']
				self.direction = 'left'
			else
              	self.animation = self.animations['idle']
			end
			
			self:checkRightCollision()
			self:checkLeftCollision()

			if not self:collides(map:tileAt(self.x, self.y + self.height)) then

				self.state = 'jumping'
				self.animation = self.animations['jumping']
				self.dy = self.dy + GRAVITY
			end




        end,
        
        ['jumping'] = function(dt)
        	if love.keyboard.isDown('a') then
            	self.direction = 'left'
				self.dx = -MOVE_SPEED
			elseif love.keyboard.isDown('d') then
            	self.direction = 'right'
				self.dx = MOVE_SPEED
			else
                self.dx = 0
			end
            
            self.dy = self.dy + GRAVITY

	

			self:checkRightCollision()
			self:checkLeftCollision()

			if self:collides(map:tileAt(self.x, self.y + self.height)) then

				self.state = 'idle'
				self.animation = self.animations['idle']
				self.dy = 0

			end
		end,
          
         ['victory'] = function(dt)
        	self.dx = 0
			self.dy = 0
			self.x = (map.mapWidth) * (map.tileWidth - 1)
			self.y = map.tileHeight * (map.mapHeight / 2 - 1) - self.height

		end,
		
		 ['death'] = function(dt)
			self.dx = 0
			self.dy = 0
			
		end
        
    }

end

function Player:update(dt)
	self.behaviors[self.state](dt)

	self.animation:update(dt)


	self.y = self.y + self.dy*dt
    self.x = self.x + self.dx*dt
    
    if self.dy < 0 then
    
  	  if map:tileAt(self.x - self.width / 2, self.y) ~= TILE_EMPTY or 
      		map:tileAt(self.x + self.width / 2, self.y) ~= TILE_EMPTY then
            
      		self.dy = 0
			self.sounds['hit']:play()

             if map:tileAt(self.x - self.width / 2, self.y) == JUMP_BLOCK then
             	map:setTile(math.floor((self.x- self.width/2)/ map.tileWidth) + 1, 
                    math.floor(self.y / map.tileHeight) + 1, JUMP_BLOCK_HIT)
				self.sounds['coin']:play()
			 end
			 

            if map:tileAt(self.x + self.width - 1, self.y) == JUMP_BLOCK then
             	map:setTile(math.floor((self.x + self.width - 1)/ map.tileWidth) + 1, 
                    math.floor(self.y / map.tileHeight) + 1, JUMP_BLOCK_HIT)
				self.sounds['coin']:play()
             end
       end
    end

    if self.x >= (map.mapWidth - 2) * map.tileWidth then
    	self.sounds['victory']:play()
		self.state = 'victory'
		self.animation = self.animations['idle']
    end
	
	--clip fix
	if self.state == 'idle' or self.state == 'walking' then
		while self:collides(map:tileAt(self.x, self.y + self.height - 1)) do
			self.y = self.y - 1
		end
	end
	
	--death condition
	if self.y > map.mapHeight * map.tileHeight then
		self.state = 'death'
	end

end

function Player:render()
	
	local scaleX
	if self.direction == 'left' then
    	scaleX = -1
	elseif self.direction == 'right' then
    	scaleX = 1
	end

    love.graphics.draw(self.texture, self.animation:getCurrentFrame(), math.floor(self.x), math.floor(self.y),
			0, scaleX, 1, self.width / 2)

	if self.state == 'victory' then
		love.graphics.draw(self.messages, self.messageSprites[1], map.mapWidth * map.tileWidth - 275, 5)
	end
	
	if self.state == 'death' then
		love.graphics.draw(self.messages, self.messageSprites[2], self.x - 73, 5)
	end

end

function Player:collides(tile)

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

function Player:checkLeftCollision()
	if self.dx < 0 then
		if self:collides(map:tileAt(self.x - 1 - self.width/2,self.y)) or
			self:collides(map:tileAt(self.x - 1 - self.width/2,self.y + self.height - 1)) then

			self.dx = 0 
			self.sounds['hit']:play()

			if self:collides(map:tileAt(self.x + self.width / 2 + 1,self.y)) then
				self.x = self.x + 1
			end

		end
	end
end

function Player:checkRightCollision()
	if self.dx > 0 then
		if self:collides(map:tileAt(self.x + self.width / 2,self.y)) or
			self:collides(map:tileAt(self.x + self.width / 2,self.y + self.height - 1)) then

			self.dx = 0
			self.sounds['hit']:play()


			if self:collides(map:tileAt(self.x + self.width / 2 - 1,self.y)) then
				self.x = self.x - 1
			end

		end
	end
end
