memory.usememorydomain('WRAM')

local state = {
    timers = {
        overlay = 0,
        menu_delay = 0,
        sub_menu_delay = 0,
        reference_time = 25
    },
    flags = {overlay = false, menu_state = 1}
}

local overlay_settings = {line_space_amount = 10, line_space = 0, menu_time = 5}

local time = {address = 0x00008E, max = 96}

local player_1 = {
    health = {address = 0x000EE4, max = 96},

    meter = {address = 0x001AC4, max = 80},

    hitbox = {
        [1] = {x_1 = 0x0014C8, x_2 = 0x001508, y_1 = 0x001516, y_2 = ''},
    },

    active_hitbox = {
        [1] = {x_1 = '', x_2 = '', y_1 = '', y_2 = ''}
    },

    projectile_hitbox = {
        [1] = {
            box = {
                x_1 = 0x0009C8,
                x_2 = 0x0009C1,
                y_1 = '',
                y_2 = ''
            },
            position = {x = '', y = ''},
            state_address = ''
        },
    },
}

local player_2 = {
    health = {address = 0x000FC4, max = 96},

    meter = {address = 0x001B14, max = 80},

    hitbox = {
        [1] = {x_1 = '', x_2 = '', y_1 = '', y_2 = ''},
    },

    active_hitbox = {
        [1] = {x_1 = '', x_2 = '', y_1 = '', y_2 = ''}
    },

    projectile_hitbox = {
        [1] = {
            box = {
                x_1 = '',
                x_2 = '',
                y_1 = '',
                y_2 = ''
            },
            position = {x = '', y = ''},
            state_address = ''
        },
    },

    facing = {address = '', bitwise_and = ''},

    address = {attack = ''},
}

local color = {
    hitbox = {border = 0xFF0000FF, fill = 0x400000FF},
    active_hitbox = {border = 0xFFFF0000, fill = 0x40FF0000},
    invisible = {border = 0x00000000, fill = 0x00000000}
}

local function noop() return 0 end

local function facing(table)
    if  memory.read_u8(table.player.facing.address) == table.player.facing.right then
        return 1
    else
        return -1
    end
end

local function one_byte_set_to_max(table)
    local function f() memory.writebyte(table.address, table.max) end
    return f
end

local menu = {
    [1] = {text = "Player 1", skip = true},
    [2] = {
        text = "Health",
        skip = false,
        state = 1,
        max_state = 2,
        options = {
            [1] = {text = " Normal >", callback = noop},
            [2] = {
                text = "< Infinate",
                callback = one_byte_set_to_max({address = player_1.health.address, max = player_1.health.max})
            }
        }
    },
    [3] = {
        text = "Meter",
        skip = false,
        state = 1,
        max_state = 2,
        options = {
            [1] = {text = " Normal >", callback = noop},
            [2] = {
                text = "< Infinate",
                callback = one_byte_set_to_max({address = player_1.meter.address, max = player_1.meter.max})
            }
        }
    },
    [4] = {text = "Player 2", skip = true},
    [5] = {
        text = "Health",
        skip = false,
        state = 1,
        max_state = 2,
        options = {
            [1] = {text = " Normal >", callback = noop},
            [2] = {
                text = "< Infinate",
                callback = one_byte_set_to_max({address = player_2.health.address, max = player_2.health.max})
            }
        }
    },
    [6] = {
        text = "Meter",
        skip = false,
        state = 1,
        max_state = 2,
        options = {
            [1] = {text = " Normal >", callback = noop},
            [2] = {
                text = "< Infinate",
                callback = one_byte_set_to_max({address = player_2.meter.address, max = player_2.meter.max})
            }
        }
    },
    [7] = {text = "Extras", skip = true},
    [8] = {
        text = "Time",
        skip = false,
        state = 1,
        max_state = 2,
        options = {
            [1] = {text = " Normal >", callback = noop},
            [2] = {
                text = "< Infinate",
                callback = one_byte_set_to_max({address = time.address, max = time.max})
            }
        }
    },
    --[9] = {
    --    text = "Hitboxes",
    --    skip = false,
    --    state = 1,
    --    max_state = 2,
    --    options = {
    --        [1] = {text = " Off >", callback = noop},
    --        [2] = {text = "< On", callback = noop}
    --    }
    --}
}

local function test_box()
    gui.drawBox(memory.read_u8(player_1.projectile_hitbox[1].box.x_1), 1, memory.read_u8(player_1.projectile_hitbox[1].box.x_1) + 3, 300)
end

local function run_menu_callbacks()
    for key, value in ipairs(menu) do
        if value.skip == false then value.options[value.state].callback() end
    end
end

local function check_timers()
    if state.timers.overlay >= state.timers.reference_time then
        state.flags.overlay = not state.flags.overlay
        state.timers.overlay = 0
    end
end

local function table_has_key(table, key)
    if table[key] ~= nil then
        return true
    else
        return false
    end
end

local function overlay()
    local inputs = joypad.get()
    local line_space_amount = overlay_settings.line_space_amount
    local line_space = overlay_settings.line_space

    for key, value in ipairs(menu) do
        if table_has_key(value, "options") == true then
            menu_text = value["text"] .. " " .. value.options[value.state].text
        else
            menu_text = value.text
        end

        if key == state.flags.menu_state and value.skip == false then
            gui.drawText(0, line_space, ">" .. menu_text, "white", "Black")

            if table_has_key(value, "state") == true and
                table_has_key(value, "max_state") == true then
                if inputs["P1 Right"] == true and state.timers.sub_menu_delay >=
                    overlay_settings.menu_time then
                    value.state = value.state + 1
                    state.timers.sub_menu_delay = 0
                end

                if inputs["P1 Left"] == true and state.timers.sub_menu_delay >=
                    overlay_settings.menu_time then
                    value.state = value.state - 1
                    state.timers.sub_menu_delay = 0
                end

                if inputs["P1 Left"] == true or inputs["P1 Right"] == true then
                    state.timers.sub_menu_delay =
                        state.timers.sub_menu_delay + 1
                end

                if value.state > value.max_state then
                    value.state = value.max_state
                end

                if value.state < 1 then value.state = 1 end
            end

            value.options[value.state].callback()

        elseif key == state.flags.menu_state and value.skip == true then
            gui.drawText(0, line_space, "-" .. menu_text, "white", "Black")
        else
            gui.drawText(0, line_space, " " .. menu_text, "white", "Black")
        end

        line_space = line_space + line_space_amount
    end

    if inputs["P1 Down"] == true or inputs["P1 Up"] == true then
        state.timers.menu_delay = state.timers.menu_delay + 1
    end

    if inputs["P1 Down"] == true and state.timers.menu_delay >=
        overlay_settings.menu_time then
        state.flags.menu_state = state.flags.menu_state + 1
        state.timers.menu_delay = 0
    end

    if inputs["P1 Up"] == true and state.timers.menu_delay >=
        overlay_settings.menu_time then
        state.flags.menu_state = state.flags.menu_state - 1
        state.timers.menu_delay = 0
    end

    if state.flags.menu_state < 1 then state.flags.menu_state = 1 end

    if state.flags.menu_state > #menu then state.flags.menu_state = #menu end
end

while true do
    local inputs = joypad.get()

    if inputs["P1 Start"] == true and inputs["P1 Select"] == true then
        state.timers.overlay = state.timers.overlay + 1
    end

    check_timers()
test_box()
    if state.flags.overlay == true then overlay() end

    run_menu_callbacks()

    emu.frameadvance()
    gui.clearGraphics()
end
