--https://github.com/Luke100000/luaVectors/
VEC2 = require('/lib/lua-vector/vec2')
VEC3 = require('/lib/lua-vector/vec3')
VEC4 = require('/lib/lua-vector/vec4')

-- API list: http://lua-users.org/wiki/LuaMatrix
MTX = require("/lib/lua-matrix/lua/matrix")

COS = math.cos
SIN = math.sin
TAN = math.tan
PI = math.pi


function MtxRotx(rx)
    return MTX{
        {1,0,0,0},
        {0,COS(rx),SIN(rx),0},
        {0,-SIN(rx),COS(rx),0},
        {0,0,0,1}
    }
end
function MtxRoty(ry)
    return MTX{
        {COS(ry),0,-SIN(ry),0},
        {0,1,0,0},
        {SIN(ry),0,COS(ry),0},
        {0,0,0,1}
    }
end
function MtxRotz(rz)
    return MTX{
        {COS(rz),SIN(rz),0,0},
        {-SIN(rz),COS(rz),0,0},
        {0,0,1,0},
        {0,0,0,1}
    }
end

-- matrices generating functions

function MTX_Model2World(pos,rot)

    local rx = MTX({
        {1,0,0,0},
        {0,COS(rot[1]),SIN(rot[1]),0},
        {0,-SIN(rot[1]),COS(rot[1]),0},
        {0,0,0,1}
    })
    local ry = MTX({
        {COS(rot[2]),0,-SIN(rot[2]),0},
        {0,1,0,0},
        {SIN(rot[2]),0,COS(rot[2]),0},
        {0,0,0,1}
    })
    local rz = MTX({
        {COS(rot[3]),SIN(rot[3]),0,0},
        {-SIN(rot[3]),COS(rot[3]),0,0},
        {0,0,1,0},
        {0,0,0,1}
    })
    local t = MTX{
        {1,0,0,pos[1]},
        {0,1,0,pos[2]},
        {0,0,1,pos[3]},
        {0,0,0,1}
    }
    return t*rx*ry*rz
end

function MTX_World2View(cameraInfo)
    local rot = cameraInfo.rotation
    local pos = cameraInfo.position
    local rx = MTX({
        {1,0,0,0},
        {0,COS(rot[1]),SIN(rot[1]),0},
        {0,-SIN(rot[1]),COS(rot[1]),0},
        {0,0,0,1}
    }):transpose()

    local ry = MTX({
        {COS(rot[2]),0,-SIN(rot[2]),0},
        {0,1,0,0},
        {SIN(rot[2]),0,COS(rot[2]),0},
        {0,0,0,1}
    }):transpose()

    local rz = MTX({
        {COS(rot[3]),SIN(rot[3]),0,0},
        {-SIN(rot[3]),COS(rot[3]),0,0},
        {0,0,1,0},
        {0,0,0,1}
    }):transpose()

    local t = MTX{
        {1,0,0,-pos[1]},
        {0,1,0,-pos[2]},
        {0,0,1,-pos[3]},
        {0,0,0,1}
    }
    
    return rx*ry*rz*t
end

function MTX_View2Clip(cameraInfo)
    local ortho = cameraInfo.type == 'ortho'
    local n = cameraInfo.near
    local f = cameraInfo.far
    local aspect = cameraInfo.aspect
    local fovY = cameraInfo.fovY

    --a bit calculating
    local nearTop = SIN(fovY/2)*n
    local nearBottom = -nearTop --assuming the camera is symmetric
    local nearRight = nearTop * aspect
    local nearLeft = -nearRight

    --local farTop = SIN(fov/2)*f
    --local farBottom = -farTop
    --local farRight = farTop * aspect
    --local farLeft = -farRight

    --ortho projection matrix
    local mtx_orthoPrj = MTX{
        {1,0,0,-(nearRight+nearLeft)/2},
        {0,1,0,-(nearTop+nearBottom)/2},
        {0,0,1,-(n+f)/2},
        {0,0,0,1}
    }
    local mtx_scale = MTX{
        {2/(nearRight-nearLeft),0,0,0},
        {0,2/(nearTop-nearBottom),0,0},
        {0,0,2/(f-n),0},
        {0,0,0,1}
    }

    --check if perspective
    if not ortho then
        local mtx_pers2ortho = MTX{
            {n,0,0,0},
            {0,n,0,0},
            {0,0,n+f,-n*f},
            {0,0,1,0}
        }
        mtx_orthoPrj = mtx_orthoPrj * mtx_pers2ortho
    end

    return mtx_scale * mtx_orthoPrj
end

function MTX_Clip2Screen(screenW,screenH)
--y axis is flipped, because LOVE2D's Y axis is top(0) to bottom(1)
    return MTX{
        {screenW/2,0,0,screenW/2},
        {0,-screenH/2,0,screenH/2},
        {0,0,1,0},
        {0,0,0,1}
    }
end

function HomogeneousDivision(p)
    assert(#p==4,"not a homogeneous coord")
    local ret = MTX{
        {p[1][1]/p[4][1]},
        {p[2][1]/p[4][1]},
        {p[3][1]/p[4][1]},
        {1},--{p[4][1]/p[4][1]}
    }
    if p[4][1] == 0 then error(DeepPrint(p)) end
    --error(DeepPrint(ret))
    return ret
end

-- 1x4 matrix (homogeneous coord)
function P(x,y,z)
    if type(x) == 'table' then
        return MTX{{x[1]},{x[2]},{x[3]},{1}}
    else
        return MTX{{x},{y},{z},{1}}
    end
end

function DeepPrint (e, indent)
    local ret = '\n'
    indent = indent or ''
    --print(indent.."==========start")
    -- if e is a table, we should iterate over its elements
        for k,v in pairs(e) do -- for every element in the table
            if type(v) == "table" then
              ret = ret..indent .. 'table:'..k..'\n'..DeepPrint(v,indent..'  ')
              --print(indent .. 'table:' .. k)
              --DeepPrint(v, indent..'  ')       -- recursively repeat the same procedure
            else -- if not, we can just print it
              --print(indent .. k ..': '.. v)
              ret = ret ..indent..k ..': '.. tostring(v)..'\n'
            end
        end
        --print(indent.."==========end")
    return ret
end

