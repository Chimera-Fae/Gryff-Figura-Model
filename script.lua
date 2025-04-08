config:setName("Gryff Config") -- Config setup

-- PREDEFINE ASSETS
require("Jumpstart")             -- Jumpstart by JimmyHelp
require("GSAnimBlend")           -- GSanimBlend by @
local squapi = require("SquAPI") -- SquAPI
local anims = require("EZAnims") -- EZAnims by JimmyHelp
local model = anims:addBBModel(animations.Avatar)

anims:setOneJump(true)

animations.Avatar.jumpingup:setBlendTime(1, 3)

-- HIDE VANILLA
vanilla_model.ALL:setVisible(false)
vanilla_model.RIGHT_ITEM:setVisible(true)
nameplate.ENTITY:setVisible(false)

local accessories = {
    { -- Hat
        models.Avatar.root.Bode.Hed.Fez:setPrimaryTexture("PRIMARY"),
        models.Avatar.root.Bode.Hed.HairBow:setPrimaryTexture("PRIMARY"),
    },
    { -- Eye
        models.Avatar.root.Bode.Hed.Goggles:setPrimaryTexture("PRIMARY"),
    },
    { -- Mouth
        models.Avatar.root.Bode.Hed.Nuzzle.Letter:setPrimaryTexture("PRIMARY"),
    },
    { -- Neck
        models.Avatar.root.Bode.Bowtie:setPrimaryTexture("PRIMARY"),
        models.Avatar.root.Bode.Collar:setPrimaryTexture("PRIMARY"),
        models.Avatar.root.Bode.Scarf:setPrimaryTexture("PRIMARY"),
    },
    { -- Back
        models.Avatar.root.Bode.Bag:setPrimaryTexture("PRIMARY"),
        models.Avatar.root.Bode.ScrollBag:setPrimaryTexture("PRIMARY"),
    },
}

local slotNames = {
    "hat",
    "eye",
    "mouth",
    "neck",
    "back",
}

local tints = {
    { ["color"] = { 1, 1, 1 },         ["wool"] = "minecraft:white_wool" },       -- White
    { ["color"] = { 0.95, 0.7, 0.2 },  ["wool"] = "minecraft:orange_wool" },      -- Orange
    { ["color"] = { 0.8, 0.3, 0.85 },  ["wool"] = "minecraft:magenta_wool" },     -- Magenta
    { ["color"] = { 0.4, 0.6, 0.85 },  ["wool"] = "minecraft:light_blue_wool" },  -- Light Blue
    { ["color"] = { 0.9, 0.9, 0.2 },   ["wool"] = "minecraft:yellow_wool" },      -- Yellow
    { ["color"] = { 0.5, 0.8, 0.25 },  ["wool"] = "minecraft:lime_wool" },        -- Lime
    { ["color"] = { 0.95, 0.5, 0.65 }, ["wool"] = "minecraft:pink_wool" },        -- Pink
    { ["color"] = { 0.2, 0.2, 0.2 },   ["wool"] = "minecraft:gray_wool" },        -- Gray
    { ["color"] = { 0.6, 0.6, 0.6 },   ["wool"] = "minecraft:light_gray_wool" },  -- Light Gray
    { ["color"] = { 0.2, 0.4, 0.8 },   ["wool"] = "minecraft:cyan_wool" },        -- Cyan
    { ["color"] = { 0.4, 0.3, 0.7 },   ["wool"] = "minecraft:purple_wool" },      -- Purple
    { ["color"] = { 0.2, 0.35, 0.5 },  ["wool"] = "minecraft:blue_wool" },        -- Blue
    { ["color"] = { 0.4, 0.25, 0.15 }, ["wool"] = "minecraft:brown_wool" },       -- Brown
    { ["color"] = { 0.3, 0.5, 0.2 },   ["wool"] = "minecraft:green_wool" },       -- Green
    { ["color"] = { 0.6, 0.2, 0.2 },   ["wool"] = "minecraft:red_wool" },         -- Red
    { ["color"] = { 0, 0, 0 },         ["wool"] = "minecraft:black_wool" },       -- Black
}

-- ACTIONS
local mainPage = action_wheel:newPage()

action_wheel:setPage(mainPage)

local coats = {}
local coatNames = {}
local coat = config:load("coat") or 1

local function capitalizeFirstLetter(str)
    return (str:gsub("^%l", string.upper))
end

for _, v in ipairs(textures:getTextures()) do
    if v:getName():find("gryff_") then
        table.insert(coats, v)

        local coatName = v:getName():gsub("Avatar%.gryff_", "")
        coatName = capitalizeFirstLetter(coatName)
        table.insert(coatNames, coatName)
    end
end

local coatScroll = mainPage:newAction()
    :item("minecraft:white_wool")

function pings.coat(dir)
    if dir == 1 and coat < #coats then
        coat = coat + dir
    end
    if dir == -1 and coat > 1 then
        coat = coat + dir
    end

    coatScroll:title("[Coat: " ..
    coatNames[coat] .. "]\nScroll to change between " .. #coats .. " coats.")

    models.Avatar:setPrimaryTexture("CUSTOM", coats[coat])
    config:save("coat", coat)
end

coatScroll:setOnScroll(pings.coat)

-- Scaling
local scale = config:load("scale") or 1

local scaleScroll = mainPage:newAction()
    :item("minecraft:piston")

function pings.scale(dir)
    if dir == 1 and scale < 1.3 then
        scale = scale + 0.05
    elseif dir == -1 and scale > 0.6 then
        scale = scale - 0.05
    end

    models.Avatar:setScale(scale)
    if scale < 1 then
        models.Avatar.root.Bode.Hed:setScale(2 - scale)
    else
        models.Avatar.root.Bode.Hed:setScale()
    end
    if scale < 0.8 then
        scaleScroll:title("[Scale | Baby]\nScroll to change size\nLeft click to reset")
    elseif scale < 1 then
        scaleScroll:title("[Scale | Runt]\nScroll to change size\nLeft click to reset")
    elseif scale < 1.2 then
        scaleScroll:title("[Scale | Average]\nScroll to change size\nLeft click to reset")
    elseif scale > 1.2 then
        scaleScroll:title("[Scale | Alpha]\nScroll to change size\nLeft click to reset")
    end

    config:save("scale", scale)
end

function pings.scaleReset()
    scale = 1
    pings.scale()
end

scaleScroll:onScroll(pings.scale):onLeftClick(pings.scaleReset)

local shiftKey = keybinds:newKeybind("shift", "key.keyboard.left.shift")
local ctrlKey = keybinds:newKeybind("shift", "key.keyboard.left.control")

local accSlot = {}

-- Accessories
for i, slot in ipairs(accessories) do
    local slotName = slotNames[i]
    
    -- Initialize accessory slot settings
    accSlot[i] = {
        Name = slotName,
        Item = config:load(slotName .. "Item") or 0,
        Color = config:load(slotName .. "Color") or 1,
        AccentColor = config:load(slotName .. "AccentColor") or 1, -- Separate accent color
        Accent = config:load(slotName .. "Accent") or true,
        Action = mainPage:newAction():setToggled(config:load(slotName .. "Accent") or true),
    }

    -- Update accessories based on current selection
    local function updateAccessories()
        for index, accessory in ipairs(slot) do
            if accessory then -- Ensure accessory is not nil
                local isSelected = (index == accSlot[i].Item)
                accessory:setVisible(isSelected)
                
                if isSelected then
                    
                    for _, child in pairs(accessory:getChildren() or {}) do
                        if string.find(child:getName(), "Base$") then -- Set color for the accessory
                            child:setColor(table.unpack(tints[accSlot[i].Color]["color"]))
                        elseif string.find(child:getName(), "Accent$") then -- Set color for the accent
                            child:setVisible(accSlot[i].Accent)
                            if accSlot[i].Accent then
                                child:setColor(table.unpack(tints[accSlot[i].AccentColor]["color"]))
                            end
                        end
                    end

                    accSlot[i].Name = accessory:getName() or "Unknown"
                end
            end
        end

        -- Update action title and save settings
        accSlot[i].Action:title(
            slotName:sub(1, 1):upper() .. slotName:sub(2) .. " | " .. (accSlot[i].Item == 0 and "None" or accSlot[i].Name) ..
            "\nScroll to change accessory" ..
            "\nHold Shift to change accessory color" ..
            "\nHold Ctrl to change accent color"
        )
        accSlot[i].Action:item(tints[accSlot[i].Color]["wool"])
        config:save(slotName .. "Item", accSlot[i].Item)
        config:save(slotName .. "Color", accSlot[i].Color)
        config:save(slotName .. "AccentColor", accSlot[i].AccentColor)
    end

    -- Scroll handler for accessories
    local function accessoryScroll(dir)
        if shiftKey:isPressed() then
            -- Cycle accessory color
            accSlot[i].Color = (accSlot[i].Color + dir - 1) % #tints + 1
        elseif ctrlKey:isPressed() then
            -- Cycle accent color
            accSlot[i].AccentColor = (accSlot[i].AccentColor + dir - 1) % #tints + 1
        else
            -- Cycle accessories
            accSlot[i].Item = math.max(0, math.min(accSlot[i].Item + dir, #slot))
        end
        updateAccessories()
    end

    -- Toggle accent visibility
    local function toggleAccent(state)
        accSlot[i].Accent = state
        config:save(slotName .. "Accent", state)
        updateAccessories()
    end

    -- Configure the action
    accSlot[i].Action
        :setOnScroll(accessoryScroll)
        :onToggle(toggleAccent)
    
    -- Initialize the accessory state
    updateAccessories()
end


-- SquAPI Physics
squapi.smoothHead:new(
    {
        models.Avatar.root.Bode.Hed,
    },
    nil,
    nil,
    nil,
    false
)

squapi.bounceWalk:new(
    models,
    0.5
)

squapi.randimation:new(
    animations.Avatar.nosetwitch,
    nil,
    false
)

function events.RENDER(delta, context)
    if world.getLightLevel(player:getPos()) < 5 then
        models.Avatar.root.Bode.Hed:setSecondaryTexture("CUSTOM", textures["Avatar.eyes"])
    else
        models.Avatar.root.Bode.Hed:setSecondaryTexture(nil)
    end
    renderer:setCameraPivot(models.Avatar.root.Bode.Hed.CameraPivot:partToWorldMatrix():apply())
    models.Avatar.root.Bode.Hed:setVisible(context ~= "OTHER")
end

function events.ENTITY_INIT()
    pings.coat()
    pings.scale()
end
