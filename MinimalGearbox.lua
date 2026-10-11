-- MinimalGearbox by Thomas Brauer
--
-- Segment layout (G1 and G2 split the middle bar):
--          ___A___
--         |\  |  /|
--         F H I J B
--         |  \|/  |
--         G1 --- G2
--         |  /|\  |
--         E M L K C
--         |/__|__\|
--            D

-- Car gears use -1 for reverse and 0 for neutral.
local GEAR_SEGMENTS = {
    [-1] = { A = true, B = true, E = true, F = true, G1 = true, G2 = true, K = true },
    [0] = { B = true, C = true, E = true, F = true, H = true, K = true },
    [1] = { B = true, C = true },
    [2] = { A = true, B = true, D = true, E = true, G1 = true, G2 = true },
    [3] = { A = true, B = true, C = true, D = true, G1 = true, G2 = true },
    [4] = { B = true, C = true, F = true, G1 = true, G2 = true },
    [5] = { A = true, C = true, D = true, F = true, G1 = true, G2 = true },
    [6] = { A = true, C = true, D = true, E = true, F = true, G1 = true, G2 = true },
    [7] = { A = true, B = true, C = true },
    [8] = { A = true, B = true, C = true, D = true, E = true, F = true, G1 = true, G2 = true },
    [9] = { A = true, B = true, C = true, D = true, F = true, G1 = true, G2 = true },
}

local COLORS = {
    red = rgbm(1, 0, 0, 1),
    blue = rgbm(0.2, 0.45, 1, 1),
    purple = rgbm(1, 0, 1, 1),
    yellow = rgbm(1, 1, 0, 1),
    cyan = rgbm(0, 1, 1, 1),
    white = rgbm(1, 1, 1, 1),
    green = rgbm(0, 1, 0, 1),
}
local COLOR_ORDER = { 'red', 'blue', 'purple', 'yellow', 'cyan', 'white', 'green' }
local DEFAULT_COLOR_NAME = 'white'

-- Light the shift dot at about 93% of the rev limiter.
local SHIFT_RPM_FRACTION = 13 / 14

-- Keep the storage key stable so existing colour choices survive updates.
local colorSetting = ac.storage('color', DEFAULT_COLOR_NAME)

local function getDisplayColor()
    return COLORS[colorSetting:get()] or COLORS[DEFAULT_COLOR_NAME]
end

local function drawPolygon(vertices, color)
    ui.pathClear()
    for _, vertex in ipairs(vertices) do
        ui.pathLineTo(vertex)
    end
    ui.pathFillConvex(color)
end

-- Pointed hexagons form the LED segments.
local function drawHorizontalSegment(startX, endX, y, thickness, color)
    local halfThickness = thickness / 2
    drawPolygon({
        vec2(startX, y),
        vec2(startX + halfThickness, y - halfThickness),
        vec2(endX - halfThickness, y - halfThickness),
        vec2(endX, y),
        vec2(endX - halfThickness, y + halfThickness),
        vec2(startX + halfThickness, y + halfThickness),
    }, color)
end

local function drawVerticalSegment(x, startY, endY, thickness, color)
    local halfThickness = thickness / 2
    drawPolygon({
        vec2(x, startY),
        vec2(x + halfThickness, startY + halfThickness),
        vec2(x + halfThickness, endY - halfThickness),
        vec2(x, endY),
        vec2(x - halfThickness, endY - halfThickness),
        vec2(x - halfThickness, startY + halfThickness),
    }, color)
end

local function drawDiagonalSegment(startX, startY, endX, endY, thickness, color)
    local dx, dy = endX - startX, endY - startY
    local length = math.sqrt(dx * dx + dy * dy)
    local halfThickness = thickness / 2

    -- Offset along and across the centreline to form the pointed ends.
    local alongX = dx / length * halfThickness
    local alongY = dy / length * halfThickness
    local acrossX, acrossY = -alongY, alongX

    drawPolygon({
        vec2(startX, startY),
        vec2(startX + alongX + acrossX, startY + alongY + acrossY),
        vec2(endX - alongX + acrossX, endY - alongY + acrossY),
        vec2(endX, endY),
        vec2(endX - alongX - acrossX, endY - alongY - acrossY),
        vec2(startX + alongX - acrossX, startY + alongY - acrossY),
    }, color)
end

local function drawGearDisplay(segments, windowSize, color, showShiftLight)
    -- Fit within both window dimensions to preserve the digit's proportions.
    local aspectRatio = 1.7
    local digitWidth = math.min(windowSize.x * 0.6, windowSize.y * 0.85 / aspectRatio)
    local digitHeight = digitWidth * aspectRatio
    local thickness = digitWidth * 0.2

    local centerX, centerY = windowSize.x / 2, windowSize.y / 2
    local leftX = centerX - digitWidth / 2
    local rightX = centerX + digitWidth / 2
    local topY = centerY - digitHeight / 2
    local bottomY = centerY + digitHeight / 2

    -- Leave a small gap between segment tips.
    local gap = thickness * 0.1

    if segments.A then
        drawHorizontalSegment(leftX + gap, rightX - gap, topY, thickness, color)
    end
    if segments.D then
        drawHorizontalSegment(leftX + gap, rightX - gap, bottomY, thickness, color)
    end
    if segments.G1 then
        drawHorizontalSegment(leftX + gap, centerX - gap, centerY, thickness, color)
    end
    if segments.G2 then
        drawHorizontalSegment(centerX + gap, rightX - gap, centerY, thickness, color)
    end

    if segments.F then
        drawVerticalSegment(leftX, topY + gap, centerY - gap, thickness, color)
    end
    if segments.B then
        drawVerticalSegment(rightX, topY + gap, centerY - gap, thickness, color)
    end
    if segments.E then
        drawVerticalSegment(leftX, centerY + gap, bottomY - gap, thickness, color)
    end
    if segments.C then
        drawVerticalSegment(rightX, centerY + gap, bottomY - gap, thickness, color)
    end

    if segments.I then
        drawVerticalSegment(centerX, topY + gap, centerY - gap, thickness, color)
    end
    if segments.L then
        drawVerticalSegment(centerX, centerY + gap, bottomY - gap, thickness, color)
    end

    -- Inset diagonals so they meet the straight segments cleanly.
    local cornerInset = thickness * 0.5
    local centerInset = thickness * 0.3
    if segments.H then
        drawDiagonalSegment(
            leftX + cornerInset, topY + cornerInset,
            centerX - centerInset, centerY - centerInset,
            thickness, color
        )
    end
    if segments.J then
        drawDiagonalSegment(
            rightX - cornerInset, topY + cornerInset,
            centerX + centerInset, centerY - centerInset,
            thickness, color
        )
    end
    if segments.K then
        drawDiagonalSegment(
            centerX + centerInset, centerY + centerInset,
            rightX - cornerInset, bottomY - cornerInset,
            thickness, color
        )
    end
    if segments.M then
        drawDiagonalSegment(
            leftX + cornerInset, bottomY - cornerInset,
            centerX - centerInset, centerY + centerInset,
            thickness, color
        )
    end

    -- Keep the shift dot inside the window, beside the lower right corner.
    if showShiftLight then
        local radius = thickness * 0.5
        local shiftLightX = math.min(rightX + thickness * 3, windowSize.x - radius - 2)
        ui.drawCircleFilled(vec2(shiftLightX, bottomY), radius, color)
    end
end

-- Main-window callback registered in manifest.ini.
function gearMain()
    local car = ac.getCar(0)
    if not car then
        return
    end

    local segments = GEAR_SEGMENTS[car.gear]
    if not segments then
        return
    end

    local showShiftLight = car.rpmLimiter > 0
        and car.rpm >= car.rpmLimiter * SHIFT_RPM_FRACTION
    drawGearDisplay(segments, ui.windowSize(), getDisplayColor(), showShiftLight)
end

-- Settings-window callback registered in manifest.ini.
function gearSettings()
    ui.text('Color')
    ui.newLine(2)

    local selectedColorName = colorSetting:get()
    local swatchSize = vec2(28, 28)
    for index, colorName in ipairs(COLOR_ORDER) do
        local position = ui.getCursor()
        ui.drawRectFilled(position, position + swatchSize, COLORS[colorName])
        if selectedColorName == colorName then
            local padding = vec2(2, 2)
            ui.drawRect(position - padding, position + swatchSize + padding, COLORS.white)
        end
        if ui.invisibleButton('color_' .. colorName, swatchSize) then
            colorSetting:set(colorName)
        end
        if index < #COLOR_ORDER then
            ui.sameLine()
        end
    end
end
