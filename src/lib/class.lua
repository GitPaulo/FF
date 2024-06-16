local Class = {}

function Class:extend(obj)
    local obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Class:new(...)
    local instance = setmetatable({}, self)
    self.__index = self
    if instance.init then
        instance:init(...)
    end
    return instance
end

return Class
