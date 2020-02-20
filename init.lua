local setmetatable = setmetatable
local math = math
local lgi = require "lgi"
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local GTop = lgi.GTop
local dbg = require(".debug")

local memory_widget = { mt = {} }

local function round(value)
    return math.floor(value + 0.5)
end

local function get_mem_use_percentage(mem)
    local usage = mem.used - mem.buffer - mem.cached
    return (usage / mem.total) * 100
end

local function mem_to_mb(mem)
    return mem >> 20 
end

local function get_mem_state(mem)
    local mem_state = {
        use_percentage = get_mem_use_percentage(mem),
        total = mem.total,
        used = (mem.used - mem.buffer - mem.cached)
    }

    return mem_state
end

function memory_widget:update_icon(mem_state)
    self.iconbox:set_text("")
end

function memory_widget:update_text(mem_state)
    local text = string.format("%02d%%", round(mem_state.use_percentage))
    self.textbox:set_text(text)
end

function memory_widget:update_tooltip(mem_state)
    local total = mem_to_mb(mem_state.total)
    local used = mem_to_mb(mem_state.used)
    local text = string.format("used:\t%d MB\ntotal:\t%d MB",used,total)
    self.tooltip:set_text(text)
end

function memory_widget:update()
    GTop.glibtop_get_mem(self._private.mem)
    local mem_state = get_mem_state(self._private.mem)
    self:update_icon(mem_state)
    self:update_text(mem_state)
    self:update_tooltip(mem_state)
end

local function new(args)
    local w = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = 4,
        {
            id = "iconbox",
            widget = wibox.widget.textbox,
            font = "FontAwesome 12",
        },
        {
            id = "textbox",
            widget = wibox.widget.textbox,
        }        
    }

    GTop.glibtop_init()

    w.tooltip = awful.tooltip({ objects = { w },})
    
    w._private.mem = GTop.glibtop_mem()

    gears.table.crush(w, memory_widget, true)

    local update_timer = gears.timer {
        timeout   = 5,
        callback = function() w:update() end
    }
    update_timer:start()

    w:update()

    return w
end

function memory_widget.mt:__call(...)
    return new(...)
end

return setmetatable(memory_widget, memory_widget.mt)