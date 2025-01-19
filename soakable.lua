--soakable parts go here
local soakable = {
    --models.modelname.modelpart,
    models.Avatar
}

local GSAnimBlend --GSAnimBlend compatiblity
for _, key in ipairs(listFiles(nil, true)) do
    if key:find("GSAnimBlend$") then
        GSAnimBlend = require(key)
        break
    end
end

local anims = animations:getAnimations() --Animations, set all to LOOP
local wet
local dry
local cold
local hot
for _, v in pairs(anims) do
    if v:getName():find("wet") then
        wet = v
        if GSAnimBlend then v:setBlendTime(3) end
    end
    if v:getName():find("dryOff") then
        dry = v
        if GSAnimBlend then v:setBlendTime(3) end
    end
    if v:getName():find("cold") then
        cold = v
        if GSAnimBlend then v:setBlendTime(3) end
    end
    if v:getName():find("hot") then
        hot = v
        if GSAnimBlend then v:setBlendTime(3) end
    end
end

local d = {} --Tracks the dampness of each part

local drySpeed = 0.005 --Speed at which parts dry
for i = 1, #soakable, 1 do --Populates the damp table based on the amount of parts in the soakable table
    table.insert(d, i, 1)
end
table.insert(d, #d + 1, 1) --Inserts base dampness to the table

local notify = false --Debugging
local debug = false --Debugging
local keybind = keybinds:newKeybind("Hud Info", "key.keyboard.grave.accent")
function keybind.press(modifier)
    if modifier == 0 then
        notify = not notify
    elseif modifier == 1 then
        debug = not debug
    end
end

function events.TICK()
    local soaking = false --Check for if player is soaking in water, rain, etc
    local totalDamp = 0 --Total dampness based of visible parts
    local maxDamp = #soakable + 1 --Max dampness based of visible parts
    local totalTemp = 0 --Total temperature
    local maxTemp = 59  --Max temperature
    local biomeTemp = world.getBiome(player:getPos()):getTemperature() --Biome temperature
    local light =  world.getLightLevel(player:getPos()) + world.getBlockLightLevel(player:getPos()) --Light temperature
    local timeTemp = math.sin((0.2617996 * (world.getDayTime()/1000)))* 12 --Time of day temperature

    for i = 1, #soakable, 1 do
        local soakablePos = soakable[i]:partToWorldMatrix():apply() --Soakable part's position as vector

        if soakable[i]:getVisible() then --Checks if the part is visible and if not clears it's dampness so the player isn't infinitely dripping water
            local min, max = world.getBuildHeight()
            local block = world.getBlocks(soakablePos, soakablePos)[1] --Gets block that the part is in

            if soakablePos.y < max and soakablePos.y > min then --Check if part is within world height so the model doesn't break
                if block.id == "minecraft:water" or block.id == "minecraft:water_cauldron" or block.properties.waterlogged == "true" or player:isInRain() then --Checks if the block that part is in is either water or waterlogged and if the player is in rain
                    d[i] = d[i] - 0.01 --Soaks part when in water
                    soaking = true --Checks soaking
                else
                    d[i] = d[i] + drySpeed --Drys part when out of water
                end
            else
                d[i] = d[i] + drySpeed --Drys part if out of world limits
            end
            --Clamps part dampness
            if d[i] <= 0 then d[i] = 0 end
            if d[i] >= 1 then d[i] = 1 end

            totalDamp = totalDamp + d[i] --Adds part dampness to the total dampness
        else --if not visible...
            d[i] = 1  --Resets part's dampness
            maxDamp = maxDamp - 1 --Removes part from the max dampness if not
        end

        soakable[i]:setColor(math.clamp(d[i], 0.4, 1), math.clamp(d[i], 0.4, 1), math.clamp(d[i], 0.4, 1)) --Darkens parts based of indiviual dampness
        --soakable[i]:setOpacity(1 - d[i]/2) --Optionally make parts that have translucent rendertypes fade in opacity when damp
    end

    if soaking then --Base dampness, if no parts in the get wet but the player enters water  amount added to the total damp so that the dripping particles play
        d[#d] = d[#d] - 0.01
    else
        d[#d] = d[#d] + drySpeed
    end
    --Clamps base dampness
    if d[#d] <= 0 then d[#d] = 0 end 
    if d[#d] >= 1 then d[#d] = 1 end 

    totalDamp = (totalDamp + d[#d]) --Adds base dampness to the total dampness

    if player:isOnFire() then --Add heat if on fire
        totalTemp = totalTemp + 5
    end
    --Adds and removes heat base of hot and cold blocks respectively
    local blocks = world.getBlocks( player:getPos() - vec(1, 1, 1), player:getPos() + vec(1, 1, 1))
    for _, v in pairs(blocks) do
        if v.id == "minecraft:ice" or v.id == "minecraft:packed_ice" or v.id == "minecraft:blue_ice" or v.id == "minecraft:frosted_ice" or v.id == "minecraft:snow_block" or v.id == "minecraft:powdwer_snow" then
            totalTemp = totalTemp - 1
        end
    end

    if player:getPos().y >= 81 then --Decreases biome temperature when at higher altitudes to match with ingame logic
        totalTemp = totalTemp + light + totalDamp + (timeTemp * (biomeTemp - (0.00125 * (player:getPos().y - 81))))
    else
        totalTemp = totalTemp + light + totalDamp + (timeTemp * biomeTemp)
    end

    maxTemp = maxTemp + maxDamp

    drySpeed = math.clamp(0.005 * ((((totalTemp*(totalDamp + 0.005)) + 0.005))/maxTemp),0.005,maxDamp)

    if totalDamp < maxDamp and not player:isInWater() then --Dynamically drips water when damp
        particles:newParticle("falling_dripstone_water", player:getPos().x + math.random() - 0.7, player:getPos().y + math.random(), player:getPos().z + math.random() - 0.7, math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)):setScale((1 - totalDamp / maxDamp))
    end

    local coldTemp = maxTemp * 0.1 --Temperature where it is cold enough to play cold animation
    local hotTemp = maxTemp * 0.55 --Temperature where it is hot enough to play hot animation
    --Plays animations based of specific conditions
    if wet ~= nil then 
        wet:setPlaying(totalDamp < maxDamp * 0.5 and not player:isUnderwater())
    end
    if dry ~= nil then
        dry:setPlaying(totalDamp >= maxDamp * 0.5 and totalDamp ~= maxDamp and not soaking)
    end
    if not player:isInWater()then
        if cold ~= nil then
            cold:setPlaying(totalTemp <= coldTemp and player:getPose() == "STANDING" and player:getVelocity().xz:length() < .01 )
        end
        if hot ~= nil then
            hot:setPlaying(totalTemp >= hotTemp and player:getPose() == "STANDING" and player:getVelocity().xz:length() < .01 )
        end
    end

    local damp = "Dry"
    local temp = "Normal"

    if totalTemp < maxTemp * 0.5 and totalTemp > maxTemp * 0.3 then
        temp = "§rNormal"
    elseif totalTemp < maxTemp * 0.1 then
        temp = "§bFreezing"
    elseif totalTemp < maxTemp * 0.2 then
        temp = "§3Cold"
    elseif totalTemp < maxTemp * 0.3 then
        temp = "§1Chilly"
    elseif totalTemp > maxTemp * 0.9 then
        temp = "§4Blazing"
    elseif totalTemp > maxTemp * 0.7 then
        temp = "§cHot"
    elseif totalTemp > maxTemp * 0.5 then
        temp = "§6Warm"
    end

    if totalDamp == maxDamp then
        damp = "§rDry"
    elseif totalDamp < maxDamp * 0.1 then
        damp = "§1Drenched"
    elseif totalDamp < maxDamp * 0.2 then
        damp = "§9Soaked"
    elseif totalDamp < maxDamp * 0.4 then
        damp = "§3Soggy"
    elseif totalDamp < maxDamp * 0.6 then
        damp = "§bDamp"
    elseif totalDamp < maxDamp * 0.8 then
        damp = "§bMoist"
    end

    if notify then
        host:setActionbar("You are " .. temp .. "§r 🌡 and " .. damp .. "§r 💧") --Notifier for dampness and temperature
    end

    if debug then --Shows useful data when debug enabled
        host:setActionbar( "§lDEBUG §r|Dampness: §b" .. totalDamp .. "/§3" .. maxDamp .. "💧 §r|Tempature: §7" .. totalTemp .. "/§c" .. maxTemp .. "🌡 §r|Temp Marks: §b" .. coldTemp .. "🥶/§4" .. hotTemp .. "🥵 §r|Light Temp: §e" .. light .. "💡 §r|Biome Temp: §2" .. biomeTemp ..  "🏞 §r|Drying Speed: §7" .. drySpeed .. "💨 §r|Time Temp: §d" .. timeTemp .. "⏰")
    end
end
