local OBJ = require("/lib/OBJ-Loader.OBJ")

local OBJHelper = {}
local META = {
    __index = OBJHelper
}



function OBJHelper.loadOBJ(self,path,settings)
    local o = setmetatable({},META)
    o.OBJData = OBJ.loadObj(path,settings)
    o.Position = VEC3(0,0,0)
    o.Rotation = VEC3(0,0,0)
    o.Matrix_Model2World = MTX_Model2World(o.Position,o.Rotation)
    return o
end

--rotation: VEC3(rotX, rotY, rotZ)
function OBJHelper.SetRotation(self,rotation)
    self.Rotation = rotation
    self.Matrix_Model2World = MTX_Model2World(self.Position,self.Rotation)
end
return OBJHelper