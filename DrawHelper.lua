--create canvas, define a grid
--draw everything in grid, dealing with Z-Depth, UV, NORMAL

local DrawHelper = {}
local Meta = {__index = DrawHelper}


-- test
local screenW, screenH = love.window.getMode()

--wrapper for vec2 cross
local cross = function(a,b)
    local r = (a.x*b.y - b.x*a.y)
    --print(r)
    return r>0
end

--input: all VEC2
local isInTriangle = function(p,p1,p2,p3)
    local a  ,b  ,c  = p1-p2, p2-p3, p3-p1
    local pp1,pp2,pp3= p-p1 , p-p2 , p-p3
    return cross(pp1,a) and cross(pp2,b) and cross(pp3,c)
end

--get boundingbox of a triangle
local getBoundingBox = function(p1,p2,p3)
    local xMin = math.min(p1.x,p2.x,p3.x)
    local xMax = math.max(p1.x,p2.x,p3.x)
    local yMin = math.min(p1.y,p2.y,p3.y)
    local yMax = math.max(p1.y,p2.y,p3.y)
    return xMin,yMin,xMax-xMin,yMax-yMin
end

function DrawHelper.new(self, blockSize)
    local o = setmetatable({},Meta)
    o:SetDimension(screenW/2,screenH/2)
    o.BlockSize = blockSize
    o.Width = math.ceil(screenW/blockSize/2)
    o.Height = math.ceil(screenW/blockSize/2)
    
    return o
end

function DrawHelper.SetDimension(self, width, height)
    if self.canvas then
        --copy from old canvas to new canvas
    else
        self.canvas = love.graphics.newCanvas(width,height)
        print("new canvas created")
    end
    return self.canvas
end

--set color at x,y
function DrawHelper.SetPixel(self, grid_x, grid_y,color)
    -- x,y : left-up corner of the target block
    local padding = self.BlockSize*.2
    local wh = self.BlockSize - 2 * padding
    local x = (grid_x-1) * self.BlockSize+padding
    local y = (grid_y-1) * self.BlockSize+padding

    
    love.graphics.setColor(color[1],color[2],color[3],color[4] or 1)
    love.graphics.rectangle('fill',x,y,wh,wh)
end

--get color at x,y
function DrawHelper.GetPixel(x,y)
    return error("not implemented yet")
end

function DrawHelper.DrawLine(p1,p2,width)
    return error("not implemented yet")
end
function DrawHelper.DrawPolygon(color,...)
    -- how to deal with UV NORMAL?
    -- local bound = CalcBoundingBox(...)
    -- for x = bound.x, bound.w do
    --     for y = bound.y, bound.h do
    --         if inPolygon(x,y,...) then
    --             self.SetPixel(color)
    --         end
    --     end
        
    -- end
    return error("not implemented yet")
end

function DrawHelper.DrawTriangle(self,p1,p2,p3,color)
    local bx,by,bw,bh = getBoundingBox(p1,p2,p3)


    for x=bx,bx+bw do
        for y=by,by+bh do
            if isInTriangle(VEC2(x,y),p1,p2,p3)then
                self:SetPixel(x,y,color or {1,1,1,1})
            end
        end
    end
end

function DrawHelper.DrawGrid(self)
    for ix=1,self.Width do
        love.graphics.line()
        for iy = 1, self.Height do
            love.graphics.line()
        end
        
    end
end

function DrawHelper._debugDraw(self)
    -- for x=1,self.Width do
    --     for y = 1,self.Height do
    --         --if x==y then
    --             local uv = VEC2(x/self.Width,y/self.Height)
    --             uv = uv*10
    --             local uvx = uv.x - math.floor(uv.x)
    --             local uvy = uv.y - math.floor(uv.y)
    --             self:SetPixel(x,y,{uvx,uvy,0})
    --         --end
    --     end
    -- end
    self:DrawTriangle(VEC2(10,10),VEC2(50,10),VEC2(10,50),{1,0,0,1})
end

function DrawHelper.BeginDraw(self)
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
end

function DrawHelper.EndDraw(self)
    return love.graphics.setCanvas()
end

return DrawHelper