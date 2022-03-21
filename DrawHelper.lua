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


local baycentricCoord = function(p,p1,p2,p3)
    local w1 = 0
    local w2 = 0
    local w3 = 0
    local x,y = p.x,p.y
    w2 = (x*(p1.y-p3.y) + y*(p3.x-p1.x) + (p1.x*p3.y - p3.x*p1.y))/( p2.x*(p1.y-p3.y) + p2.y*(p3.x-p1.x) + (p1.x*p3.y - p3.x*p1.y))
    w3 = (x*(p1.y-p2.y) + y*(p2.x-p1.x) + (p1.x*p2.y - p2.x*p1.y))/( p3.x*(p1.y-p2.y) + p3.y*(p2.x-p1.x) + (p1.x*p2.y - p2.x*p1.y))
    w1 = 1-w2-w3
    return w1,w2,w3
end

--get boundingbox of a triangle
local getBoundingBox = function(p1,p2,p3)
    local xMin = math.min(p1.x,p2.x,p3.x)
    local xMax = math.max(p1.x,p2.x,p3.x)
    local yMin = math.min(p1.y,p2.y,p3.y)
    local yMax = math.max(p1.y,p2.y,p3.y)
    return xMin,yMin,xMax-xMin,yMax-yMin
end

local lerp = function()

end

function DrawHelper.new(self, blockSize)
    local o = setmetatable({},Meta)
    o:SetDimension(screenW,screenH)
    o.BlockSize = blockSize
    o.Width = math.ceil(screenW/blockSize)
    o.Height = math.ceil(screenH/blockSize)
    
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
    PixelRate = PixelRate + 1
    -- x,y : left-up corner of the target block
    grid_x, grid_y = (grid_x - grid_x%1), (grid_y - grid_y % 1)
    local padding = 0--self.BlockSize*.2
    local wh = self.BlockSize - 2 * padding
    local x = (grid_x-1) * self.BlockSize+padding
    local y = (grid_y-1) * self.BlockSize+padding

    love.graphics.setColor(color[1],color[2],color[3],color[4] or 1)
    love.graphics.rectangle('fill',x,y,wh,wh)
end

--get color at x,y
function DrawHelper.GetPixel(self,x,y)
    return error("not implemented yet")
end

function DrawHelper.DrawLine(self,p1,p2,color)
    color = color or {1,1,1,1}
    if p1.x>p2.x then p1,p2 = p2,p1 end -- p2.x must bigger then p1.x
    local kx = (p2.y-p1.y)/(p2.x-p1.x)
    --print("drawLine kx= "..kx)
    for x=p1.x,p2.x do
            local xx = x--+p1.x
            local yy = p1.y+(xx-p1.x)*kx--p1.y+x*d.y
            --print("drawLine "..xx..','..yy)
            self:SetPixel(xx,yy,color)
    end

    if p1.y > p2.y then p1,p2 = p2,p1 end -- p2.y must be bigger then p1.y
    local ky = (p2.x-p1.x)/(p2.y-p1.y)
    --print("drawLine ky= "..ky)
    for y=p1.y,p2.y do
        local yy = y
        local xx = p1.x + (yy-p1.y)*ky
        --print("drawLine "..xx..','..yy)
        self:SetPixel(xx,yy,color)
end
end

function DrawHelper.DrawLine3D(p1,p2,color)

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

--[[
    data = {
        objVerts = {},
        normal = {VEC3(),...},
        uv = {VEC2(),...},
        verts = {num,...}
    }
]]
function DrawHelper.DrawTriangle_Interpolate(self,data,shaderFunc)
    local objVerts = data.objVerts
    local vIndice = data.verts
    local uvIndice = data.uvs
    local nIndice = data.uv
    local p1,p2,p3 = data[vIndice[1]],data[vIndice[2]],data[vIndice[3]]
    local bx,by,bw,bh = getBoundingBox(p1,p2,p3)
    
    for x=bx,bx+bw do
        for y=by,by+bh do
            if isInTriangle(VEC2(x,y),p1,p2,p3)then
                local w1,w2,w3 = baycentricCoord(p1,p2,p3,VEC2(x,y))
                self:SetPixel(x,y,shaderFunc({}))
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
    local p1,p2,p3 = VEC2(90,10), VEC2(150,10), VEC2(120,70)
    local bx,by,bw,bh = getBoundingBox(p1,p2,p3)
    local c1,c2,c3 = VEC3(1,0,0),VEC3(0,1,0),VEC3(0,0,1)

    for x=bx,bx+bw do
        for y=by,by+bh do
            if isInTriangle(VEC2(x,y),p1,p2,p3)then
                local w1,w2,w3 = baycentricCoord(VEC2(x,y),p1,p2,p3)
                local color = w1*c1 + w2*c2 + w3*c3
                self:SetPixel(x,y,color or {1,1,1,1})
            end
        end
    end
end

function DrawHelper.BeginDraw(self)
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
end

function DrawHelper.EndDraw(self)
    return love.graphics.setCanvas()
end

return DrawHelper