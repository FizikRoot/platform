require('strict').on()

log = require('log')
clock = require('clock')
metrics = require('metrics')

metrics.enable_default_metrics()

local httpd = require('http.server')
local http_handler = require('metrics.plugins.prometheus').collect_http

local function start_metrics_server(port)
    httpd.new('0.0.0.0', port):route({
        path = '/metrics',
        public = true,
        method = 'GET',
    }, http_handler):start()
end

local function tail(status, ...)
    if not status then
        error(..., 2)
    end
    return ...
end

local function wrap_func(function_name, func)
    return function(...)
        return pcall(func, ...)
    end
end

local function init(options)
    local tbl = _G
    for k, v in pairs(options.functions) do
        -- TODO(a.petrukhin): add roles.
        -- TODO(a.petrukhin): probably improve function wrapping.
        box.schema.func.create(k, {setuid = true, if_not_exists = true})
        rawset(tbl, k, v)
    end
end

return {
    init = init,
    start_metrics_server = start_metrics_server,
    wrap_func = wrap_func,
}
