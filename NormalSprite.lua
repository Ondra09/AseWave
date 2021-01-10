-- NormalSprite is a Plugin for Aseprite editor v1.2+
-- Version: 1.0
-- Author: https://github.com/Ondra09
----------------------------------------------------------------------

if app.apiVersion < 1 then
   return app.alert("This script requires Aseprite v1.2.10-beta3")
end

local cel = app.activeCel
if not cel then
   return app.alert("There is no active image")
end

local range = app.range

if range.type == RangeType.EMPTY
   or not range.type == RangeType.CELS then
   return app.alert("Cels must be selected")
end


sobel_smooth = {1, 2, 1}
sobel_smooth_denom = 1.0/4.0
sobel_smooth_shift = 0
sobel_edge = {1, 0, -1}
sobel_edge_flip = {-1, 0, 1}
sobel_edge_denom = 1.0/2.0
sobel_edge_shift = 128 -- (255 * 0.5)

-- sobel_horizontal_x = {1, 0, -1}
-- sobel_horizontal_x_denom = 1.0/2.0
-- sobel_horizontal_y = {1, 2, 1}
-- sobel_horizontal_y_denom = 1.0/4.0

width = cel.image.width
height = cel.image.height


function convolution(img_dst, img_src, assignFun, readFun, filter, filter_denom, filter_shift, isHorizontal)
   local rgba = app.pixelColor.rgba

   hor = 0

   if isHorizontal then
      hor = 1
   end

   for i=0, width-1 do
      for j=0, height-1 do
         local sum = 0.0

         for k=1,#filter do
            x = math.fmod(i - (k-2) * hor + width, width)
            y = math.fmod(j - (k-2) * (1-hor) + height, height)

            color = Color(img_src:getPixel(x, y))

            color_part = readFun(color)
            sum = sum + math.floor(color_part * filter[k] * filter_denom + filter_shift)
         end

         dstColor = Color(img_dst:getPixel(i, j))

         dstColor = assignFun(dstColor, sum)

         img_dst:drawPixel(i, j,
                           dstColor)
      end
   end
end

function imageToNormal(value)
   return (value / 255.0) * 2.0 - 1.0
end


function normalToImage(value)
   return math.floor((value + 1.0) * 0.5 * 255)
end


function normalizeImage(img)
   for i=0, width - 1 do
      for j=0, height - 1 do
         color = Color(img:getPixel(i,j))

         r = imageToNormal(color.red)
         g = imageToNormal(color.green)
         b = math.sqrt(1 - (r*r + g*g))

         b = normalToImage(b)

         img:drawPixel(i, j, Color(color.red, color.green, b))
      end
   end
end

function processCel(cel)
   if cel == nil then
      return app.alert("Cel is nil")
   end
   local finalImg = cel.image:clone()
   -- local img = createZeroArray(width, height)
   -- local img_buf = createZeroArray(width, height)

   local img = cel.image:clone()
   local img_buf = cel.image:clone()

   local position = cel.position

   if img.colorMode == ColorMode.RGB then
      local rgba = app.pixelColor.rgba
      local rgbaA = app.pixelColor.rgbaA

      --
      set_red = function(color, sum) return Color(sum, 0, 0, 255) end
      get_red = function(color) return color.red end
      convolution(img_buf, cel.image, set_red, get_red, sobel_smooth, sobel_smooth_denom, sobel_smooth_shift, false)
      convolution(img, img_buf, set_red, get_red, sobel_edge, sobel_edge_denom, sobel_edge_shift, true)

      set_green = function(color, sum) return Color(color.red, sum, color.blue, 255) end
      get_green = function(color) return color.green end

      convolution(img_buf, cel.image, set_green, get_green, sobel_smooth, sobel_smooth_denom, sobel_smooth_shift, true)
      convolution(img, img_buf, set_green, get_green, sobel_edge_flip, sobel_edge_denom, sobel_edge_shift, false)

      normalizeImage(img)

   elseif img.colorMode == ColorMode.GRAY then
      return app.alert("This script is only for RGB Color Mode")
   elseif img.colorMode == ColorMode.INDEXED then
      return app.alert("This script is only for RGB Color Mode")
   end
   return img
end

local cels = app.range.cels
local sprite = app.activeSprite
local currentLayer = app.activeLayer
local newLayerName = currentLayer.name .. "_NormalGenerated"
local newLayer = nil
for i,layer in ipairs(sprite.layers) do
   if layer.name == newLayerName then
      -- the layer to write normal on already exists
      newLayer = layer
   end
end

if newLayer == nil then
   newLayer = sprite:newLayer()
   newLayer.name = newLayerName
end

for i=1, #cels do
   sprite:newCel(newLayer, i, processCel(cels[i]))
end

app.refresh()
