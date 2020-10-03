LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    local keygenerate=true
    local keyid=math.random(#KEYS)
    local lockid=LOCKS[keyid]
    local locked=false
    particles=true

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do 
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end
        --starting with ground
        if x==1 then
            tileID = TILE_ID_GROUND
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y==7 and topper or nil, tileset, topperset))
            end

        -- chance to just be emptiness
        elseif
             math.random(10) == 1 then
                tileID = TILE_ID_EMPTY
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            --spawing lock

            lock=GameObject{
                        texture='keys_and_locks',
                        x=(width-10)*TILE_SIZE,
                        y =(4- 1) * TILE_SIZE,
                        width=16,
                        height=16,
                        frame=lockid,
                        solid = true,
                        collidable=false,
                        onConsume=function(player,object)
                                        gSounds['pickup']:play()
                                        score = score + 500
                                        particles=false                 --removing particles
                                        local flag= GameObject {                    --spawning flag
                                                        x=(width-3)*TILE_SIZE,
                                                        y=(7-1)*TILE_SIZE-4,
                                                        width=12,
                                                        height=16,
                                                        texture='flags',
                                                        frame=11,
                                                        consumable=true,
                                                        solid=false,
                                                        collidable=false,
                                                        onConsume=function(player,object)
                                                                 gSounds['pickup']:play()
                                                                 renderkey=false
                                                                 gStateMachine:change('play')
                                                                 level=level+1
                                                                end
                                                    }
                                                    

                                            Timer.tween(2,{
                                                [flag]={y=3*TILE_SIZE}
                                            })
                                            table.insert(objects,flag)
                                    end,
                            onCollide=function(player,object)
                                    gSounds['empty-block']:play()
                                    end
             }
            table.insert(objects,lock)  


           
              --chance to spawn a key
            if math.random(5)==1 and keygenerate and x>=50 and x<=70  then
                table.insert(objects,
                    GameObject{
                        texture='keys_and_locks',
                        x=(x-1)*TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width=16,
                        height=16,
                        frame=keyid,
                        consumable = true,
                        solid = false,
                        collidable=true,
                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            renderkey=true
                                            score=score + 100
                                            lock.solid=false
                                            lock.consumable=true 
                                            lock.collidable=true  
                                     end
                    }
                )
                keygenerate=false
            end           

            --pole object
            table.insert(objects,
                GameObject{
                    x=(width-3)*TILE_SIZE,
                    y=(4-1)*TILE_SIZE,
                    width=12,
                    height=48,
                    texture='poles',
                    frame=1,
                    solid=false,
                    consumable=false,
                    collidable=true,
                    onCollide=function(player,object)
                                     gSounds['pickup']:play()            
                             end

                })

            -- chance to spawn a block
            if math.random(10) == 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            score = score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end

function LevelMaker:update(dt)
    psystem:update(dt)
end

function LevelMaker:renderParticles(width)
    love.graphics.draw(psystem,(width-10)*TILE_SIZE+ 8, (4-1)* TILE_SIZE + 8)
end

