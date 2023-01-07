UltrakillFileManager = {}

-- Thank you MyNameIsTrez / StackOverflow!

--[[
Example usage:
s = serializeTable({a = "foo", b = {c = 123, d = "foo"}})
print(s)
a = loadstring(s)()
]]--

--[[
Returns the entire file as a string.
]]--

function UltrakillFileManager:SerializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. UltrakillFileManager:SerializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
	end
	
    return tmp
end

function UltrakillFileManager:FileExists(filepath)
    local fileID = LuaMan:FileOpen(filepath, "r");
    LuaMan:FileClose(fileID);
    if fileID == -1 then return false; end
    return true;
end

function UltrakillFileManager:ReadFile(filepath)
    if not UltrakillFileManager:FileExists(filepath) then return false; end
    local fileID = LuaMan:FileOpen(filepath, "r");
    local strTab = {};
    local i = 1;
    while not LuaMan:FileEOF(fileID) do
        strTab[i] = LuaMan:FileReadLine(fileID);
        i = i + 1;
    end
    LuaMan:FileClose(fileID);
    return table.concat(strTab);
end


function UltrakillFileManager:ReadFileAsTable(filepath)
    local fileStr = UltrakillFileManager:ReadFile(filepath);
    if fileStr == false then return false; end
    return loadstring("return " .. fileStr)();
end


function UltrakillFileManager:WriteToFile(filepath, str)
    local fileID = LuaMan:FileOpen(filepath, "w");
    LuaMan:FileWriteLine(fileID, str);
    LuaMan:FileClose(fileID);
end


function UltrakillFileManager:WriteTableToFile(filepath, tab)
    local tabStr = UltrakillFileManager:SerializeTable(tab)
    UltrakillFileManager:WriteToFile(filepath, tabStr)
end