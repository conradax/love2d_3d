require("MTXhelper")

OH = require("OBJHelper")
Draw = require("DrawHelper")
local fragShader = require("fragShader")

PixelRate = 0
MODELSCALE = 10

function MTX_MVP(model2world,cameraInfo)
    local mtx_model2world = model2world--MTX_Model2World(VEC3(0,0,10),VEC3(0,0,0))
    local mtx_world2view = MTX_World2View(cameraInfo)
    local mtx_view2Clip = MTX_View2Clip(cameraInfo)

    local mvp =  mtx_view2Clip * mtx_world2view * mtx_model2world

    return mvp
end

function Init(screenW, screenH)
    --ScreenW, ScreenH = love.window.getMode()
    Clip2Screen = MTX_Clip2Screen(screenW,screenH)
    CAMERA = {
        position = VEC3(0,0,-50),
        rotation = VEC3(0,0,0),
        type = 'persp',--'ortho',
        near = 40,
        far = 170,
        aspect = screenW/screenH, --near plane's width / height
        fovY = PI/16
    }
end


function love.load()
    -- must be a triangulated mesh
    local modelPath = "kanade2.obj" --"testplane.obj"
    MODEL = OH:loadOBJ(modelPath,{scale=MODELSCALE})--i dont know why, but the scale also applied to uv coord, which needs a counter division

    MODEL.OBJData.texture = love.image.newImageData("kanade_tex.png")--hacking for texture

    CANVAS = Draw:new(1)
    Init(CANVAS.Width, CANVAS.Height)
end

function love.update(dt)
    PixelRate = 0
    HandleInput(dt*10)

    MODEL:SetRotation(MODEL.Rotation+VEC3(0,PI * dt /9,0))
    local mvp = MTX_MVP(MODEL.Matrix_Model2World,CAMERA)

    CANVAS:BeginDraw()
    CANVAS:_debugDraw()
    local objData = MODEL.OBJData
    for _,face in ipairs(objData.faces) do
        CANVAS:DrawTriangle_Interpolate(mvp,face,objData,fragShader)
    end
    CANVAS:EndDraw()

end

function love.draw()
    

    --draw canvas out
    local canvas = CANVAS.canvas
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(canvas,0,0)--ScreenW/4,ScreenH/4)
    
    --love.graphics.rectangle('line',ScreenW/4,ScreenH/4,ScreenW/2,ScreenH/2)
    --old drawing code using LOVE's graphics api
        -- local dt = love.timer.getDelta()
        -- local mtx_MVP = MTX_MVP(MODEL.Matrix_Model2World,CAMERA)
        -- DrawAxis(mtx_MVP)

        -- local faces = MODEL:getFaces()
        -- love.graphics.setColor(1,1,1,1)
        -- for k,face in ipairs(faces) do
        --     DrawFace(face,mtx_MVP)
        -- end
    ------------------------

    PrintDebugText()
end

-- { scancode = function }
-- https://love2d.org/wiki/Scancode
local _keys = {
    a = function(dt) CAMERA.position = CAMERA.position + VEC3(-1,0,0)*dt end,
    d = function(dt) CAMERA.position = CAMERA.position + VEC3(1,0,0)*dt end,
    w = function(dt) CAMERA.position = CAMERA.position + VEC3(0,0,1)*dt end,
    s = function(dt) CAMERA.position = CAMERA.position + VEC3(0,0,-1)*dt end,
    --p = function(dt) end,
    right=function(dt) MODEL:SetRotation(MODEL.Rotation + VEC3(0,-PI*dt,0)) end,
    left = function(dt) MODEL:SetRotation(MODEL.Rotation + VEC3(0,PI*dt,0)) end,
    up = function(dt) MODEL:SetRotation(MODEL.Rotation + VEC3(PI*dt,0,0)) end,
    down = function(dt) MODEL:SetRotation(MODEL.Rotation + VEC3(-PI*dt,0,0)) end
}
function HandleInput(dt)
    for key,fn in pairs(_keys) do
        if  love.keyboard.isScancodeDown(key) then
            fn(dt)
        end
    end
end
function love.keyreleased(key)
    if 'p' == key then
        if 'persp' == CAMERA.type then
            CAMERA.type = 'ortho'
        else
            CAMERA.type = 'persp'
        end
    end
end

function FlatTable2(...)
    local ret = {}
    local index = 1
    for k,v in ipairs(...) do
        for kk,vv in ipairs(v) do
            ret[index] = vv
            index = index + 1
        end
    end
    return ret
end

function PrintDebugText()
    local debug_text = string.format(
        "FPS: %d\nCamera Info:\n%s\nPixelRate: %d\nFace count:%d",
        1/love.timer.getDelta(),
        DeepPrint(CAMERA,'|  '),
        PixelRate,
        #MODEL.OBJData.faces)

        love.graphics.print(debug_text)
end

function DrawFace(model_space_face,mvp)
    
    local verts,smallZ = CalcFace(model_space_face,mvp)
    --verts = FlatTable2(love.math.triangulate(verts))
    if verts ~= nil then
        love.graphics.polygon('line',verts)
    end
end

-- returns nil if any vertex clipped
function CalcFace(model_space_face,mvp)
    local verts = {}
    local ndc_coords = {}
    for k,vertex in ipairs(model_space_face) do
        verts[k],ndc_coords[k] = Model2Screen(vertex,mvp)
        if verts[k] == nil then return end --vertex clipped
    end
    return verts,ndc_coords
end


--convert Model Space Coord to Screen Space
--return: (screenX, screenY, depth), (ndc_coord)
function Model2Screen(vert,mvp)
    local clip_space_p = HomogeneousDivision(mvp * P(vert.x,vert.y,vert.z))
    if clip_space_p ~= nil then
        if clip_space_p[3][1] <-1.01 or clip_space_p[3][1]>1.01 then --clipping
            --print("vertex clipped\n"..DeepPrint(clip_space_p))
            return
        end
    end
    --clip_space_p = Clip2Screen * clip_space_p --screen space
    local screen_space_p = Clip2Screen * clip_space_p
    return VEC3(screen_space_p[1][1], screen_space_p[2][1],screen_space_p[3][1]),VEC3(clip_space_p[1][1], clip_space_p[2][1],clip_space_p[3][1])
end

--model space
function DrawLine(p1,p2,mvp)
    p1 = Model2Screen(p1,mvp)
    p2 = Model2Screen(p2,mvp)
    if (p1 ~= nil) and (p2 ~= nil) then
        love.graphics.line(p1[1],p1[2],p2[1],p2[2])
    end
end

function DrawAxis(mvp)
    --x
    -- love.graphics.setColor(1,0,0,1)
    -- DrawLine(VEC3(-1,0,0),VEC3(1,0,0),mvp)
    -- DrawLine(VEC3(1,0,0),VEC3(.9,0,.1),mvp)
    -- DrawLine(VEC3(1,0,0),VEC3(.9,0,-.1),mvp)
    local x1 = Model2Screen(VEC3(-1,0,0),mvp)
    local x2 = Model2Screen(VEC3(1,0,0),mvp)
    
    if (x1 ~= nil) and (x2 ~= nil) then
        x1 = VEC2(x1[1],x1[2])
        x2 = VEC2(x2[1],x2[2])
        CANVAS:DrawLine(x1,x2,{1,0,0,1})
    end
    
    --y
    -- love.graphics.setColor(0,1,0,1)
    -- DrawLine(VEC3(0,-1,0),VEC3(0,1,0),mvp)
    -- DrawLine(VEC3(0,1,0),VEC3(.1,.9,0),mvp)
    -- DrawLine(VEC3(0,1,0),VEC3(-.1,.9,0),mvp)
    --z
    -- love.graphics.setColor(0,0,1,1)
    -- DrawLine(VEC3(0,0,-1),VEC3(0,0,1),mvp)
    -- DrawLine(VEC3(0,0,1),VEC3(.1,0,.9),mvp)
    -- DrawLine(VEC3(0,0,1),VEC3(-.1,0,.9),mvp)
end