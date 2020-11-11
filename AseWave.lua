local pp = {151,160,137,91,90,15,
131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180};



-- To remove the need for index wrapping, double the permutation table length

for i=1,#pp do
    pp[i-1] = pp[i]
    pp[i] = nil
end

local p = {}

for i=0,255 do
    p[i] = pp[i]
    p[i+256] = pp[i]
end

local function band(a, b) --Bitwise and
    local p, c = 1, 0
    while a > 0 and b > 0 do
        local ra, rb = a % 2, b % 2
        if ra + rb > 1 then
            c = c + p
        end
        a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
    end
    return c
end

local function fade(t)
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
end

function lerp(a, b, x)
    return a + x * (b - a);
end

local repeatTileX = 0
local repeatTileY = 0
local repeatTileZ = 0

function incX(num)
    num = num +1
    if (repeatTileX > 0) then
        num = num % repeatTileX
    end
    return num
end

function incY(num)
    num = num +1
    if (repeatTileY > 0) then
        num = num % repeatTileY
    end
    return num
end

function incZ(num)
    num = num +1
    if (repeatTileZ > 0) then
        num = num % repeatTileZ
    end
    return num
end

local function Dot3D(tbl, x, y, z)
    return tbl[1]*x + tbl[2]*y + tbl[3]*z
end

local Gradients3D = {{1,1,0},{-1,1,0},{1,-1,0},{-1,-1,0},
{1,0,1},{-1,0,1},{1,0,-1},{-1,0,-1},
{0,1,1},{0,-1,1},{0,1,-1},{0,-1,-1}};

function grad(hash, x, y, z)
    hash = (math.floor(hash) % 12) + 1
    -- print(hash)
    return Dot3D(Gradients3D[hash], x, y, z)
end

function Perlin3d(x, y, z)
-- repeat
    if (repeatTileX > 0) then
        x = x % repeatTileX
    end
    if (repeatTileY > 0) then
        y = y % repeatTileY
    end
    if (repeatTileZ > 0) then
        z = z % repeatTileZ
    end
--
    xi = band(math.floor(x), 0xff)
    yi = band(math.floor(y), 0xff)
    zi = band(math.floor(z), 0xff)

    xf = x - math.floor(x)
    yf = y - math.floor(y)
    zf = z - math.floor(z)

    u = fade(xf)
    v = fade(yf)
    w = fade(zf)

   aaa = p[p[p[    xi ] +      yi ]+    zi ];
   aba = p[p[p[    xi ] + incY(yi)]+    zi ];
   aab = p[p[p[    xi ] +      yi ]+incZ(zi)];
   abb = p[p[p[    xi ] + incY(yi)]+incZ(zi)];
   baa = p[p[p[incX(xi)]+      yi ]+    zi ];
   bba = p[p[p[incX(xi)]+ incY(yi)]+    zi ];
   bab = p[p[p[incX(xi)]+      yi ]+incZ(zi)];
   bbb = p[p[p[incX(xi)]+ incY(yi)]+incZ(zi)];

   x1 = lerp(grad(aaa, xf  , yf  , zf),
             grad(baa, xf-1, yf  , zf), u);
   x2 = lerp(grad(aba, xf  , yf-1, zf),
             grad (bba, xf-1, yf-1, zf),
             u);

   y1 = lerp(x1, x2, v);

   x1 = lerp(grad (aab, xf  , yf  , zf-1),
             grad (bab, xf-1, yf  , zf-1),
             u);

   x2 = lerp(grad (abb, xf  , yf-1, zf-1),
             grad (bbb, xf-1, yf-1, zf-1),
             u);

   y2 = lerp(x1, x2, v);

   return lerp (y1, y2, w);

end

-- this function uses torus mapping in 3d space to create seamless texture
-- in one dimension only
-- TODO: implement Perlin4D noise to have both direction
function tilingTexture(nx, ny, scale_height, scale_width, seed)
    twoPi = 2.0 * math.pi

    angle_x = twoPi * nx
    -- angle_y = twoPi * ny

    return Perlin3d((1+ math.cos(angle_x)) / twoPi * scale_height,
                    (1 + math.sin(angle_x)) / twoPi * scale_height,
                    ny * scale_width)

    --return Perlin4D(math.cos(angle_x) / twoPi,
    --                math.sin(angle_x) / twoPi,
    --                math.cos(angle_y) / twoPi,
    --                math.sin(angle_y) / twoPi)
end

-- return simplex
--
function gen(
        scale_width,
        scale_height,
        seed,
        time,
        steps
    )
    twoPi = 2 * math.pi

    height = app.activeImage.height
    width = app.activeImage.width

    -- Begin rendering, iterate over pixels --
    for y = 0, height do
        for x = 0, width do
            -- pcol, float: Contextualized perlin noise value
            -- pcol = simplex.Noise2D((y / height * scale) + seed, (x / width * scale) + seed) * 128 + 128
            --
          --pcol = tilingTexture((y/height) * scale_height + seed,
          --    (x/width) * scale_width + seed)

           pcol = Perlin3d((y/height) * scale_height + seed,
                            (x/width) * scale_width + seed,
                            time + seed)

           -- pcol = tilingTexture((y/height), (x/width), scale_width, scale_height, seed)

            -- -1 .. 1 to 0 .. 255
            pcol = (pcol * 0.5 + 0.5) * 255
           
            -- clamp value to (0, 255)
            if pcol > 255 then
                -- pcol = 255
            end

            if pcol < 0 then
                -- pcol = 0
            end
            -- fcolor, Color: Final color value to use for pixel
            fcolor = {}
            fcolor = app.pixelColor.rgba(pcol, pcol, pcol)

            if bumpgen then
                -- Place black/white perline noise map (bumpmap)
                app.activeLayer:cel(app.activeFrame.frameNumber).image:drawPixel(x, y, fcolor)
            else
                --Place the pixel
                app.activeImage:drawPixel(x, y, fcolor)
            end
            app.activeImage:drawPixel(x, y, fcolor)
        end
    end
    -- End rendering --
    -- End rendering function and return nothing --
    return
end

--
-- https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/procedural-patterns-noise-part-1/simple-pattern-examples
-- dlg, Dialog: Main dialog object
local dlg = {}
-- cStopDlg, Dialog: Color stop dialog object
local cStopDlg = nil

-- TODO
-- Context aware modular dialog refreshment
function refreshDLG()
end

-- Creates main dialog object, used to initialize and refresh dialog
function createDLG(
        scale_width,
        scale_height,
        seed,
        steps,
        tile
    )
    -- NOTE: Initializing Dialog with string gives the window a title
    dlg = Dialog("Noise")
    -- If given bounding box, set bounding coordinates for dlg
    if bounding then
        dlg.bounds = bounding
    end
    dlg:entry {id = "scale_width", label = "Scale Width:", text = scale or "1.0"}
    dlg:entry {id = "scale_height", label = "Scale Height:", text = scale or "1.0"}
    dlg:entry {id = "seed", label = "Seed:", text = seed or "0.0"}

    dlg:check {
        id = "repeatHeight",
        label = "Repeat Height: ",
        text  = "Yes",
        selected = false or repeatHeight
    }

    dlg:check {
        id = "repeatWidth",
        label = "Repeat Width: ",
        text  = "Yes",
        selected = false or repeatWidth
    }

    dlg:check {
        id = "repeatTime",
        label = "Repeat in time: ",
        text  = "Yes",
        selected = false or repeatTime
    }

    dlg:label {
        text = "number of 'Frames' must be divisible by 'Time step' value"
    }

    -- dlg:check {
    --     id = "randomseed",
    --     label = "Random Seed: ",
    --     text = "Yes",
    --     selected = false or randomseed
    -- }

    dlg:entry {id = "time_step", label = "Time step:", text = scale or "0.2"}

    dlg:slider {
        id = "frames",
        label = "Frames: ",
        min = 1,
        max = 128,
        value = frames or 1
    }

    dlg:slider {
        id = "steps",
        label = "Steps:",
        min = 1,
        max = 16,
        value = steps or 4
    }

    dlg:newrow()

    -- Clicking button

    dlg:button {
        id = "ok",
        text = "Generate",
        onclick = function()
            -- Short hand, save a decimal and three characters for the duration of the function
            local data = dlg.data

            scale_width = tonumber(data.scale_width)
            scale_height = tonumber(data.scale_height)
            seed = tonumber(data.seed)

            repeatTileX = 0
            repeatTileY = 0
            repeatTileZ = 0

            time_step = tonumber(data.time_step)

            if data.repeatWidth then
                repeatTileY = scale_width
            end
            if data.repeatHeight then
                repeatTileX = scale_height
            end
            if data.repeatTime then
                repeatTileZ = tonumber(data.frames) * time_step
            end

            steps = data.steps

            -- Generation of images
            gen(scale_width, scale_height, seed, 0 * time_step, steps)
            for i=2, tonumber(data.frames) do
                app.activeSprite:newFrame()
                gen(scale_width, scale_height, seed, (i-1) * time_step, steps)
            end
            -- Hard refreshes canvas to update, revisit on API updates
            app.refresh()

        end
    }
    dlg:button {id = "cancel", text = "Cancel"}
    -- Info button, pop up contains version information and link to repository/readme
    dlg:button {
        id = "info",
        text = "Info",
        onclick = function()
            if not infoDlg then
                infoDlg = Dialog("Info")
            else
                infoDlg:close()
                infoDlg = Dialog("Info")
            end
            infoDlg:entry{id="repo", label="Repository:", text="https://github.com/Ondra09/lawaves"}
            infoDlg:label{id="version", label="Version:", text=version}
            infoDlg:show{wait=false}
        end
    }
end
-- Create main dialog and show it
createDLG()
dlg:show {wait = false}
