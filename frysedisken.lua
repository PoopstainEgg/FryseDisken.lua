local ui_reference, ui_new_combobox, ui_new_label, ui_new_slider, ui_new_checkbox, ui_new_hotkey, ui_set_visible, ui_get, ui_set, ui_set_callback, client_set_event_callback, client_unset_event_callback, entity_get_local_player, entity_get_prop, math_sqrt, globals_curtime = ui.reference, ui.new_combobox, ui.new_label, ui.new_slider, ui.new_checkbox, ui.new_hotkey, ui.set_visible, ui.get, ui.set, ui.set_callback, client.set_event_callback, client.unset_event_callback, entity.get_local_player, entity.get_prop, math.sqrt, globals.curtime
local t, c = 'AA', 'Anti-aimbot angles'

local ref = {
    aa = {
        pitch = ui_reference(t, c, 'Pitch'),
        pitch_amount = select(2, ui_reference(t, c, 'Pitch')),
        yaw_base = ui_reference(t, c, 'Yaw base'),
        yaw = ui_reference(t, c, 'Yaw'),
        yaw_amount = select(2, ui_reference(t, c, 'Yaw')),
        yaw_jitter = ui_reference(t, c, 'Yaw jitter'),
        yaw_jitter_amount = select(2, ui_reference(t, c, 'Yaw jitter')),
        body_yaw = ui_reference(t, c, 'Body yaw'),
        body_yaw_amount = select(2, ui_reference(t, c, 'Body yaw')),
        fs_body_yaw = ui_reference(t, c, 'Freestanding body yaw'),
        edge_yaw = ui_reference(t, c, 'Edge yaw'),
        edge_yaw_key = select(2, ui_reference(t, c, 'Edge yaw')),
        freestanding = ui_reference(t, c, 'Freestanding'),
        freestanding_key = select(2, ui_reference(t, c, 'Freestanding')),
        roll = ui_reference(t, c, 'Roll')
    },

    misc = {
        enabled = ui_reference(t, c, 'Enabled'),
        slowwalk = ui_reference('AA', 'Other', 'Slow motion'),
        slowwalk_key = select(2, ui_reference('AA', 'Other', 'Slow motion')),
        os_aa = ui_reference('AA', 'Other', 'On shot anti-aim'),
        os_aa_key = select(2, ui_reference('AA', 'Other', 'On shot anti-aim')),
        double_tap = ui_reference('RAGE', 'Aimbot', 'Double tap'),
        double_tap_key = select(2, ui_reference('RAGE', 'Aimbot', 'Double tap'))
    }
}

local builder = {}

local var = {
    states = {'Global', 'Stand', 'Move', 'Walk', 'Duck'},
    states_idx = {['Global'] = 1, ['Stand'] = 2, ['Move'] = 3, ['Walk'] = 4, ['Duck'] = 5}
}
local selected_state = ui_new_combobox(t, c, 'State', var.states)

for i = 1, #var.states do
    builder[i] = {
        override = ui_new_checkbox(t, c, 'Override global\n' .. var.states[i]),
        pitch = ui_new_combobox(t, c, 'Pitch\n' .. var.states[i], 'Off', 'Down', 'Up'),
        yaw_base = ui_new_combobox(t, c, 'Yaw base\n' .. var.states[i], 'Local view', 'At targets'),
        yaw = ui_new_combobox(t, c, 'Yaw\n' .. var.states[i], 'Off', '180', 'Jitter', 'Spin'),
        yaw_amount = ui_new_slider(t, c, '\nyaw_amount' .. var.states[i], -180, 180, 0, true, '°'),
        yaw_first = ui_new_slider(t, c, '\nyaw_first' .. var.states[i], -180, 180, 0, true, '°'),
        yaw_second = ui_new_slider(t, c, '\nyaw_second' .. var.states[i], -180, 180, 0, true, '°'),
        yaw_delay = ui_new_slider(t, c, '\nyaw_delay' .. var.states[i], 1, 10, 1, true, 's', 0.1),
        yaw_jitter = ui_new_combobox(t, c, 'Yaw jitter\n' .. var.states[i], 'Off', 'Center', 'Random', 'Skitter'),
        yaw_jitter_amount = ui_new_slider(t, c, '\nyaw_jitter_amount' .. var.states[i], -180, 180, 0, true, '°'),
        body_yaw = ui_new_combobox(t, c, 'Body yaw\n' .. var.states[i], 'Off', 'Opposite', 'Jitter', 'Static'),
        body_yaw_amount = ui_new_slider(t, c, '\nbody_yaw_amount' .. var.states[i], -180, 180, 0, true, '°'),
        fs_body_yaw = ui_new_checkbox(t, c, 'Freestand body yaw\n' .. var.states[i]),
        roll = ui_new_slider(t, c, 'Roll\n' .. var.states[i], -45, 45, 0, true, '°'),
        freestand = ui_new_checkbox(t, c, 'Freestand\n' .. var.states[i])
    }
end

local freestand_key = ui_new_hotkey(t, c, 'freestand_key', true)
ui_new_label(t, c, ' ')
local invert = ui_new_hotkey(t, c, 'Invert anti-aim')

local function menu_vis(bool)
    for _, v in pairs(ref.aa) do
        ui_set_visible(v, bool)
    end
end

local function get_state()
    local velocity = {entity_get_prop(entity_get_local_player(), 'm_vecVelocity')}
    local moving = math_sqrt(velocity[1] * velocity[1] + velocity[2] * velocity[2]) >= 2
    local walking = (ui_get(ref.misc.slowwalk) and ui_get(ref.misc.slowwalk_key))
    local ducking = entity_get_prop(entity_get_local_player(), 'm_flDuckAmount') > 0.9

    local conds = {
        ['Stand'] = not moving and not ducking,
        ['Move'] = moving and not ducking,
        ['Walk'] = walking and moving,
        ['Duck'] = ducking
    }

    for k, v in pairs(conds) do 
        if v and ui_get(builder[var.states_idx[k]].override) then
            return var.states_idx[k]
        end
    end
    return 1
end

local function yaw_jitter()
    local b = builder[get_state()]
    local delay = ui_get(b.yaw_delay) * 0.1 / 2

    ui_set(ref.aa.yaw, '180')
    ui_set(ref.aa.yaw_amount, globals_curtime() % delay >= delay / 2 and ui_get(b.yaw_first) or ui_get(b.yaw_second))
end

local function invert_aa(cmd, bool)
    if not bool then 
        return
    end

    local b = builder[get_state()]

    if ui_get(b.yaw) ~= 'Jitter' then
        ui_set(ref.aa.yaw_amount, ui_get(b.yaw_amount) * -1)
    end
    ui_set(ref.aa.body_yaw_amount, ui_get(b.body_yaw_amount) * -1)
    ui_set(ref.aa.roll, ui_get(b.roll) * -1)
    cmd.roll = ui_get(b.roll) * -1
end

local function on_setup_command(cmd)
    local exploiting = (ui_get(ref.misc.os_aa) and ui_get(ref.misc.os_aa_key)) or (ui_get(ref.misc.double_tap) and ui_get(ref.misc.double_tap_key))
    local b = builder[get_state()]

    ui_set(ref.aa.pitch, ui_get(b.pitch))
    ui_set(ref.aa.yaw_base, ui_get(b.yaw_base))
    ui_set(ref.aa.yaw_jitter, ui_get(b.yaw_jitter))
    ui_set(ref.aa.yaw_jitter_amount, ui_get(b.yaw_jitter_amount))
    ui_set(ref.aa.body_yaw, ui_get(b.body_yaw))
    ui_set(ref.aa.body_yaw_amount, ui_get(b.body_yaw_amount))
    ui_set(ref.aa.fs_body_yaw, ui_get(b.fs_body_yaw))
    ui_set(ref.aa.freestanding, ui_get(b.freestand) and ui_get(freestand_key))
    ui_set(ref.aa.roll, exploiting and 0 or ui_get(b.roll))
    cmd.roll = exploiting and 0 or ui_get(b.roll)

    if ui_get(b.yaw) == 'Jitter' then
        yaw_jitter()
    else
        ui_set(ref.aa.yaw, ui_get(b.yaw))
        ui_set(ref.aa.yaw_amount, ui_get(b.yaw_amount))
    end

    invert_aa(cmd, ui_get(invert))
    menu_vis(false)
end

local function update_menu()
    local master = ui_get(ref.misc.enabled)
    local active = var.states_idx[ui_get(selected_state)]
    local b = builder[active]
    local override = ui_get(b.override)

    for i = 1, #var.states do
        ui_set_visible(builder[i].override, master and active == i and active ~= 1)
        ui_set_visible(builder[i].pitch, master and active == i and override)
        ui_set_visible(builder[i].yaw_base, master and active == i and override)
        ui_set_visible(builder[i].yaw, master and active == i and override)
        ui_set_visible(builder[i].yaw_amount, master and active == i and override and ui_get(b.yaw) ~= 'Off' and ui_get(b.yaw) ~= 'Jitter')
        ui_set_visible(builder[i].yaw_first, master and active == i and override and ui_get(b.yaw) == 'Jitter')
        ui_set_visible(builder[i].yaw_second, master and active == i and override and ui_get(b.yaw) == 'Jitter')
        ui_set_visible(builder[i].yaw_delay, master and active == i and override and ui_get(b.yaw) == 'Jitter')
        ui_set_visible(builder[i].yaw_jitter, master and active == i and override and ui_get(b.yaw) ~= 'Off')
        ui_set_visible(builder[i].yaw_jitter_amount, master and active == i and override and ui_get(b.yaw) ~= 'Off' and ui_get(b.yaw_jitter) ~= 'Off')
        ui_set_visible(builder[i].body_yaw, master and active == i and override)
        ui_set_visible(builder[i].body_yaw_amount, master and active == i and override and ui_get(b.body_yaw) ~= 'Off' and ui_get(b.body_yaw) ~= 'Opposite')
        ui_set_visible(builder[i].fs_body_yaw, master and active == i and override and ui_get(b.body_yaw) ~= 'Off')
        ui_set_visible(builder[i].roll, master and active == i and override)
        ui_set_visible(builder[i].freestand, master and active == i and override)
    end

    ui_set_visible(freestand_key, master and override)
    ui_set_visible(selected_state, master)
    ui_set_visible(invert, master)

    menu_vis(false)
end 

local function init()
    ui_set_callback(ref.misc.enabled, function()
        local master = ui_get(ref.misc.enabled)
        local callback = master and client_set_event_callback or client_unset_event_callback
    
        callback('setup_command', on_setup_command)
        update_menu()
    end)
    
    ui_set_callback(selected_state, update_menu)
    
    for i = 1, #var.states do
        ui_set_callback(builder[i].override, update_menu) 
        ui_set_callback(builder[i].yaw, update_menu)
        ui_set_callback(builder[i].yaw_jitter, update_menu)
        ui_set_callback(builder[i].body_yaw, update_menu)
    end

    client_set_event_callback('shutdown', function()
        menu_vis(true)
    end)

    ui_set(ref.misc.enabled, false)
    ui_set(builder[1].override, true)
    ui_set(ref.aa.freestanding_key, 'Always on')   

    update_menu()
end

init()
