package chip8

import "../config"

Screen :: struct {
	pixels: [config.SCREEN_HEIGHT][config.SCREEN_WIDTH]bool,
}

screen_set :: proc(screen: ^Screen, x: int, y: int) {
	screen_check_bounds(x, y)
	screen.pixels[y][x] = true
}


screen_is_set :: proc(screen: ^Screen, x: int, y: int) -> bool {
	screen_check_bounds(x, y)
	return screen.pixels[y][x]
}


screen_check_bounds :: proc(x: int, y: int) {
	assert(x >= 0 && x < config.SCREEN_WIDTH && y >= 0 && y < config.SCREEN_HEIGHT)
}

clear_screen :: proc(screen: ^Screen) {
	for y := 0; y < config.SCREEN_HEIGHT; y += 1 {
		for x := 0; x < config.SCREEN_WIDTH; x += 1 {
			screen.pixels[y][x] = false
		}
	}
}


draw_sprite :: proc(screen: ^Screen, x: int, y: int, sprite: ^u8, num: int) -> u8 {
	pixel_collision: u8 = 0

	for ly := 0; ly < num; ly += 1 {
		c := ((^u8)(uintptr(sprite) + uintptr(ly)))^
		for lx := 0; lx < 8; lx += 1 {
			if (c & (0b10000000 >> u32(lx))) == 0 {
				continue
			}

			screen_y := (ly + y) % config.SCREEN_HEIGHT
			screen_x := (lx + x) % config.SCREEN_WIDTH

			if screen.pixels[screen_y][screen_x] {
				pixel_collision = 1
			}

			screen.pixels[screen_y][screen_x] ~= true
		}
	}
	return pixel_collision
}
