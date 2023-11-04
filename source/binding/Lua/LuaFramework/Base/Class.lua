_class = _class or {}

function Class(base)
    local class_type = {}
    class_type.Ctor = false
    class_type.base = base
    class_type.New = function(...)
        local obj = {}
        setmetatable(obj,{ __index = _class[class_type]})
        do
            local create
            create = function(c,...)
                if c.base then
                    create(c.base,...)
                end
                if c.Ctor then
                    c.Ctor(obj,...)
                end
            end
            create(class_type,...)
        end
        return obj
    end
    local vtbl = {}
    _class[class_type] = vtbl
    setmetatable(class_type,{__newindex =
        function(t,k,v)
            vtbl[k] = v
        end,
        __index = _class[class_type]
    })

    if base then
        setmetatable(vtbl,
        {__index =
            function(t,k)
                local ret = _class[base][k]
                if type(ret) == "function" then
--                    vtbl[k] = ret
                    return ret
                end
            end
        })
    end

    return class_type
end