package chip8

import "../config"
import sdl "vendor:sdl2"

Keyboard :: struct {
	keyboard: [config.TOTAL_KEYS]bool,
}

keyboard_map: [config.TOTAL_KEYS]u8 = {
	u8(sdl.Keycode.NUM0),
	u8(sdl.Keycode.NUM1),
	u8(sdl.Keycode.NUM2),
	u8(sdl.Keycode.NUM3),
	u8(sdl.Keycode.NUM4),
	u8(sdl.Keycode.NUM5),
	u8(sdl.Keycode.NUM6),
	u8(sdl.Keycode.NUM7),
	u8(sdl.Keycode.NUM8),
	u8(sdl.Keycode.NUM9),
	u8(sdl.Keycode.A),
	u8(sdl.Keycode.B),
	u8(sdl.Keycode.C),
	u8(sdl.Keycode.D),
	u8(sdl.Keycode.E),
	u8(sdl.Keycode.F),
}


map_keyboard :: proc(key: u8) -> int {
	for i in 0 ..< config.TOTAL_KEYS {
		if keyboard_map[i] == key {
			return i
		}
	}

	return -1
}


key_down :: proc(keyboard: ^Keyboard, key: int) {
	keyboard.keyboard[key] = true
}

key_up :: proc(keyboard: ^Keyboard, key: int) {
	keyboard.keyboard[key] = false
}


key_is_pressed :: proc(keyboard: ^Keyboard, key: int) -> bool {
	return keyboard.keyboard[key]
}


key_in_bound_check :: proc(key: int) {
	assert(key >= 0 && key < config.TOTAL_KEYS)
}
