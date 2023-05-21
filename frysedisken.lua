local ui_reference, ui_new_combobox, ui_new_label, ui_new_slider, ui_new_checkbox, ui_new_hotkey, ui_set_visible, ui_get, ui_set, ui_set_callback, client_set_event_callback, entity_get_local_player, entity_get_prop, math_sqrt = ui.reference, ui.new_combobox, ui.new_label, ui.new_slider, ui.new_checkbox, ui.new_hotkey, ui.set_visible, ui.get, ui.set, ui.set_callback, client.set_event_callback, entity.get_local_player, entity.get_prop, math.sqrt

local t, c = 'AA', 'Anti-aimbot angles'

local ref = {
    aa = {
        enabled = ui_reference(t, c, 'Enabled'),
        pitch = ui_reference(t, c, 'Pitch'),
        pitch_type = select(2, ui_reference(t, c, 'Pitch')),
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

    other = {
        slowwalk = ui_reference('AA', 'Other', 'Slow motion'),
        slowwalk_key = select(2, ui_reference('AA', 'Other', 'Slow motion')),
        os_aa = ui_reference('AA', 'Other', 'On shot anti-aim'),
        os_aa_key = select(2, ui_reference('AA', 'Other', 'On shot anti-aim')),
        double_tap = ui_reference('RAGE', 'Aimbot', 'Double tap'),
        double_tap_key = select(2, ui_reference('RAGE', 'Aimbot', 'Double tap'))
    }
}

local builder = {}
local states = {'Stand', 'Move', 'Walk', 'Duck'}
local states_idx = {['Stand'] = 1, ['Move'] = 2, ['Walk'] = 3, ['Duck'] = 4}
local current_state = ui_new_combobox(t, c, 'State', states)
ui_new_label(t, c, ' ')

for i = 1, #states do
    builder[i] = {
        pitch = ui_new_combobox(t, c, '[' .. states[i] .. ']' .. ' Pitch', 'Off', 'Down', 'Up'),
        yaw_base = ui_new_combobox(t, c, '[' .. states[i] .. ']' .. ' Yaw base', 'Local view', 'At targets'),
        yaw = ui_new_combobox(t, c, '[' .. states[i] .. ']' .. ' Yaw', 'Off', '180', '180 Z', 'Spin'),
        yaw_amount = ui_new_slider(t, c, '\nyaw_amount', -180, 180, 0, true, '°'),
        yaw_jitter = ui_new_combobox(t, c, '[' .. states[i] .. ']' .. ' Yaw jitter', 'Off', 'Offset', 'Center', 'Random', 'Skitter'),
        yaw_jitter_amount = ui_new_slider(t, c, '\nyaw_jitter_amount', -180, 180, 0, true, '°'),
        body_yaw = ui_new_combobox(t, c, '[' .. states[i] .. ']' .. ' Body yaw', 'Off', 'Opposite', 'Jitter', 'Static'),
        body_yaw_amount = ui_new_slider(t, c, '\nbody_yaw_jitter_amount', -180, 180, 0, true, '°'),
        fs_body_yaw = ui_new_checkbox(t, c, '[' .. states[i] .. ']' .. ' Freestand body yaw'),
        roll = ui_new_slider(t, c, '[' .. states[i] .. ']' .. ' Roll', -45, 45, 0, true, '°')
    }
end

ui_new_label(t, c, ' ')
local fs_key = ui_new_hotkey(t, c, 'Freestand')
local invert = ui_new_hotkey(t, c, 'Invert anti-aim')

local function menu_vis(bool)
    for k, v in pairs(ref.aa) do
        ui_set_visible(v, bool)
    end
end

client_set_event_callback('setup_command', function(cmd)
    local velocity = {entity_get_prop(entity_get_local_player(), 'm_vecVelocity')}
    local speed = math_sqrt(velocity[1] * velocity[1] + velocity[2] * velocity[2])
    local slowwalking = (ui_get(ref.other.slowwalk) and ui_get(ref.other.slowwalk_key))
    local duck_amount = entity_get_prop(entity_get_local_player(), 'm_flDuckAmount')

    local state = {
        ['Stand'] = speed < 2 and duck_amount < 0.9,
        ['Move'] = speed >= 2 and not slowwalking and duck_amount < 0.9,
        ['Walk'] = speed >= 2 and slowwalking and duck_amount < 0.9,
        ['Duck'] = duck_amount > 0.9
    }

    for k, v in pairs(state) do
        if v then
            ui_set(ref.aa.pitch, ui_get(builder[states_idx[k]].pitch))
            ui_set(ref.aa.yaw_base, ui_get(builder[states_idx[k]].yaw_base))
            ui_set(ref.aa.yaw, ui_get(builder[states_idx[k]].yaw))
            ui_set(ref.aa.yaw_amount, ui_get(builder[states_idx[k]].yaw_amount))
            ui_set(ref.aa.yaw_jitter, ui_get(builder[states_idx[k]].yaw_jitter))
            ui_set(ref.aa.yaw_jitter_amount, ui_get(builder[states_idx[k]].yaw_jitter_amount))
            ui_set(ref.aa.body_yaw, ui_get(builder[states_idx[k]].body_yaw))
            ui_set(ref.aa.body_yaw_amount, ui_get(builder[states_idx[k]].body_yaw_amount))
            ui_set(ref.aa.fs_body_yaw, ui_get(builder[states_idx[k]].fs_body_yaw))

            if (ui_get(ref.other.os_aa) and ui_get(ref.other.os_aa_key)) or (ui_get(ref.other.double_tap) and ui_get(ref.other.double_tap_key)) then
                ui_set(ref.aa.roll, 0)
                cmd.roll = 0
            else
                ui_set(ref.aa.roll, ui_get(builder[states_idx[k]].roll))
                cmd.roll = ui_get(builder[states_idx[k]].roll)
            end

            if ui_get(invert) then
                ui_set(ref.aa.yaw_amount, ui_get(builder[states_idx[k]].yaw_amount) * -1)
                ui_set(ref.aa.body_yaw_amount, ui_get(builder[states_idx[k]].body_yaw_amount) * -1)
                ui_set(ref.aa.roll, ui_get(builder[states_idx[k]].roll) * -1)
                cmd.roll = ui_get(builder[states_idx[k]].roll) * -1
            end
        end
    end

    ui_set(ref.aa.freestanding, ui_get(fs_key))
    ui_set(ref.aa.freestanding_key, 'Always on')

    menu_vis(false)
end)

client_set_event_callback('shutdown', function()
    menu_vis(true)
end)

local function update_menu()
    local active = states_idx[ui_get(current_state)]

    for i = 1, #states do
        ui_set_visible(builder[i].pitch, active == i)
        ui_set_visible(builder[i].yaw_base, active == i)
        ui_set_visible(builder[i].yaw, active == i)
        ui_set_visible(builder[i].yaw_amount, active == i and ui_get(builder[active].yaw) ~= 'Off')
        ui_set_visible(builder[i].yaw_jitter, active == i and ui_get(builder[active].yaw) ~= 'Off')
        ui_set_visible(builder[i].yaw_jitter_amount, active == i and ui_get(builder[active].yaw) ~= 'Off' and ui_get(builder[active].yaw_jitter) ~= 'Off')
        ui_set_visible(builder[i].body_yaw, active == i)
        ui_set_visible(builder[i].body_yaw_amount, active == i and ui_get(builder[active].body_yaw) ~= 'Off' and ui_get(builder[active].body_yaw) ~= 'Opposite')
        ui_set_visible(builder[i].fs_body_yaw, active == i and ui_get(builder[active].body_yaw) ~= 'Off')
        ui_set_visible(builder[i].roll, active == i)
    end

    menu_vis(false)
end 

ui_set(ref.aa.enabled, true)
for i = 1, #states do 
    ui_set_callback(builder[i].yaw, update_menu)
    ui_set_callback(builder[i].yaw_jitter, update_menu)
    ui_set_callback(builder[i].body_yaw, update_menu)
end
ui_set_callback(current_state, update_menu)
update_menu()