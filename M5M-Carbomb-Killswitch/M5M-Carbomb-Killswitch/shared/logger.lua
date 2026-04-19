local function _safePrint(...)
    print(...)
end

Debug = Debug or function(...)
    if Config and Config.Debug then
        _safePrint(...)
    end
end

Debugf = Debugf or function(fmt, ...)
    if not (Config and Config.Debug) then return end
    local ok, msg = pcall(string.format, fmt, ...)
    if ok then
        _safePrint(msg)
    else
        _safePrint(fmt, ...)
    end
end
