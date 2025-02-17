package main

import c8 "chip8"
import "config"
import "core:fmt"
import "core:os"
import "core:time"
import sdl "vendor:sdl2"
import sdl_image "vendor:sdl2/image"


WINDOW_WIDTH :: 640
WINDOW_HEIGHT :: 320
WINDOW_FLAGS :: sdl.WINDOW_SHOWN
RENDER_FLAGS :: sdl.RENDERER_ACCELERATED

renderer: ^sdl.Renderer
event: sdl.Event

main :: proc() {
	if len(os.args) < 2 {
		fmt.println("Usage: program <rom_name>")
		return
	}

	chip8 := c8.Chip8{}
	c8.init(&chip8)

	rom_filename := fmt.tprintf("./ROMS/%s", os.args[1])
	rom_data, ok := os.read_entire_file(rom_filename)
	if !ok {
		fmt.println("Failed to load ROM")
		return
	}
	defer delete(rom_data)

	c8.load(&chip8, raw_data(rom_data), i64(len(rom_data)))


	assert(sdl.Init(sdl.INIT_VIDEO) == 0, sdl.GetErrorString())
	defer sdl.Quit()

	assert(sdl_image.Init(sdl_image.INIT_PNG) != nil, sdl.GetErrorString())

	window := sdl.CreateWindow(
		config.EMULATOR_WINDOW_TITLE,
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		config.SCREEN_WIDTH * config.WINDOW_SCALING,
		config.SCREEN_HEIGHT * config.WINDOW_SCALING,
		WINDOW_FLAGS,
	)
	assert(window != nil, sdl.GetErrorString())
	defer sdl.DestroyWindow(window)

	renderer = sdl.CreateRenderer(window, -1, RENDER_FLAGS)
	assert(renderer != nil, sdl.GetErrorString())
	defer sdl.DestroyRenderer(renderer)


	game_loop: for {
		// Input
		if sdl.PollEvent(&event) {
			if event.type == sdl.EventType.QUIT {
				break game_loop
			}

			if event.type == sdl.EventType.KEYDOWN {
				k := u8(event.key.keysym.sym)
				vkey := c8.map_keyboard(k)

				if vkey != -1 {
					c8.key_down(&chip8.keyboard, vkey)
					fmt.printf("%x : Key is Down\n", vkey)
				}
				#partial switch event.key.keysym.scancode {
				case .ESCAPE:
					break game_loop
				}


			}
			if event.type == sdl.EventType.KEYUP {
				k := u8(event.key.keysym.sym)
				vkey := c8.map_keyboard(k)

				if vkey != -1 {
					c8.key_up(&chip8.keyboard, vkey)
					fmt.printf("%x : Key is Down\n", vkey)
				}
			}
		}

		sdl.SetRenderDrawColor(renderer, 0, 0, 0, 0)
		sdl.RenderClear(renderer)
		sdl.SetRenderDrawColor(renderer, 255, 255, 255, 0)

		for x := 0; x < config.SCREEN_WIDTH; x += 1 {
			for y := 0; y < config.SCREEN_HEIGHT; y += 1 {

				if c8.screen_is_set(&chip8.screen, x, y) {
					rect: sdl.Rect = sdl.Rect {
						i32(x * config.WINDOW_SCALING),
						i32(y * config.WINDOW_SCALING),
						config.WINDOW_SCALING,
						config.WINDOW_SCALING,
					}
					sdl.RenderFillRect(renderer, &rect)
				}


			}
		}


		if chip8.registers.DT > 0 {
			time.sleep(time.Millisecond * 1)
			chip8.registers.DT -= 1
		}

		if chip8.registers.ST > 0 {
			// beep(8000, 100) TODO: Need to implement sound
			chip8.registers.ST -= 1
		}


		opcode := c8.memory_get_short(&chip8.memory, int(chip8.registers.PC))
		chip8.registers.PC += 2
		c8.exec(&chip8, opcode)

		sdl.RenderPresent(renderer)
	}

}
