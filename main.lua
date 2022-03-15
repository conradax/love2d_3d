require("MTXhelper")

OH = require("OBJHelper")

function MTX_MVP(model2world,cameraInfo)
    local mtx_model2world = model2world--MTX_Model2World(VEC3(0,0,10),VEC3(0,0,0))
    local mtx_world2view = MTX_World2View(cameraInfo)
    local mtx_view2Clip = MTX_View2Clip(cameraInfo)

    local mvp =  mtx_view2Clip * mtx_world2view * mtx_model2world

    return mvp
end

function Init()
    ScreenW, ScreenH = love.window.getMode()
    Clip2Screen = MTX_Clip2Screen(ScreenW,ScreenH)
    CAMERA = {
        position = VEC3(0,0,-50),
        rotation = VEC3(0,0,0),
        type = 'persp',--'ortho',
        near = 20,
        far = 170,
        aspect = ScreenW/ScreenH, --near plane's width / height
        fovY = PI/4
    }
end


function love.load()
    Init()

    local modelPath = "testCube.obj"--"KANADE.OBJ"-- 
    MODEL = OH:loadOBJ(modelPath)
end

function love.update(dt)
    HandleInput(dt*10)
end

function love.draw()
    love.graphics.setColor(1,1,1,1)
    PrintDebugText()

    local dt = love.timer.getDelta()
    MODEL:SetRotation(MODEL.Rotation+VEC3(PI * dt /9,PI * dt /9,PI * dt /9))
    local mtx_MVP = MTX_MVP(MODEL.Matrix_Model2World,CAMERA)
    DrawAxis(mtx_MVP)

    local faces = MODEL:getFaces()
    love.graphics.setColor(1,1,1,1)
    for k,face in ipairs(faces) do
        DrawFace(face,mtx_MVP)
    end
end

local f = .03
-- { scancode = function }
-- https://love2d.org/wiki/Scancode
local _keys = {
    a = function(dt) CAMERA.position = CAMERA.position + VEC3(-1,0,0)*dt end,
    d = function(dt) CAMERA.position = CAMERA.position + VEC3(1,0,1)*dt end,
    w = function(dt) CAMERA.position = CAMERA.position + VEC3(0,0,1)*dt end,
    s = function(dt) CAMERA.position = CAMERA.position + VEC3(0,0,-1)*dt end,
    p = function(dt) end,
    right=function(dt) MODEL:SetRotation(MODEL.Rotation + VEC3(0,-PI*f,0)) end,
    left = function(dt) MODEL:SetRotation(MODEL.Rotation + VEC3(0,PI*f,0)) end,
    up = function(dt) MODEL:SetRotation(MODEL.Rotation + VEC3(PI*f,0,0)) end,
    down = function(dt) MODEL:SetRotation(MODEL.Rotation + VEC3(-PI*f,0,0)) end
}
function HandleInput(dt)
    for key,fn in pairs(_keys) do
        if  love.keyboard.isScancodeDown(key) then
            fn(dt)
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
        "FPS: %d\nCamera Info:\n%s",
        1/love.timer.getDelta(),
        DeepPrint(CAMERA,'|  '))

        love.graphics.print(debug_text)
end

function DrawFace(model_space_face,mvp)
    
    local verts,smallZ = CalcFace(model_space_face,mvp)
    --verts = FlatTable2(love.math.triangulate(verts))
    if verts ~= nil then
        love.graphics.polygon('line',verts)
    end
end

function CalcFace(model_space_face,mvp)
    local verts = {}
    local smallestZ = 999
    local tempZ = 999
    for k,vertex in ipairs(model_space_face) do
        verts[k],tempZ = Model2Screen(vertex,mvp)
        if verts[k] == nil then return end --vertex clipped
        if tempZ < smallestZ then smallestZ = tempZ end
    end
    verts = FlatTable2(verts)
    --love.graphics.polygon("fill",verts)
    return verts,smallestZ
end


--convert Model Space Coord to Screen Space
--return: table(x,y), z
function Model2Screen(vert,mvp)
    local clip_space_p = HomogeneousDivision(mvp * P(vert))
    if clip_space_p ~= nil then
        if clip_space_p[3][1] <-1.01 or clip_space_p[3][1]>1.01 then --clipping
            print("vertex clipped\n"..DeepPrint(clip_space_p))
            return
        end 
    end
    clip_space_p = Clip2Screen * clip_space_p --screen space
    return {clip_space_p[1][1], clip_space_p[2][1]},clip_space_p[3][1]
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
    love.graphics.setColor(1,0,0,1)
    DrawLine(VEC3(-1,0,0),VEC3(1,0,0),mvp)
    DrawLine(VEC3(1,0,0),VEC3(.9,0,.1),mvp)
    DrawLine(VEC3(1,0,0),VEC3(.9,0,-.1),mvp)
    --y
    love.graphics.setColor(0,1,0,1)
    DrawLine(VEC3(0,-1,0),VEC3(0,1,0),mvp)
    DrawLine(VEC3(0,1,0),VEC3(.1,.9,0),mvp)
    DrawLine(VEC3(0,1,0),VEC3(-.1,.9,0),mvp)
    --z
    love.graphics.setColor(0,0,1,1)
    DrawLine(VEC3(0,0,-1),VEC3(0,0,1),mvp)
    DrawLine(VEC3(0,0,1),VEC3(.1,0,.9),mvp)
    DrawLine(VEC3(0,0,1),VEC3(-.1,0,.9),mvp)
end