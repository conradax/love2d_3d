local function mix(weights,values)
    local ret = 0
    for index,weight in ipairs(weights) do
        ret = ret + weight*values[index]
    end
    return ret
end

local function mix_x(weights,values)
    local ret = 0
    for index,weight in ipairs(weights) do
        ret = ret + weight*values[index].x
    end
    return ret
end
local function mix_y(weights,values)
    local ret = 0
    for index,weight in ipairs(weights) do
        ret = ret + weight*values[index].y
    end
    return ret
end
local function mix_z(weights,values)
    local ret = 0
    for index,weight in ipairs(weights) do
        ret = ret + weight*values[index].z
    end
    return ret
end

local function mix_vec3(weights,values)
    local ret = VEC3(0,0,0)
    for index,weight in ipairs(weights) do
        local v = values[index]
        ret = ret + weight*VEC3(v.x,v.y,v.z)
    end
    return ret
end
local function mix_uv(weights,values)
    local ret = VEC2(0,0)
    for index,weight in ipairs(weights) do
        local v = values[index]
        ret = ret + weight*VEC2(v.u,v.v)
    end
    return ret
end
local light = VEC3(0,0,0)
local timer = 0
local radius = 100
return function(x,y,param)
    --error(DeepPrint(param))
    local uv = param.uv
    local normals = param.normals
    local weights = param.weights
    local vertices = param.vertices -- model space
    local tex = param.objData.texture
    local ndc = mix(param.weights,param.ndc)
    ndc = (ndc+1)/2

    local dt = love.timer.getDelta()
    timer = timer + dt*0.00001
    local xx = SIN(timer)*radius
    local zz = COS(timer)*radius
    light = VEC3(xx,30,zz)
    --error(DeepPrint(light))
    local lightDir = light-mix_vec3(weights,vertices)
    local normal = mix_vec3(weights,normals)
    lightDir = lightDir:normalize()
    normal = normal:normalize()
    local l = normal:dot(lightDir) --lightDir:dot(normal)
    l = math.max(l,.4)--ambient

    local v = mix_vec3(weights,vertices)
    uv = mix_uv(weights,uv)/MODELSCALE
    uv.y = 1-uv.y
    local w,h = tex:getDimensions()
    if uv.x>1 or uv.y >1 or uv.x<0 or uv.y<0 then
        return {1,1,1,1}
    else
        local r,g,b,a = tex:getPixel(uv.x*w, uv.y*h)
        return {r*l,g*l,b*l,a}
    end
end