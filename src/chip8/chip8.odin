package chip8

import "../config"
import "base:runtime"
import "core:fmt"
import "core:math/rand"
import "core:mem"
import sdl "vendor:sdl2"

Chip8 :: struct {
	memory:    Memory,
	stack:     Stack,
	registers: Registers,
	keyboard:  Keyboard,
	screen:    Screen,
}

init :: proc(chip8: ^Chip8) {
	load_character_set(chip8)
}

exec :: proc(chip8: ^Chip8, opcode: u16) {
	switch opcode {
	// CLS: Clear the display
	case 0x00E0:
		clear_screen(&chip8.screen)
	// RET: Return from subroutine
	case 0x00EE:
		chip8.registers.PC = stack_pop(chip8)
	case:
		exec_extended(chip8, opcode)
	}

}

exec_extended :: proc(chip8: ^Chip8, opcode: u16) {

	nnn := opcode & 0x0fff
	x := (opcode >> 8) & 0x000f
	y := (opcode >> 4) & 0x000f
	kk := opcode & 0x00ff
	n := opcode & 0x000f

	switch opcode & 0xf000 {
	// JP addr, 1nnn jump to location nnn
	case 0x1000:
		chip8.registers.PC = nnn
	// CALL addr, 2nnn Call subroutine at location nnn
	case 0x2000:
		stack_push(chip8, chip8.registers.PC)
		chip8.registers.PC = nnn
	// SE Vx, byte 3xkk Skip next instruction if Vx = kk
	case 0x3000:
		if (u16(chip8.registers.V[x]) == kk) {
			chip8.registers.PC += 2
		}
	// SNE Vx, byte 3xkk Skip next instruction if Vx != kk
	case 0x4000:
		if (chip8.registers.V[x] != u8(kk)) {
			chip8.registers.PC += 2
		}

	// 5xy0 - SE, Vx, Vy, Skip next instruction if Vx = Vy
	case 0x5000:
		if (chip8.registers.V[x] == chip8.registers.V[y]) {
			chip8.registers.PC += 2
		}
	// 6xkk - LD Vx, byte Vx = kk
	case 0x6000:
		chip8.registers.V[x] = u8(kk)
	// 7xkk Add Vx byte Set Vx == Vx + kk
	case 0x7000:
		chip8.registers.V[x] += u8(kk)
	case 0x8000:
		exec_extended_eight(chip8, opcode)
	// 9xy0 - SNE Vx, Vy
	case 0x9000:
		if chip8.registers.V[x] != chip8.registers.V[y] {
			chip8.registers.PC += 2
		}
	// Annn - LD I, addr
	case 0xA000:
		chip8.registers.I = nnn
	// Bnnn - JP V0, addr
	case 0xB000:
		chip8.registers.PC = nnn + u16(chip8.registers.V[0x00])
	// Cxkk - RND Vx, byte
	case 0xC000:
		chip8.registers.V[x] = u8(u16(rand.int_max(255)) & kk)
	// Dxyn - DRW Vx, Vy, nibble
	case 0xD000:
		sprite := &chip8.memory.memory[chip8.registers.I]
		chip8.registers.V[0x0f] = draw_sprite(
			&chip8.screen,
			int(chip8.registers.V[x]),
			int(chip8.registers.V[y]),
			sprite,
			int(n),
		)

	// Keyboard
	case 0xE000:
		switch (opcode & 0x00ff) {
		// Ex9E = SKP Vx
		case 0x9E:
			if key_is_pressed(&chip8.keyboard, int(chip8.registers.V[x])) {
				chip8.registers.PC += 2
			}
		// ExA1 - SKNP Vx
		case 0xa1:
			if !key_is_pressed(&chip8.keyboard, int(chip8.registers.V[x])) {
				chip8.registers.PC += 2
			}
		}
	case 0xF000:
		exec_extended_f(chip8, opcode)


	}


}

exec_extended_f :: proc(chip8: ^Chip8, opcode: u16) {
	x := (opcode >> 8) & 0x000f

	switch (opcode & 0x00ff) {
	// Fx07 - LD Vx, DT
	case 0x07:
		chip8.registers.V[x] = chip8.registers.DT
	// Fx0A - LD Vx, K
	case 0x0A:
		pressed_key := wait_for_key_press(chip8)
		chip8.registers.V[x] = u8(pressed_key)
	// Fx15 -  LD DT, Vx
	case 0x15:
		chip8.registers.DT = chip8.registers.V[x]
	// Fx18 - LD ST, Vx
	case 0x18:
		chip8.registers.ST = chip8.registers.V[x]
	// Fx1E
	case 0x1E:
		chip8.registers.I += u16(chip8.registers.V[x])
	// Fx29 - LD F, Vx
	case 0x29:
		chip8.registers.I = u16(chip8.registers.V[x] * config.DEFAULT_SPRITE_HEIGHT)
	// Fx33 - LD B, Vx
	case 0x33:
		hundreds := chip8.registers.V[x] / 100
		tens := chip8.registers.V[x] / 10 % 10
		units := chip8.registers.V[x] % 10
		memory_set(&chip8.memory, int(chip8.registers.I), hundreds)
		memory_set(&chip8.memory, int(chip8.registers.I + 1), tens)
		memory_set(&chip8.memory, int(chip8.registers.I + 2), units)
	// Fx55 - LD [I], vx
	case 0x55:
		for i: u16 = 0; i <= x; i += 1 {
			memory_set(&chip8.memory, int(chip8.registers.I + i), chip8.registers.V[i])
		}
	// Fx65 - LD Vx, [I]
	case 0x65:
		for i: u16 = 0; i <= x; i += 1 {
			chip8.registers.V[i] = memory_get(&chip8.memory, int(chip8.registers.I + i))
		}
	}
}

exec_extended_eight :: proc(chip8: ^Chip8, opcode: u16) {
	x := (opcode >> 8) & 0x000f
	y := (opcode >> 4) & 0x000f
	last_bits := opcode & 0x00f
	carry: u16 = 0

	switch last_bits {
	// 8xy0 - LD Vx, Vy Vx = Vy
	case 0x00:
		chip8.registers.V[x] = chip8.registers.V[y]
	// 8xy1 - Bitwise OR on Vx and Vy and stores result in Vx
	case 0x01:
		chip8.registers.V[x] = chip8.registers.V[x] | chip8.registers.V[y]
	// 8xy2 - Bitwise AND on Vx and Vy and stores result in Vx
	case 0x02:
		chip8.registers.V[x] = chip8.registers.V[x] & chip8.registers.V[y]
	// 8xy3 - Bitwiser OR on Vx and Vy stores result in Vx
	case 0x03:
		chip8.registers.V[x] = chip8.registers.V[x] ~ chip8.registers.V[y]
	// 8xy4 - Set Vx = Vx + Vy set VF CARRY
	case 0x04:
		carry = u16(chip8.registers.V[x]) + u16(chip8.registers.V[y])
		chip8.registers.V[0x0f] = 0
		if carry > 0xff {
			chip8.registers.V[0x0f] = 1
		}
		chip8.registers.V[x] = u8(carry)
	// 8xy5 Set Vx = Vx - Vy set VF = NOT borrow
	case 0x05:
		chip8.registers.V[0x0f] = chip8.registers.V[x] > chip8.registers.V[y]
		chip8.registers.V[x] = chip8.registers.V[x] - chip8.registers.V[y]
	// 8xy6 - SHR Vx {, Vy}
	case 0x06:
		chip8.registers.V[0x0f] = chip8.registers.V[x] & 0x01
		chip8.registers.V[x] = chip8.registers.V[x] / 2
	// 8xy7 - SUBN Vx, Vy
	case 0x07:
		chip8.registers.V[0x0f] = chip8.registers.V[y] > chip8.registers.V[x]
		chip8.registers.V[x] = chip8.registers.V[y] - chip8.registers.V[x]
	// 8xyE - SHL Vx {, Vy}
	case 0x0E:
		chip8.registers.V[0x0f] = chip8.registers.V[x] & 0x80
		chip8.registers.V[x] = chip8.registers.V[x] * 2
	}
}

wait_for_key_press :: proc(chip8: ^Chip8) -> int {
	event: sdl.Event
	for {
		if sdl.WaitEvent(&event) {
			if event.type == sdl.EventType.KEYDOWN {
				c := event.key.keysym.sym
				chip8_key := map_keyboard(u8(c))

				if chip8_key != -1 {
					key_down(&chip8.keyboard, chip8_key)
					return chip8_key
				}
			}
		}
	}

	return -1
}

load :: proc(chip8: ^Chip8, buf: ^u8, size: i64) {
	assert(size + config.PROGRAM_LOAD_ADDRESS < config.MEMORY_SIZE)
	src := mem.slice_ptr(buf, int(size))
	dst := chip8.memory.memory[config.PROGRAM_LOAD_ADDRESS:config.PROGRAM_LOAD_ADDRESS + int(size)]
	runtime.copy_slice(dst, src)

	chip8.registers.PC = config.PROGRAM_LOAD_ADDRESS
}


load_character_set :: proc(chip8: ^Chip8) {
	for i := 0; i < len(default_character_set); i += 1 {
		value := default_character_set[i]
		memory_set(&chip8.memory, i, value)
	}
}


default_character_set := []u8 {
	0xf0,
	0x90,
	0x90,
	0x90,
	0xf0,
	0x20,
	0x60,
	0x20,
	0x20,
	0x70,
	0xf0,
	0x10,
	0xf0,
	0x80,
	0xf0,
	0xf0,
	0x10,
	0xf0,
	0x10,
	0xf0,
	0x90,
	0x90,
	0xf0,
	0x10,
	0x10,
	0xf0,
	0x80,
	0xf0,
	0x10,
	0xf0,
	0xf0,
	0x80,
	0xf0,
	0x90,
	0xf0,
	0xf0,
	0x10,
	0x20,
	0x40,
	0x40,
	0xf0,
	0x90,
	0xf0,
	0x90,
	0xf0,
	0xf0,
	0x90,
	0xf0,
	0x10,
	0xf0,
	0xf0,
	0x90,
	0xf0,
	0x90,
	0x90,
	0xe0,
	0x90,
	0xe0,
	0x90,
	0xe0,
	0xf0,
	0x80,
	0x80,
	0x80,
	0xf0,
	0xe0,
	0x90,
	0x90,
	0x90,
	0xe0,
	0xf0,
	0x80,
	0xf0,
	0x80,
	0xf0,
	0xf0,
	0x80,
	0xf0,
	0x80,
	0x80,
}
