require 'cairo'
require 'cairo_xlib'
local COLORS = {CPU=0xEEEEEE, MEM=0xEEEEEE, TEMP=0xEEEEEE, DISK=0xEEEEEE}
local BG_ALPHA = 0.3
local FG_ALPHA = 1
local MAX_HISTORY_SIZE = 81
local ANGLE_0 = -150 * (2 * math.pi / 360) - math.pi / 2
local ANGLE_F = 150 * (2 * math.pi / 360) - math.pi / 2
local MAX_ARC = ANGLE_F - ANGLE_0
local PEAK_TEXT_COLOR = 0x999999
local OUTLINE_COLOR = 0xFFFFFF
local DISK_UPDATE_INTERVAL = 60
local PEAK_UPDATE_INTERVAL = 1
local function create_initial_array()
local arr = {}
for i = 0, MAX_HISTORY_SIZE - 1 do
arr[i] = 0.1
end
return arr
end
local state = {
up = create_initial_array(),
down = create_initial_array(),
nchart = 0,
last_update = os.time(),
disk_update_counter = 0,
peak_update_counter = 0,
disk_values_cache = {},
cached_peaks_up = {},
cached_peaks_down = {},
}
local cached_temp_unit = nil
local dynamic_settings_table = {
{name='cpu', arg='cpu0', max=100, color=COLORS.CPU, x=64, y=303, radius=30, thickness=10},
{name='memperc', arg='', max=100, color=COLORS.MEM, x=148, y=303, radius=30, thickness=10},
{name='acpitemp', arg='', max=100, color=COLORS.TEMP, x=316, y=303, radius=30, thickness=10},
}
local disk_settings_table = {
{name='fs_used_perc', arg='/', max=100, color=COLORS.DISK, x=233, y=303, radius=30, thickness=10},
{name='fs_used_perc', arg='${template8}', max=100, color=COLORS.DISK, x=56, y=448, radius=20, thickness=6},
{name='fs_used_perc', arg='${template1}', max=100, color=COLORS.DISK, x=137, y=448, radius=20, thickness=6},
{name='fs_used_perc', arg='${template2}', max=100, color=COLORS.DISK, x=56, y=528, radius=20, thickness=6},
{name='fs_used_perc', arg='${template3}', max=100, color=COLORS.DISK, x=137, y=528, radius=20, thickness=6},
}
local function rgb_to_rgba(color, alpha)
return (color // 0x10000) % 0x100 / 255, (color // 0x100) % 0x100 / 255, color % 0x100 / 255, alpha
end
local function draw_half_circle(cr, t, pt)
local xc, yc, ring_r, ring_w = pt.x, pt.y, pt.radius, pt.thickness
local progress_arc = MAX_ARC * t
cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
cairo_set_line_width(cr, ring_w)
cairo_set_source_rgba(cr, rgb_to_rgba(pt.color, BG_ALPHA))
cairo_arc(cr, xc, yc, ring_r, ANGLE_0, ANGLE_F)
cairo_stroke(cr)
cairo_set_source_rgba(cr, rgb_to_rgba(pt.color, FG_ALPHA))
cairo_arc(cr, xc, yc, ring_r, ANGLE_0, ANGLE_0 + progress_arc)
cairo_stroke(cr)
end
local function safe_number(v)
local val = v or 0.1
if val < 0.1 or val ~= val then
return 0.1
else
return val
end
end
function add_network_traffic(iface_template, s)
s.nchart = (s.nchart + 1) % MAX_HISTORY_SIZE
local up_val = tonumber(conky_parse('${upspeedf ' .. iface_template .. '}'))
local down_val = tonumber(conky_parse('${downspeedf ' .. iface_template .. '}'))
s.up[s.nchart] = safe_number(up_val)
s.down[s.nchart] = safe_number(down_val)
s.last_update = os.time()
end
function get_max_value(data_array)
local max_val = 1.0
for _, value in pairs(data_array) do
if value > max_val then
max_val = value
end
end
return max_val
end
function draw_smooth_curve(cr, data, x, y, l, h, nchart, direction, max_value)
local _chart = nchart + 1
local step = l / (MAX_HISTORY_SIZE - 1)
local x_prev, y_prev = x, y
for i = 0, MAX_HISTORY_SIZE - 1, 1 do
if _chart >= MAX_HISTORY_SIZE then
_chart = 0
end
local value = safe_number(data[_chart])
local y_offset = math.floor((value / max_value) * h)
if direction == "down" then
y_offset = -y_offset
end
local x_new = x + step * i
local y_new = y - y_offset
cairo_curve_to(cr, (x_prev + x_new) / 2, y_prev, (x_prev + x_new) / 2, y_new, x_new, y_new)
x_prev, y_prev = x_new, y_new
_chart = _chart + 1
end
end
local function get_circ_index(start_index, offset)
return (start_index + offset) % MAX_HISTORY_SIZE
end
local function draw_dot(cr, x, y, radius, color, alpha)
cairo_new_path(cr)
cairo_arc(cr, x, y, radius, 0, 2 * math.pi)
cairo_set_source_rgba(cr, rgb_to_rgba(color, alpha))
cairo_fill(cr)
end
local function draw_peak_text(cr, x, y, text, color, direction)
cairo_save(cr)
local FONT_SIZE = 6
local TEXT_ALPHA = 1.0
local text_width_approx = 20
local INTERNAL_TEXT_OFFSET = 3
cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
cairo_set_font_size(cr, FONT_SIZE)
local text_y = y
if direction == "up" then
text_y = y - INTERNAL_TEXT_OFFSET
else
text_y = y + INTERNAL_TEXT_OFFSET + FONT_SIZE
end
local text_x = x - text_width_approx / 2
cairo_set_source_rgba(cr, rgb_to_rgba(OUTLINE_COLOR, TEXT_ALPHA * 0.5))
cairo_move_to(cr, text_x + 0.5, text_y + 0.5)
cairo_show_text(cr, text)
cairo_set_source_rgba(cr, rgb_to_rgba(PEAK_TEXT_COLOR, TEXT_ALPHA))
cairo_move_to(cr, text_x, text_y)
cairo_show_text(cr, text)
cairo_restore(cr)
end
local function draw_peaks_from_cache(cr, cached_peaks, color, direction, y_base, h_chart, max_value)
local BORDER_COLOR = OUTLINE_COLOR
local PEAK_Y_OFFSET = 4
local DOT_RADIUS = 1.0
local BORDER_THICKNESS = 1.5
local OUTLINE_RADIUS = DOT_RADIUS + BORDER_THICKNESS
local BORDER_ALPHA = 0.5
local FILL_ALPHA = 1.0
local PEAK_COLOR = color
for _, peak in ipairs(cached_peaks) do
local peak_y
local peak_value_str
if direction == "up" then
peak_y = y_base - math.floor((peak.value / max_value) * h_chart) - PEAK_Y_OFFSET
if peak.value >= 1024 then
peak_value_str = string.format("%.1fMiB", peak.value / 1024)
else
peak_value_str = string.format("%.0fKiB", peak.value)
end
else
peak_y = y_base + math.floor((peak.value / max_value) * h_chart) + PEAK_Y_OFFSET
if peak.value >= 1024 then
peak_value_str = string.format("%.1fMiB", peak.value / 1024)
else
peak_value_str = string.format("%.0fKiB", peak.value)
end
end
draw_dot(cr, peak.x, peak_y, OUTLINE_RADIUS, BORDER_COLOR, BORDER_ALPHA)
draw_dot(cr, peak.x, peak_y, DOT_RADIUS, PEAK_COLOR, FILL_ALPHA)
draw_peak_text(cr, peak.x, peak_y, peak_value_str, PEAK_COLOR, direction)
end
end
function draw_network_chart(cr, iface, up, down, nchart, x, y, l, h)
local max_UL = get_max_value(up)
local max_DL = get_max_value(down)
local color_up = COLORS.TEMP
local color_down = 0x999999
cairo_set_line_width(cr, 1)
cairo_new_path(cr)
cairo_move_to(cr, x, y)
draw_smooth_curve(cr, up, x, y, l, h, nchart, "up", max_UL)
cairo_line_to(cr, x + l, y)
cairo_close_path(cr)
cairo_set_source_rgba(cr, rgb_to_rgba(color_up, 0.5))
cairo_fill(cr)
cairo_new_path(cr)
cairo_move_to(cr, x, y)
draw_smooth_curve(cr, down, x, y, l, h, nchart, "down", max_DL)
cairo_line_to(cr, x + l, y)
cairo_close_path(cr)
cairo_set_source_rgba(cr, rgb_to_rgba(color_down, 0.5))
cairo_fill(cr)
cairo_new_path(cr)
cairo_move_to(cr, x, y)
draw_smooth_curve(cr, up, x, y, l, h, nchart, "up", max_UL)
cairo_set_source_rgba(cr, rgb_to_rgba(color_up, 0.9))
cairo_stroke(cr)
cairo_new_path(cr)
cairo_move_to(cr, x, y)
draw_smooth_curve(cr, down, x, y, l, h, nchart, "down", max_DL)
cairo_set_source_rgba(cr, rgb_to_rgba(color_down, 0.9))
cairo_stroke(cr)
if state.peak_update_counter == 0 then
state.cached_peaks_up = {}
state.cached_peaks_down = {}
local step = l / (MAX_HISTORY_SIZE - 1)
local MIN_PEAK_THRESHOLD = 0.85
local MIN_PEAK_DISTANCE = 50
local _current_chart = nchart + 1
local last_peak_x_up = -MIN_PEAK_DISTANCE
local last_peak_x_down = -MIN_PEAK_DISTANCE
for i = 2, MAX_HISTORY_SIZE - 3, 1 do
local curr_idx = get_circ_index(_current_chart, i)
local curr_up = safe_number(up[curr_idx])
local curr_down = safe_number(down[curr_idx])
local x_plot = x + step * i
if curr_up / max_UL > MIN_PEAK_THRESHOLD and x_plot > last_peak_x_up + MIN_PEAK_DISTANCE then
table.insert(state.cached_peaks_up, {x = x_plot, value = curr_up})
last_peak_x_up = x_plot
end
if curr_down / max_DL > MIN_PEAK_THRESHOLD and x_plot > last_peak_x_down + MIN_PEAK_DISTANCE then
table.insert(state.cached_peaks_down, {x = x_plot, value = curr_down})
last_peak_x_down = x_plot
end
end
end
draw_peaks_from_cache(cr, state.cached_peaks_up, color_up, "up", y, h, max_UL)
draw_peaks_from_cache(cr, state.cached_peaks_down, color_down, "down", y, h, max_DL)
end
function conky_ring_stats()
if conky_window == nil then return end
local display = conky_window.display or conky_display
local cs = cairo_xlib_surface_create(display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
local cr = cairo_create(cs)
for _, pt in ipairs(dynamic_settings_table) do
local value_str = conky_parse('${' .. pt.name .. ' ' .. pt.arg .. '}')
local value = tonumber(value_str) or 0
draw_half_circle(cr, value / pt.max, pt)
end
local needs_update = state.disk_update_counter == 0
for i, pt in ipairs(disk_settings_table) do
if needs_update then
local value_str = conky_parse('${' .. pt.name .. ' ' .. pt.arg .. '}')
local value = tonumber(value_str) or 0
state.disk_values_cache[i] = value
end
local cached_value = state.disk_values_cache[i] or 0
draw_half_circle(cr, cached_value / pt.max, pt)
end
state.disk_update_counter = (state.disk_update_counter + 1) % DISK_UPDATE_INTERVAL
state.peak_update_counter = (state.peak_update_counter + 1) % PEAK_UPDATE_INTERVAL
local network_interface = conky_parse('${template0}')
add_network_traffic(network_interface, state)
draw_network_chart(cr, network_interface, state.up, state.down, state.nchart, 220, 150, 130, 30)
cairo_destroy(cr)
cairo_surface_destroy(cs)
end
function ring_stats()
conky_ring_stats()
end
function conky_cpu_temp()
if conky_parse then
local temp_unit_override = conky_parse('${template9}')
local temp_unit
if temp_unit_override ~= 'nil' and temp_unit_override ~= '' then
temp_unit = temp_unit_override
elseif cached_temp_unit then
temp_unit = cached_temp_unit
else
temp_unit = io.popen(os.getenv("HOME") .. '/.config/conky/Mimod-green/scripts/weather-unit.sh temp'):read('*l') or "°C"
cached_temp_unit = temp_unit
end
if temp_unit:match("°F") then
local temp_c_str = conky_parse('${acpitemp}')
local temp_c = tonumber(temp_c_str)
if temp_c and temp_c > 0 then
local temp_f = math.floor((temp_c * 9/5) + 32)
return temp_f .. temp_unit
else
return "N/A" .. temp_unit
end
else
return conky_parse('${acpitemp}') .. temp_unit
end
else
return "${acpitemp}°C"
end
end
