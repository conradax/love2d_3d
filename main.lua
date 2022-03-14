require("helper")
local OBJ = require("/lib/OBJ-Loader.OBJ")

OH = require("objHelper")

function MTX_MVP(model2world,cameraInfo)
    local mtx_model2world = model2world--MTX_Model2World(VEC3(0,0,10),VEC3(0,0,0))
    local mtx_world2view = MTX_World2View(CAMERA)
    local mtx_view2Clip = MTX_View2Clip(cameraInfo)

    local mvp =  mtx_view2Clip * mtx_world2view * mtx_model2world

    return mvp
end

function Init()
    ScreenW, ScreenH = love.window.getMode()
    Clip2Screen = MTX_Clip2Screen(ScreenW,ScreenH)
    CAMERA = {
        position = VEC3(0,0,-8),
        rotation = VEC3(0,0,0),
        type = 'persp',--'ortho',
        near = 60,
        far = 170,
        aspect = ScreenW/ScreenH, --near plane's width / height
        fovY = PI/4
    }
end


function love.load()
    Init()

    local modelPath = "KANADE.OBJ"--"testCube.obj" 
    TestCube = OBJ.loadObj(modelPath)
    MODEL = OH:loadOBJ(modelPath)
    MODEL:SetRotation(VEC3(0,0,0))

    -- local p=P(VEC3(0,1,0))
    -- --error(DeepPrint(p))
    -- p = MTX_Model2World(VEC3(0,0,0),VEC3(0,0,0))*p
    -- --error(DeepPrint(p))
    -- p = MTX_World2View(CAMERA) * p
    -- p = MTX_View2Clip(CAMERA) * p
    -- p = HomogeneousDivision(p)
    -- p = MTX_Clip2Screen(ScreenW,ScreenH) * p
    -- error(DeepPrint(p))
end

function love.update(dt)
end

function love.draw()
    



    love.graphics.setColor(1,1,1,1)
    PrintDebugText()

    local dt = love.timer.getDelta()
    MODEL:SetRotation(MODEL.Rotation+VEC3(PI * dt /9,PI * dt /9,PI * dt /9))

    local mtx_MVP = MTX_MVP(MODEL.Matrix_Model2World,CAMERA)
    DrawAxis(mtx_MVP)
    --MODEL.Matrix_Model2World * MTX_World2View(CAMERA.position,CAMERA.rotation) * MTX_View2Clip(CAMERA)
    local faces = MODEL:getFaces()
    --print("#faces = "..#faces)
    for k,face in ipairs(faces) do
        love.graphics.setColor(1,1,1,1)
        print("draw face "..k)
        DrawFace(face,mtx_MVP)

        --line
        -- love.graphics.setColor(.2,.2,.2,1)
        -- DrawLine(face[1],face[2],mtx_MVP)
        -- DrawLine(face[2],face[3],mtx_MVP)
        -- DrawLine(face[3],face[4],mtx_MVP)
        -- DrawLine(face[4],face[1],mtx_MVP)
    end
end

function MTX_face(face,mtx)
    local mtx_clip2Screen = MTX_Clip2Screen(ScreenW,ScreenH)
    local ret = {}
    for k,vert in ipairs(face) do
        local v = P(vert[1],vert[2],vert[3])
        --local v_clip = HomogeneousDivision( MTX_MVP(CAMERA) * v)
        local v_clip = HomogeneousDivision( mtx * v)
        -- TODO: clipping
        v_clip = mtx_clip2Screen * v_clip
        --error(DeepPrint(v_clip))
        ret[k] = {v_clip[1][1],v_clip[2][1]}
    end
    return ret
end

local f = .03
-- { scancode = function }
-- https://love2d.org/wiki/Scancode
local _keys = {
    a = function() end,
    d = function() end,
    w = function() end,
    s = function() end,
    p = function() end,
    right=function() MODEL:SetRotation(MODEL.Rotation + VEC3(0,-PI*f,0)) end,
    left = function() MODEL:SetRotation(MODEL.Rotation + VEC3(0,PI*f,0)) end,
    up = function() MODEL:SetRotation(MODEL.Rotation + VEC3(PI*f,0,0)) end,
    down = function() MODEL:SetRotation(MODEL.Rotation + VEC3(-PI*f,0,0)) end
}
function love.keypressed(key, scancode)
    local fn = _keys[scancode]
    if  type(fn) == "function" then
        fn()
    end

end

function FlatTable(...)
    local ret = {}
    local index = 1
    for k,v in pairs(...) do
        for kk,vv in pairs(v) do
            for kkk,vvv in pairs(vv) do
                ret[index] = vvv
            index = index + 1
            end
            
        end
    end

    return ret
end

function FlatTable2(...)
    local ret = {}
    local index = 1
    for k,v in pairs(...) do
        for kk,vv in pairs(v) do
            ret[index] = vv
            index = index + 1
        end
    end

    return ret
end

function PrintDebugText()
    local debug_text = string.format(
    [[FPS: %d
    Camera Info: %s]],
        1/love.timer.getDelta(),
        DeepPrint(CAMERA,'|  '))
    
        love.graphics.print(debug_text)
end

--return: 
--  float: smallest Z,
--  table: vertices , need flat
function DrawFace(model_space_face,mvp)
    -- local verts = {}
    -- print("==drawFace: vert count: "..#model_space_face)
    -- for k,vertex in ipairs(model_space_face) do
    --     verts[k] = Model2Screen(vertex,mvp)
    -- end
    -- verts = FlatTable2(verts)
    -- love.graphics.polygon("line",verts)
    
    local verts,smallZ = CalcFace(model_space_face,mvp)
    print("smallZ = "..smallZ)
    print("verts:\n"..DeepPrint(verts))
    love.graphics.polygon('line',verts)
end

function CalcFace(model_space_face,mvp)
    local verts = {}
    local smallestZ = 999
    local tempZ = 999
    for k,vertex in ipairs(model_space_face) do
        verts[k],tempZ = Model2Screen(vertex,mvp)
        if tempZ < smallestZ then smallestZ = tempZ end
    end
    verts = FlatTable2(verts)
    --love.graphics.polygon("fill",verts)
    return verts,smallestZ
end


--convert Model Space Coord to Screen Space
--return: table(x,y), z
function Model2Screen(vert,mvp)
    --print("====Model2Screen")
    --print(type(vert))
    --print(DeepPrint(vert))
    --print(DeepPrint(mvp))

    local p = P(vert)
    local clip_space_p = Clip2Screen * HomogeneousDivision(mvp*p) --TODO: clipping
    return {clip_space_p[1][1], clip_space_p[2][1]},clip_space_p[3][1]

    -- local p = P(vert)
    -- p = MTX_Model2World(VEC3(0,0,0),VEC3(0,0,0))*p
    -- --error(DeepPrint(p))
    -- p = MTX_World2View(CAMERA) * p
    -- p = MTX_View2Clip(CAMERA) * p
    -- p = HomogeneousDivision(p)
    -- p = MTX_Clip2Screen(ScreenW,ScreenH) * p
    -- print(string.format("x,y,z = %.3f, %.3f, %.3f",vert[1],vert[2],vert[3]))
    -- print(string.format("x,y = %.3f, %.3f",p[1][1],p[2][1]))
    -- return {p[1][1],p[2][1]}
end

--model space
function DrawLine(p1,p2,mvp)
    p1 = Model2Screen(p1,mvp)
    p2 = Model2Screen(p2,mvp)
    love.graphics.line(p1[1],p1[2],p2[1],p2[2])
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