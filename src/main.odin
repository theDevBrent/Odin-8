package main

import c8 "chip8"
import "config"
import "core:fmt"
import sdl "vendor:sdl2"
import sdl_image "vendor:sdl2/image"

WINDOW_WIDTH :: 640
WINDOW_HEIGHT :: 320
WINDOW_FLAGS :: sdl.WINDOW_SHOWN
RENDER_FLAGS :: sdl.RENDERER_ACCELERATED

renderer: ^sdl.Renderer
event: sdl.Event

main :: proc() {

	chip8 := c8.Chip8{}
	chip8.registers.SP = 0

	c8.stack_push(&chip8, 0xff)
	c8.stack_push(&chip8, 0xaa)

	fmt.printf("::%x\n", c8.stack_pop(&chip8))
	fmt.printf("::%x\n", c8.stack_pop(&chip8))


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
				#partial switch event.key.keysym.scancode {
				case .ESCAPE:
					break game_loop
				}
			}
		}

		sdl.SetRenderDrawColor(renderer, 0, 0, 0, 0)
		sdl.RenderClear(renderer)
		sdl.SetRenderDrawColor(renderer, 255, 255, 255, 0)
		rect: sdl.Rect = sdl.Rect{0, 0, 40, 40}

		sdl.RenderFillRect(renderer, &rect)
		sdl.RenderPresent(renderer)
	}
	fmt.println("Odin-8 Emulator!")

}
