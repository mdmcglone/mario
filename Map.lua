
require 'Player'
require 'Enemy'

Map = Class{}

TILE_BRICK = 1
TILE_EMPTY = 4

-- cloud tiles
CLOUD_LEFT = 6
CLOUD_RIGHT = 7

-- bush tiles
BUSH_LEFT = 2
BUSH_RIGHT = 3

-- mushroom tiles
MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

-- jump block
JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9

local SCROLL_SPEED = 62


function Map:init()
    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 50
    self.mapHeight = 28
    self.tiles = {}

    self.tileSprites = generateQuads(self.spritesheet, self.tileWidth, self.tileHeight)

    self.music = love.audio.newSource('sounds/music.wav', 'static')

    self.camX = 0
    self.camY = 0

    self.player = Player(self)
    self.enemies = {Enemy(self, math.random(0,40)*self.tileWidth), Enemy(self,math.random(0,40)*self.tileWidth), Enemy(self,math.random(0,40)*self.tileWidth)}


    self.mapWidthPixels = self.mapWidth*self.tileWidth
    self.mapHeightPixels = self.mapHeight*self.tileHeight



     -- first, fill map with empty tiles
     for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            
            -- support for multiple sheets per tile; storing tiles as tables 
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    for y = self.mapHeight/2, self.mapHeight do
        for x = 1, 12 do

            self:setTile(x,y, TILE_BRICK)
        end

    end



    -- begin generating the terrain using vertical scan lines
    local x = 12
    while x < self.mapWidth - 10 do
        
        -- 5% chance to generate a cloud
        -- make sure we're 2 tiles from edge at least
        if x < self.mapWidth - 2 then
            if math.random(20) == 1 then
                
                -- choose a random vertical spot above where blocks/pipes generate
                local cloudStart = math.random(self.mapHeight / 2 - 6)

                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
            end
        end

        -- 5% chance to generate a mushroom
        if math.random(20) == 1 then
            -- left side of pipe
            self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_TOP)
            self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_BOTTOM)

            -- creates column of tiles going to bottom of map
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end

            -- next vertical scan line
            x = x + 1

        -- 10% chance to generate bush, being sure to generate away from edge
        elseif math.random(10) == 1 and x < self.mapWidth - 3 then
    

            -- place bush component and then column of bricks
            self:setTile(x, self.mapHeight / 2 - 1, BUSH_LEFT)
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1

            self:setTile(x, self.mapHeight / 2 - 1, BUSH_RIGHT)
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1

        -- 10% chance to not generate anything, creating a gap
        elseif math.random(10) ~= 1 then
            
            -- creates column of tiles going to bottom of map
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end

            -- chance to create a block for Mario to hit
            if math.random(15) == 1 then
                self:setTile(x, self.mapHeight / 2 - 4, JUMP_BLOCK)
            end

            -- next vertical scan line
            x = x + 1
        else
            -- increment X so we skip two scanlines, creating a 2-tile gap
            x = x + 2
        end
    end

    for x = self.mapWidth - 10, self.mapWidth do
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_BRICK)
        end
    end

    for x = self.mapWidth - 7, self.mapWidth - 2 do
        self:setTile(x, self.mapHeight / 2- 1, TILE_BRICK)
    end

    for x = self.mapWidth - 6, self.mapWidth - 2 do
        self:setTile(x, self.mapHeight /2 - 2, TILE_BRICK)
    end

    for x = self.mapWidth - 5, self.mapWidth - 2 do
        self:setTile(x, self.mapHeight /2 - 3, TILE_BRICK)
    end


    self.music:setLooping(true)
    self.music:setVolume(0.25)
    self.music:play()

end

function Map:tileAt(x,y)
    return self:getTile(math.floor(x/self.tileWidth) + 1, math.floor(y/self.tileHeight) + 1)
end

function Map:setTile(x,y,tile)
    self.tiles[(y-1)*self.mapWidth+x] = tile
end

function Map:getTile(x,y)
    return self.tiles[(y-1)*self.mapWidth+x]
end


function Map:update(dt)
    self.camX = math.max(0,
        math.min(self.player.x - VIRTUAL_WIDTH / 2,
            math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))

    self.player:update(dt)

    for i = 1,3 do
     self.enemies[i]:update(dt)
    end


end


function Map:render()
    for y = 1,self.mapHeight do
        for x = 1, self.mapWidth do
            love.graphics.draw(self.spritesheet, self.tileSprites[self:getTile(x,y)], (x-1)*self.tileWidth, (y-1)*self.tileHeight)
        end
    end

    
    
    self.player:render()

    for i = 1,3 do
        self.enemies[i]:render()
    end
end