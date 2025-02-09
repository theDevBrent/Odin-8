package chip8

import "../config"
import "base:runtime"
import "core:fmt"
import "core:math/rand"
import "core:mem"

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
	0xf0, // 0
	0x20,
	0x60,
	0x20,
	0x20,
	0x70, // 1
	0xf0,
	0x10,
	0xf0,
	0x80,
	0xf0, // 2
	0xf0,
	0x10,
	0xf0,
	0xf0,
	0xf0, // 3
	0x90,
	0x90,
	0xf0,
	0x10,
	0x10, // 4
	0xf0,
	0x80,
	0xf0,
	0x10,
	0xf0, // 5
	0xf0,
	0x80,
	0xf0,
	0x90,
	0xf0, // 6
	0xf0,
	0x10,
	0x20,
	0x40,
	0x40, // 7
	0xf0,
	0x90,
	0xf0,
	0x90,
	0xf0, // 8
	0xf0,
	0x90,
	0xf0,
	0x10,
	0xf0, // 9
	0xf0,
	0x90,
	0xf0,
	0x90,
	0x90, // a
	0xf0,
	0x90,
	0xe0,
	0x90,
	0xe0, // b
	0xf0,
	0x80,
	0x80,
	0x80,
	0xf0, // c
	0xe0,
	0x90,
	0x90,
	0x90,
	0xe0, // d
	0xf0,
	0x80,
	0xf0,
	0x80,
	0xf0, // e
	0xf0,
	0x80,
	0xf0,
	0x80,
	0x80, // f
}
