local OBJ = require("/lib/OBJ-Loader.OBJ")

local OBJHelper = {}
local META = {
    __index = OBJHelper
}



function OBJHelper.loadOBJ(self,path)
    local o = setmetatable({},META)
    o.OBJData = OBJ.loadObj(path)
    --error(DeepPrint(o.OBJData))
    o.Vertices = {} -- store vertex position in VEC3
    o.Faces = {} -- store faces
    o.Position = VEC3(0,0,0)
    o.Rotation = VEC3(0,0,0)
    OBJHelper._process(o)
    return o
end

--re-construct data
function OBJHelper._process(self)
    --model to world matrix
    self.Matrix_Model2World = MTX_Model2World(self.Position,self.Rotation)

    --convert faces
    local faces = self.OBJData.faces
    for k,face in ipairs(faces) do
        local face_to_save = {}
        for kk,data in ipairs(face.data) do
            local vertex = data.vertex
            face_to_save[kk] = {vertex.x,vertex.y,vertex.z}
        end
        self.Faces[k] = face_to_save
    end


    -- local objData = self.OBJData
    -- local objVerts = self.OBJData.vertices
    -- self.Verts = objData.vertices
    -- local faceData = {}
    -- for _,face in ipairs(objData.faces) do
    --     local vert_index = {}
    --     local uv_index = {}
    --     local normal_index = {}
    --     for _,data in ipairs(face.data) do
    --         vertIndex[#vertIndex+1] = data.vertex_index
    --         UVIndex[#UVIndex+1] = data.uv_index
    --         normalIndex[#normalIndex+1] = data.normal_index
    --     end
    -- end
end

-- return a table contains faces' vertex position (nested table)
function OBJHelper.getFaces(self)
    return self.Faces
    --return deepcopy(self.Faces)
end

--rotation: VEC3(rotX, rotY, rotZ)
function OBJHelper.SetRotation(self,rotation)
    self.Rotation = rotation
    self.Matrix_Model2World = MTX_Model2World(self.Position,self.Rotation)
end
return OBJHelper