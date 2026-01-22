-- system_rings.lua: 4 rings for CPU, RAM, Battery, and Temperature (acpitemp)
require 'cairo'

-- Ring configuration table
system_rings = {
    {
        name = 'cpu',
        arg = 'cpu0',
        max = 100,
        x = 35, y = 520,
        radius = 30,
        thickness = 8,
        start_angle = -140,
        end_angle = 140,
        bg_color = 0xffffff,
        bg_alpha = 0.4,
        fg_color = 0xFF7400,
        fg_alpha = 1.0,
        rounded = true
    },
    {
        name = 'memperc',
        arg = '',
        max = 100,
        x = 115, y = 520,
        radius = 30,
        thickness = 8,
        start_angle = -140,
        end_angle = 140,
        bg_color = 0xffffff,
        bg_alpha = 0.4,
        fg_color = 0xFF7400,
        fg_alpha = 1.0,
        rounded = true
    },
    {
        name = 'fs_used_perc',
        arg = '/',
        max = 100,
        x = 195, y = 520,
        radius = 30,
        thickness = 8,
        start_angle = -140,
        end_angle = 140,
        bg_color = 0xffffff,
        bg_alpha = 0.4,
        fg_color = 0xFF7400,
        fg_alpha = 1.0,
        rounded = true
    },
    {
        name = 'fs_used_perc',
        arg = '/home',
        max = 100,
        x = 195, y = 520,
        radius = 18,
        thickness = 8,
        start_angle = -140,
        end_angle = 140,
        bg_color = 0xffffff,
        bg_alpha = 0.4,
        fg_color = 0xFF7400,
        fg_alpha = 1.0,
        rounded = true
    }
}

-- Converts hex color to normalized RGBA components
function rgb_to_r_g_b(colour, alpha)
	return ((colour / 0x10000) % 0x100) / 255.,
	       ((colour / 0x100) % 0x100) / 255.,
	       (colour % 0x100) / 255.,
	       alpha
end

-- Draws a single ring with background and foreground arcs
function draw_system_ring(cr, ring, value)
    local angle_0 = (ring.start_angle or 0) * math.pi/180 - math.pi/2
    local angle_f = (ring.end_angle or 360) * math.pi/180 - math.pi/2
    local angle_v = angle_0 + (angle_f - angle_0) * (value / ring.max)

    cairo_set_line_width(cr, ring.thickness)
    cairo_set_line_cap(cr, ring.rounded and CAIRO_LINE_CAP_ROUND or CAIRO_LINE_CAP_BUTT)

    -- Draw background arc
    cairo_arc(cr, ring.x, ring.y, ring.radius, angle_0, angle_f)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(ring.bg_color, ring.bg_alpha))
    cairo_stroke(cr)

    -- Draw foreground arc representing the value
    cairo_arc(cr, ring.x, ring.y, ring.radius, angle_0, angle_v)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(ring.fg_color, ring.fg_alpha))
    cairo_stroke(cr)
end

-- Main function called by Conky
function conky_system_rings()
    if conky_window == nil then return end

    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
                                         conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    -- Loop through all rings and draw them
    for i, ring in ipairs(system_rings) do
        local val = tonumber(conky_parse('${' .. ring.name .. ' ' .. ring.arg .. '}')) or 0
        draw_system_ring(cr, ring, val)
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
