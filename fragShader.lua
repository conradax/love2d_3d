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

return function(x,y,param)
    --error(DeepPrint(param))
    local uv = param.uv
    local normals = param.normals
    local weights = param.weights
    local vertices = param.vertices -- model space
    local tex = param.objData.texture


    --local v = mix_vec3(weights,vertices)
    uv = mix_uv(weights,uv)/MODELSCALE
    uv.y = 1-uv.y
    --error(DeepPrint(uv))
    local w,h = tex:getDimensions()
    --local str = string.format("tex w=%d, h=%d, cur uvx=%d, uvy=%d",w,h,uv.x*w, uv.y*h)
    if uv.x>1 or uv.y >1 or uv.x<0 or uv.y<0 then
        --error(str)
        return {1,0,0,1}
    else
        local r,g,b,a = tex:getPixel(uv.x*w, uv.y*h)
        return {r,g,b,1}
    end
    
end